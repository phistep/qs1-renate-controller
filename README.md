# Arduino

[Tutorial][instructables]

```sh
brew install arduino-ide
```

1. Add the Pro Micro board to your listGo to Arduino < Preferences... (File < Preferences... for PC)
2. Paste this URL to the Additional Boards Manager URLs text field
   ```
   https://raw.githubusercontent.com/sparkfun/Arduino_Boards/master/IDE_Board_Manager/package_sparkfun_index.json
   ```
3. Add the `MIDIUSB.h` Library
4. Go to _Tools_ > _Manage Libraries..._, search for `MIDIUSB` by _Gary Grewal_ and install the latest version
6. Go to _Tools_ < _Boards Manager_, install `Sparkfun AVR Boards`...
7. Seledct  _Tools_ > _Board_ > `Sparkfun Pro Micro`
8. Select _Tools_ > _Processor..._ > `ATmega32U4 (5V, 16 MHz)` (Make sure you select the correct voltage, otherwise you will need to reset your Pro Micro)
9. _Tools_ > _Port..._ > `/dev/cu.usbmodemMID1` (PC will probably say COM)



[instructables]: https://www.instructables.com/DIY-USB-Midi-Controller-With-Arduino-a-Beginners-G/
