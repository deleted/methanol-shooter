/*
* Egg Shooter control box
 */

const int NUM_SHOOTERS = 6;
const unsigned long MIN_PURGE_DELAY = 750; // milliseconds
const unsigned long MAX_PURGE_DELAY = 1500; // milliseconds
const unsigned long SIGNAL_INTERVAL = 300; //milliseconds

// Pins for LEDs
const int LED_1 = 13;
const int LED_2 = 12;
const int LED_3 = 11;

// Addresses for Relay Boxes
const String BOX1 = "0e";
const String BOX2 = "0f";

// Addresses for individual switched outlets
const String FUEL1 = BOX1 + "1";
const String FUEL2 = BOX1 + "2";
const String FUEL3 = BOX1 + "3";
const String PURGE1 = BOX1 + "4";
const String PURGE2 = BOX1 + "5";
const String PURGE3 = BOX1 + "6";

const String FUEL4 = BOX2 + "1";
const String FUEL5 = BOX2 + "2";
const String FUEL6 = BOX2 + "3";
const String PURGE4 = BOX2 + "4";
const String PURGE5 = BOX2 + "5";
const String PURGE6 = BOX2 + "6";

typedef struct Shooter{
  int button_pin;
  String fuel_address;
  String purge_address;
};

Shooter shooters[] = {
  {2, FUEL1, PURGE1},
  {3, FUEL2, PURGE2},
  {4, FUEL3, PURGE3},
  {5, FUEL4, PURGE4},
  {6, FUEL5, PURGE5},
  {7, FUEL6, PURGE6},
};

const int PURGE_BUTTON_PIN = 8;
const int PURGE_DELAY_PIN = A0; // Analog pin for the knob

boolean last_button_state[NUM_SHOOTERS];
boolean last_purge_button_state;

//unsigned long purge_off_time[NUM_SHOOTERS];
unsigned long button_off_time[NUM_SHOOTERS];
unsigned long last_signal_sent[NUM_SHOOTERS];
unsigned long last_purge_all_signal = 0;

boolean last_fuel_valve_state[NUM_SHOOTERS];
boolean last_purge_valve_state[NUM_SHOOTERS];


int delay_knob_min_value, delay_knob_max_value;
unsigned long purge_delay = MIN_PURGE_DELAY; // start it at the minimum value.

void setup() {
  Serial.begin(19200);

  pinMode(LED_1, OUTPUT); 
  pinMode(LED_2, OUTPUT); 
  pinMode(LED_3, OUTPUT); 
  digitalWrite(LED_1, HIGH); // Power light!

  pinMode(PURGE_DELAY_PIN, INPUT);
  pinMode(PURGE_BUTTON_PIN, INPUT);
  digitalWrite(PURGE_BUTTON_PIN, HIGH);
  last_purge_button_state = (digitalRead(PURGE_BUTTON_PIN) == LOW);

  for (int i=0; i<NUM_SHOOTERS; i++) {
    last_fuel_valve_state[i] = false;
    last_purge_valve_state[i] = false;
    pinMode(shooters[i].button_pin, INPUT);
    digitalWrite(shooters[i].button_pin, HIGH);  // This activates the internal pull-up resistor.
    last_button_state[i] = (digitalRead(shooters[i].button_pin) == LOW);
  }
}

boolean led_1;
boolean led_2;
boolean led_3;
boolean activity;
void loop() {

  //led_1 = false; // using this as a power indicator
  led_2 = false;
  led_3 = false;
  activity = false;

  unsigned long purge_delay = getPurgeDelay();
  boolean purge_button_pressed = (digitalRead(PURGE_BUTTON_PIN) == LOW);
  if ( purge_button_pressed) {
    purgeAll( !last_purge_button_state );
    led_3 = true;
  }
  last_purge_button_state = purge_button_pressed;
  

  for (int i=0; i<NUM_SHOOTERS; i++) {
    boolean button_pressed = ( digitalRead(shooters[i].button_pin) == LOW );// LOW means the switch is closed.
    if (button_pressed) {
      led_2 = true;
      fuelSignal(i, 1, !last_button_state[i]);
    } else {
      if ( last_button_state[i] ) { // button was on but is now off
        led_3 = true;
        button_off_time[i] = millis();
        fuelSignal(i, 0, true);
        purgeSignal(i, 1, true); 
      } else { // button was and is off
        if ( (button_off_time[i] + purge_delay) > millis() ) {
          led_3 = true;
          purgeSignal(i, 1, false);
        } else {
          purgeSignal(i, 0, true);
        }
      }
    }
    last_button_state[i] = button_pressed;
  }
  //digitalWrite(LED_1, led_1 ? HIGH : LOW);
  digitalWrite(LED_1, activity ? LOW : HIGH);
  digitalWrite(LED_2, led_2 ? HIGH : LOW);
  digitalWrite(LED_3, led_3 ? HIGH : LOW);
}

void sendSignal(int shooter_idx, String address, int value, unsigned long last_signal_time, boolean now) {
  // Unless now is true, only send the signal if we've exceeded the signal interval.
  if ( now || ( (last_signal_time + SIGNAL_INTERVAL) <= millis() ) ) {
    Serial.print("!" + address);
    Serial.print(value);
    Serial.print(".");
    Serial.print("\n");
    last_signal_sent[shooter_idx] = millis();
    activity = true;
  } 
}

void fuelSignal(int shooter_idx, int value, boolean now) {
  if ( value != 0 || last_fuel_valve_state[shooter_idx] ) { // "off" signal only sent once"
    //Serial.println("FIRE");
    String address = shooters[shooter_idx].fuel_address;
    unsigned long last_signal_time = last_signal_sent[shooter_idx];
    sendSignal( shooter_idx, address, value, last_signal_time, now);
    last_fuel_valve_state[shooter_idx] = (value > 0);
  }
}

void purgeSignal(int shooter_idx, int value, boolean now) {
  if ( value != 0 || last_purge_valve_state[shooter_idx] ) { // "off" signal only sent once"
    //Serial.println("PURGE");
    String address = shooters[shooter_idx].purge_address;
    unsigned long last_signal_time = last_signal_sent[shooter_idx];
    sendSignal( shooter_idx, address, value, last_signal_time, now);
    last_purge_valve_state[shooter_idx] = (value ==  0);
  }
}

void purgeAll(boolean now) {
  for ( int i=0; i<NUM_SHOOTERS; i++) {
    purgeSignal(i, 1, now);
  }
}

int getPurgeDelay() {
  int knob_value = 1023 - analogRead(PURGE_DELAY_PIN); // invert
  unsigned long delay = (int)( (knob_value / 1023.0) * (MAX_PURGE_DELAY - MIN_PURGE_DELAY) + MIN_PURGE_DELAY );
  return delay;
}
