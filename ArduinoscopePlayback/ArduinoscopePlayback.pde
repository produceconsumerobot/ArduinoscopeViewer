/*
  A simple oscilliscope widget test
  
  (c) 2009 David Konsumer <david.konsumer@gmail.com>
  
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General
  Public License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA  02111-1307  USA
*/

/**** ArduinoscopeViewer.pde ****
** Modified from TestOscope.pde by Sean M. Montgomery 2012/05
** http://produceconsumerobot.com/
** The program can used to plot and record
** any CSV data via the serial stream.
**
** -- Data is read from an arduino csv serial stream
** -- Select the serialPort and plotVars to display (See User 
**    Selected Setup Variables below.)
** -- Data may be written to a csv file using the "RECORD" button.
** -- y-axis scale may be adjusted using the "*2" and "/2" buttons.
** -- y-axis scale and offset defaults may be adjusted in code below.
**
***********************************/


/**** User Selected Setup Variables ****/
/***************************************/
// Use serialPort to select the correct serial port of your MindSet.
// See list printed on program start for serial port options.
String serialPort = "COM10";

// Give labels to the data values read from the arduino. 
String[] plotVars = {"cushion_m", "Arm_m", "Arm_s", "LumbarSide_f", "LumbarHorz_f", "RF_Spring_f", "RB_Spring_f", "L_thigh_f", "R_thigh_f", "Time"};

// yOffsets sets the y-axis offset for each plotVar
// offset the raw data (1st variable) by half the default scope resolution
// to prevent negative values from extending into other windows
int[] yOffsets = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

// yFactors sets the default y-axis scale for each plotVar
// yFactors can also be adjusted using buttons in the display window
float[] yFactors = {1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f,1f}; 

float playbackSpeed = 1.08;

// Directory and name of your saved MindSet data. Make sure you 
// have write privileges to that location.
String saveDir = ".\\";
String[] fName = {saveDir, "Faurecia_Compliant_Back_Cushion_Matt_cushion_magpot_ruler", nf(year(),4), nf(month(),2), nf(day(),2), 
  nf(hour(),2), nf(minute(),2), nf(second(),2), "csv"};
String saveFileName = join(fName, '.');

// Choose window dimensions in number of pixels
int windowWidth = 650; 
int windowHeight = 900;

// plotLastVar can be set to false omit the last variable from plotting
// This can be useful if "Time" is the last variable
boolean plotLastVar = false;
/*******************************************/
/**** END User Selected Setup Variables ****/


boolean saveDataBool = false; // wait until user turns on recording
boolean printPlotVarNames = true; // prints plotVars when recordind is first turned on

int numScopes;

import arduinoscope.*;
import processing.serial.*;
import controlP5.*;
import javax.swing.JFileChooser;

Oscilloscope[] scopes;
Serial port;
ControlP5 controlP5;
PrintWriter output = null;
BufferedReader reader;
long currentTime;
//int[] currentVals;
long nextTime;
long totalTime = 0;
Timer timer;
boolean paused = false;
long timerRemaining = 0;

int LINE_FEED=10; 
int[] vals;
int[] nextVals;

void setup() {
  size(windowWidth, windowHeight, P2D);
  background(0);
  
  readFile();
  
  if (plotLastVar) {
    numScopes = plotVars.length;
  } else {
    numScopes = plotVars.length - 1;
  }     
  
  scopes = new Oscilloscope[numScopes];
  
  controlP5 = new ControlP5(this);
     
  int[] dimv = new int[2];
  dimv[0] = width-130; // 130 margin for text
  dimv[1] = height/scopes.length;
  
  // setup vals from serial
  vals = new int[scopes.length];
  nextVals = new int[scopes.length];

  readNextLine();
  println(currentTime + ", " + nextTime);
  for (int i=0;i<scopes.length;i++){
    print(vals[i] + ",");
  }
  timer = new Timer(nextTime-currentTime);
  timer.start();
  
  String buttonKlug = "";
  
  for (int i=0;i<scopes.length;i++){
    int[] posv = new int[2];
    posv[0]=0;
    posv[1]=dimv[1]*i;

    // random color, that will look nice and be visible
    scopes[i] = new Oscilloscope(this, posv, dimv);
    scopes[i].setLine_color(color((int)random(255), (int)random(127)+127, 255)); 
    
    // yFactor buttons
    controlP5.addButton(i+"*2",1,dimv[0]+10,posv[1]+20,20,20).setId(i).setLabel("*2");  
    controlP5.addButton((20+i)+"/2",1,dimv[0]+10,posv[1]+70,20,20).setId(20+i).setLabel("/2");       
  }
  // record and pause buttons at top of window
  //controlP5.addButton("Record",1,dimv[0]+85,5,40,20).setId(1000);
  //controlP5.controller("Record").setColorBackground( color( 0, 255 , 0 ) );
  //controlP5.controller("Record").setColorLabel(0);
  controlP5.addButton("Pause",1,dimv[0]+85,30,40,20).setId(1100);
  
  if (false) {
    // setup serial port     
    println(Serial.list());
    //port = new Serial(this, Serial.list()[serialPortNum], 57600);
    port = new Serial(this, serialPort, 57600);
    // clear and wait for linefeed
    port.clear();
    port.bufferUntil(LINE_FEED);
  }

}

void draw() {
  
  if (!paused) {
    background(0);
    
    if (timer.isFinished()) {
      totalTime = totalTime + (nextTime-currentTime);
      readNextLine();
      timer = new Timer((long)((nextTime-currentTime)/playbackSpeed));
      timer.start();
    }  
    
    for (int i=0;i<scopes.length;i++){
      
      scopes[i].drawBounds(); 
      scopes[i].addData(int(vals[i] * yFactors[i]) + yOffsets[i]);
      scopes[i].draw();
    
      stroke(255);
      
      int[] pos = scopes[i].getPos();
      int[] dim = scopes[i].getDim();
      
      // separator lines
      line(0, pos[1], width, pos[1]);
   
      if (true) {
        // yfactor text
        fill(255);
        text("y * " + yFactors[i], dim[0] + 10,pos[1] + 60); 
        fill(scopes[i].getLine_color());
        text(plotVars[i], dim[0] + 10, pos[1] + 15);
      }
    }    
    
    // draw text seperator, based on first scope
    int[] dim = scopes[0].getDim();
    stroke(255);
    line(dim[0], 0, dim[0], height);
  }  
  // update buttons
  if (true) {
    controlP5.draw();
  }
}

void readFile() {
  JFileChooser chooser = new JFileChooser(saveDir);
  chooser.setFileFilter(chooser.getAcceptAllFileFilter());
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) 
  {
    println("You chose to open this file: " + chooser.getSelectedFile().getName());
    reader = createReader(chooser.getSelectedFile().getName());
    String s;
    try {
      s = reader.readLine();
      String[] temp = split(s,',');
      for (int i=0; i<temp.length; i++) {
        String t = temp[i];
        print(t + ", ");
      }
      plotVars = temp;
    } catch (IOException e) {
      e.printStackTrace();
      s = null;
    }
  }
}

void readNextLine() {
  String s;
  try {
    s = reader.readLine();
    //println(s);
    if (vals[0] == 0) {
      vals = int(split(s, ','));
      currentTime = vals[vals.length-2];
      s = reader.readLine();
      nextVals = int(split(s, ','));
      nextTime = nextVals[vals.length-2];
    } else {
      vals = nextVals;
      currentTime = vals[vals.length-2];
      nextVals = int(split(s, ','));
      nextTime = nextVals[vals.length-2];
      //println(totalTime + ", " + vals.length + ", " + currentTime + ", " + nextTime); 
      println("t=" + totalTime + ", " + vals.length); 
      for (int i=0;i<scopes.length;i++){
        print(vals[i] + ",");
      }
      println("");
    }
  } catch (IOException e) {
    e.printStackTrace();
    s = null;
    for (int i=0;i<scopes.length;i++){
      vals[i] = 0;
    }
    println("END OF FILE REACHED");  
  } 
}


// handle serial data
void serialEvent(Serial p) { 
  String data = p.readStringUntil(LINE_FEED);
  if (data != null) {
    // println(data);
    vals = int(split(data, ','));
  }
  
  if (saveDataBool)
  {
    if (printPlotVarNames) {
      output.println(join(plotVars,','));
      printPlotVarNames = false;
    }
    output.print(data);
  }
}

// handles button clicks
void controlEvent(ControlEvent theEvent) {
  int id = theEvent.controller().id();
  println(id);  
  if (id < 20) { // increase yFactor
    yFactors[id] = yFactors[id] * 2;
  } else if (id < 40){ // decrease yFactor
    yFactors[id-20] = yFactors[id-20] / 2;
  } else if ( id == 1100) { // pause display
    if (!paused) {
      paused = true;
      timerRemaining = timer.timeLeft();
      println(timerRemaining); 
    } else {
      paused = false;
      timer = new Timer(timerRemaining);
      //timer = new Timer(nextTime-currentTime);
      timer.start();
    }
    //for (int i=0; i<numScopes; i++) {
    //  scopes[i].setPause(!scopes[i].isPause());
    //}
  }
}

class Timer {
 
  long savedTime; // When Timer started
  long totalTime; // How long Timer should last
  
  Timer(long tempTotalTime) {
    totalTime = tempTotalTime;
  }
  
  // Starting the timer
  void start() {
    // When the timer starts it stores the current time in milliseconds.
    savedTime = millis(); 
  }
  
  long timeLeft() {
    return (totalTime - (millis()- savedTime));
  }
  
  // The function isFinished() returns true if 5,000 ms have passed. 
  // The work of the timer is farmed out to this method.
  boolean isFinished() { 
    // Check how much time has passed
    long passedTime = millis()- savedTime;
    if (passedTime > totalTime) {
      return true;
    } else {
      return false;
    }
  }
}
