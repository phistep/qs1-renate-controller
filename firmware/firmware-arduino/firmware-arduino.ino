#define SPEED_OF_SOUND_MPS 343.0f

#define LED LED_BUILTIN
#define PIN_TRIG 9
#define PIN_ECHO 10

#define TIMEOUT_US 1000000
#define SAMPLE_RATE_FPS 60


void setup() {
  pinMode(LED, OUTPUT);

  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);

  Serial.begin(9600);
}

void loop() {
    digitalWrite(LED, LOW);
    digitalWrite(PIN_TRIG, LOW);
    delayMicroseconds(2);

    digitalWrite(LED, HIGH);
    digitalWrite(PIN_TRIG, HIGH);
    delayMicroseconds(10);
    digitalWrite(LED, LOW);
    digitalWrite(PIN_TRIG, LOW);

    double duration_s = pulseIn(PIN_ECHO, HIGH, TIMEOUT_US) * 1e-6;
    double distance_m = duration_s * SPEED_OF_SOUND_MPS / 2.;
    Serial.print("distance [cm]: ");
    Serial.println(distance_m * 100., 8);

    delay(1./SAMPLE_RATE_FPS * 1000);
}
