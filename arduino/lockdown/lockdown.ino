const String VERSION = "0.1.0";

const int EGRESS = 0;
const int MOTION = 1;
const int TRIP   = 2;
const int CLOSED = 0;
const int OPEN   = 1;
const String TYPES[] = { "egress", "motion", "trip" };
String incoming = "";

// All sensor states
int states[54];
int lastStates[54];

void setup() {
  //start serial connection
  Serial.begin(57600);
  //configure pin2 as an input and enable the internal pull-up resistor
  for (int i=22; i<54; i++) {
    pinMode(i, INPUT_PULLUP);
    states[i] = lastStates[i] = digitalRead(i);
  }
  pinMode(13, OUTPUT);
  pinMode(2, INPUT);
}

void loop() {
  checkForIncoming();
  checkAllSensors();
}

void outputState(int i, int type) {
  Serial.print("{\"result\":{\"type\":\"");
  Serial.print(TYPES[type]);
  Serial.print("\",\"id\":");
  Serial.print(i);
  Serial.print(",\"value\":");
  Serial.print(states[i]);
  Serial.print(",\"millis\":");
  Serial.print(millis());
  Serial.println("}}");
}


void checkForIncoming() {
  incoming = "";
  byte incomingByte;

  while (Serial.available() > 0) {
    incomingByte = Serial.read();

    if (incomingByte != 13 && incomingByte != 10) {
      incoming += char(incomingByte);
    }

    // give a chance for each byte to make it to the stream
    delay(1);
  }

  if (incoming != "") {
    if (incoming == "{\"method\":\"status\"}") {
      status();
    } else if (incoming == "{\"method\":\"version\"}") {
      version();
    } else {
      error("unknown method");
    }
  }
}


void checkAllSensors() {
  for (int i=22; i<54; i++) {
    inputStatus(i, true);
  }

  digitalWrite(13, digitalRead(22));

  // just a little bit of delay to debounce
  delay(10);
}


// Return status all inputs
void status() {
  for (int i=22; i<54; i++) {
    outputState(i, EGRESS);
  }
}


// Get the state of a single input and optionally automatically output it
void inputStatus(int id, bool output) {
  states[id] = digitalRead(id);

  if (states[id] != lastStates[id]) {
    if (output) {
      outputState(id, EGRESS);
    }
    lastStates[id] = states[id];
  }
}


// Return status all inputs
void version() {
  Serial.print("{\"result\":\"");
  Serial.print(VERSION);
  Serial.println("\"}");
}


// Return an error messagse
void error(String message) {
  Serial.print("{\"error\":\"");
  Serial.print(message);
  Serial.println("\"}");
}
