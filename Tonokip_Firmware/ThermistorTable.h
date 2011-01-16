#ifndef THERMISTORTABLE_H_
#define THERMISTORTABLE_H_

// Thermistor lookup table for RepRap Temperature Sensor Boards (http://make.rrrf.org/ts)
// See this page:  
// http://dev.www.reprap.org/bin/view/Main/Thermistor
// for details of what goes in this table.
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=4066 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 4450
// max adc: 1023
// UltiMachine.com Thermistor

#define NUMTEMPS 34
short _thTempTable[NUMTEMPS][2] = {

  {960,172},
  {962,160},
  {964,146},
  {966,136},
  {968,128},
  {970,120},
  {972,115},
  {974,110},
  {976,105},
  {978,100},
  {980,95},
  {982,90},
  {984,85},
  {986,80},
  {988,75},
  {990,70},
  {992,65},
  {994,60},
  {996,55},
  {998,50},
  {1000,45},
  {1002,40},
  {1004,35},
  {1006,30},
  {1008,25},
  {1010,20},
  {1012,15},
  {1014,12},
  {1016,9},
  {1018,6},
  {1020,3},
  {1022,0},
  {1024,-3}
};

/*short _thTempTable[NUMTEMPS][2] = {

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
 };*/
 
#ifndef REPSTRAP
/*
// EPCOS 100K Thermistor (B57560G1104F)
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=4092 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 4092
// max adc: 1023
short _thNTempTable[NUMTEMPS][2] = {
   {1, 821},
   {54, 252},
   {107, 207},
   {160, 182},
   {213, 165},
   {266, 152},
   {319, 141},
   {372, 131},
   {425, 123},
   {478, 115},
   {531, 107},
   {584, 100},
   {637, 93},
   {690, 86},
   {743, 78},
   {796, 70},
   {849, 60},
   {902, 49},
   {955, 34},
   {1008, 3}
 };
 */
// Thermistor lookup table for RepRap Temperature Sensor Boards (http://make.rrrf.org/ts)
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=1000 --beta=4092 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 1000
// beta: 4092
// max adc: 1023
#define NUMTEMPS 40
short  _thNTempTable[NUMTEMPS][2] = {
   {1, 1596},
   {27, 469},
   {53, 385},
   {79, 343},
   {105, 315},
   {131, 295},
   {157, 279},
   {183, 265},
   {209, 254},
   {235, 244},
   {261, 235},
   {287, 227},
   {313, 219},
   {339, 213},
   {365, 206},
   {391, 200},
   {417, 194},
   {443, 189},
   {469, 184},
   {495, 178},
   {521, 173},
   {547, 168},
   {573, 164},
   {599, 159},
   {625, 154},
   {651, 149},
   {677, 144},
   {703, 140},
   {729, 135},
   {755, 129},
   {781, 124},
   {807, 119},
   {833, 113},
   {859, 106},
   {885, 99},
   {911, 91},
   {937, 82},
   {963, 71},
   {989, 55},
   {1015, 22}
};
#endif
#endif
