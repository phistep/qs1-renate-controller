/*
  Based on Sketch built by Gustavo Silveira (aka Music Nerd)
  Modified by Dolce Wang

  This code is only for Arduinos that use ATmega32u4 (like Micro, Pro Micro, Leonardo...)
  Remember to also assign the correct board in the IDE (like Tools / Boards / Sparkfun AVR / Pro Micro...)

*/

// Change any fields with //**


// LIBRARY

#include "MIDIUSB.h"  

// BUTTONS
const int NButtons = 4; //***  total number of buttons
const int buttonPin[NButtons] = {2, 3, 5, 7}; //*** define Digital Pins connected from Buttons to Arduino; (ie {10, 16, 14, 15, 6, 7, 8, 9, 2, 3, 4, 5}; 12 buttons)
                                            
int buttonCState[NButtons] = {};        // stores the button current value
int buttonPState[NButtons] = {};        // stores the button previous value

      
// debounce
unsigned long lastDebounceTime[NButtons] = {0};  // the last time the output pin was toggled
unsigned long debounceDelay = 50;    //** the debounce time; increase if the output flickers


// POTENTIOMETERS
const int NPots = 8; //*** total number of pots (knobs and faders)
const int potPin[NPots] = {A9, A8, A7, A6, A3, A2, A1, A0}; //*** define Analog Pins connected from Pots to Arduino; Leave nothing in the array if 0 pots {}
int potCState[NPots] = {0}; // Current state of the pot; delete 0 if 0 pots
int potPState[NPots] = {0}; // Previous state of the pot; delete 0 if 0 pots
int potVar = 0; // Difference between the current and previous state of the pot

int midiCState[NPots] = {0}; // Current state of the midi value; delete 0 if 0 pots
int midiPState[NPots] = {0}; // Previous state of the midi value; delete 0 if 0 pots

const int TIMEOUT = 300; //* Amount of time the potentiometer will be read after it exceeds the varThreshold
const int varThreshold = 20; //* Threshold for the potentiometer signal variation
boolean potMoving = true; // If the potentiometer is moving
unsigned long PTime[NPots] = {0}; // Previously stored time; delete 0 if 0 pots
unsigned long timer[NPots] = {0}; // Stores the time that has elapsed since the timer was reset; delete 0 if 0 pots


// MIDI Assignments 
byte midiCh = 1; //* MIDI channel to be used
byte note = 36; //* Lowest note to be used; 36 = C2; 60 = Middle C
byte cc = 0; //* Lowest MIDI CC to be used


// SETUP
void setup() {

  // Baud Rate
  // 31250 for MIDI class compliant | 115200 for Hairless MIDI

  // Buttons
  // Initialize buttons with pull up resistors
  for (int i = 0; i < NButtons; i++) {
    pinMode(buttonPin[i], INPUT_PULLUP);
  }

}

////
// LOOP
void loop() {

  potentiometers(A9,0);
  potentiometers(A8,1);
  potentiometers(A7,2);
  buttons(2, 36);
}

////
// BUTTONS
void buttons(int input, int channel) {


    buttonCState[channel] = digitalRead(input);  // read pins from arduino

    if ((millis() - lastDebounceTime[channel]) > debounceDelay) {

      if (buttonPState[channel] != buttonCState[channel]) {
        lastDebounceTime[channel] = millis();

        if (buttonCState[channel] == LOW) {

          // Sends the MIDI note ON 
          
         // use if using with ATmega32U4 (micro, pro micro, leonardo...)
          noteOn(midiCh, channel, 127);  // channel, note, velocity
          MidiUSB.flush();


        }
        else {

          // Sends the MIDI note OFF accordingly to the chosen board

          // use if using with ATmega32U4 (micro, pro micro, leonardo...)
          noteOn(midiCh, channel, 0);  // channel, note, velocity
          MidiUSB.flush();

        }
        buttonPState[channel] = buttonCState[channel];
      }
    }

}

////
// POTENTIOMETERS
void potentiometers(int input, int channel) {

    int potAvg = 0;
    for ( int j = 0; j < 10; j++){
       potAvg += analogRead(input); // reads the pins from arduino
    }
    potCState[channel] = int(potAvg/10);
    Serial.print(int(potCState[channel]/10));
    midiCState[channel] = map(potCState[channel], 0, 1023, 0, 127); // Maps the reading of the potCState to a value usable in midi

    potVar = abs(potCState[channel] - potPState[channel]); // Calculates the absolute value between the difference between the current and previous state of the pot

    if (potVar > varThreshold) { // Opens the gate if the potentiometer variation is greater than the threshold
      PTime[channel] = millis(); // Stores the previous time
    }

    timer[channel] = millis() - PTime[channel]; // Resets the timer 11000 - 11000 = 0ms

    if (timer[channel] < TIMEOUT) { // If the timer is less than the maximum allowed time it means that the potentiometer is still moving
      potMoving = true;
    }
    else {
      potMoving = false;
    }

    if (potMoving == true) { // If the potentiometer is still moving, send the change control
      if (midiPState[channel] != midiCState[channel]) {

        // Sends  MIDI CC 
        // Use if using with ATmega32U4 (micro, pro micro, leonardo...)
        controlChange(midiCh, channel, midiCState[channel]); //  (channel, CC number,  CC value)
        MidiUSB.flush();

        potPState[channel] = potCState[channel]; // Stores the current reading of the potentiometer to compare with the next
        midiPState[channel] = midiCState[channel];
      }
    }
    delay(10);

}


// if using with ATmega32U4 (micro, pro micro, leonardo...)


// Arduino MIDI functions MIDIUSB Library
void noteOn(byte channel, byte pitch, byte velocity) {
  midiEventPacket_t noteOn = {0x09, 0x90 | channel, pitch, velocity};
  MidiUSB.sendMIDI(noteOn);
}

void noteOff(byte channel, byte pitch, byte velocity) {
  midiEventPacket_t noteOff = {0x08, 0x80 | channel, pitch, velocity};
  MidiUSB.sendMIDI(noteOff);
}

void controlChange(byte channel, byte control, byte value) {
  midiEventPacket_t event = {0x0B, 0xB0 | channel, control, value};
  MidiUSB.sendMIDI(event);
}
