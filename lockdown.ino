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
  incoming = "";
  byte incomingByte;
  
  while (Serial.available() > 0) {
    incomingByte = Serial.read();
    
    if (incomingByte != 13 && incomingByte != 10) {
      incoming += char(incomingByte);
    }
    
    delay(10);
  }
  
  if (incoming != "") {
    // Serial.print(incoming);
    if (incoming == "{\"message\":\"status\"}") {
      status();
    } else { 
      error("unknown message");
    }
  }
  
  for (int i=22; i<54; i++) {
    //read the pushbutton value into a variable
    states[i] = digitalRead(i);
    
    //print out the value of the pushbutton
    if (states[i] != lastStates[i]) {
      outputState(i, EGRESS);
      lastStates[i] = states[i];
    }
  }
  
  digitalWrite(13, digitalRead(22));
}  

void outputState(int i, int type) {
  Serial.print("{\"type\":\"");
  Serial.print(TYPES[type]);
  Serial.print("\",\"id\":");
  Serial.print(i);
  Serial.print(",\"state\":");
  Serial.print(states[i]);
  Serial.print(",\"millis\":");
  Serial.print(millis());
  Serial.println("}");
}


// Return status all inputs
void status() {
  for (int i=22; i<54; i++) {
    outputState(i, EGRESS);
  }
}


// Return an error messagse
void error(String message) {
  Serial.print("{\"error\":\"");
  Serial.print(message);
  Serial.println("\"}");
}
