#ifndef PINS_STRAP_H
#define PINS_STRAP_H

/****************************************************************************************
* Arduino Mega pin assignment
*
****************************************************************************************/
#if MOTHERBOARD == 3
//////////////////FIX THIS//////////////
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
  #define FAN_PIN            9 // THIS LINE FOR V1.1
  
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





#else

#error Unknown MOTHERBOARD value in parameters.h

#endif

#endif
