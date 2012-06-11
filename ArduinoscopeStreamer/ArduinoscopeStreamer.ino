/**** ArduinoscopeStreamer ********
** Written by Sean M. Montgomery 2012/05
** http://produceconsumerobot.com/
** Reads values from the specified arduino inputs at the
** specified sampling rate and writes them to the serial stream
** in csv format, followed by the time of data aquisition 
** in milliseconds
** Created for use with ArduinoscopeViewer
**
**** NOTE ****
// Created to work with Arduino Mega with A0-A15 analog pins and
// the program will crash on arduino board without these pins.
// Needs an ifdef or something to determine if the A0-A15 functions
// are available. Until that's implemented, the user may comment out the
// appropriate lines below, e.g. //if (A15 == pin) {return true;}
**********************************/

/********* USER DEFINED VARIABLES *************/
const int nInputs = 1; // Number of inputs to read
int inputs[nInputs] = {A0}; // Specifies which inputs to measure
unsigned long samplingFreq = 1000; // Sampling rate in Hz

#define BAUDRATE 57600 // Serial baud rate
/****** END OF USER DEFINED VARIABLES *********/


unsigned long samplingDelay;
unsigned long lastDelay;
unsigned long lastSampleTime;
unsigned long totalTime = 0;
int values[nInputs];

void setup() {
  Serial.begin(BAUDRATE); // USB
  samplingDelay = 1000000/samplingFreq; // In microseconds
  for (int i=0; i<nInputs; i++) {
    pinMode(inputs[i], INPUT);  
  }
  lastSampleTime = micros();
}

void loop() {
  lastDelay = GetMicrosDelay(lastSampleTime); 
  if ( lastDelay > samplingDelay ) {
    lastSampleTime = micros();
    totalTime += (lastDelay / 1000); // in milliseconds
    
    // Read values from pins
    for (int i=0; i<nInputs; i++) {
      if (IsAnalogPin(inputs[i])) {
        values[i] = analogRead(inputs[i]);
      } else {
        values[i] = digitalRead(inputs[i]);
      }
    }
    
    // Write values to serial stream
    for (int i=0; i<nInputs; i++) {
      Serial.print(values[i], DEC);  
      Serial.print(",");
    }
    
    // Last value is the duration
    Serial.print(totalTime, DEC); // record time (in ms) data was received for accuracy
    Serial.println(",");
  }
}

// Returns true if pin is an analog pin
// Created to work with Arduino Mega with A0-A15 analog pins and
// the program will crash on arduino board without these pins.
// Needs an ifdef or something to determine if the A0-A15 functions
// are available. Until that's implemented, the user may comment out the
// appropriate lines.
boolean IsAnalogPin(int pin) {
  if (A0 == pin) {return true;} 
  if (A1 == pin) {return true;} 
  if (A2 == pin) {return true;} 
  if (A3 == pin) {return true;} 
  if (A4 == pin) {return true;} 
  if (A5 == pin) {return true;} 
  if (A6 == pin) {return true;} 
  if (A7 == pin) {return true;} 
  if (A8 == pin) {return true;} 
  if (A9 == pin) {return true;} 
  if (A10 == pin) {return true;} 
  if (A11 == pin) {return true;} 
  if (A12 == pin) {return true;} 
  if (A13 == pin) {return true;} 
  if (A14 == pin) {return true;} 
  if (A15 == pin) {return true;} 
  return false;
}
      
/* GetMicrosDelay 
** calculates time difference in microseconds between current time
** and passed time
** accounts for rollover of unsigned long
*/
unsigned long GetMicrosDelay(unsigned long t0) {
  unsigned long dt; // delay time (change)
  
  unsigned long t1 = micros();
  if ( (t1 - t0) < 0 ) { // account for unsigned long rollover
    dt = 4294967295 - t0 + t1; 
  } else {
    dt = t1 - t0;
  }
  return dt;
}
    
