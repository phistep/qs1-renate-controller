int RXLED = 17;

void setup() {
  Serial.begin(9600);
  pinMode(RXLED, OUTPUT);
}

void loop() {
  digitalWrite(RXLED, HIGH);
  delay(1000);
  digitalWrite(RXLED, LOW);
  delay(500);
}
