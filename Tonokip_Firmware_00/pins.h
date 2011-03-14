#ifndef PINS_H
#define PINS_H


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
#elif MOTHERBOARD == 1
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



/****************************************************************************************
* Arduino Mega pin assignment
*
****************************************************************************************/
#elif MOTHERBOARD == 3
//////////////////FIX THIS//////////////
#ifndef __AVR_ATmega1280__
 #ifndef __AVR_ATmega2560__
 #error Oops!  Make sure you have 'Arduino Mega' selected from the 'Tools -> Boards' menu.
 #endif
#endif

  #define X_STEP_PIN         26
  #define X_DIR_PIN          28
  #define X_ENABLE_PIN       24
  #define X_MIN_PIN           3
  #define X_MAX_PIN           2
  
  #define Y_STEP_PIN         38
  #define Y_DIR_PIN          40
  #define Y_ENABLE_PIN       36
  #define Y_MIN_PIN          16
  #define Y_MAX_PIN          17
  
  #define Z_STEP_PIN         44
  #define Z_DIR_PIN          46
  #define Z_ENABLE_PIN       42
  #define Z_MIN_PIN          18
  #define Z_MAX_PIN          19
  
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
  //#define TEMP_1_PIN          1   // MUST USE ANALOG INPUT NUMBERING NOT DIGITAL OUTPUT NUMBERING!!!!!!!!!
  
  #define HEATER_0_PIN        8
  #define TEMP_0_PIN          2

  //MAX6675 nozzle heater pins
  #define MAX6675_EN 50 //19
  #define MAX6675_SO 48 //20
  #define MAX6675_SCK 52 //21


#else

#error Unknown MOTHERBOARD value in parameters.h

#endif

#endif
