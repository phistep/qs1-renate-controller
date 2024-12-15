/*
  Based on Sketch built by Gustavo Silveira (aka Music Nerd)
  Modified by Dolce Wang
*/

#include "MIDIUSB.h"

// MIDI
const byte MIDI_CHANNEL = 1;
const byte MIDI_BUTTON_UP = 0;
const byte MIDI_BUTTON_DOWN = 127;

// buttons
const int NUM_BUTTONS = 5;
const int button_pin[NUM_BUTTONS] = {7, 14, 15, 16, 18};
int button_value[NUM_BUTTONS] = {};
int button_prev_value[NUM_BUTTONS] = {};
unsigned long last_debounce_time[NUM_BUTTONS] = {0};
const unsigned long DEBOUNCE_DELAY = 50; // ms
const byte PIN_BUTTON_UP = HIGH;
const byte PIN_BUTTON_DOWN = LOW;

/*
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

 */

void controlChange(byte channel, byte control, byte value) {
  midiEventPacket_t event = {0x0B, 0xB0 | channel, control, value};
  MidiUSB.sendMIDI(event);
}


void updateButton(int pin, int cc, int channel = MIDI_CHANNEL) {
    button_value[pin] = digitalRead(pin);
    if ((millis() - last_debounce_time[pin]) > DEBOUNCE_DELAY) {
      if (button_prev_value[pin] != button_value[pin]) {
        last_debounce_time[cc] = millis();
        int value = (button_value[pin] == PIN_BUTTON_DOWN) ? MIDI_BUTTON_DOWN : MIDI_BUTTON_UP;
        controlChange(channel, cc, value);
        MidiUSB.flush();
        button_prev_value[pin] = button_value[pin];
      }
    }

    char buff[80];
    sprintf(
      buff,
      "P%02i=%4s #%2i=%03i  |  ",
      pin,
      (button_value[pin] == PIN_BUTTON_DOWN) ? "DOWN": "UP",
      cc,
      (button_value[pin] == PIN_BUTTON_DOWN) ? MIDI_BUTTON_DOWN : MIDI_BUTTON_UP
    );
    Serial.print(buff);
}

/*
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
*/


void setup() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
    pinMode(button_pin[i], INPUT_PULLUP);
  }
}

void loop() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
      int pin = button_pin[i];
      //int value = digitalRead(pin);
      updateButton(pin, pin);
  }
  Serial.println();

  //potentiometers(A7,7);
  // potentiometers(A8,8);
  // potentiometers(A9,9);
}
