#ifndef PARAMETERS_H
#define PARAMETERS_H

#define DEBUG 0
// NO RS485/EXTRUDER CONTROLLER SUPPORT
// PLEASE VERIFY PIN ASSIGNMENTS FOR YOUR CONFIGURATION!!!!!!!
#define MOTHERBOARD 3 // ATMEGA168 0, SANGUINO 1, MOTHERBOARD = 2, MEGA 3, ATMEGA328 4

//Comment out to disable SD support
#define SDSUPPORT 1

//Acceleration settings
float min_units_per_second = 25;//10; // the minimum feedrate
long max_acceleration_units_per_sq_second = 2000;//750; // Max acceleration in mm/s^2 for printing moves
//long max_travel_acceleration_units_per_sq_second = 1500; // Max acceleration in mm/s^2 for travel moves
//const bool USE_THERMISTOR = true; //Set to false if using thermocouple
//#define THERMOCOUPLE

// Calibration formulas
// e_extruded_steps_per_mm = e_feedstock_steps_per_mm * (desired_extrusion_diameter^2 / feedstock_diameter^2)
// new_axis_steps_per_mm = previous_axis_steps_per_mm * (test_distance_instructed/test_distance_traveled)
// units are in millimeters or whatever length unit you prefer: inches,football-fields,parsecs etc

//Calibration variables
float x_steps_per_unit = 80;
float y_steps_per_unit = 80;
float z_steps_per_unit = 4571.43;
float e_steps_per_unit = 724.022; //65.304; //set for sf40 TO 0.85*measured filament feed

#define RAPID_Z 500
#define RAPID_XY 30000

//For Inverting Stepper Enable Pins (Active Low) use 0, Non Inverting (Active High) use 1
const bool X_ENABLE_ON = 0;
const bool Y_ENABLE_ON = 0;
const bool Z_ENABLE_ON = 0;
const bool E_ENABLE_ON = 0;

//Disables axis when it's not being used.
const bool DISABLE_X = false;
const bool DISABLE_Y = false;
const bool DISABLE_Z = true;
const bool DISABLE_E = false;

const bool INVERT_X_DIR = true;
const bool INVERT_Y_DIR = false;
const bool INVERT_Z_DIR = false;
const bool INVERT_E_DIR = true;

//Endstop Settings
#define ENDSTOPPULLUPS 1
const bool ENDSTOPS_INVERTING = 0;
const bool min_software_endstops = true; //If true, axis won't move to coordinates less than zero.
const bool max_software_endstops = true;  //If true, axis won't move to coordinates greater than the defined lengths below.
const int X_MAX_LENGTH = 150;
const int Y_MAX_LENGTH = 148;
const int Z_MAX_LENGTH = 100;

//#define PROBING
#ifdef PROBING
  //probing position
  #define Z_HOME_X 70
  #define Z_HOME_Y 70
  #define PROBE_PIN 19 //use Z max pin
#endif

#define BAUDRATE 115200
#define MAX_CMD_SIZE 256

#define HEAT_INTERVAL 225 // extruder control interval in milliseconds
#define LZONE 0
#define UZONE 1

//RESISTOR 12 OHM
#define PID_MAX 255 // limits current to nozzle
#define PID_INTEGRAL_DRIVE_MAX 220 //200
#define PID_PGAIN 1.8 //1.8
#define PID_IGAIN 0.02//0.02
#define PID_DGAIN 1.0//1.0

#define TEMP_MULTIPLIER 4 //1
#define NZONE 5

//bed table
#define bNUMTEMPS 33
short _thTempTable[bNUMTEMPS][2] = {

{704,155},
{714,150},
{724,145},
{734,140},
{744,135},
{754,130},
{764,125},
{774,120},
{784,115},
{794,110},
{804,105},
{814,100},
{824,95},
{834,90},
{844,85},
{854,80},
{864,75},
{874,70},
{884,65},
{894,60},
{904,55},
{914,50},
{924,45},
{934,40},
{944,35},
{954,30},
{964,25},
{974,20},
{984,15},
{994,10},
{1004,5},
{1014,0},
{1024,-5}
};

#ifndef THERMOCOUPLE
//nozzle table
#define nNUMTEMPS 40
short  _thNTempTable[nNUMTEMPS][2] = {
   {1, 9999},
   {27, 400},
   {53, 300},
   {79, 290},
   {105, 280},
   {131, 270},
   {157, 260},
   {183, 250},
   {209, 240},
   {235, 230},
   {261, 220},
   {287, 210},
   {313, 197},
   {340, 193},
   {366, 184},
   {391, 174},
   {417, 170},
   {442, 163},
   {467, 157},
   {495, 151},
   {521, 134},
   {547, 125},
   {573, 129},
   {599, 124},
   {625, 120},
   {652, 112},
   {677, 107},
   {704, 101},
   {729, 95},
   {755, 91},
   {781, 87},
   {806, 80},
   {831, 74},
   {860, 65},
   {886, 57},
   {910, 47},
   {936, 36},
   {963, 29},
   {991, 14},
   {1015, 2}
};
#endif

/****************************************************************************************
* Arduino Mega pin assignment
*
****************************************************************************************/

#ifndef __AVR_ATmega1280__
 #ifndef __AVR_ATmega2560__
 #error Oops!  Make sure you have 'Arduino Mega' selected from the 'Tools -> Boards' menu.
 #endif
#endif

  #define X_STEP_PIN         26
  #define X_DIR_PIN          28
  #define X_ENABLE_PIN       24
  #define X_MIN_PIN           3
  #define X_MAX_PIN           -1//2
  
  #define Y_STEP_PIN         38
  #define Y_DIR_PIN          40
  #define Y_ENABLE_PIN       36
  #define Y_MIN_PIN          16
  #define Y_MAX_PIN          -1//17
  
  #define Z_STEP_PIN         44
  #define Z_DIR_PIN          46
  #define Z_ENABLE_PIN       42
  #define Z_MIN_PIN          18
  #define Z_MAX_PIN          -1//19
  
  #define E_STEP_PIN         32
  #define E_DIR_PIN          34
  #define E_ENABLE_PIN       30
  
  #define LED_PIN            13
  
  //#define FAN_PIN            11 // UNCOMMENT THIS LINE FOR V1.0
  #define FAN_PIN            9 // THIS LINE FOR V1.1
  
  #define PS_ON_PIN          -1
  #define KILL_PIN           -1
  
  //#define HEATER_0_PIN        12  // UNCOMMENT THIS LINE FOR V1.0
  #define HEATER_1_PIN       10 // THIS LINE FOR V1.1
#ifndef THERMOCOUPLE
  #define TEMP_1_PIN          1   // MUST USE ANALOG INPUT NUMBERING NOT DIGITAL OUTPUT NUMBERING!!!!!!!!!
#endif
  
  #define HEATER_0_PIN        8
  #define TEMP_0_PIN          2

  //MAX6675 nozzle heater pins
  #define MAX6675_EN 41//50 //19
  #define MAX6675_SO 39//48 //20
  #define MAX6675_SCK 43//52 //21
  
  #define SDPOWER          48
  #define SDSS          53

#endif
