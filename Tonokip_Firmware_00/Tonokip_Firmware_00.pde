// Tonokip RepRap firmware rewrite based off of Hydra-mmm firmware.
// Licence: GPL
//#define REPSTRAP
//#define SANGUINOLOLU
//#define MFUK
#define RAMPS

#ifdef REPSTRAP
  #include "configuration_strap.h"
  //#include "pins_strap.h"
#elif defined MFUK
  #include "configuration_mfuk.h"
#elif defined SANGUINOLOLU
  #include "configuration_sanguinololu.h"
  //#include "pins_strap.h"
#elif defined RAMPS
  #include "configuration.h"
  //#include "pins.h"
#else
  #error Oops!  Make sure you have defined a machine!
#endif
//#include "ThermistorTable.h"

// look here for descriptions of gcodes: http://linuxcnc.org/handbook/gcode/g-code.html
// http://objects.reprap.org/wiki/Mendel_User_Manual:_RepRapGCodes

//Implemented Codes
//-------------------
// G0  - Rapid feedrate (non-modal)
// G1  - Coordinated Movement X Y Z E (permanently modal so not necessary for feed move)
// G4  - Dwell S<seconds> or P<milliseconds>
// G28 - reference X Y Z axes
// G90 - Use Absolute Coordinates
// G91 - Use Relative Coordinates
// G92 - Set current position to cordinates given

//RepRap M Codes
// M104 - Set target temp
// M105 - Read current temp
// M106 - Fan on
// M107 - Fan off
// M109 - Wait for nozzle temp to reach target temp.
// M114 - Report current position
// M140 - Set bed temp
// M141 - Wait for bed temp to reach target

//Custom M Codes
// M80  - Turn on Power Supply
// M81  - Turn off Power Supply
// M82  - Set E codes absolute (default)
// M83  - Set E codes relative while in Absolute Coordinates (G90) mode
// M84  - Disable steppers until next move
// M85  - Set inactivity shutdown timer with parameter S<seconds>. To disable set zero (default)
// M86  - If Endstop is Not Activated then Abort Print. Specify X and/or Y
// M92  - Set axis_steps_per_unit - same syntax as G92

//Stepper Movement Variables
bool direction_x, direction_y, direction_z, direction_e;
unsigned long previous_micros=0, previous_micros_x=0, previous_micros_y=0, previous_micros_z=0, previous_micros_e=0;
unsigned long x_steps_to_take, y_steps_to_take, z_steps_to_take, e_steps_to_take;
float destination_x = 0.0, destination_y = 0.0, destination_z = 0.0, destination_e = 0.0;
float current_x = 0.0, current_y = 0.0, current_z = 0.0, current_e = 0.0;
float x_interval, y_interval, z_interval, e_interval; // for speed delay
float feedrate = 1500, next_feedrate;
float time_for_move;
long gcode_N;
long gcode_LastN = 0;
bool relative_mode = false;  //Determines Absolute or Relative Coordinates
bool relative_mode_e = true;  //Determines Absolute or Relative E Codes while in Absolute Coordinates mode. E is always relative in Relative Coordinates mode.

// comm variables
char cmdbuffer[MAX_CMD_SIZE];
char serial_char;
int serial_count = 0;
boolean comment_mode = false;
char *strchr_pointer; // just a pointer to find chars in the cmd string like X, Y, Z, E, etc

//manage heater variables
int bed_targ = 0;
int bed_curr;
int nozzle_targ;
int nozzle_curr;
int temp_iState;
int temp_dState;
unsigned long previous_millis_heater=0;
int output;


//Inactivity shutdown variables
unsigned long previous_millis_cmd=0;
unsigned long max_inactive_time = 0;

boolean NotHome = true;

void setup()
{ 
  //Initialize Step Pins
  if(X_STEP_PIN > -1) pinMode(X_STEP_PIN,OUTPUT);
  if(Y_STEP_PIN > -1) pinMode(Y_STEP_PIN,OUTPUT);
  if(Z_STEP_PIN > -1) pinMode(Z_STEP_PIN,OUTPUT);
  if(E_STEP_PIN > -1) pinMode(E_STEP_PIN,OUTPUT);
  
  //Initialize Dir Pins
  if(X_DIR_PIN > -1) pinMode(X_DIR_PIN,OUTPUT);
  if(Y_DIR_PIN > -1) pinMode(Y_DIR_PIN,OUTPUT);
  if(Z_DIR_PIN > -1) pinMode(Z_DIR_PIN,OUTPUT);
  if(E_DIR_PIN > -1) pinMode(E_DIR_PIN,OUTPUT);

  //Initialize Enable Pins
  if(X_ENABLE_PIN > -1) pinMode(X_ENABLE_PIN,OUTPUT);
  if(Y_ENABLE_PIN > -1) pinMode(Y_ENABLE_PIN,OUTPUT);
  if(Z_ENABLE_PIN > -1) pinMode(Z_ENABLE_PIN,OUTPUT);
  if(E_ENABLE_PIN > -1) pinMode(E_ENABLE_PIN,OUTPUT);

  //Steppers default to disabled.
  if(X_ENABLE_PIN > -1) if(!X_ENABLE_ON) digitalWrite(X_ENABLE_PIN,HIGH);
  if(Y_ENABLE_PIN > -1) if(!Y_ENABLE_ON) digitalWrite(Y_ENABLE_PIN,HIGH);
  if(Z_ENABLE_PIN > -1) if(!Z_ENABLE_ON) digitalWrite(Z_ENABLE_PIN,HIGH);
  if(E_ENABLE_PIN > -1) if(!E_ENABLE_ON) digitalWrite(E_ENABLE_PIN,HIGH);
  

  if(HEATER_0_PIN > -1) pinMode(HEATER_0_PIN,OUTPUT);
  
#ifdef THERMOCOUPLE
  pinMode(MAX6675_EN,OUTPUT);
  pinMode(MAX6675_SO,INPUT);
  pinMode(MAX6675_SCK,OUTPUT);
  pinMode(HEATER_1_PIN,OUTPUT);
  digitalWrite(MAX6675_EN,HIGH);

#endif  

  pinMode(TEMP_0_PIN,INPUT);
  //pinMode(TEMP_1_PIN,INPUT);
  
  analogWrite(FAN_PIN,255);
  
  Serial.begin(BAUDRATE);
  Serial.println("start");
  Serial.println("ok");
  Serial.println("ok");
}


void loop()
{
  get_command();
  manage_heaters();
  manage_inactivity(1); //shutdown if not receiving any new commands
}

inline void get_command() 
{ 

  if( Serial.available() > 0 ) {
    serial_char = Serial.read();
    if(serial_char == '\n' || serial_char == '\r' || serial_char == ':' || serial_count >= (MAX_CMD_SIZE - 1) ) 
    {
      if(!serial_count) return; //if empty line
      cmdbuffer[serial_count] = 0; //terminate string
      //Serial.print("Echo:");
      //Serial.println(&cmdbuffer[0]);
      
      process_commands();
      
      comment_mode = false; //for new command
      serial_count = 0; //clear buffer
      //Serial.println("ok"); 
    }
    else
    {
      if(serial_char == ';') comment_mode = true;
      if(!comment_mode) cmdbuffer[serial_count++] = serial_char; 
    }
  }  
}


//#define code_num (strtod(&cmdbuffer[strchr_pointer - cmdbuffer + 1], NULL))
//inline void code_search(char code) { strchr_pointer = strchr(cmdbuffer, code); }
inline float code_value() { return (strtod(&cmdbuffer[strchr_pointer - cmdbuffer + 1], NULL)); }
inline long code_value_long() { return (strtol(&cmdbuffer[strchr_pointer - cmdbuffer + 1], NULL, 10)); }
inline bool code_seen(char code_string[]) { return (strstr(cmdbuffer, code_string) != NULL); }  //Return True if the string was found

inline bool code_seen(char code)
{
  strchr_pointer = strchr(cmdbuffer, code);
  return (strchr_pointer != NULL);  //Return True if a character was found
}



inline void process_commands()
{
  unsigned long codenum; //throw away variable
  unsigned long previous_millis=0;
  unsigned int oldFeed;
  
  if(code_seen('N'))
  {
    gcode_N = code_value_long();
    if(gcode_N != gcode_LastN+1 && (strstr(cmdbuffer, "M110") == NULL) ) {
      Serial.print("Serial Error: Line Number is not Last Line Number+1, Last Line:");
      Serial.println(gcode_LastN);
      FlushSerialRequestResend();
      return;
    }
    
    if(code_seen('*'))
    {
      byte checksum = 0;
      byte count=0;
      while(cmdbuffer[count] != '*') checksum = checksum^cmdbuffer[count++];
     
      if( (int)code_value() != checksum) {
        Serial.print("Error: checksum mismatch, Last Line:");
        Serial.println(gcode_LastN);
        FlushSerialRequestResend();
        return;
      }
      //if no errors, continue parsing
    }else{
      Serial.print("Error: No Checksum with line number, Last Line:");
      Serial.println(gcode_LastN);
      FlushSerialRequestResend();
      return;
    }
    
    gcode_LastN = gcode_N;
    //if no errors, continue parsing
  }
  else  // if we don't receive 'N' but still see '*'
  {
    if(code_seen('*'))
    {
      Serial.print("Error: No Line Number with checksum, Last Line:");
      Serial.println(gcode_LastN);
      return;
    }
  }

  //continues parsing only if we don't receive any 'N' or '*' or no errors if we do. :)
  if(code_seen('G'))
  {
    switch((int)code_value())
    {
      case 0: // G0 -> G1
        get_coordinates(); // For X Y Z E F
        oldFeed = feedrate;
        if(code_seen('Z'))
        {
          feedrate = RAPID_Z;
        }else{
          feedrate = RAPID_XY;
        }
        pre_move(destination_x,destination_y,destination_z,destination_e);
        feedrate = oldFeed;
        break;        
      case 1: // G1
        get_coordinates(); // For X Y Z E F
        pre_move(destination_x,destination_y,destination_z,destination_e);
      case 4: // G4 dwell
        codenum = 0;
        if(code_seen('P')) codenum = code_value(); // milliseconds to wait
        if(code_seen('S')) codenum = code_value()*1000; // seconds to wait
        previous_millis = millis();  // keep track of when we started waiting
        while((millis() - previous_millis) < codenum ) manage_heaters(); //manage heater until time is up
        break;
      case 28: // G28 - reference axes TODO
        NotHome = true;
        reference_x();
        reference_y();
        reference_z();
        current_e = 0;
        NotHome = false;
        break;
      case 90: // G90
        relative_mode = false;
        break;
      case 91: // G91
        relative_mode = true;
        break;
      case 92: // G92
        if(code_seen('X')){
          current_x = code_value();
          break;
        }
        if(code_seen('Y')){
          current_y = code_value();
          break;
        }
        if(code_seen('Z')){
          current_z = code_value();
          break;
        }
        if(code_seen('E')){
          current_e = code_value();
          break;
        }
        current_x = current_y = current_z = current_e = 0;
        break;
        
    }
  }else if(code_seen('M'))
  {
    
    switch( (int)code_value() ) 
    {
      case 104: // M104 - set nozzle temp
        if (code_seen('S'))
         {
#ifdef THERMOCOUPLE
           nozzle_targ = code_value() * TEMP_MULTIPLIER;
#else
           nozzle_targ = temp2analog(code_value(), _thNTempTable, nNUMTEMPS);
#endif
         }
        break;
      case 140: // M140 - set bed temp
        if (code_seen('S')) bed_targ = temp2analog(code_value(), _thTempTable, bNUMTEMPS);
        break;
      case 105: // M105 - report temps
        Serial.print("T:");
#ifdef THERMOCOUPLE
#define NOZZLE_OUT nozzle_curr / TEMP_MULTIPLIER
#else
#define NOZZLE_OUT analog2temp(nozzle_curr, _thNTempTable, nNUMTEMPS)
#endif
        Serial.print( NOZZLE_OUT );
        Serial.print(" B:");
        Serial.println( analog2temp(bed_curr, _thTempTable, bNUMTEMPS) ); 
        break;
      case 205:
#ifdef THERMOCOUPLE
        Serial.print("Nc:");
        Serial.print( nozzle_curr / TEMP_MULTIPLIER );
        Serial.print(" Nh:");
        Serial.print( output );
        Serial.print(" Nt:");
        Serial.print( nozzle_targ / TEMP_MULTIPLIER );
#else
        Serial.print("Nc:");
        Serial.print( analog2temp(nozzle_curr, _thNTempTable, nNUMTEMPS) );
        Serial.print(" Nh:");
        Serial.print( output );
        Serial.print(" Nt:");
        Serial.print( analog2temp(nozzle_targ, _thNTempTable, nNUMTEMPS) );
#endif
        Serial.print(" Bc:");
        Serial.println( analog2temp(bed_curr, _thTempTable, bNUMTEMPS) ); 
        Serial.print(" Bt:");
        Serial.println( analog2temp(bed_targ, _thTempTable, bNUMTEMPS) ); 
        break;
      case 905:
#ifndef THERMOCOUPLE
        Serial.print("Ta: ");
        Serial.print(analogRead(TEMP_1_PIN));
#endif        
        Serial.print(" Tb: ");
        Serial.println(analogRead(TEMP_0_PIN));
        break;
      case 109: // M109 - Wait for nozzle to reach target temp
        if (code_seen('S'))
        {
#ifdef THERMOCOUPLE
          nozzle_targ = code_value() * TEMP_MULTIPLIER;
          previous_millis = millis(); 
          while(nozzle_curr < (nozzle_targ - NZONE * TEMP_MULTIPLIER))
          {
            if( (millis()-previous_millis) > 1000 ) //Print Temp Reading every 1 second while heating up.
            {
              Serial.print("T:");
              Serial.print( nozzle_curr / TEMP_MULTIPLIER ); 
              Serial.print(" / ");
              Serial.println( nozzle_targ / TEMP_MULTIPLIER ); 
              previous_millis = millis(); 
            }
            manage_heaters();
          }
#else
          nozzle_targ = temp2analog(code_value(), _thNTempTable, nNUMTEMPS);
          previous_millis = millis(); 
          while(nozzle_curr < (nozzle_targ - NZONE))
          {
            if( (millis()-previous_millis) > 1000 ) //Print Temp Reading every 1 second while heating up.
            {
              Serial.print("T:");
              Serial.print( analog2temp(nozzle_curr, _thNTempTable, nNUMTEMPS) ); 
              Serial.print(" / ");
              Serial.println( analog2temp(nozzle_targ, _thNTempTable, nNUMTEMPS) ); 
              previous_millis = millis(); 
            }
            manage_heaters();
          }
#endif
        }
        break;
      case 141: // M141 - Wait for bed to reach target temp
        if (code_seen('S'))
         {
           bed_targ = temp2analog(code_value(), _thTempTable, bNUMTEMPS);
           previous_millis = millis(); 
           while(bed_curr < bed_targ)
           {
             if( (millis()-previous_millis) > 1000 ) //Print Temp Reading every 1 second while heating up.
             {
               Serial.print("B:");
               Serial.print( analog2temp(bed_curr, _thTempTable, bNUMTEMPS) ); 
               Serial.print(" / ");
               Serial.println( bed_targ ); 
               previous_millis = millis(); 
             }
             manage_heaters();
           }
         }
        break;
      case 106: //M106 Ss Fan On
        if(code_seen('S'))
        {
          analogWrite(FAN_PIN, constrain(code_value(),0,255));
        }
        break;
      case 107: //M107 Fan Off
        digitalWrite(FAN_PIN, LOW);
        break;
      case 80: // M81 - ATX Power On
        if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,OUTPUT); //GND
        break;
      case 81: // M81 - ATX Power Off
        if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,INPUT); //Floating
        break;
      case 82:
        relative_mode_e = false;
        break;
      case 83:
        relative_mode_e = true;
        break;
      case 84:
        disable_x();
        disable_y();
        disable_z();
        disable_e();
        break;
      case 184:
        enable_x();
        enable_y();
        enable_z();
        enable_e();
        break;
      case 85: // M85
        code_seen('S');
        max_inactive_time = code_value()*1000; 
        break;
      case 86: // M86 If Endstop is Not Activated then Abort Print
        if(code_seen('X')) if( digitalRead(X_MIN_PIN) == ENDSTOPS_INVERTING ) kill(3);
        if(code_seen('Y')) if( digitalRead(Y_MIN_PIN) == ENDSTOPS_INVERTING ) kill(4);
        break;
      case 92: // M92
        if(code_seen('X')) x_steps_per_unit = code_value();
        if(code_seen('Y')) y_steps_per_unit = code_value();
        if(code_seen('Z')) z_steps_per_unit = code_value();
        if(code_seen('E')) e_steps_per_unit = code_value();
        break;
      case 114: // M114
        Serial.print( "X" );
        Serial.print( current_x );
        Serial.print( " Y" );
        Serial.print( current_y );
        Serial.print( " Z" );
        Serial.print( current_z );
        Serial.print( " E" );
        Serial.print( current_e );
        Serial.print( " F" );
        Serial.println( feedrate );
        break;
    }
  }else{
    if(code_seen('X') || code_seen('Y') || code_seen('Z') || code_seen('E') || code_seen('F'))
    {
      get_coordinates(); // For X Y Z E F
      pre_move(destination_x,destination_y,destination_z,destination_e);
    }else{
      Serial.print( 'Unknown command at line: ' );
      Serial.println( gcode_LastN );
    }
  }
  
  ClearToSend();
}

inline void reference_x()
{
        feedrate = 1000;
        pre_move(-(X_MAX_LENGTH + 1), current_y, current_z, current_e);
        current_x = 0;
        pre_move(1, current_y, current_z, current_e);
        feedrate = 100;
        pre_move(-1, current_y, current_z, current_e);
        current_x = 0;
        feedrate = 1500;
}
inline void reference_y()
{
        feedrate = 1000;
        pre_move(current_x, -(Y_MAX_LENGTH + 1), current_z, current_e);
        current_y = 0;
        pre_move(current_x, 1, current_z, current_e);
        feedrate = 100;
        pre_move(current_x, -1, current_z, current_e);
        current_y = 0;
        feedrate = 1500;
}
inline void reference_z()
{
        feedrate = 100;
        pre_move(current_x, current_y, -(Z_MAX_LENGTH + 2), current_e);
        current_z = 0;
        pre_move(current_x, current_y, 1, current_e);
        pre_move(current_x, current_y, -1, current_e);
        current_z = 0;
        feedrate = 1500;
}
inline void pre_move(float dest_x, float dest_y, float dest_z, float dest_e)
{
  unsigned long x_steps=0;
  unsigned long y_steps=0;
  unsigned long z_steps=0;
  unsigned long e_steps=0;
  
          x_steps_to_take = abs(dest_x - current_x)*x_steps_per_unit;
          y_steps_to_take = abs(dest_y - current_y)*y_steps_per_unit;
          z_steps_to_take = abs(dest_z - current_z)*z_steps_per_unit;
          //e_steps_to_take = abs(dest_e - current_e)*e_steps_per_unit;
          e_steps_to_take = abs(dest_e)*e_steps_per_unit;
  
          #define X_TIME_FOR_MOVE ((float)x_steps_to_take / (x_steps_per_unit*feedrate/60000000))
          #define Y_TIME_FOR_MOVE ((float)y_steps_to_take / (y_steps_per_unit*feedrate/60000000))
          #define Z_TIME_FOR_MOVE ((float)z_steps_to_take / (z_steps_per_unit*feedrate/60000000))
          #define E_TIME_FOR_MOVE ((float)e_steps_to_take / (e_steps_per_unit*feedrate/60000000))
          
          time_for_move = max(X_TIME_FOR_MOVE,Y_TIME_FOR_MOVE);
          time_for_move = max(time_for_move,Z_TIME_FOR_MOVE);
          time_for_move = max(time_for_move,E_TIME_FOR_MOVE);
  
          if(x_steps_to_take) x_interval = time_for_move/x_steps_to_take;
          if(y_steps_to_take) y_interval = time_for_move/y_steps_to_take;
          if(z_steps_to_take) z_interval = time_for_move/z_steps_to_take;
          if(e_steps_to_take) e_interval = time_for_move/e_steps_to_take;
          
          if(DEBUG) {
            Serial.print("destination_x: "); Serial.println(dest_x); 
            Serial.print("current_x: "); Serial.println(current_x); 
            Serial.print("x_steps_to_take: "); Serial.println(x_steps_to_take); 
            Serial.print("X_TIME_FOR_MVE: "); Serial.println(X_TIME_FOR_MOVE); 
            Serial.print("x_interval: "); Serial.println(x_interval); 
            Serial.println("");
            Serial.print("destination_y: "); Serial.println(dest_y); 
            Serial.print("current_y: "); Serial.println(current_y); 
            Serial.print("y_steps_to_take: "); Serial.println(y_steps_to_take); 
            Serial.print("Y_TIME_FOR_MVE: "); Serial.println(Y_TIME_FOR_MOVE); 
            Serial.print("y_interval: "); Serial.println(y_interval); 
            Serial.println("");
            Serial.print("destination_z: "); Serial.println(dest_z); 
            Serial.print("current_z: "); Serial.println(current_z); 
            Serial.print("z_steps_to_take: "); Serial.println(z_steps_to_take); 
            Serial.print("Z_TIME_FOR_MVE: "); Serial.println(Z_TIME_FOR_MOVE); 
            Serial.print("z_interval: "); Serial.println(z_interval); 
            Serial.println("");
            Serial.print("destination_e: "); Serial.println(dest_e); 
            Serial.print("current_e: "); Serial.println(current_e); 
            Serial.print("e_steps_to_take: "); Serial.println(e_steps_to_take); 
            Serial.print("E_TIME_FOR_MVE: "); Serial.println(E_TIME_FOR_MOVE); 
            Serial.print("e_interval: "); Serial.println(e_interval); 
            Serial.println("");
          }
          
          //linear_move(x_steps_to_take, y_steps_to_take, z_steps_to_take, e_steps_to_take); // make the move

  //Determine direction of movement
  //Find direction
  if(dest_x >= current_x) direction_x=1;
  else direction_x=0;
  if(dest_y >= current_y) direction_y=1;
  else direction_y=0;
  if(dest_z >= current_z) direction_z=1;
  else direction_z=0;
  if(dest_e >= current_e) direction_e=1;
  else direction_e=0;
  //Set direction
  if (direction_x) digitalWrite(X_DIR_PIN,!INVERT_X_DIR);
  else digitalWrite(X_DIR_PIN,INVERT_X_DIR);
  if (direction_y) digitalWrite(Y_DIR_PIN,!INVERT_Y_DIR);
  else digitalWrite(Y_DIR_PIN,INVERT_Y_DIR);
  if (direction_z) digitalWrite(Z_DIR_PIN,!INVERT_Z_DIR);
  else digitalWrite(Z_DIR_PIN,INVERT_Z_DIR);
  if (direction_e) digitalWrite(E_DIR_PIN,!INVERT_E_DIR);
  else digitalWrite(E_DIR_PIN,INVERT_E_DIR);
  
  //Only enable axis that are moving. If the axis doesn't need to move then it can stay disabled depending on configuration.
  if(x_steps_to_take) enable_x();
  if(y_steps_to_take) enable_y();
  if(z_steps_to_take) enable_z();
  if(e_steps_to_take) enable_e();

  if(NotHome)
  {
    if(!direction_x) if(digitalRead(X_MIN_PIN) != ENDSTOPS_INVERTING) x_steps_to_take=0;
    if(!direction_y) if(digitalRead(Y_MIN_PIN) != ENDSTOPS_INVERTING) y_steps_to_take=0;
    if(!direction_z) if(digitalRead(Z_MIN_PIN) != ENDSTOPS_INVERTING) z_steps_to_take=0;
  }
  
  //synchronise all axes
  previous_micros_x = previous_micros_y = previous_micros_z = previous_micros_e = micros();
  
  while(x_steps_to_take + y_steps_to_take + z_steps_to_take + e_steps_to_take > 0) // move until no more steps remain
  { 
    if(x_steps_to_take)
    {
      if ((micros()-previous_micros_x) >= x_interval)
      {
        do_x_step();
        x_steps_to_take--;
        x_steps++;
      }
      if(!direction_x && NotHome) if(digitalRead(X_MIN_PIN) != ENDSTOPS_INVERTING) x_steps_to_take=0;
    }
    
    if(y_steps_to_take)
    {
      if ((micros()-previous_micros_y) >= y_interval)
      {
        do_y_step();
        y_steps_to_take--;
        y_steps++;
      }
      if(!direction_y && NotHome) if(digitalRead(Y_MIN_PIN) != ENDSTOPS_INVERTING) y_steps_to_take=0;
    }
    
    if(z_steps_to_take)
    {
      if ((micros()-previous_micros_z) >= z_interval)
      {
        do_z_step();
        z_steps_to_take--;
        z_steps++;
      }
      if(!direction_z && NotHome) if(digitalRead(Z_MIN_PIN) != ENDSTOPS_INVERTING) z_steps_to_take=0;
    }    
    
    if(e_steps_to_take)
    {
      if ((micros()-previous_micros_e) >= e_interval)
      {
        do_e_step();
        e_steps_to_take--;
      }
    }
    
    if( (millis() - previous_millis_heater) >= HEAT_INTERVAL )
    {
      manage_heaters();      
      manage_inactivity(2);
    }
  } //end while
  
  if(DISABLE_X) disable_x();
  if(DISABLE_Y) disable_y();
  if(DISABLE_Z) disable_z();
  if(DISABLE_E) disable_e();
  
  // Update current position partly based on direction, we probably can combine this with the direction code above...
  if (destination_x > current_x) current_x = current_x + x_steps/x_steps_per_unit;
  else current_x = current_x - x_steps/x_steps_per_unit;
  if (destination_y > current_y) current_y = current_y + y_steps/y_steps_per_unit;
  else current_y = current_y - y_steps/y_steps_per_unit;
  if (destination_z > current_z) current_z += z_steps/z_steps_per_unit;
  else current_z -= z_steps/z_steps_per_unit;
  
//  if (destination_e > current_e) current_e = current_e + e_steps_to_take/e_steps_per_unit;
//  else current_e = current_e - e_steps_to_take/e_steps_per_unit;
          
  return;
}
inline void FlushSerialRequestResend()
{
  char cmdbuffer[100]="Resend:";
  ltoa(gcode_LastN+1, cmdbuffer+7, 10);
  Serial.flush();
  Serial.println(cmdbuffer);
  ClearToSend();
}

inline void ClearToSend()
{
  previous_millis_cmd = millis();
  Serial.println("ok"); 
}

inline void get_coordinates()
{
  if(code_seen('X')) destination_x = (float)code_value() + relative_mode*current_x;
  else destination_x = current_x;                                                       //Are these else lines really needed?
  if(code_seen('Y')) destination_y = (float)code_value() + relative_mode*current_y;
  else destination_y = current_y;
  if(code_seen('Z')) destination_z = (float)code_value() + relative_mode*current_z;
  else destination_z = current_z;
  if(code_seen('E')) destination_e = (float)code_value() + (relative_mode_e || relative_mode)*current_e;
  else destination_e = current_e;
  if(code_seen('F')) {
    next_feedrate = code_value();
    if(next_feedrate > 0.0) feedrate = next_feedrate;
  }
  
/*  //Find direction
  if(destination_x >= current_x) direction_x=1;
  else direction_x=0;
  if(destination_y >= current_y) direction_y=1;
  else direction_y=0;
  if(destination_z >= current_z) direction_z=1;
  else direction_z=0;
  if(destination_e >= current_e) direction_e=1;
  else direction_e=0;
*/
  
  if (min_software_endstops && !NotHome) {
    if (destination_x < 0) destination_x = 0.0;
    if (destination_y < 0) destination_y = 0.0;
    if (destination_z < 0) destination_z = 0.0;
  }

  if (max_software_endstops) {
    if (destination_x > X_MAX_LENGTH) destination_x = X_MAX_LENGTH;
    if (destination_y > Y_MAX_LENGTH) destination_y = Y_MAX_LENGTH;
    if (destination_z > Z_MAX_LENGTH) destination_z = Z_MAX_LENGTH;
  }
  if(code_seen('Z')) {
    feedrate = min(feedrate,RAPID_Z);
  }else{
    feedrate = min(feedrate,RAPID_XY);
  }
}

/*void linear_move(unsigned long x_steps_remaining, unsigned long y_steps_remaining, unsigned long z_steps_remaining, unsigned long e_steps_remaining) // make linear move with preset speeds and destinations, see G0 and G1
{
}
*/

inline void do_x_step()
{
  digitalWrite(X_STEP_PIN, HIGH);
  previous_micros_x = micros();
  //delayMicroseconds(3);
  digitalWrite(X_STEP_PIN, LOW);
}

inline void do_y_step()
{
  digitalWrite(Y_STEP_PIN, HIGH);
  previous_micros_y = micros();
  //delayMicroseconds(3);
  digitalWrite(Y_STEP_PIN, LOW);
}

inline void do_z_step()
{
  digitalWrite(Z_STEP_PIN, HIGH);
  previous_micros_z = micros();
  //delayMicroseconds(3);
  digitalWrite(Z_STEP_PIN, LOW);
}

inline void do_e_step()
{
  digitalWrite(E_STEP_PIN, HIGH);
  previous_micros_e = micros();
  //delayMicroseconds(3);
  digitalWrite(E_STEP_PIN, LOW);
}

inline void disable_x() { if(X_ENABLE_PIN > -1) digitalWrite(X_ENABLE_PIN,!X_ENABLE_ON); }
inline void disable_y() { if(Y_ENABLE_PIN > -1) digitalWrite(Y_ENABLE_PIN,!Y_ENABLE_ON); }
inline void disable_z() { if(Z_ENABLE_PIN > -1) digitalWrite(Z_ENABLE_PIN,!Z_ENABLE_ON); }
inline void disable_e() { if(E_ENABLE_PIN > -1) digitalWrite(E_ENABLE_PIN,!E_ENABLE_ON); }
inline void  enable_x() { if(X_ENABLE_PIN > -1) digitalWrite(X_ENABLE_PIN, X_ENABLE_ON); }
inline void  enable_y() { if(Y_ENABLE_PIN > -1) digitalWrite(Y_ENABLE_PIN, Y_ENABLE_ON); }
inline void  enable_z() { if(Z_ENABLE_PIN > -1) digitalWrite(Z_ENABLE_PIN, Z_ENABLE_ON); }
inline void  enable_e() { if(E_ENABLE_PIN > -1) digitalWrite(E_ENABLE_PIN, E_ENABLE_ON); }

inline void manage_heaters()
{
 if( (millis() - previous_millis_heater) >= HEAT_INTERVAL )
 {
    previous_millis_heater = millis();
    manage_nozzle();
    manage_bed();
 }
}
void manage_nozzle()
{
  int pTerm;
    int iTerm;
    int dTerm;
    //int output;
    int error;
    int temp_iState_min = -PID_INTEGRAL_DRIVE_MAX/PID_IGAIN;
    int temp_iState_max = PID_INTEGRAL_DRIVE_MAX/PID_IGAIN;
    
#ifdef THERMOCOUPLE
    tcTemperature();
#else
    //nozzle_curr = thTemperature(_thNTempTable, TEMP_1_PIN, nNUMTEMPS);
    nozzle_curr = 1023 - analogRead(TEMP_1_PIN);
#endif

    // code for PID control
    error = nozzle_targ - nozzle_curr;

    pTerm = PID_PGAIN * error;

    temp_iState += error;
    temp_iState = constrain(temp_iState, temp_iState_min, temp_iState_max);
    iTerm = PID_IGAIN * temp_iState;

    dTerm = PID_DGAIN * (nozzle_curr - temp_dState);
    temp_dState = nozzle_curr;

    output = pTerm + iTerm - dTerm;
    output = constrain(output, 0, PID_MAX);
  
    analogWrite(HEATER_1_PIN, output);
}
void manage_bed()
{
    int prev_curr = bed_curr;
    int zone;
    // code for thermistor bang-bang control
    //bed_curr = thTemperature(_thTempTable, TEMP_0_PIN, bNUMTEMPS);
    bed_curr = 1023 - analogRead(TEMP_0_PIN);
    if(bed_curr >= prev_curr)
    {
      zone = bed_targ - LZONE;
    }
    if(bed_curr < prev_curr)
    {
      zone = bed_targ + UZONE;
    }
    if(bed_curr<zone)
    {
      digitalWrite(HEATER_0_PIN, HIGH);
    }else{
      digitalWrite(HEATER_0_PIN, LOW);
    }
/*  bed_curr = analogRead(TEMP_0_PIN);                  // If using thermistor, when the heater is colder than targer temp, we get a higher analog reading than target, 
  //if(USE_THERMISTOR) bed_curr = 1023 - bed_curr;   // this switches it up so that the reading appears lower than target for the control logic.
  
  if(bed_curr >= bed_targ)
   {
     digitalWrite(HEATER_0_PIN,LOW);
     digitalWrite(LED_PIN,LOW);
   }
  else 
  {
    digitalWrite(HEATER_0_PIN,HIGH);
    digitalWrite(LED_PIN,HIGH);
  }
*/
}
/*int thTemperature(short table[][2], int temp_pin, int numtemps)
{
  int raw = analogRead(temp_pin);
  int curr=0;
  byte i;

  // TODO: This should do a binary chop

  for (i=1; i<numtemps; i++)
  {
    if (table[i][0] > raw)
    {
      curr  = table[i-1][1] + 
        (raw - table[i-1][0]) * 
        (table[i][1] - table[i-1][1]) /
        (table[i][0] - table[i-1][0]);
      break;
    }
  }

  // Overflow: Set to last value in the table
  if (i >= numtemps) curr = table[i-1][1];
  // Clamp to byte
  //if (celsius > 255) celsius = 255; 
  //else if (celsius < 0) celsius = 0; 
  return curr;
}
*/
#ifdef THERMOCOUPLE
void tcTemperature()
{
  int value = 0;
  byte error_tc = 0;

  digitalWrite(MAX6675_EN, 0); // Enable device

  /* Cycle the clock for dummy bit 15 */
  digitalWrite(MAX6675_SCK,1);
  digitalWrite(MAX6675_SCK,0);

  /* Read bits 14-3 from MAX6675 for the Temp
  Loop for each bit reading the value */
  for (int i=11; i>=0; i--)
  {
    digitalWrite(MAX6675_SCK,1);  // Set Clock to HIGH
    value += digitalRead(MAX6675_SO) << i;  // Read data and add it to our variable
    digitalWrite(MAX6675_SCK,0);  // Set Clock to LOW
  }

  /* Read the TC Input inp to check for TC Errors */
  digitalWrite(MAX6675_SCK,1); // Set Clock to HIGH
  error_tc = digitalRead(MAX6675_SO); // Read data
  digitalWrite(MAX6675_SCK,0);  // Set Clock to LOW

  digitalWrite(MAX6675_EN, 1); //Disable Device

  if(error_tc)
  {
    nozzle_curr = 9999;
  }else{
    //nozzle_curr = value/4;
    nozzle_curr = value;
  }

}
#endif
// Takes temperature value as input and returns corresponding analog value from RepRap thermistor temp table.
// This is needed because PID in hydra firmware hovers around a given analog value, not a temp value.
// This function is derived from inversing the logic from a portion of getTemperature() in FiveD RepRap firmware.
float temp2analog(int celsius, short table[][2], int numtemps) {
    int raw = 0;
    byte i;
    
    for (i=1; i<numtemps; i++)
    {
      if (table[i][1] < celsius)
      {
        raw = table[i-1][0] + 
          (celsius - table[i-1][1]) * 
          (table[i][0] - table[i-1][0]) /
          (table[i][1] - table[i-1][1]);
      
        break;
      }
    }

    // Overflow: Set to last value in the table
    if (i == numtemps) raw = table[i-1][0];

    return 1023 - raw;
}

// Derived from RepRap FiveD extruder::getTemperature()
float analog2temp(int raw, short table[][2], int numtemps) {
    int celsius = 0;
    byte i;
    int raw_ = 1023 - raw;

    for (i=1; i<numtemps; i++)
    {
      if (table[i][0] > raw_)
      {
        celsius  = table[i-1][1] + 
          (raw_ - table[i-1][0]) * 
          (table[i][1] - table[i-1][1]) /
          (table[i][0] - table[i-1][0]);

        break;
      }
    }

    // Overflow: Set to last value in the table
    if (i == numtemps) celsius = table[i-1][1];

    return celsius;
    
}

inline void kill(byte debug)
{
  if(HEATER_0_PIN > -1) digitalWrite(HEATER_0_PIN,LOW);
  #ifdef REPSTRAP
  if(HEATER_1_PIN > -1) digitalWrite(HEATER_1_PIN,LOW);
  #endif
  
  disable_x;
  disable_y;
  disable_z;
  disable_e;
  
  if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,INPUT);
  
  while(1)
  {
    switch(debug)
    {
      case 1: Serial.print("Inactivity Shutdown, Last Line: "); break;
      case 2: Serial.print("Linear Move Abort, Last Line: "); break;
      case 3: Serial.print("Homing X Min Stop Fail, Last Line: "); break;
      case 4: Serial.print("Homing Y Min Stop Fail, Last Line: "); break;
    } 
    Serial.println(gcode_LastN);
    delay(5000); // 5 Second delay
  }
}

inline void manage_inactivity(byte debug) { if(max_inactive_time) if( (millis()-previous_millis_cmd) >  max_inactive_time ) kill(debug); }