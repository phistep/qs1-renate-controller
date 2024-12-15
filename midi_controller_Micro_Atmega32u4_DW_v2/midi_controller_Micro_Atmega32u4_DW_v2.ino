/*
  Based on Sketch built by Gustavo Silveira (aka Music Nerd)
  Modified by Dolce Wang

  TODO
  - fix midi channel, volume updates, ...
  - set custom name
*/

#include "MIDIUSB.h"

// MIDI
const byte MIDI_CHANNEL = 1;
const byte MIDI_BUTTON_UP = 0;
const byte MIDI_BUTTON_DOWN = 127;
const byte MIDI_MIN = 0;
const byte MIDI_MAX = 127;

// buttons
const int NUM_BUTTONS = 5;
const int button_pin[NUM_BUTTONS] = {7, 14, 15, 16, 18};
int button_value[NUM_BUTTONS] = {};
int button_prev_value[NUM_BUTTONS] = {};
unsigned long last_debounce_time[NUM_BUTTONS] = {0};
const unsigned long DEBOUNCE_DELAY = 50; // ms
const byte PIN_BUTTON_UP = HIGH;
const byte PIN_BUTTON_DOWN = LOW;

// potentiometers
const int NUM_POTS = 6;
const int pot_pin[NUM_POTS] = {A2, A3, A6, A7, A8, A9};
const int POT_MIN = 0;
const int POT_MAX = 1023;
int pot_prev_value[NUM_POTS] = {POT_MIN};
unsigned long pot_last_change[NUM_POTS] = {0}; // ms
const int POT_TIMEOUT = 300; // ms
const int POT_THRESHOLD = 20; // /1024
int midi_prev_value[NUM_POTS] = {MIDI_MIN};


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
        button_prev_value[pin] = button_value[pin];
      }
    }

    char buff[80];
    sprintf(
      buff, "P%02i=%4s #%2i=%03i  |  ",
      pin, (button_value[pin] == PIN_BUTTON_DOWN) ? "DOWN": "UP",
      cc, (button_value[pin] == PIN_BUTTON_DOWN) ? MIDI_BUTTON_DOWN : MIDI_BUTTON_UP
    );
    Serial.print(buff);
}

void updatePotentiometer(
    const int pin,
    const int cc,
    const int channel = MIDI_CHANNEL,
    const int num_avg = 10
) {
    int value = 0;
    for (int i = 0; i < num_avg; i++) {
        value += analogRead(pin);
    }
    value /= num_avg;
    value = POT_MAX - value;  // potentiometer position was inverted
    int midi_value = map(value, POT_MIN, POT_MAX, MIDI_MIN, MIDI_MAX);

    int change = abs(value - pot_prev_value[pin]);
    if (change > POT_THRESHOLD) {
      pot_last_change[pin] = millis();
    }
    unsigned long timer = millis() - pot_last_change[pin];

    bool pot_changing = (timer < POT_TIMEOUT);
    if (pot_changing) {
      // only send control if value is still chaning
      if (midi_prev_value[cc] != midi_value) {
        controlChange(channel, cc, midi_value);
        pot_prev_value[cc] = value;
        midi_prev_value[cc] = midi_value;
      }
    }

    char buff[80];
    sprintf(
      buff, "P%02i=%4i #%02i=%03i  |  ",
      pin, value,
      cc, midi_value
    );
    Serial.print(buff);
}


void setup() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
    pinMode(button_pin[i], INPUT_PULLUP);
  }
}

void loop() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
    int pin = button_pin[i];
    updateButton(pin, pin);
  }

  for (int i = 0; i < NUM_POTS; i++) {
    int pin = pot_pin[i];
    updatePotentiometer(pin, pin);
  }

  Serial.println();
  MidiUSB.flush();
}
