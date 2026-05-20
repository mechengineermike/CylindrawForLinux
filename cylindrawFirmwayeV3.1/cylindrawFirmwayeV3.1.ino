/* PROGRAM DESCRIPTION & PINOUT FOR CUP CYCLONE CNC
  This is an Arduino Sketch for 2.5axis control of a Cylindrical CNC Plotter.
  Enables movement via custom gcode sent via USB Serial by a windows PC running a specific processing program.
  ***Software Sharing License: Creative Commons Attribution-NonCommercial-NoDerivs (CC-BY-NC-ND) https://creativecommons.org/licenses/by-nc-nd/4.0/
	*"CylinDraw" By Graham Research LLC
	*Copyright (C) 2021 Graham Research LLC
	*All Rights Reserved.
  //Arduino Nano Pinout:
  // (T axis = X axis on board has ALL jumpers present = 1/16 step
  // (H axis = Y axis on board has center jumper removed = 1/8 step
  // (Z stepper is left open)
  // The Circuit
  //  A0 (abort)=
  //  A1 (hold)=
  //  A2 (resume)=
  //  A3(cool) =
  //  A4 (SDA)=
  //  A5 (SCL) =
  //  A6 servo1 = Servo Z axis (DOUT) ("servo#1 \")
  //  A7 servo2 = (also set this for redundant A^ in case of burnout?)
  //  D0 (RX) =
  //  D1 (TX) =
  //  D2 (stpr:Xstep)=
  //  D3~(stpr:Ystep)=
  //  D4 (stpr:Zstep)=
  //  D5~(stpr:Xdir) =
  //  D6~(stpr:Ydir)=
  //  D7 (stpr:Zdir)=
  //  D8 = Enable Steppers   //logic high = disable motors.
  //  D9~ (X+,X-) =
  //  D10~ (Y+,Y-)=   End Stop (DIGITAL INPUT)
  //  D11~(Z-,Z+) = Zer to servo out
  //  D12 =  Buzzer
  //  D13 = Arduino Embedded LED
*/
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//*DECLARATIONS & CONSTANTS*
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////{
#include <Servo.h>
#include <SpeedyStepper.h>

#define pinServoZ 11 // Digital Pin # of servo (Second servo slot in)
#define pinSwitchH 10 // Digital Pin # of end stop switch  (NORMALLY OPEN)
#define LINE_BUFFER_LENGTH 70 // number of characters per gcode line that can be read. 
#define pinDirX 5
#define pinStepX 2
#define pinDirY 6
#define pinStepY 3
#define pinEnable 8 //enables all motors
#define pinBuzzer 12 //#define LEDPIN 13 is covered up so dotn waste shit on it
#define motorInterfaceType 1 //meaning it has a driver

SpeedyStepper stepperT;
SpeedyStepper stepperH;
Servo servoZ;

struct point {
  float x;
  float y;
  float z;
}; //x correlates to the T axis & Y to the H axis. Gcode is generated on an XY plane
struct point currentPos; //default it high to prevent a wierdly timeed drop on startup

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////}
//*DEFINE DRAWING SETTINGS*
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////{
float CupHeight = 100.000; //mm,  between 80mm & 234mm per machine limitations
float CupDiaMin = 65.000; //mm, minimum of 40 per machine limitations
float CupDiaMax = 94.5000; //mm, maximum of 110 per machine limitations
float CupDiaMean = (CupDiaMin + CupDiaMax) / 2; //Estimate the mean cup dia

float stepMultiplyT = 16; //16 is 1/16th steps
float stepMultiplyH = 4; //4; //quarter =4, half steps =2. 1 = full steps. The reason for doing this is because he mechanical advantage on this axis is already adequate for resolution. If we keep all jumpers we lose speed because the processor cant push that many steps/sec

float MotorStepAngle = 1.800; //deg (200 steps per rotation)
float BeltPitch = 2.000; //mm, used GT2
float PulleyToothCount = 16.000;//Number of teeth on pulley
float GearRatio = 1.000;
float HStepPermm = stepMultiplyH * (360.000 / MotorStepAngle) / (BeltPitch * PulleyToothCount); // 6.25 step/mm for default HW configuration //float HMicroStepPermm = HStepPermm*16.000;  //100 for default HW configuration
//= stepMultiplyH * (360.000/1.8) / (2 * 16) = stepMultiplyH *6.25 = 100 step/mm (or .01 mm/step @ 1/16 step) 
																			 //  (or .02 mm/step @ 1/8 step...
																			 //  (or .04 mm/step @ 1/4 step...
																			 //  (or .08 mm/step @ 1/2 step... 

float TStepPermm = stepMultiplyT * 1.000 / ((3.14159265359 * CupDiaMean) * (MotorStepAngle / 360.000)) * GearRatio; //.637 step/mm at 100dia, 0.772 at 82.5dia////////float TStepm * 16.000; //=~10.191  microsteps/mm at 100mmdia, 12.35   >>>> You get MORE steps/mm when the cup dia is smaller! >>Also this 16 is a hard code  function of the motors
//= stepMultiplyT * 1.000 /(pi * 100mm * 1.8/360*1) = stepMultiplyT *0.63662 = 10.1859 step/mm = (or 0.09817 mm/step, @ 100mm cup dia)
									 //@50mm dia     stepMultiplyT * 1.273240 = 20.372 step/mm = (or 0.049087367 mm/step, @ 50mm cup dia)

 //We maximize microstep for T since its resolution is so limiting at the top end of our cup size
 //Then, since 50mm is pretty much the smallest cup size you would ever do, 0.049087367 mm/step is the best resolution this axis can get
 //So we want to get as much speed out of H axis as we can, without limiting our resolution. 04 mm/step @ 1/4 step  = ideal balance without limiting res.
									 									 
float Tresolution = (1.000 / TStepPermm); //.098 mm at Maxdia. (, (for microstep w/o gears =~.098mm, OR  length of smallest motion possible
float Hresolution = (1.000 / HStepPermm); //  .16 mm on full step
float Resolution = Hresolution * Tresolution; // Uses the least common multiple method to calculate segments that will be conducive for both axes.

float chuckLen = 9; //the unusable length
float Hmin = chuckLen;  //mm, minimum position mechanically reachable on the cup != 0.
float Hmax = CupHeight;
float Tmin = 0.000; //mm
float Tmax = (3.14159265359 * CupDiaMean); //mm. Calculated using PI*D. Note: >>>> You get MORE resolution when the cup dia is smaller!
int Zmin = 90;//110; //deg, Pen Engaged Position, servo angle used for drawing.
int Zmax = 0;//175; //deg, Lifted Pen Position, servo angle for jogging. Make sure pen NOT touching cup. (Not set to one eighty because dont want to overcenter horn & get it stuck!)
float Hpos = Hmin;   //Current REAL Position calculated from steps(mm!)
float Tpos =  3.14159265359 * CupDiaMax / 2; //Current T  Position (mm!). Default position set so drawing will start on top center
float TposHome = Tpos;
float Zpos = Zmax;   //Current Z Position in deg

boolean quietMode = false; //Sacrifice a bit of drawing quality to use a silent algorithm so you can draw at the office!
boolean verbose = false; //USED FOR INTERNAL TESTING. If 'true' then print positional feedback to arduino serial monitor, NOTE this prevents gcode reading!

boolean bMotorsOn = false;
boolean bServoOn = false;
boolean bHomeSet = false;

int EndStopState;// = digitalRead(pinSwitchH); //normally open switch = HIGH, TOUCHING = LOW


//YOU CAN UNKNOWINGLY MAX OUT THE CONTROLLER WITH HIGH SPEEDS
//MOTORS WILL TAKE TOO LONG TO PERFORM STEPS IF YOU MOVE TOO FAST! (Steps wont get lost but it shows up as a curved line!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 ///6,250 steps per second IS MAX for each motor because im using 2 at same time, (12,500 otherwise)
 //have XmaxSpeedMM mm/s, need step/sec,      XmaxSpeedMM* step/mm = step/sec maximum
//6250/100	 >>>> Max Speed in mm/s is **62.5** with stepMultiplyH = 16!!!!
//6250/25	 >>>> Max Speed in mm/s is **250** with stepMultiplyH = 4!!!! 
//6250/10.18 >>>> Max Speed in mm/s is **613.94** with stepMultiplyT = 16!!!!
   //Drawing resolution vs speed is a trade off based on the arduino clock speed. The knob we have control over is microstep-resolution, & to lesser extent the cup size.  
   //We want to enable fast speeds for jogging, but we also want to maximize drawing resolution. Since T axis is resolution limiter down to 40mm, might as well go with 1/4 step on H axis.
   //H axis quarter step enables the fast jog speeds for use on paper.
   //H axis is limiting for large cups, T axis is speed limiting for cup diameters < 40mm  (so never)
   
float maxStepRate = 6000; //max steps/sec per motor arduino is capable of. Rounding down from 6250 as a safey factor
//Separate variables used so we never attempt to go faster than machine is capable of
float fMaxSpeedMM = min(maxStepRate/(stepMultiplyH *6.25),maxStepRate/(stepMultiplyT *0.63662) ) ;    //1000; // Speed when Lifted (mm/sec) (use min() bc want both motors to move same speed)
float fMaxAccelMM = fMaxSpeedMM*5;//*5 =accelerate/decelerate to top speed over 0.2 sec     //1000; //Acceleration when lifted ( mm/sec/sec )

float fTargetSpeedMMDraw =25; //Speed when drawing, mm/sec    
float fTargetAccelMMDraw =fTargetSpeedMMDraw*5;//*5 =accelerate/decelerate to drawing speed over 0.2 sec  //500; // Acceleration when drawing,  mm/sec/sec
float fTargetSpeedMMJog =fMaxSpeedMM;
float fTargetAccelMMJog =fMaxAccelMM;



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////}
//*SETUP*
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////{
void setup() {
  Serial.begin(38400);//released 40000);9600 baud is unhelpful for monitoring because arduino IDE gets in the way of processing IDE
  Serial.println(" ");//the initial line sent is usually lost in noise
  Serial.println("~Machine Connected! FW Revision = V3.1 ");

  pinMode(pinEnable, OUTPUT);
  pinMode(pinBuzzer, OUTPUT);
  pinMode(pinSwitchH, INPUT_PULLUP);

  stepperT.connectToPins(pinStepX, pinDirX);
  stepperH.connectToPins(pinStepY, pinDirY);
  stepperT.setStepsPerRevolution(200*stepMultiplyT);
  stepperH.setStepsPerRevolution(200*stepMultiplyH);
  digitalWrite(pinEnable, HIGH); //low = motors enabled
  BuzzBegin();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////}
//* Main loop*
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////{

void loop() {
  
  char line[ LINE_BUFFER_LENGTH ]; //Array size of character
  char c;
  int lineIndex;
  bool lineIsComment, lineIsSemiColon;
  bool commandFound; // has a command been found
  String sResponce;
  lineIndex = 0;
  lineIsSemiColon = false;
  lineIsComment = false;
  commandFound = false;

  while (true) {
    
    while ( Serial.available() > 0 ) {
      c = Serial.peek();
      
      if ( c == '\n'  && commandFound ) { // check if the next character starts a new command
        c = '#'; // insert a end of line character and skip reading the serial buffer to end the command
      } else {
        c = Serial.read();
        sResponce = sResponce + String(c);
      }

      switch (c) {
        
        case '#':
          if ( lineIndex > 0 && commandFound ) {         // Line or command is finished. Then execute!
            line[ lineIndex ] = '\0';                   // Terminate string
            processIncomingLine( line);//, lineIndex ); //move commands are completed in this function.
            lineIndex = 0;
            commandFound = false; // reset the command found flag to false
            lineIsComment = false;
            lineIsSemiColon = false;
          } else { // Empty or comment line. Reset everything & move to next line. To get here you reached the end of a line without finding a command.
            line[ lineIndex ] = '\0';                   // Terminate string
            lineIndex = 0;
            commandFound = false; // reset the command found flag to false
            lineIsComment = false;
            lineIsSemiColon = false;
          }

          sResponce = "@" + sResponce + ";";//" " + currentPos.x +" " +currentPos.y +
          Serial.print(sResponce);// THIS IS CRITICAL FEEDBACK SENT TO PROCESSING
          sResponce = "";

          break;
        case ';':
          lineIsSemiColon = true;
          break;
        case '(':
          lineIsComment = true;
          break;
        case ')':
          lineIsComment = false;
          break;
        case ' ':  // Throw away white space and control characters
        case '/':
          break;
        case 'G':
          commandFound = true;

        default:
          //if ( (!lineIsComment) && (!lineIsSemiColon) ) {   // Only save if not comments
          //  if ( c >= 'a' && c <= 'z' ) {        // Upcase lowercase characters
          //    line[ lineIndex++ ] = c-'a'+'A';
          //  } else {
          line[ lineIndex++ ] = c;
          // }
          //}
          break;
      }
    }
  }
}//end of main loop

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////}
//*Function Definitions*
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////{

void penUp() {   //  Raises pen
  currentPos.z = 10;//set first to fix wierd thing

  if (bServoOn == false) {    enableServo();  }

  if (Zpos != Zmax) {
    for (int i = 0; i < (abs(Zmax - Zmin)); i++ ) { //lift pen slowly so its makes less sound
      servoZ.write(Zmin - i); delay(3); //delay(4);  //experimentally determined to be fast but not instant..
    }
    servoZ.write(Zmax);
  } else {
    servoZ.write(Zmax);
  }
  Zpos = Zmax;  currentPos.z = 10; //Note zmin is ~90, zmax is ~0
}

void penDown() {// Gradually Lowers pen.   //moving from zMax (5) to Zmin=90
  if (bServoOn == false) {
    enableServo();
  }

  if (Zpos != Zmin) {
    for (int i = 0; i < (abs(Zmax - Zmin)); i++ ) { //drop pen slowly so it doesn't bounce
      servoZ.write(Zmax + i); delay(8);//slower than lift so we dont bounce //was 10 but if pen too close to cup it will have extended duration contact. Bleed if paper. Also dont want to bounce heavy stuff....
    }
  } else {
    servoZ.write(Zmin);
  }
  servoZ.write(Zmin); Zpos = Zmin;   currentPos.z = 0;
}

void enableServo() {
  servoZ.attach( pinServoZ );
  bServoOn = true;
}
void killServo() {
  servoZ.detach();
  bServoOn = false;
}
void killMotors() {
  digitalWrite(pinEnable, HIGH); //low = motors enabled
  bMotorsOn = false;
}

void enableMotors() {
  digitalWrite(pinEnable, LOW); //low = motors enabled
  bMotorsOn = true;
}


void moveTo(float T2, float H2) { //Input variables are in mm. Moves are all absolute
  //Position notations: Original = '0', Current = 'pos', Ultimate Target = 't', Intermediate target = '1', Input parameters = '2'
  float T0 = Tpos;//Tholder; //original position = current position in mm
  float H0 = Hpos;//Hholder; //Was Hpos orginally
  float Tt = T2;   //Ultimate Target Positions
  float Ht = H2;
  if (Ht > Hmax) { Ht = Hmax;} //  Try to bring instructions within limits.
  if (Ht == 0 ) {return; } //if its zero then it was likely a persistant communication bug, skip trying to move this time and hope that point wasnt important! 
  if (Ht < Hmin) { Ht = Hmin; } //try to prevent crash...
  
  float stepsTideal = ( (Tt - T0) * TStepPermm); //ideal steps is fractional
  float stepsTrounded = round( (Tt - T0) * TStepPermm);//mm * steps/mm (this includes the step Multiplier)
  
  float stepsHideal = ( (Ht - H0) * HStepPermm);
  float stepsHrounded = round( (Ht - H0) * HStepPermm);//mm * steps/mm (this includes the step Multiplier)

  //Troubleshoointg 
  // Serial.print("~Drawing Line from: "); Serial.print(T0,2); Serial.print(",");Serial.print(H0,2);Serial.print(" to ");Serial.print(Tt,2); Serial.print(",");Serial.println(Ht,2);
  //Serial.print("~stepsTrounded: "); Serial.print(stepsTrounded,2); Serial.print("     "); Serial.print("stepsHrounded");Serial.println(stepsHrounded,2);

  moveSteps(stepsTrounded, stepsHrounded);
  Tpos = Tt - ((stepsTideal -stepsTrounded) /TStepPermm);
  Hpos = Ht - ((stepsHideal -stepsHrounded) /HStepPermm);
  
 // Tpos = Tt;//stepsTrounded /TStepPermm +T0; //This calculate stha achieved target position with tthe rpunding considered. Now the real position is known and we are to the nearest step of the target.
  //Hpos = Ht;//stepsHrounded /HStepPermm +H0; //This calculate stha achieved target position with tthe rpunding considered. Now the real position is known and we are to the nearest step of the target.
  
  //Tpos = (stepsTrounded / TStepPermm - T0); //steps / (steps/mm) = mm actually moved
  //this failed Tpos = (stepsTrounded / TStepPermm ); //steps / (steps/mm) = mm actuall moved
  //this failed >Hpos = stepsHrounded / HStepPermm; //know that your actual position is not your ideal one for next move.
}

void goHome() {
  if (!bHomeSet) {
    //BuzzLoud;
    home();
  } else {
    enableMotors(); penUp();
    moveTo(TposHome, chuckLen);
    if (quietMode == false) {
      Buzz();
    }
  }
}

void home() { //sets home  Sends printer to home position without drawing on anything. Note: this function DEFINES the H position, but NOT the T position
  bHomeSet = true;
  penUp();
  enableMotors();
  int counter = 0;
  
  TposHome = Tpos =  3.14159265359 * CupDiaMax / 2; //assume you are centered on the cup
  
   while (true) {  //Procedure to touch H axis against endstop
    EndStopState = digitalRead(pinSwitchH);//normally = HIGH, switch is NO. TOUCHING = LOW
    if (EndStopState == LOW && counter < 1) {  //if its already touching the end stop then move away a bit ONCE
      moveSteps(0 * stepMultiplyT, 30 * stepMultiplyH);
      counter = counter + 1;
    }
    
    moveSteps(0 * stepMultiplyT, -1 * stepMultiplyH); // move slowly toward endstop

    EndStopState = digitalRead(pinSwitchH);//normally = HIGH, switch is NO.TOUCHINGd = LOW
    if (EndStopState == LOW && counter > 0) {
      Hpos = chuckLen; //This is physically set by the length of the chuck grip.
      break;
    }
  } 

  // stepperT.move(1*stepMultiplyT);
  // stepperT.runToPosition();
  // stepperT.move(-1*stepMultiplyT);
  // stepperT.runToPosition();
  //MotorT->step(1, FORWARD, MICROSTEP); //rotate a little to ensure this motor is active & holding position
  //MotorT->step(1, BACKWARD, MICROSTEP);

  if (quietMode == true) {
    //Buzz();
  } else {
    BuzzComplete();
  }
}//end of home

float lineDist(float x0, float y0, float x1, float y1) {   //Determine direct distance between two points in mm
  return ((float) pow(pow(x1 - x0, 2) + pow(y1 - y0, 2), 0.5));
}

void drawRectSpiral(float x0, float y0, float x1, float y1, float dec) {  //  Draw a rectangular spiral using two points & a spiral spacing distance
  for (int b = 0; ((x1 - x0) / 2 > dec * b) && ((y1 - y0) / 2 > dec * b); b++) {
    drawRect(x0 + dec * b, y0 + dec * b, x1 - dec * b, y1 - dec * b);
    delay(300);
  }
}

//  Draw a rectangle using two points
void drawRect(float x0, float y0, float x1, float y1) { //inputs are in mm
  penUp();
  moveTo(x0, y0);
  penDown();
  moveTo(x1, y0); //delay(1000);
  moveTo(x1, y1); //delay(1000);
  moveTo(x0, y1); //delay(1000);
  moveTo(x0, y0); //delay(1000);
  penUp();
}

void Buzz() { //Increasing the duration of the buzz changes the volume drastically. Set delay to 80+ms for a loud beep!
  digitalWrite(pinBuzzer, HIGH);
  delay(7);
  digitalWrite(pinBuzzer, LOW);
}

void BuzzLong() {  //Increasing the duration of the buzz changes the volume drastically. Set delay to 80+ms for a loud beep!
  digitalWrite(pinBuzzer, HIGH);
  delay(50);
  digitalWrite(pinBuzzer, LOW);
}

void BuzzLoud() {  //Increasing the duration of the buzz changes the volume drastically. Set delay to 80+ms for a loud beep!
  digitalWrite(pinBuzzer, HIGH);
  delay(111);
  digitalWrite(pinBuzzer, LOW);
}

void BuzzBegin() { //A beep/pause/beep function
  if (quietMode == true) {
    Buzz();
  } else {
    delay (195);
    Buzz();
    delay (195);
    Buzz();
    delay (195);
    BuzzLong();
    //delay (50);
    // Buzz();
  }
}

void BuzzNotif() {
  BuzzLong();
  delay (295);
  BuzzLoud();
  delay (295);
  BuzzLong();
}

void BuzzComplete() {
  if (quietMode == true) {
    Buzz();
  } else {
    BuzzLoud();
    delay (295);
    BuzzLong();
    delay (295);
    BuzzLoud();
  }
}


//COMMANDS LIST
void processIncomingLine( char* line) {// line = Line to process,  charNB = Number of characters
  char* indexG;//command starter for all commands
  char* indexX;
  char* indexY;
  char* indexZ;
  char* indexS;  //speed prompt
  char* indexH;  //H = cup height
  char* indexB;  //B = base Cup diameter
  char* indexD;  //D = Major cup Diameter

  char buffer[ LINE_BUFFER_LENGTH ]; // Hope that LINE_BUFFER_LENGTH is long enough for max # of input parameters
  struct point newPos;
  int iCmd = 1000;
  newPos = currentPos; // Set new position to current motor position, individual values are reused if new ones not listed in command!

  int centerX = (Tmin + Tmax) / 2;
  int centerY = (Hmin + Hmax) / 2;
  int cntr = 0;
  int i=0;
  indexG = strchr( line, 'G' );  // Get XYZ position in the string (if any)
  if ( indexG != NULL ) { // Find new current position and direction of motion if available
    iCmd = atoi( indexG + 1); // get value from the line char array as an integer

    switch ( iCmd ) {               // Select G command
	  case 1000: //G1000 
	    Serial.println("@COMMAND ERR... CONTINUE ONWARD;");
        break;
      case 0: 
        home(); //G0 = SET home (not just go home)
        break;
      case 1: //G1 positioning command
        indexX = strchr( line, 'X' );  // Get XYZ position in the string (if any)
        indexY = strchr( line, 'Y' );
        indexZ = strchr( line, 'Z' );
        if ( indexX != NULL ) { // Find new current position and direction of motion if available
          if (atof( indexX + 1) > 0.0001) {  //Prevent accidental misread or rounded real error from sending to zero on a misread
            newPos.x = atof( indexX + 1); // get value from the line char array as a float
          }
        }
        if ( indexY != NULL ) {
          if (atof( indexY + 1) > 0.0001) {
            newPos.y = atof( indexY + 1);  // get value from the line char array as a float. The +1 is because the array starts at zero
          }
        }
        if ( indexY != NULL && indexX != NULL) { //currentPos.x!=newPos.x || currentPos.y!=newPos.y
          if (newPos.y > 0.0001 && newPos.x > 0.0001) {
            moveTo(newPos.x, newPos.y );   //MOVE TO XY POSITION BEFORE Z
			
          }
        }
        if ( indexZ != NULL ) {
          newPos.z = atoi( indexZ + 1);  // get value from the line char array as an int
          if ( newPos.z == 0) { // < currentPos.z ){  //very simple check means Z control is binary.  ?Switch form < to !=?
            penDown(); //newPos.z = 0;
          }
          if ( newPos.z == 10) { //> currentPos.z ){  //very simple check means Z control is binary.  ?Switch form < to !=?
            penUp();// newPos.z = 10;;
          }     //else{ penUp();  } //newPos.z = Zmax;
        } currentPos = newPos;
        break;
      case 2: //G2 Audio Notification Only
        if (quietMode == true) {
          Buzz();
        } else {
          BuzzNotif();
        }
        break;
      case 3: //G3 goHome();// GO HOME ( but do not set curr pos as home)
        goHome();
        break;
      case 4: //G4 QUIET MODE
        quietMode = true;
        Buzz();
        break;
      case 5: //G5 Normal(LOUD) MODE
        quietMode = false;
        BuzzNotif();
        break;
      case 6: //G6 roll untracked X axis forwards, (cup rolls away from you = positive)
        if (bServoOn == false) {          penUp();        }
        if (bMotorsOn == false) {          enableMotors();        }

        moveSteps(200 * stepMultiplyT, 0 * stepMultiplyH);
        break;
      case 7://G7 roll untracked X axis backwards (Cup rolls towards you)
        if (bServoOn == false) {          penUp();        }
        if (bMotorsOn == false) {          enableMotors();        }
        moveSteps(-200 * stepMultiplyT, 0 * stepMultiplyH);

        break;
      case 8: //G8 roll untracked Y axis forwards (moves UP CUP)
        if (bServoOn == false) {
          penUp();
        }
        if (bMotorsOn == false) {
          enableMotors();
        }
        moveSteps(0 * stepMultiplyT, 10 * stepMultiplyH);

        break;
      case 9://G9 roll untracked Y axis backwards (moves DOWN cup)
        if (bServoOn == false) {
          penUp();
        }
        if (bMotorsOn == false) {
          enableMotors();
        }
        moveSteps(0 * stepMultiplyT, -10 * stepMultiplyH);

        break;
      case 11: //G11 TEST1:#1 verify basic function of pen up & down positions
        enableMotors();  penUp();
        for (cntr = 0; cntr < 5; cntr++) {
          penUp();
          delay(500);
          penDown();
          delay(500);
        }
        penUp();
        BuzzComplete();
        Serial.print("Test 1 finished");
        break;
      case 12: //G12 TEST2: #2 verify that the motors move in the correct directions. Motor H Should move UP in H, & Motor T should draw right in T (cup roll AWAY from you!)
        enableMotors(); penUp();
        for ( i = 0; i < 3; i++) {
          moveSteps(20 * stepMultiplyT, 20 * stepMultiplyH);
        }
        BuzzComplete();
        Serial.print("Test 2 finished");
        break;
        //need to come up with a safer homing algorithm for G3, like ...
      case 13: //G13 TEST#3 verify that homing switch responds
        for ( i = 0; i < 10000; i++) {//10,000 -> 10 seconds
          delay(1);
          EndStopState = digitalRead(pinSwitchH);//normal = HIGH, switch is NOpen. TOUCHING = LOW
          if (EndStopState == LOW) { Buzz(); }
        }
        Serial.print("Test 3 finished");
        break;
        
        //need to come up with a safer homing algorithm for G3, like ...
        
      case 14: //G14 TEST4: #4 verify repeatability of min & max extent positions.
        enableMotors(); penUp();
        for ( i = 0; i < 2; i++ ) {
          home();
          moveTo(Tmin, Hmin + 5);
          penDown();
          penUp();
          moveTo(Tmax, Hmax);
          penDown();
          penUp();
          moveTo(Tmin, Hmin + 5);
          penDown();
        } home();
        BuzzComplete();
        Serial.print("Test 4 finished");
        break;
      case 15: // G15 TEST5 #5 draw a nested calibration test square to check looseness
        enableMotors();  penUp();
        home();
		
		CupHeight = 85; //hard coded dimensions of 12 oz paper cup, something to start with
        CupDiaMin = 56;
		CupDiaMax = 75;
        CupDiaMean = (CupDiaMin + CupDiaMax) / 2; //Estimate the mean cup dia
        TStepPermm = stepMultiplyT * 1.000 / ((3.14159265359 * CupDiaMean) * (MotorStepAngle / 360.000)) * GearRatio; //.637 step/mm @ 100dia, 0.772 @ 82.5dia ///// * 16.000; //=~10.191  microsteps/mm @100mmdia, 12.35   >>>> You get MORE steps/mm when the cup dia is smaller!
        Tresolution = (1.000 / TStepPermm); //.098 mm @ Maxdia. (, (for microstep w/o gears =~.098mm, OR  length of smallest motion possible
        Resolution = Hresolution * Tresolution; // Uses the least common multiple method to calculate segments that will be conducive for both axes.
        Hmax = CupHeight; //if (CupHeight > 234){Hmax = 234;}  //Define Max H axis limit. 230mm is a machine limitation
        Tmax = (3.14159265359 * CupDiaMean); //mm. Calculated using PI*D. Note: >>>> You get MORE res when the cup dia is smaller (counterintuitively)!
        TposHome = Tpos =  3.14159265359 * CupDiaMax / 2; //(Tmin+Tmax)/2;   //Current T  Position (mm!) /default position set so drawing will start on top center
        
        //Serial.print("~Taxis StepPermm is: ");
        //Serial.print(TStepPermm,1);
        //Serial.print(", Haxis StepPermm is: ");
        //Serial.println(HStepPermm,1)
	
        drawRectSpiral(Tpos, Hmin + 10, Tpos + 50, Hmin + 60, 5);  home(); //
        Serial.print("Test 5 finished");
		Serial.print("~(RECALIBRATED STEPS FOR 12 OZ PAPER CUP)");
        break;
       
      case 20:  //G20 Rotate 180 deg untracked
        enableMotors(); penUp();
        moveSteps(-100 * stepMultiplyT, 0 * stepMultiplyH); //moveSteps is untracked
        break;
      case 21: // G21 Import Cup dimensions
        indexH = strchr( line, 'H' );  // H = cup height
        indexB = strchr( line, 'B' );  //B = base Cup diameter
        indexD = strchr( line, 'D' );  //D = Major cup Diameter
        if ( indexH != NULL ) { // Find new current position and direction of motion if available
          CupHeight = atof( indexH + 1); // get value from the line char array as a float
          if (CupHeight > 234) {
            CupHeight = 234; //Define Max H axis limit. 230mm is a machine limitation
          }
        }
        if ( indexB != NULL ) { // Find new current position and direction of motion if available
          CupDiaMin = atof( indexB + 1); // get value from the line char array as a float
        }
        if ( indexD != NULL ) { // Find new current position and direction of motion if available
          CupDiaMax = atof( indexD + 1); // get value from the line char array as a float
        }
        CupDiaMean = (CupDiaMin + CupDiaMax) / 2; //Estimate the mean cup dia
        TStepPermm = stepMultiplyT * 1.000 / ((3.14159265359 * CupDiaMean) * (MotorStepAngle / 360.000)) * GearRatio; //.637 step/mm at 100dia, 0.772 at 82.5dia ///// /=~10.191  microsteps/mm at 100mmdia, 12.35   >>>> You get MORE steps/mm when the cup dia is smaller!
        Tresolution = (1.000 / TStepPermm); //.098 mm/step at Maxdia. (, (for microstep w/o gears =~.098mm, OR  length of smallest motion possible
        Resolution = Hresolution * Tresolution; // Uses the least common multiple method to calculate segments that will be conducive for both axes.
        Hmax = CupHeight; //if (CupHeight > 234){Hmax = 234;}  //Define Max H axis limit. 230mm is a machine limitation
        Tmax = (3.14159265359 * CupDiaMean); //mm. Calculated using PI*D. Note: >>>> You get MORE resolution when the cup dia is smaller!
        TposHome = Tpos =  3.14159265359 * CupDiaMax / 2; //(Tmin+Tmax)/2;   //Current T  Position (mm!) /default position set so drawing will start on top center

        Serial.print("~Taxis StepPermm is: ");
        Serial.print(TStepPermm,1);
        Serial.print(", Haxis StepPermm is: ");
        Serial.print(HStepPermm,1);
		Serial.println(" ");
        break;
      case 50: //G50  Drawing speed.  Command looks like this:  "G50 S95.0 \n";where S indicates the drawing speed of 95
        indexS = strchr( line, 'S' );
        if ( indexS != NULL ) { // Find new current position and direction of motion if available         
          fTargetSpeedMMDraw = atof( indexS + 1);//program passes in speed in mm/s
		  
		  if (fTargetSpeedMMDraw > fMaxSpeedMM){ //cap it!
			  fTargetSpeedMMDraw = fMaxSpeedMM;//
		  }
		  if (fTargetSpeedMMDraw <=0 ){
			  fTargetSpeedMMDraw =1;
		  }
		  		 
          Serial.print("~Speed is: ");
          Serial.print( fTargetSpeedMMDraw);
          Serial.println(" mm/sec");//, or ");
        }
        break;
      case 51: //G51 Drawing acceleration. Command looks like this:  "G50 S95.0 \n";where S indicates the drawing accel of 95
        indexS = strchr( line, 'A' );
        if ( indexS != NULL ) { // Find new current position and direction of motion if available
          fTargetAccelMMDraw = atof( indexS + 1);
		  
		  if (fTargetAccelMMDraw > fMaxAccelMM){ //cap it!
			  fTargetAccelMMDraw = fMaxAccelMM;//
		  }
		  if (fTargetAccelMMDraw <=0 ){
			  fTargetAccelMMDraw =1;
		  }
		          
          Serial.print("~Acceleration is: ");
          Serial.print( fTargetAccelMMDraw);
          Serial.println(" mm/sec/sec");
        }
        break;
      case 60: //G60 Command looks like this: JOG SPEED   "G50 S95.0 \n";where S indicates the jog speed of 95
        indexS = strchr( line, 'S' );
        if ( indexS != NULL ) { // Find new current position and direction of motion if available
          fTargetSpeedMMJog = atof( indexS + 1);
		  
		  if (fTargetSpeedMMJog > fMaxSpeedMM){ //cap it!
			  fTargetSpeedMMJog = fMaxSpeedMM;//
		  }
		  if (fTargetSpeedMMJog <=0 ){
			  fTargetSpeedMMJog =1;
		  }
		  
          Serial.print("~Travel Speed is: ");
          Serial.print( fTargetSpeedMMJog);
          Serial.println(" mm/sec");
        }
        break;
      case 61: //G61  Jog Acceleration. Command looks like this:  "G50 A95.0 \n";where S indicates the jog accel of 95
        indexS = strchr( line, 'A' );
        if ( indexS != NULL ) { // Find new current position and direction of motion if available
          fTargetAccelMMJog = atof( indexS + 1);
        
		  if (fTargetAccelMMJog > fMaxAccelMM){ //cap it!
			  fTargetAccelMMJog = fMaxAccelMM;//
		  }
		  if (fTargetAccelMMJog <=0 ){
			  fTargetAccelMMJog =1;
		  }
		  
          Serial.print("~Travel Acceleration is: ");
          Serial.print( fTargetAccelMMJog);
          Serial.println(" mm/sec/sec");
        }
        break;
        
      case 99: //G99 IMMEDIATELY KILL ALL MOTION
        penUp();
        killServo();
        killMotors();
        break;
        
      case 100: //G100 Complete Job = GoHome (no kill)
        goHome();//moveTo(3.14*CupDiaMean/2,0);
        killServo();
        if (quietMode == true) {
          Buzz();
        } else {
          BuzzComplete();
        }
        break;
        
      default:
        Serial.println("@MISSED A COMMAND... CONTINUE ONWARD;");
        break;
    }
  }

}//end of processIncomingL



// move both X & Y motors together in a coordinated way, such that they each start and stop at the same time, even if one motor moves a greater distance
void moveSteps(float stepsX, float stepsY)//, float speedInStepsPerSecond, float accelerationInStepsPerSecondPerSecond)
{
  float speedInStepsPerSecond_X;
  float accelerationInStepsPerSecondPerSecond_X;
  float speedInStepsPerSecond_Y;
  float accelerationInStepsPerSecondPerSecond_Y;
  float absStepsX;
  float absStepsY;  
  
  if (Zpos == Zmax){ //JOG speed. HARD CODED for JOG
      speedInStepsPerSecond_X = fTargetSpeedMMJog * TStepPermm; 
      accelerationInStepsPerSecondPerSecond_X =fTargetAccelMMJog * TStepPermm;
    
      speedInStepsPerSecond_Y =fTargetSpeedMMJog * HStepPermm;
      accelerationInStepsPerSecondPerSecond_Y =fTargetAccelMMJog * HStepPermm;
  }else{ 
    // setup initial speed and acceleration values for DRAWING speeds
    speedInStepsPerSecond_X = fTargetSpeedMMDraw * TStepPermm;//
    accelerationInStepsPerSecondPerSecond_X = fTargetAccelMMDraw*TStepPermm ;
  
    speedInStepsPerSecond_Y =fTargetSpeedMMDraw * HStepPermm;//(mm/s * step/mm)//
    accelerationInStepsPerSecondPerSecond_Y = fTargetAccelMMDraw * HStepPermm ;//
  }
 
  //need to convert from steps into actual distance to get this scalar to work right because the axes have different resolutions
  float absDistX = abs((float)stepsX /(float)TStepPermm);// (steps / (steps/mm) = mm.    
  float absDistY = abs((float)stepsY /(float)HStepPermm);
  
  
  // determine which motor is traveling the farthest, then slow down the speed rates for the motor moving the shortest distance
  if ((absDistX > absDistY) && (stepsX != 0)){ // slow down the motor traveling less far
    float scaler = (float) absDistY / (float) absDistX;
    speedInStepsPerSecond_Y = speedInStepsPerSecond_Y * scaler;
    accelerationInStepsPerSecondPerSecond_Y = accelerationInStepsPerSecondPerSecond_Y * scaler;
  }

  if ((absDistY > absDistX) && (stepsY != 0)){  // slow down the motor traveling less far //in my example this needs to be slowed down MORE
    float scaler = (float) absDistX / (float) absDistY;
    speedInStepsPerSecond_X = speedInStepsPerSecond_X * scaler;
    accelerationInStepsPerSecondPerSecond_X = accelerationInStepsPerSecondPerSecond_X * scaler;
  }

  // setup the motion for the X motor
  stepperT.setSpeedInStepsPerSecond(speedInStepsPerSecond_X);
  stepperT.setAccelerationInStepsPerSecondPerSecond(accelerationInStepsPerSecondPerSecond_X);
  stepperT.setupRelativeMoveInSteps(stepsX);

  // setup the motion for the Y motor
  stepperH.setSpeedInStepsPerSecond(speedInStepsPerSecond_Y);
  stepperH.setAccelerationInStepsPerSecondPerSecond(accelerationInStepsPerSecondPerSecond_Y);
  stepperH.setupRelativeMoveInSteps(stepsY);

  // now execute the moves, looping until both motors have finished
  while ((!stepperT.motionComplete()) || (!stepperH.motionComplete()))
  {
    stepperT.processMovement();
    stepperH.processMovement();
  }
}
