#ifndef PARAMETERS_H
#define PARAMETERS_H

#define DEBUG false

// NO RS485/EXTRUDER CONTROLLER SUPPORT
// PLEASE VERIFY PIN ASSIGNMENTS FOR YOUR CONFIGURATION!!!!!!!
#define MOTHERBOARD 3 // ATMEGA168 0, SANGUINO 1, MOTHERBOARD = 2, MEGA 3, ATMEGA328 4

// THERMOCOUPLE SUPPORT UNTESTED... USE WITH CAUTION!!!!
const bool USE_THERMISTOR = true; //Set to false if using thermocouple
//#define THERMOCOUPLE

// Calibration formulas
// e_extruded_steps_per_mm = e_feedstock_steps_per_mm * (desired_extrusion_diameter^2 / feedstock_diameter^2)
// new_axis_steps_per_mm = previous_axis_steps_per_mm * (test_distance_instructed/test_distance_traveled)
// units are in millimeters or whatever length unit you prefer: inches,football-fields,parsecs etc

//Calibration variables
float x_steps_per_unit = 80;
float y_steps_per_unit = 80;
float z_steps_per_unit = 4571.43;
float e_steps_per_unit = 65.304; //754.91424; //65.304; //set for sf40=65.304*11.56
int max_feedrate = 6000;
#define RAPID_Z 500
#define RAPID_XY 6000

//float x_steps_per_unit = 10.047;
//float y_steps_per_unit = 10.047;
//float z_steps_per_unit = 833.398;
//float e_steps_per_unit = 0.706;
//float max_feedrate = 3000;

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
const bool INVERT_Y_DIR = true;
const bool INVERT_Z_DIR = true;
const bool INVERT_E_DIR = false;

//Endstop Settings
const bool ENDSTOPS_INVERTING = 0;
const bool min_software_endstops = true; //If true, axis won't move to coordinates less than zero.
const bool max_software_endstops = true;  //If true, axis won't move to coordinates greater than the defined lengths below.
const int X_MAX_LENGTH = 140;
const int Y_MAX_LENGTH = 140;
const int Z_MAX_LENGTH = 100;

//Comms settings
#define BAUDRATE 115200
#define MAX_CMD_SIZE 256

#define HEAT_INTERVAL 225 // extruder control interval in milliseconds
#define LZONE 0
#define UZONE 1

//RESISTOR 12 OHM
#define PID_MAX 255 // limits current to nozzle
#define PID_INTEGRAL_DRIVE_MAX 220 //200
#define PID_PGAIN 2.0 //1.8
#define PID_IGAIN 0.02//0.02
#define PID_DGAIN 1.0//1.0

#define TEMP_MULTIPLIER 4 //1
#define NZONE 5

#define bNUMTEMPS 33
short _thTempTable[33][2] = {

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

//nozzle table
#define nNUMTEMPS 40
short  _thNTempTable[nNUMTEMPS][2] = {
   {1, 9999},
   {27, 1100},
   {53, 1000},
   {79, 900},
   {105, 800},
   {131, 700},
   {157, 600},
   {183, 500},
   {209, 400},
   {235, 320},
   {261, 300},
   {287, 290},
   {313, 277},
   {340, 273},
   {366, 264},
   {391, 254},
   {417, 250},
   {442, 243},
   {467, 237},
   {495, 231},
   {521, 224},
   {547, 215},
   {573, 209},
   {599, 204},
   {625, 200},
   {652, 192},
   {677, 187},
   {704, 181},
   {729, 175},
   {755, 171},
   {781, 167},
   {806, 160},
   {831, 154},
   {860, 145},
   {886, 137},
   {910, 127},
   {936, 116},
   {963, 99},
   {991, 74},
   {1015, 22}
};


/****************************************************************************************
* Sanguinololu
*
*                        ATMega644P
*
*                        +---\/---+
*            (D 0) PB0  1|        |40  PA0 (AI 0 / D31)
*            (D 1) PB1  2|        |39  PA1 (AI 1 / D30)
*       INT2 (D 2) PB2  3|        |38  PA2 (AI 2 / D29)
*        PWM (D 3) PB3  4|        |37  PA3 (AI 3 / D28)
*        PWM (D 4) PB4  5|        |36  PA4 (AI 4 / D27)
*       MOSI (D 5) PB5  6|        |35  PA5 (AI 5 / D26)
*       MISO (D 6) PB6  7|        |34  PA6 (AI 6 / D25)
*        SCK (D 7) PB7  8|        |33  PA7 (AI 7 / D24)
*                  RST  9|        |32  AREF
*                  VCC 10|        |31  GND 
*                  GND 11|        |30  AVCC
*                XTAL2 12|        |29  PC7 (D 23)
*                XTAL1 13|        |28  PC6 (D 22)
*       RX0 (D 8)  PD0 14|        |27  PC5 (D 21) TDI
*       TX0 (D 9)  PD1 15|        |26  PC4 (D 20) TDO
*  INT0 RX1 (D 10) PD2 16|        |25  PC3 (D 19) TMS
*  INT1 TX1 (D 11) PD3 17|        |24  PC2 (D 18) TCK
*       PWM (D 12) PD4 18|        |23  PC1 (D 17) SDA
*       PWM (D 13) PD5 19|        |22  PC0 (D 16) SCL
*       PWM (D 14) PD6 20|        |21  PD7 (D 15) PWM
*                        +--------+
*
****************************************************************************************/
#ifndef __AVR_ATmega644P__
#error Oops!  Make sure you have 'Sanguino' selected from the 'Tools -> Boards' menu.
#endif

#define X_STEP_PIN         21
#define X_DIR_PIN          22
#define X_ENABLE_PIN       20
#define X_MIN_PIN          17
#define X_MAX_PIN          -1

#define Y_STEP_PIN         7
#define Y_DIR_PIN          6
#define Y_ENABLE_PIN       23
#define Y_MIN_PIN          18
#define Y_MAX_PIN          -1

#define Z_STEP_PIN         4
#define Z_DIR_PIN          3
#define Z_ENABLE_PIN       5
#define Z_MIN_PIN          19
#define Z_MAX_PIN          -1

#define E_STEP_PIN         1
#define E_DIR_PIN          0
#define E_ENABLE_PIN       2

#define LED_PIN            -1
#define FAN_PIN            -1
#define PS_ON_PIN          -1
#define KILL_PIN           -1

#define HEATER_0_PIN       14
#define TEMP_0_PIN          4 //D27   // MUST USE ANALOG INPUT NUMBERING NOT DIGITAL OUTPUT NUMBERING!!!!!!!!!

#define HEATER_1_PIN       14
#define TEMP_1_PIN          4



#endif
