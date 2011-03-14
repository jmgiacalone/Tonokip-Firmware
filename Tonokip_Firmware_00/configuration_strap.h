#ifndef PARAMETERS_H
#define PARAMETERS_H

#define DEBUG false

// NO RS485/EXTRUDER CONTROLLER SUPPORT
// PLEASE VERIFY PIN ASSIGNMENTS FOR YOUR CONFIGURATION!!!!!!!
#define MOTHERBOARD 3 // ATMEGA168 0, SANGUINO 1, MOTHERBOARD = 2, MEGA 3, ATMEGA328 4

// THERMOCOUPLE SUPPORT UNTESTED... USE WITH CAUTION!!!!
const bool USE_THERMISTOR = true; //Set to false if using thermocouple
#define THERMOCOUPLE

// Calibration formulas
// e_extruded_steps_per_mm = e_feedstock_steps_per_mm * (desired_extrusion_diameter^2 / feedstock_diameter^2)
// new_axis_steps_per_mm = previous_axis_steps_per_mm * (test_distance_instructed/test_distance_traveled)
// units are in millimeters or whatever length unit you prefer: inches,football-fields,parsecs etc

//Calibration variables
float x_steps_per_unit = 20;
float y_steps_per_unit = 20;
float z_steps_per_unit = 2000;
float e_steps_per_unit = 21;
float max_feedrate = 9000;

//float x_steps_per_unit = 10.047;
//float y_steps_per_unit = 10.047;
//float z_steps_per_unit = 833.398;
//float e_steps_per_unit = 0.706;
//float max_feedrate = 3000;

//For Inverting Stepper Enable Pins (Active Low) use 0, Non Inverting (Active High) use 1
const bool X_ENABLE_ON = 1;
const bool Y_ENABLE_ON = 1;
const bool Z_ENABLE_ON = 1;
const bool E_ENABLE_ON = 0;

//Disables axis when it's not being used.
const bool DISABLE_X = false;
const bool DISABLE_Y = false;
const bool DISABLE_Z = true;
const bool DISABLE_E = false;

const bool INVERT_X_DIR = false;
const bool INVERT_Y_DIR = false;
const bool INVERT_Z_DIR = false;
const bool INVERT_E_DIR = true;

//Endstop Settings
const bool ENDSTOPS_INVERTING = 1;
const bool min_software_endstops = false; //If true, axis won't move to coordinates less than zero.
const bool max_software_endstops = true;  //If true, axis won't move to coordinates greater than the defined lengths below.
const int X_MAX_LENGTH = 245;
const int Y_MAX_LENGTH = 165;
const int Z_MAX_LENGTH = 130;

#define BAUDRATE 115200
#define MAX_CMD_SIZE 256

#define HEAT_INTERVAL 225 // extruder control interval in milliseconds
#define LZONE 4
#define UZONE 2

//RESISTOR 12 OHM
#define PID_MAX 150 // limits current to nozzle
#define PID_INTEGRAL_DRIVE_MAX 95
#define PID_PGAIN 1.45//1.45
#define PID_IGAIN 0.02//0.02
#define PID_DGAIN 1.0//1.0

#define TEMP_MULTIPLIER 4
#define NZONE 5

#define NUMTEMPS 20
short _thTempTable[NUMTEMPS][2] = {

   {1, 628},
   {54, 222},
   {107, 184},
   {160, 163},
   {213, 149},
   {266, 138},
   {319, 128},
   {372, 120},
   {425, 112},
   {478, 106},
   {531, 99},
   {584, 93},
   {637, 86},
   {690, 80},
   {743, 73},
   {796, 66},
   {849, 57},
   {902, 47},
   {955, 33},
   {1008, 4}
 };


/****************************************************************************************
* Arduino Mega pin assignment
*
****************************************************************************************/

#ifndef __AVR_ATmega1280__
 #ifndef __AVR_ATmega2560__
 #error Oops!  Make sure you have 'Arduino Mega' selected from the 'Tools -> Boards' menu.
 #endif
#endif


  #define X_STEP_PIN         27
  #define X_DIR_PIN          28
  #define X_ENABLE_PIN       29
  #define X_MIN_PIN           30
  #define X_MAX_PIN           -1
  
  #define Y_STEP_PIN         22
  #define Y_DIR_PIN          23
  #define Y_ENABLE_PIN       24
  #define Y_MIN_PIN          25
  #define Y_MAX_PIN          -1
  
  #define Z_STEP_PIN         35
  #define Z_DIR_PIN          36
  #define Z_ENABLE_PIN       37
  #define Z_MIN_PIN          38
  #define Z_MAX_PIN          -1
  
  #define E_STEP_PIN         31
  #define E_DIR_PIN          32
  #define E_ENABLE_PIN       33
  
  #define LED_PIN            13
  
  //#define FAN_PIN            11 // UNCOMMENT THIS LINE FOR V1.0
  #define FAN_PIN            6 // THIS LINE FOR V1.1
  
  #define PS_ON_PIN          -1
  #define KILL_PIN           -1
  
  //bed heater pins
  //#define HEATER_0_PIN        12  // UNCOMMENT THIS LINE FOR V1.0
  #define HEATER_0_PIN       7//10 // THIS LINE FOR V1.1
  #define TEMP_0_PIN          4//2   // MUST USE ANALOG INPUT NUMBERING NOT DIGITAL OUTPUT NUMBERING!!!!!!!!!
  
  //MAX6675 nozzle heater pins
  #define MAX6675_EN 19
  #define MAX6675_SO 20
  #define MAX6675_SCK 21
  #define HEATER_1_PIN 5

#endif
