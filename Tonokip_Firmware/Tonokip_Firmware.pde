// Tonokip RepRap firmware rewrite based off of Hydra-mmm firmware.
// Licence: GPL
//jmgiacalone/Tonokip-Firmware -branch jmgkip
#include "configuration.h"
//#include <EEPROM.h>

#ifdef SDSUPPORT
#include "SdFat.h"
#endif

// look here for descriptions of gcodes: http://linuxcnc.org/handbook/gcode/g-code.html
// http://objects.reprap.org/wiki/Mendel_User_Manual:_RepRapGCodes

//Implemented Codes
//-------------------
// G0 -> G1
// G1  - Coordinated Movement X Y Z E
// G4  - Dwell S<seconds> or P<milliseconds>
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
// M20  - List SD card
// M21  - Init SD card
// M22  - Release SD card
// M23  - Select SD file (M23 filename.g)
// M24  - Start/resume SD print
// M25  - Pause SD print
// M26  - Set SD position in bytes (M26 S12345)
// M27  - Report SD print status
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
unsigned long long_full_velocity_units = (sq(max_units_per_second)-sq(min_units_per_second))/(2*acc)*100;
unsigned long max_x_interval = 100000000.0 / (min_units_per_second * x_steps_per_unit);//1x10^6/(35*80)=357.143
unsigned long max_y_interval = 100000000.0 / (min_units_per_second * y_steps_per_unit);
unsigned long max_e_interval = 100000000.0 / (min_units_per_second * e_steps_per_unit);
unsigned long max_interval, interval;
boolean acceleration_enabled,accelerating;
float destination_x =0.0, destination_y = 0.0, destination_z = 0.0, destination_e = 0.0;
float current_x = 0.0, current_y = 0.0, current_z = 0.0, current_e = 0.0;
long x_interval, y_interval, z_interval, e_interval; // for speed delay
float feedrate = 1500, next_feedrate;
float time_for_move;
long gcode_N, gcode_LastN;
bool relative_mode = false;  //Determines Absolute or Relative Coordinates
bool relative_mode_e = true;  //Determines Absolute or Relative E Codes while in Absolute Coordinates mode. E is always relative in Relative Coordinates mode.
long timediff=0;


// comm variables
#define BUFSIZE 8
char cmdbuffer[BUFSIZE][MAX_CMD_SIZE];
bool fromsd[BUFSIZE];
int bufindr=0;
int bufindw=0;
int buflen=0;
int i=0;
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
int prev_nozzle_curr;
        
//Inactivity shutdown variables
unsigned long previous_millis_cmd=0;
unsigned long max_inactive_time = 0;

boolean NotHome = true;

#ifdef SDSUPPORT
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;
uint32_t filesize=0;
uint32_t sdpos=0;
bool sdmode=false;
bool sdactive=false;
bool savetosd=false;
int16_t n;

void initsd(){
sdactive=false;
if(root.isOpen())
    root.close();
if (!card.init(SPI_FULL_SPEED)){
    if (!card.init(SPI_HALF_SPEED))
      Serial.println("SD init fail");
}
else if (!volume.init(&card))
      Serial.println("volume.init failed");
else if (!root.openRoot(&volume)) 
      Serial.println("openRoot failed");
else 
        sdactive=true;

}

inline void write_command(char *buf){
    char* begin=buf;
    char* npos=0;
    char* end=buf+strlen(buf)-1;
    
    file.writeError = false;
    if((npos=strchr(buf, 'N')) != NULL){
        begin = strchr(npos,' ')+1;
        end =strchr(npos, '*')-1;
    }
    end[1]='\r';
    end[2]='\n';
    end[3]='\0';
    //Serial.println(begin);
    file.write(begin);
    if (file.writeError){
        Serial.println("Err: file write");
    }
}


#endif


void setup()
{ 
//  EEPROM.write(0,1);
  Serial.begin(BAUDRATE);
  Serial.println("start");
  for(int i=0;i<BUFSIZE;i++){
      fromsd[i]=false;
  }
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

  //Steppers default to disabled.
  if(X_ENABLE_PIN > -1) if(!X_ENABLE_ON) digitalWrite(X_ENABLE_PIN,HIGH);
  if(Y_ENABLE_PIN > -1) if(!Y_ENABLE_ON) digitalWrite(Y_ENABLE_PIN,HIGH);
  if(Z_ENABLE_PIN > -1) if(!Z_ENABLE_ON) digitalWrite(Z_ENABLE_PIN,HIGH);
  if(E_ENABLE_PIN > -1) if(!E_ENABLE_ON) digitalWrite(E_ENABLE_PIN,HIGH);
  
  //endstop pullups
  #ifdef ENDSTOPPULLUPS
  if(X_MIN_PIN > -1) { pinMode(X_MIN_PIN,INPUT); digitalWrite(X_MIN_PIN,HIGH);}
  if(Y_MIN_PIN > -1) { pinMode(Y_MIN_PIN,INPUT); digitalWrite(Y_MIN_PIN,HIGH);}
  if(Z_MIN_PIN > -1) { pinMode(Z_MIN_PIN,INPUT); digitalWrite(Z_MIN_PIN,HIGH);}
  if(X_MAX_PIN > -1) { pinMode(X_MAX_PIN,INPUT); digitalWrite(X_MAX_PIN,HIGH);}
  if(Y_MAX_PIN > -1) { pinMode(Y_MAX_PIN,INPUT); digitalWrite(Y_MAX_PIN,HIGH);}
  if(Z_MAX_PIN > -1) { pinMode(Z_MAX_PIN,INPUT); digitalWrite(Z_MAX_PIN,HIGH);}
  #endif
  #ifdef PROBING
    pinMode(PROBE_PIN,INPUT);
    digitalWrite(PROBE_PIN,HIGH);
  #endif
  //Initialize Enable Pins
  if(X_ENABLE_PIN > -1) pinMode(X_ENABLE_PIN,OUTPUT);
  if(Y_ENABLE_PIN > -1) pinMode(Y_ENABLE_PIN,OUTPUT);
  if(Z_ENABLE_PIN > -1) pinMode(Z_ENABLE_PIN,OUTPUT);
  if(E_ENABLE_PIN > -1) pinMode(E_ENABLE_PIN,OUTPUT);

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
 
#ifdef SDSUPPORT
#if SDPOWER > -1
pinMode(SDPOWER,OUTPUT); 
digitalWrite(SDPOWER,HIGH);
#endif
initsd();
#endif
  
}


void loop()
{


  if(buflen<3)
	get_command();
  
  if(buflen){
#ifdef SDSUPPORT
    if(savetosd){
        if(strstr(cmdbuffer[bufindr],"M29")==NULL){
            write_command(cmdbuffer[bufindr]);
            file.sync();
            Serial.println("ok");
        }else{
            file.close();
            savetosd=false;
            Serial.println("File saved");
        }
    }else{
        process_commands();
    }
#else
    process_commands();
#endif
    buflen=(buflen-1);
    bufindr=(bufindr+1)%BUFSIZE;
    }
  
  manage_heaters();
  
  manage_inactivity(1); //shutdown if not receiving any new commands
}


inline void get_command() 
{ 
  while( Serial.available() > 0  && buflen<BUFSIZE) {
    serial_char=Serial.read();
    if(serial_char == '\n' || serial_char == '\r' || serial_char == ':' || serial_count >= (MAX_CMD_SIZE - 1) ) 
    {
      if(!serial_count) return; //if empty line
      cmdbuffer[bufindw][serial_count] = 0; //terminate string
      if(!comment_mode){
    fromsd[bufindw]=false;
  if(strstr(cmdbuffer[bufindw], "N") != NULL)
  {
    strchr_pointer = strchr(cmdbuffer[bufindw], 'N');
    gcode_N = (strtol(&cmdbuffer[bufindw][strchr_pointer - cmdbuffer[bufindw] + 1], NULL, 10));
    if(gcode_N != gcode_LastN+1 && (strstr(cmdbuffer[bufindw], "M110") == NULL) ) {
      Serial.print("Serial Error: N!=(N-1)+1:");
      Serial.println(gcode_LastN);
      Serial.println(gcode_N);
      FlushSerialRequestResend();
      serial_count = 0;
      return;
    }
    
    if(strstr(cmdbuffer[bufindw], "*") != NULL)
    {
      byte checksum = 0;
      byte count=0;
      while(cmdbuffer[bufindw][count] != '*') checksum = checksum^cmdbuffer[bufindw][count++];
      strchr_pointer = strchr(cmdbuffer[bufindw], '*');
  
      if( (int)(strtod(&cmdbuffer[bufindw][strchr_pointer - cmdbuffer[bufindw] + 1], NULL)) != checksum) {
        Serial.print("Error: checksum mismatch, Last Line:");
        Serial.println(gcode_LastN);
        FlushSerialRequestResend();
        serial_count=0;
        return;
      }
      //if no errors, continue parsing
    }
    else 
    {
      Serial.print("Error: No * with N:");
      Serial.println(gcode_LastN);
      FlushSerialRequestResend();
      serial_count=0;
      return;
    }
    
    gcode_LastN = gcode_N;
    //if no errors, continue parsing
  }
  else  // if we don't receive 'N' but still see '*'
  {
    if((strstr(cmdbuffer[bufindw], "*") != NULL))
    {
      Serial.print("Error: No N with *:");
      Serial.println(gcode_LastN);
      serial_count=0;
      return;
    }
  }
	if((strstr(cmdbuffer[bufindw], "G") != NULL)){
		strchr_pointer = strchr(cmdbuffer[bufindw], 'G');
		switch((int)((strtod(&cmdbuffer[bufindw][strchr_pointer - cmdbuffer[bufindw] + 1], NULL)))){
		case 0:
		case 1:
              #ifdef SDSUPPORT
              if(savetosd)
                break;
              #endif
			  Serial.println("ok"); 
			  break;
		default:
			break;
		}

	}
        bufindw=(bufindw+1)%BUFSIZE;
        buflen+=1;
        
      }
      comment_mode = false; //for new command
      serial_count = 0; //clear buffer
    }
    else
    {
      if(serial_char == ';') comment_mode = true;
      if(!comment_mode) cmdbuffer[bufindw][serial_count++] = serial_char;
    }
  }
#ifdef SDSUPPORT
if(!sdmode || serial_count!=0){
    return;
}
  while( filesize > sdpos  && buflen<BUFSIZE) {
    n=file.read();
    serial_char=(char)n;
    if(serial_char == '\n' || serial_char == '\r' || serial_char == ':' || serial_count >= (MAX_CMD_SIZE - 1) || n==-1) 
    {
        sdpos=file.curPosition();
        if(sdpos>=filesize){
            sdmode=false;
            Serial.println("SD print done");
        }
      if(!serial_count) return; //if empty line
      cmdbuffer[bufindw][serial_count] = 0; //terminate string
      if(!comment_mode){
        fromsd[bufindw]=true;
        buflen+=1;
        bufindw=(bufindw+1)%BUFSIZE;
      }
      comment_mode = false; //for new command
      serial_count = 0; //clear buffer
    }
    else
    {
      if(serial_char == ';') comment_mode = true;
      if(!comment_mode) cmdbuffer[bufindw][serial_count++] = serial_char;
    }
}
#endif

}


inline float code_value() { return (strtod(&cmdbuffer[bufindr][strchr_pointer - cmdbuffer[bufindr] + 1], NULL)); }
inline long code_value_long() { return (strtol(&cmdbuffer[bufindr][strchr_pointer - cmdbuffer[bufindr] + 1], NULL, 10)); }
inline bool code_seen(char code_string[]) { return (strstr(cmdbuffer[bufindr], code_string) != NULL); }  //Return True if the string was found

inline bool code_seen(char code)
{
  strchr_pointer = strchr(cmdbuffer[bufindr], code);
  return (strchr_pointer != NULL);  //Return True if a character was found
}
 //experimental feedrate calc
float d=0;
//float xdiff=0,ydiff=0,zdiff=0,ediff=0;

inline void process_commands()
{
  unsigned long codenum; //throw away variable
  unsigned long previous_millis=0;
  char *starpos=NULL;
  if(code_seen('G'))
  {
    switch((int)code_value())
    {
      case 0: // G0 -> G1
      case 1: // G1
        get_coordinates(); // For X Y Z E F
        linear_move(destination_x,destination_y,destination_z,destination_e); // make the move
        return;
      case 4: // G4 dwell
        codenum = 0;
        if(code_seen('P')) codenum = code_value(); // milliseconds to wait
        if(code_seen('S')) codenum = code_value()*1000; // seconds to wait
        previous_millis = millis();  // keep track of when we started waiting
        while((millis() - previous_millis) < codenum ) manage_heaters(); //manage heater until time is up
        break;
      case 28: // G28 - reference axes TODO
        NotHome = true;
#ifndef PROBING
        reference_x();
        reference_y();
        reference_z();
        current_e = 0;
#else
        //fast feed XY to roughly find home
        feedrate = 1000;
        linear_move(-(X_MAX_LENGTH + 1), -(Y_MAX_LENGTH + 1), current_z, current_e);
        current_x = current_y = 0;
        //back off
        linear_move(1, 1, current_z, current_e);
        //low feed home X
        feedrate = 100;
        linear_move(-1, current_y, current_z, current_e);
        current_x = (code_seen('X')) ? code_value() : 0;
        //low feed home Y
        linear_move(current_x, -1, current_z, current_e);
        current_y = (code_seen('Y')) ? code_value() : 0;
        feedrate = 1500;
        NotHome = false;
        //move to centre of build surface ready to probe Z
        linear_move(Z_HOME_X,Z_HOME_Y,current_z,current_e);
        //probe Z
        probe_z(-1);
        current_z = (code_seen('Z')) ? code_value() : 0;
        feedrate = 1500;
        break;
      case 31: //probe
        NotHome = true;
        if(code_seen('Z')) probe_z(code_value());
#endif
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
  }

  else if(code_seen('M'))
  {
    
    switch( (int)code_value() ) 
    {
#ifdef SDSUPPORT
        
      case 20: // M20 - list SD card
        Serial.println("Begin file list");
        root.ls();
        Serial.println("End file list");
        break;
      case 21: // M21 - init SD card
        sdmode=false;
        initsd();
        break;
      case 22: //M22 - release SD card
        sdmode=false;
        sdactive=false;
        break;
      case 23: //M23 - Select file
        if(sdactive){
            sdmode=false;
            file.close();
            starpos=(strchr(strchr_pointer+4,'*'));
            if(starpos!=NULL)
                *(starpos-1)='\0';
            if (file.open(&root, strchr_pointer+4, O_READ)) {
                Serial.print("File opened:");
                Serial.print(strchr_pointer+4);
                Serial.print(" Size:");
                Serial.println(file.fileSize());
                sdpos=0;
                filesize=file.fileSize();
                Serial.println("File selected");
            }
            else{
                Serial.println("file.open failed");
            }
        }
        break;
      case 24: //M24 - Start SD print
        if(sdactive){
            sdmode=true;
        }
        break;
      case 25: //M25 - Pause SD print
        if(sdmode){
            sdmode=false;
        }
        break;
      case 26: //M26 - Set SD index
        if(sdactive && code_seen('S')){
            sdpos=code_value_long();
            file.seekSet(sdpos);
        }
        break;
      case 27: //M27 - Get SD status
        if(sdactive){
            Serial.print("SD printing byte ");
            Serial.print(sdpos);
            Serial.print("/");
            Serial.println(filesize);
        }else{
            Serial.println("Not SD printing");
        }
        break;
      case 28: //M28 - Start SD write
        if(sdactive){
          char* npos=0;
            file.close();
            sdmode=false;
            starpos=(strchr(strchr_pointer+4,'*'));
            if(starpos!=NULL){
              npos=strchr(cmdbuffer[bufindr], 'N');
              strchr_pointer = strchr(npos,' ')+1;
                *(starpos-1)='\0';
            }
            if (!file.open(&root, strchr_pointer+4, O_CREAT | O_APPEND | O_WRITE | O_TRUNC))
            {
            Serial.print("open failed: ");
            Serial.print(strchr_pointer+4);
            Serial.print(".");
            }else{
            savetosd = true;
            Serial.print("Writing to file: ");
            Serial.println(strchr_pointer+4);
            }
        }else{
          Serial.println("SD !active");
        }
        break;
      case 29: //M29 - Stop SD write
        //processed in write to file routine above
        //savetosd=false;
        break;
#endif
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
        return;
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
               Serial.println( analog2temp(bed_targ, _thTempTable, bNUMTEMPS) ); 
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
/*      case 80: // M81 - ATX Power On
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
*/      case 84:
        disable_x();
        disable_y();
        disable_z();
        disable_e();
        break;
/*      case 85: // M85
        code_seen('S');
        max_inactive_time = code_value()*1000; 
        break;
      case 86: // M86 If Endstop is Not Activated then Abort Print
        if(code_seen('X')) if( digitalRead(X_MIN_PIN) == ENDSTOPS_INVERTING ) kill(3);
        if(code_seen('Y')) if( digitalRead(Y_MIN_PIN) == ENDSTOPS_INVERTING ) kill(4);
        break;
*/      case 92: // M92
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
        return;
#if DEBUG == 2
      case 206:
        if(code_seen('F')){
          Serial.print("m_u_p_s were "); Serial.println(min_units_per_second);
          min_units_per_second = code_value();
          Serial.print("m_u_p_s now "); Serial.println(min_units_per_second);
        }
        if(code_seen('A')){
          Serial.print("acc was "); Serial.println(acc);
          acc = code_value();
          long_full_velocity_units = (sq(max_units_per_second)-sq(min_units_per_second))/(2*acc) * 100;
          Serial.print("acc now "); Serial.println(acc);
        }
#endif
/*        if(code_seen('B')){
          Serial.print("a was "); Serial.println(a);
          a = code_value();
          //long_full_velocity_units = (sq(max_units_per_second)-sq(min_units_per_second))/(2*acc) * 100;
          Serial.print("a now "); Serial.println(a);
        }*/
        break;
    }
  }else if(code_seen('X') || code_seen('Y') || code_seen('Z') || code_seen('E') || code_seen('F'))
  {
    get_coordinates(); // For X Y Z E F
    linear_move(destination_x,destination_y,destination_z,destination_e);    
  }else{
    Serial.println("?:");
    Serial.println(cmdbuffer[bufindr]);
  }
  ClearToSend();
      
}
#ifndef PROBING
inline void reference_x()
{
        feedrate = 1000;
        linear_move(-(X_MAX_LENGTH + 1), current_y, current_z, current_e);
        current_x = 0;
        linear_move(1, current_y, current_z, current_e);
        feedrate = 100;
        linear_move(-1, current_y, current_z, current_e);
        current_x = 0;
        feedrate = 1500;
}
inline void reference_y()
{
        feedrate = 1000;
        linear_move(current_x, -(Y_MAX_LENGTH + 1), current_z, current_e);
        current_y = 0;
        linear_move(current_x, 1, current_z, current_e);
        feedrate = 100;
        linear_move(current_x, -1, current_z, current_e);
        current_y = 0;
        feedrate = 1500;
}
inline void reference_z()
{
  feedrate = 100;
  linear_move(current_x, current_y, -(Z_MAX_LENGTH + 2), current_e);
  current_z = 0;
  linear_move(current_x, current_y, 1, current_e);
  linear_move(current_x, current_y, -1, current_e);
  current_z = 0;
  feedrate = 1500;
}
#else
void probe_z(float dest_z)
{
  float start_z = current_z;
  //check probe is down
  if(digitalRead(PROBE_PIN)==1) {
    Serial.println("Err:probe open");
  }else{
    //find surface
    feedrate = 100;
    while(digitalRead(PROBE_PIN)==1 && current_z > dest_z) {
      linear_move(current_x,current_y,current_z-0.1,current_e);
    }
    //back off until probe contact makes
    feedrate = 50;
    while(digitalRead(PROBE_PIN)==0 && current_z < start_z) {
      linear_move(current_x,current_y,current_z+0.01,current_e);
    }
    Serial.println(current_z);
  }
}
#endif
inline void FlushSerialRequestResend()
{
  //char cmdbuffer[bufindr][100]="Resend:";
  Serial.flush();
  Serial.print("Resend:");
  Serial.println(gcode_LastN+1);
  ClearToSend();
}

inline void ClearToSend()
{
  previous_millis_cmd = millis();
  #ifdef SDSUPPORT
  if(fromsd[bufindr])
    return;
  #endif
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
    if(next_feedrate > 0.0) feedrate = min(next_feedrate,RAPID_XY);
    long_full_velocity_units = (sq(max(feedrate/60,min_units_per_second))-sq(min_units_per_second))/(2*acc)*100;
    //Serial.print("long_full_velocity_units:"); Serial.println(long_full_velocity_units);
  }
  
  
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
  if(code_seen('Z') && feedrate > RAPID_Z) {
    feedrate = RAPID_Z;
  }
}

void linear_move(float dest_x, float dest_y, float dest_z, float dest_e) // make linear move with preset speeds and destinations, see G0 and G1
{
  unsigned long x_steps_remaining, y_steps_remaining, z_steps_remaining, e_steps_remaining;
  unsigned long x_steps_to_take, y_steps_to_take, z_steps_to_take, e_steps_to_take;
        x_steps_to_take = x_steps_remaining = abs(dest_x - current_x)*x_steps_per_unit;//11200 for 140mm move
        y_steps_to_take = y_steps_remaining = abs(dest_y - current_y)*y_steps_per_unit;
        z_steps_to_take = z_steps_remaining = abs(dest_z - current_z)*z_steps_per_unit;
        e_steps_to_take = e_steps_remaining = abs(dest_e)*e_steps_per_unit;//11294.7432 for 15.6mm move
        if(feedrate<10)
            feedrate=10;
        #define X_TIME_FOR_MOVE ((float)x_steps_remaining / (x_steps_per_unit*feedrate/60000000))//11200/(80*3000/60000000)=2800000
        #define Y_TIME_FOR_MOVE ((float)y_steps_remaining / (y_steps_per_unit*feedrate/60000000))
        #define Z_TIME_FOR_MOVE ((float)z_steps_remaining / (z_steps_per_unit*feedrate/60000000))
        #define E_TIME_FOR_MOVE ((float)e_steps_remaining / (e_steps_per_unit*feedrate/60000000))//11294/(724.022*3000/60000000)=311979.470237092
        
        time_for_move = max(X_TIME_FOR_MOVE,Y_TIME_FOR_MOVE);//2800
        time_for_move = max(time_for_move,Z_TIME_FOR_MOVE);
        //if(time_for_move <= 0) time_for_move = max(time_for_move,E_TIME_FOR_MOVE);
        time_for_move = max(time_for_move,E_TIME_FOR_MOVE);

        if(x_steps_remaining) x_interval = time_for_move/x_steps_remaining*100;//2800000/8000=350
        if(y_steps_remaining) y_interval = time_for_move/y_steps_remaining*100;
        if(z_steps_remaining) z_interval = time_for_move/z_steps_remaining*100;
        if(e_steps_remaining) e_interval = time_for_move/e_steps_remaining*100;
        
	#if DEBUG == 1       
          Serial.print("destination_x: "); Serial.println(dest_x); 
          Serial.print("current_x: "); Serial.println(current_x); 
          Serial.print("x_steps_to_take: "); Serial.println(x_steps_remaining); 
          Serial.print("X_TIME_FOR_MVE: "); Serial.println(X_TIME_FOR_MOVE); 
          Serial.print("x_interval: "); Serial.println(x_interval); 
          Serial.println("");
          Serial.print("destination_y: "); Serial.println(dest_y); 
          Serial.print("current_y: "); Serial.println(current_y); 
          Serial.print("y_steps_to_take: "); Serial.println(y_steps_remaining); 
          Serial.print("Y_TIME_FOR_MVE: "); Serial.println(Y_TIME_FOR_MOVE); 
          Serial.print("y_interval: "); Serial.println(y_interval); 
          Serial.println("");
          Serial.print("destination_z: "); Serial.println(dest_z); 
          Serial.print("current_z: "); Serial.println(current_z); 
          Serial.print("z_steps_to_take: "); Serial.println(z_steps_remaining); 
          Serial.print("Z_TIME_FOR_MVE: "); Serial.println(Z_TIME_FOR_MOVE); 
          Serial.print("z_interval: "); Serial.println(z_interval); 
          Serial.println("");
          Serial.print("destination_e: "); Serial.println(dest_e); 
          Serial.print("current_e: "); Serial.println(current_e); 
          Serial.print("e_steps_to_take: "); Serial.println(e_steps_remaining); 
          Serial.print("E_TIME_FOR_MVE: "); Serial.println(E_TIME_FOR_MOVE); 
          Serial.print("e_interval: "); Serial.println(e_interval); 
          Serial.println("");
        #endif
  //Determine direction of movement
  //Find and set direction
  if(dest_x >= current_x){
    direction_x=1;
    digitalWrite(X_DIR_PIN,!INVERT_X_DIR);
  }else{
    direction_x=0;
    digitalWrite(X_DIR_PIN,INVERT_X_DIR);
  }
  if(dest_y >= current_y){
    direction_y=1;
    digitalWrite(Y_DIR_PIN,!INVERT_Y_DIR);
  }else{
    direction_y=0;
    digitalWrite(Y_DIR_PIN,INVERT_Y_DIR);
  }
  if(dest_z >= current_z){
    direction_z=1;
    digitalWrite(Z_DIR_PIN,!INVERT_Z_DIR);
  }else{
    direction_z=0;
    digitalWrite(Z_DIR_PIN,INVERT_Z_DIR);
  }
  if(dest_e >= current_e){
    direction_e=1;
    digitalWrite(E_DIR_PIN,!INVERT_E_DIR);
  }else{
    direction_e=0;
    digitalWrite(E_DIR_PIN,INVERT_E_DIR);
  }
  
  //Only enable axis that are moving. If the axis doesn't need to move then it can stay disabled depending on configuration.
  if(x_steps_remaining) enable_x();
  if(y_steps_remaining) enable_y();
  if(z_steps_remaining) { enable_z(); do_z_step(); z_steps_remaining--;}
  if(e_steps_remaining) enable_e();
  
  if(NotHome)
  {
  if(X_MIN_PIN > -1) if(!direction_x) if(digitalRead(X_MIN_PIN) != ENDSTOPS_INVERTING) x_steps_remaining=0;
  if(Y_MIN_PIN > -1) if(!direction_y) if(digitalRead(Y_MIN_PIN) != ENDSTOPS_INVERTING) y_steps_remaining=0;
  if(Z_MIN_PIN > -1) if(!direction_z) if(digitalRead(Z_MIN_PIN) != ENDSTOPS_INVERTING) z_steps_remaining=0;
  }  
  
  unsigned long start_move_micros = micros(); 
  unsigned int delta_x = x_steps_remaining;
  //unsigned long x_interval_nanos;
  unsigned int delta_y = y_steps_remaining;
  //unsigned long y_interval_nanos;
  unsigned int delta_e = e_steps_remaining;
  //unsigned long e_interval_nanos;
  unsigned int delta_z = z_steps_remaining;
  //unsigned long z_interval_nanos;
  //long interval;
  boolean steep_y = delta_y > delta_x && delta_y >= delta_e;// && delta_y > delta_z;
  boolean steep_x = delta_x >= delta_y && delta_x >= delta_e;// && delta_x > delta_z;
  boolean steep_e = delta_e > delta_x && delta_e > delta_y;
  
  //boolean steep_z = delta_z > delta_x && delta_z > delta_y && delta_z > delta_e;
  int error_x;
  int error_y;
  int error_z;
  int error_e;
  unsigned long virtual_full_velocity_steps;
  unsigned long full_velocity_steps;
  unsigned long steps_remaining;
//  unsigned long steps_to_take;
  
  //Do some Bresenham calculations depending on which axis will lead it.
  if(steep_y) {
   error_x = delta_y / 2;
   error_e = delta_y / 2;
   previous_micros_y=micros()*100;
   interval = y_interval;
   virtual_full_velocity_steps = long_full_velocity_units * y_steps_per_unit /100;
   full_velocity_steps = min(virtual_full_velocity_steps, delta_y / 2);
   steps_remaining = delta_y;
//   steps_to_take = delta_y;
   max_interval = max_y_interval;
  } else if (steep_x) {
   error_y = delta_x / 2;
   error_e = delta_x / 2;
   previous_micros_x=micros()*100;
   interval = x_interval;
   virtual_full_velocity_steps = long_full_velocity_units * x_steps_per_unit /100;
   full_velocity_steps = min(virtual_full_velocity_steps, delta_x / 2);
   steps_remaining = delta_x;
//   steps_to_take = delta_x;
   max_interval = max_x_interval;
  } else if (steep_e) {
   error_y = delta_e / 2;
   error_x = delta_e / 2;
   previous_micros_e=micros()*100;
   interval = e_interval;
   virtual_full_velocity_steps = long_full_velocity_units * e_steps_per_unit /100;
   full_velocity_steps = min(virtual_full_velocity_steps, delta_e / 2);
   steps_remaining = delta_e;
   max_interval = max_e_interval;
  }
  previous_micros_z=micros()*100;
  acceleration_enabled = true;
  if(full_velocity_steps == 0) full_velocity_steps++;
  long full_interval = interval;//max(interval, max_interval - ((max_interval - full_interval) * full_velocity_steps / virtual_full_velocity_steps));//max( 350 , 357.143-((357.143-?)*800/800) )=350
  if(interval > max_interval) acceleration_enabled = false;
  unsigned long steps_done = 0;
  unsigned int steps_acceleration_check = 1;
  accelerating = acceleration_enabled;
  //long prev_interval;
  
  // move until no more steps remain 
  while(x_steps_remaining + y_steps_remaining + z_steps_remaining + e_steps_remaining > 0) { 
    //If acceleration is enabled on this move and we are in the acceleration segment, calculate the current interval
    //prev_interval = interval;
    if (acceleration_enabled && steps_done < full_velocity_steps && steps_done / full_velocity_steps < 1 && (steps_done % steps_acceleration_check == 0)) {
      if(steps_done == 0) {
        interval = max_interval;
      } else {
        interval = max_interval - ((max_interval - full_interval) * steps_done / virtual_full_velocity_steps);
        //interval = prev_interval - (2*prev_interval/(4*steps_done*a+1));
      }
    } else if (acceleration_enabled && steps_remaining < full_velocity_steps) {
      //Else, if acceleration is enabled on this move and we are in the deceleration segment, calculate the current interval
      if(steps_remaining == 0) {
        interval = max_interval;
      } else {
        interval = max_interval - ((max_interval - full_interval) * steps_remaining / virtual_full_velocity_steps);
        //interval = prev_interval - (2*prev_interval/(4*steps_remaining*a+1));
      }
      accelerating = true;
    } else if (steps_done - full_velocity_steps >= 1 || !acceleration_enabled){
      //Else, we are just use the full speed interval as current interval
      interval = full_interval;
      accelerating = false;
    }
      
    //If there are x, y or e steps remaining, perform Bresenham algorithm
    if(x_steps_remaining || y_steps_remaining || e_steps_remaining) {
      if(NotHome){
        if(X_MIN_PIN > -1) if(!direction_x) if(digitalRead(X_MIN_PIN) != ENDSTOPS_INVERTING) x_steps_remaining=0;
        if(Y_MIN_PIN > -1) if(!direction_y) if(digitalRead(Y_MIN_PIN) != ENDSTOPS_INVERTING) y_steps_remaining=0;
      }
      if(steep_y) {
        timediff = micros() * 100 - previous_micros_y;
        while(timediff >= interval && y_steps_remaining>0) {
          steps_done++;
          steps_remaining--;
          y_steps_remaining--; timediff-=interval;
          error_x -= delta_x;
          error_e -= delta_e;
          do_y_step();
          if(error_x < 0) {
            do_x_step(); x_steps_remaining--;
            error_x += delta_y;
          }
          if(error_e < 0) { 
            do_e_step(); e_steps_remaining--;
            error_e += delta_y;
          }
        }
      } else if (steep_x) {
        timediff=micros() * 100 - previous_micros_x;
        while(timediff >= interval && x_steps_remaining>0) {
          steps_done++;
          steps_remaining--;
          x_steps_remaining--; timediff-=interval;
          error_y -= delta_y;
          error_e -= delta_e;
          do_x_step();
          if(error_y < 0) { 
            do_y_step(); y_steps_remaining--;
            error_y += delta_x;
          }
          if(error_e < 0) { 
            do_e_step(); e_steps_remaining--;
            error_e += delta_x;
          }
        }
      } else if (steep_e) {
        timediff=micros() * 100 - previous_micros_e;
        while(timediff >= interval && e_steps_remaining>0) {
          steps_done++;
          steps_remaining--;
          e_steps_remaining--;
          timediff-=interval;
          error_y -= delta_y;
          error_x -= delta_x;
          do_e_step();
          if(error_y < 0) { 
            do_y_step(); y_steps_remaining--;
            error_y += delta_e;
          }
          if(error_x < 0) { 
            do_x_step(); x_steps_remaining--;
            error_x += delta_e;
          }
        }
      }
    }
    
    //If there are z steps remaining, check if z steps must be taken
    if(z_steps_remaining) {
      if(NotHome){
        if(Z_MIN_PIN > -1) if(!direction_z) if(digitalRead(Z_MIN_PIN) != ENDSTOPS_INVERTING) z_steps_remaining=0;
      }
      timediff=micros() * 100 - previous_micros_z;
      while(timediff >= z_interval && z_steps_remaining) { do_z_step(); z_steps_remaining--; timediff-=z_interval;}
    }    
    
    if(!accelerating &&  (millis() - previous_millis_heater) >= HEAT_INTERVAL ) {
      manage_heaters();      
      manage_inactivity(2);
    }
  }//end while motion loop
  
  if(DISABLE_X) disable_x();
  if(DISABLE_Y) disable_y();
  if(DISABLE_Z) disable_z();
  if(DISABLE_E) disable_e();
  
  // Update current position partly based on direction, we probably can combine this with the direction code above...
  if (dest_x > current_x) current_x += x_steps_to_take/x_steps_per_unit;
  else current_x -= x_steps_to_take/x_steps_per_unit;
  if (dest_y > current_y) current_y += y_steps_to_take/y_steps_per_unit;
  else current_y -= y_steps_to_take/y_steps_per_unit;
  if (dest_z > current_z) current_z += z_steps_to_take/z_steps_per_unit;
  else current_z -= z_steps_to_take/z_steps_per_unit;
//  if (dest_e > current_e) current_e = current_e + e_steps_to_take/e_steps_per_unit;
//  else current_e = current_e - e_steps_to_take/e_steps_per_unit;
}


inline void do_x_step()
{
  digitalWrite(X_STEP_PIN, HIGH);
  previous_micros_x += interval;
  //delayMicroseconds(3);
  digitalWrite(X_STEP_PIN, LOW);
}

inline void do_y_step()
{
  digitalWrite(Y_STEP_PIN, HIGH);
  previous_micros_y += interval;
  //delayMicroseconds(3);
  digitalWrite(Y_STEP_PIN, LOW);
}

inline void do_z_step()
{
  digitalWrite(Z_STEP_PIN, HIGH);
  previous_micros_z += z_interval;
  //delayMicroseconds(3);
  digitalWrite(Z_STEP_PIN, LOW);
}

inline void do_e_step()
{
  digitalWrite(E_STEP_PIN, HIGH);
  previous_micros_e += interval;
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
//    prev_nozzle_curr = nozzle_curr;
    tcTemperature();
    //cancel heat command if heat error
//    if(abs(prev_nozzle_curr-nozzle_curr)>100) {
//      nozzle_targ = 0;
//      Serial.println("nT err");
//      return;
//    }
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
}
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

  if(error_tc || (value / TEMP_MULTIPLIER) > 300 )
  {
    nozzle_curr = 9999;
  }else{
    //nozzle_curr = value/4;
    nozzle_curr = value;
  }

}
#endif
// Takes hot end temperature value as input and returns corresponding analog value from RepRap thermistor temp table.
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
  
  disable_x();
  disable_y();
  disable_z();
  disable_e();
  
  if(PS_ON_PIN > -1) pinMode(PS_ON_PIN,INPUT);
  
  while(1)
  {
    switch(debug)
    {
      case 1: Serial.print("Inactivity Shutdown: "); break;
      case 2: Serial.print("Linear Move Abort: "); break;
/*      case 3: Serial.print("Homing X Min Stop Fail: "); break;
      case 4: Serial.print("Homing Y Min Stop Fail: "); break;*/
    } 
    Serial.println(gcode_LastN);
    delay(5000); // 5 Second delay
  }
}

inline void manage_inactivity(byte debug) { if( (millis()-previous_millis_cmd) >  max_inactive_time ) if(max_inactive_time) kill(debug); }
