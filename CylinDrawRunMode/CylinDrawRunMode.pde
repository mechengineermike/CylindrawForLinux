import javax.swing.*; //fopr the jtextfield

import java.awt.event.KeyEvent;
import processing.serial.*;
import java.io.*;
import controlP5.*;
import processing.svg.*;
import geomerative.*;
import processing.dxf.*;
import java.awt.Color;
import java.awt.Dimension;
import javax.swing.JFrame;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.lang.System;

import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import java.awt.BorderLayout;


String sVersion  =  "Version: 2.01 @ RunMode CylinDraw Control Suite";

ControlP5 gui;

boolean bPaid  = true;// has a license been found.
boolean bTerms  = true;// has the user agreed to the terms of use
String  sKey ="null"; //Key = XCg8_XA@RA=yyN4cW4FD
String  sEmail ="CylinDraw@gmail.com"; //Key = XCg8_XA@RA=yyN4cW4FD

Button buttonReset; 
Button buttonConnect;
Button buttonLoadJob; 
Button buttonKillJob;
//Toggle togglePlay;  Toggle toggleQuiet;
Button buttonPlay; 
Button buttonPause; 
Button buttonQuiet; 
Button buttonLoud;
Button buttonRoll;
Button buttonRollStop;

//Slider sliderSpeed;
//Slider sliderAccel;
Button buttonSpeed;
Button buttonRotate180;
Button buttonGoHome; 
Button buttonSetHome;
Button buttonJumpTo;

Button buttonSupport;
Button buttonProgCalibrate; 
Button buttonProgCreate; 
Button buttonProgConvert; 
Button buttonProgRun;
Button buttonHelp;
Button buttonExit;  
Button buttonPenUp; 
Button buttonPenDown;
Button buttonTester; //junk

Button buttonTest1;
Button buttonTest2;
Button buttonTest3;
Button buttonTest4;
Button buttonTest5;

int xWindow = 1200;
int yWindow = 900; 

Serial myPort = null;
String command;

RShape Rpreview;
PShape Ppreview;
PImage logoHeaderImg; //logo header image
PImage logoCalImg; //logo header image
float previewY=207.5;//yWindow/4.5;
float previewX=xWindow/2;
int fileSize =0; //size of input file in bytes. Used to prevent trying to load preview of enormous file.
boolean bFastPreview=false;//set to true to reduce laggy large files

int myPortIndex = 0; //Set for your desired port.
String portName = "/dev/ttyUSB0";//"No USB Device found yet...";// searching now...."; // select and modify the appropriate line for your operating system. Leave as null to use interactive port 
//String portName = Serial.list()[0]; // Mac OS X, //String portName = "/dev/ttyUSB0"; // Linux, //String portName = "COM6"; // Windows- specific port

String[] cmdQue  =new String[500];
int iCmdIndex  =0;
int iCmdMax  =0;

boolean bOKtoSend = true; //you are only allows to sned things if true (toggles with every to/from message!)
boolean bToolChange = false;
boolean bRun = false;//ovevrrides streaming
boolean bRolling = false;//if true roll forever
boolean bRollingForward = false;//Toggleing forward vs backward

boolean bFileLoaded = false;
boolean bConnected = false;
boolean bProvenConnection = false;
boolean bQuietMode = false; //if even = normal mode, if odd = quiet mode
boolean bPreviewLoaded = false;
//boolean bSliderLock = false;
boolean bdoneOnce  = false;//if true dont display thankyou
File storedFile;

float   Tposition = 148; 
float   Hposition = 0;
float   timeEstCore = 0;
float   timeEstMath = 0;
float   percentComplete = 0;
float   previewScale = 2;
int     dataCounter = 0;
int     iLine = 0; //The current line number where you are at in the gcode. Always start ay zero  //int z = 0; //line counter used only for displaying teh gcode
int     imessage  =0; //message number
boolean bPenUp  = true; //current pen state tracker, used for proper Pausing
boolean bPenWasUp = true;//track if pen was up priot to pausing so it doesn accidentally invert pen pos upon resume if paused whit pen was alreadu up! (start high so when you play it assumes it was and doesn try to resume a start where it wasnt 

int     initI =0;
int     iSpeed =20;//mm/sec   //OUT OF 1000for jog but really only use up to 300?
int     iAccel =iSpeed *5;//mm/sec/sec //OUT OF 1000 
int     iSpeedJog =240;//mm/sec   //OUT OF 1000for jog but really only use up to 300?
int     iAccelJog =iSpeedJog*4;//mm/sec/sec //OUT OF 1000

int     DisplayDataWindowY = 420;
int     prevRectWidth = 550; 

float timeCount= 0;
float timeElapsed =0;

int timerConnectHold =0;  

String[] gcode;
String   liveData = "";
String   filePath = "";
String   fileName = null;
String   fileNameOriginal = "none";
String   previewName = "";

boolean  bVerbose = true; //only for troubleshooting for me!
String   sLog = " ";//for writing troubleshooting notes

boolean  bManual = true;//auto vs manual usb connect
boolean  bCalibration = false;
boolean  bDumbNotif = false;
//////////////////////////////////////////////////////////////////////////

void isPortActive() {
  if (!bConnected) {
    bOKtoSend=true;
  };

  String[] ports = Serial.list();
  if (ports.length == 0) {
    if (bConnected && ! bDumbNotif) {
      // bManual = false;
      DisplayData("USB Connection Lost!!"); 
      portName = "USB DEVICE LOST! Check cable or click HELP & select 'manual usb connect'";   
      bConnected = false;  
      bDumbNotif = true;
      return;
    }  
    if (!bConnected && !bManual) {
      if (! bDumbNotif) {
        DisplayData("No USB Connection Detected. Automatically searching for CylinDraw...");
        bDumbNotif = true;
      }
      bConnected = false;  
      bRun = false;
      return;
    }
  }
  bDumbNotif = false;

  if (bConnected ) {//verify that it is still connected to same port
    //  bManual = false;
    for (int jj=0; jj<ports.length; jj++) {
      String[] m1 = match(portName, ports[jj]);
      if (m1 != null ) {
        return;
      }
    }
    DisplayData("USB Connection Lost!"); 
    bConnected = false; 
    bRun = false; 
    return;//getting here means no match!
  } else if (!bManual) { //try to connect   //
    //
    for (int jj=int(random(0, ports.length)); jj<ports.length; jj++) { //this part is important. For every serial device found we hold its portname and check if it connects at our unusual baud rate via openSerialPor. This should work on any platform...
      String result = Serial.list()[jj];
      if (result != null) {
        portName = result;

        if (bVerbose)DisplayData("Testing connection on port:  " + result);

        if ( openSerialPort()) {
          //DisplayData("USB Connection Found!");
          delay(3000);//let the arduino com initialize
          //myPort.write("\n");//clears initial buffer by making it reply and checkserial will parse it
          //
          sendSpeed();
          sendAccel();
          checkAny();
        }
        //bConnected = bProvenConnection;
        if (bConnected) {
          /*if (storedFile.exists()) {
           DisplayData("Loading last file used......");//(load instructions gcode?)
           fileSelected(storedFile);
           } else { 
           DisplayData("No local job file found to load..");
           }*/
          return;
        }//else{DisplayData("No responce on port: " + portName); }
      };
    }

    DisplayData("USB Connection Lost!!!"); 
    bConnected = false; 
    bRun = false; 
    return;//getting here means no match!
  }
}//isPortActiv


boolean openSerialPort() {
  try {   
    bProvenConnection= false;
    ///DisplayData("Testing usb connection... on "+portName); 
    if (portName == null) return false;
    if (myPort != null) { 
      myPort.stop(); 
      bConnected = false;
    }
    myPort = new Serial(this, portName, 40000); // 9600); //115200 76800 baud, 38400
    myPort.bufferUntil(';'); //calls serialEvnt when this character is found
    bConnected = true;
    /*
    delay(3000);//let the arduino com initialize, it takes ~3 seconds unfortunately & program must stop & wait for com!
     iCmdIndex = iCmdMax= 0;
     //queCmd("G7\n",false);
     delay(1000);//let the arduino com initialize, it takes ~3 seconds unfortunately & program must stop & wait for com!
     
     if (myPort.available() > 0) {
     int inByte = myPort.read();
     println(inByte);
     bConnected = true;
     }else{
     bConnected = false;
     }
     //bOKtoSend=true;
     //cmdQue = new String[500];
    /*
     int timeHold = millis();  
     int timeElapsed =0;
     // int timeCount =timeElapsed +(millis()-timeHold);//result is time in milliseconds
     if(bProvenConnection && bConnected){
     && timeElapsed<3000
     bProvenConnection
     timeElapsed = (millis()-timeHold);//result is time in milliseconds
     } */
    //queCmd("\n",true);

    //bConnected = checkAny();
    /*
    if (!bConnected){
     myPort.dispose(); 
     // myPort.stop(); 
     }else{
     
     }
     
     //if (bFileLoaded)buttonReset();
     sendAccel();
     sendSpeed();*/
    return bConnected ;
  }
  catch(RuntimeException e) {
    // myPort.clear(); 
    // myPort.stop();
    DisplayData("USB problem detected! You may have 2 CylinDraws or 2 seperate RunMode's open. Switched to Manual USB mode to be safe...");
    DisplayData("   If not then unplug & replug in your usb port.");
    bManual = true;
    return false;
  }
}


void selectSerialPort() { //Use selectSerialPor OR isPortActiv but not both (need a settings file2 and have this be an option)
  String result = (String) JOptionPane.showInputDialog(null, 
    "Select the USB port on your computer that CylinDraw is plugged into.\nIf nothing is shown here make sure it is connected to your computer.", // within port selection window
    "Select USB serial port", //Port selection Window title
    JOptionPane.QUESTION_MESSAGE, 
    null, 
    Serial.list(), 
    0);
  if (result != null) {
    portName = result;
    openSerialPort();
    if (openSerialPort()) {
      //bConnected = true;
      delay(3000);
      myPort.write("\n");//clears initial buffer by making it reply and checkserial will parse it
      checkAny();      
      if (bFileLoaded) { 
        fileSelected(storedFile);
      }
      //bSliderLock = false;
      sendAccel();
      sendSpeed();
      showHideButtons();
    }
    /*if (openSerialPort()) {
     //myPort.write("\n");//clears initial buffer by making it reply and checkserial will parse it
     queCmd("\n",true);
     bConnected = checkAny();
     if (bConnected){       
     } 
     } */
  } else {//  if (result == null) {
    DisplayData("Window was closed OR the user hit cancel OR the device USB was not connected...");
  }
  delay(500);
} //end of selectSerialPor


void settings() {
  size(displayWidth-50, displayHeight-50);//size(xWindow, yWindow); // cant use p2d beecause buttons ..../7may, changed from default to p2d to run faster
  // fullScreen(P3D);   surface.setResizable(true);  surface.setSize(xWindow, yWindow);
  noSmooth();
  logoHeaderImg = requestImage("system/logoRunMode.png");// loadImage("logo.png"); //Header Image
  logoCalImg = requestImage("system/logoCalibration.png");
}

void setup() {
  cursor(HAND);
  if (xWindow >displayWidth) {
    xWindow = displayWidth-50;
  }
  if (yWindow >displayHeight) {
    yWindow = displayHeight-50;
  }
  surface.setSize(xWindow, yWindow); //THIS CAN BE USED TO RESIZE THE WINDOW HERE by loading from a file
  surface.setLocation(displayWidth/2-width/2, displayHeight/2-height/2);  
  surface.setTitle("CylinDraw -RUN MODE-");//or surface. 

  RG.init(this); //must remain in setup!
  RG.ignoreStyles(false);
  RG.setPolygonizer(RG.UNIFORMSTEP);//RG.ADAPTATIVE);  //segmenterMethod - can be RG.ADAPTATIVE, RG.UNIFORMLENGTH or RG.UNIFORMSTEP. step is fastest for this program
  //RG.useFastClip = true; //i thinkthis makles it faster at the cost of accuracy

  logWrite(false);//clear previous log when opening program

  checkLicense("", "");
  setButtons();

  surface.setTitle("CylinDraw -RUN MODE-"); 


  String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
  newPath = newPath + "/system/temp.JOB.svg";   //.replace("CylinDrawJobCreator", "CylinDrawViewer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
  storedFile = new File(newPath);  

  if (storedFile.exists()) {
    DisplayData("Loading last file used......");//(load instructions gcode?)
    fileSelected(storedFile);
  } else {
    DisplayData("No local job file found to load..");
  }

  frameRate(60);
  surface.setResizable(true);
  surface.setResizable(true);
}//end of SETUP

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DRAW
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw() {


  if ((millis() - timerConnectHold)>5000) {
    timerConnectHold = millis();
    if (!bProvenConnection) { 
      DisplayData("No responce on port: " + portName); 
      bConnected=false;
    };
    isPortActive();
  }

  //if (millis() % 10 ==0) {  
  //   isPortActive();
  //}
  if (millis() % 2 ==0) {
    showHideButtons();
  }
  //if (millis() % 10 ==0) {  
  //  DisplayData(nf(currentTime(),14,0));
  //}


  textAlign(LEFT);
  background(160, 219, 232); //baby blue
  fill(0);
  stroke(0);

  int y = 25, dy = 25;  //y is how far DOWN from the top of the box that the works start. dy is the spacing
  imageMode(CENTER);
  float downscale = 2.2;  
  int imgpixelwidth = 2048;
  int imgpixelheight = 250;
  if (bCalibration) {
    image(logoCalImg, width/2, 40, imgpixelwidth/2/downscale, imgpixelheight/2/downscale);
  } else {
    image(logoHeaderImg, width/2, 40, imgpixelwidth/2/downscale, imgpixelheight/2/downscale);
  }

  textSize(20);  //////text("----Cup Cyclone Control Program!----", 12, y); y += dy;    //  text(characters, x coordinate, y  coordinate)
  y += dy;    
  //////line(0, y+dy, width, y);
  y += dy;
  y += 10.9*dy;
  //line(0, y, width, y);
  y += dy;//upper line
  if (bConnected && bProvenConnection) {
    text("USB Connection Status: Connected on port " + portName, 12, y);
  } else {
    text("USB Connection Status: Not Connected. " + portName, 12, y);
  }
  y += dy;     //  text(characters, x coordinate, y  coordinate)
  /*if (!bRun){
   if (bWasRunning){
   timeElapsed = timeCount;
   }
   }else{
   if (!bWasRunning){
   timeHold = millis();  
   }
   timeCount =timeElapsed +(millis()-timeHold);//result is time in milliseconds
   }
   bWasRunning = bRun; */
  //float calc= ((timeEstCore * (100/iSpeed  ) * (1000/(iAccel)) -(timeCount/1000/60))  *1.65/20/60);
  float calc= ((timeEstCore * (100/iSpeed + 100/iSpeedJog)/2 * (1000/iAccel + 1000/iAccelJog)/2 -(timeCount/1000/60))  *1.65/20/60);

  timeEstMath = calc - calc*percentComplete/100 ; 
  text("Job File Loaded: " + fileNameOriginal + ", " + nf(percentComplete, 2, 1)  + "% completed, ~"  + nf(timeEstMath, 0, 1)  + " minutes remain, @Line #: " + (iLine), 12, y); 
  //y += dy;
  //text("Total Estimated Job Time is: " , 12, y);   
  y += dy*.5;
  line(0, y, width, y);
  y += dy;
  dy = 15; 
  fill(255);
  rectMode(CORNERS); //interprets the first two parameters of rect() as the location of one corner, and the third and fourth parameters as the location of the opposite corner.
  DisplayDataWindowY = int(height-(y-dy-2)-30);  
  rect(5, y-dy-2, width-5, y+DisplayDataWindowY); //live system msg box window
  fill(0);

  text("--System Messages--", 20, y); 
  y += dy*.7;   //REDUCE TEXT SIZE & DY RIGHT HERE TO GET MORE COMMANDS VISIBLE ON SCREEN
  textSize(16);
  text(liveData, 12, y);
  textSize(20);


  fill(255);//white box for preview
  
  rectMode(CENTER); 
  rect(width/2, 70+prevRectWidth/4, prevRectWidth, prevRectWidth/2); //Aspect ratio =2 as estimate. wide rect. //second two dimensions are the rectangle size

  textAlign(CENTER);
  if (gcode == null) { 
    text("(No job loaded. Load '.JOB.svg' file for preview.)", width/2, 200);
  }

  if (bPreviewLoaded == true) {  //This will rescale the preview
    float h = Rpreview.getHeight();
    float w = Rpreview.getWidth();

    if (  h >550/2) {//||  w > 550 //SHRINK IT
      text("(Loading job preview now! (scaling the preview...)", width/2, 200);
      previewScale = previewScale*.85;
      //if (bVerbose)print(previewScale);
      loadPreview();
    } else if (  h <400/2) {//||w < 400   //GROW IT
      text("(Loading job preview now! (scaling the preview...)", width/2, 200);
      previewScale = previewScale*1.15;
      //if (bVerbose)print(previewScale);
      loadPreview();
    } else {   //  */
      Rpreview.draw();
    }
  }
  fill(0);   

  if (bFileLoaded ==true && bPreviewLoaded == false) {  
    if (bFastPreview){
       text("(Job too big to load preview here. Proceed as normal.)", width/2, 200);
       text("(You can still click here to view preview in Viewer.)", width/2, 225);
    }else{ text("(No Job Preview.)", width/2, 200);}
  } //this was a loading message but if you load a regular svg it stays there..

  if (xWindow != width) {   // if  surface.setSize(xWindow, yWindow);
    xWindow = width;
    //bSliderLock = true;
    setButtons();
    // bSliderLock = false;
  } else if (yWindow != height) {
    yWindow = height;
    //bSliderLock = true;
    setButtons();
    //bSliderLock = false;
  }
} //end of DRAW



void DisplayData(String in) { //Used to show serial data within the user application window
  //imessage = imessage +1;// println(imessage +" Displayed Data: " + in); // THIS IS ONLY USEFUL FOR DISPLAYING IN PROCSSINGS COMMAND WINDOW BELOW< NOT USEFUL FOR THE PROGRAM
  int lineLimit = int(DisplayDataWindowY/26.5);
  String[] newlines = match(in, "\n");
  if (newlines != null) {    
    dataCounter += newlines.length;
  }


  if (bVerbose) {
    if (bPaid) { 
      liveData = liveData + "\n"  + in;
    } //+ imessage +" "
    else {
      liveData = liveData + "\n" + "Viewing gcode is ony available with a full license.\n ";
      bVerbose = false;
    }
  } else { 
    liveData = liveData + "\n" + in;
  }

  logHold(in+"\n");

  dataCounter++; //Lines of displayable data
  if (dataCounter>=lineLimit) { 
    liveData = "\n" + in;
    //if(bPaid && bVerbose){
    //  liveData = "\n" + imessage + in; 
    //}else{
    //  liveData = "\n" + in;
    //}
    dataCounter = 0;
  }
}

void keyPressed() { //Keyboard Commands
  if (key == ESC) { 
    key = 0; 
    buttonExit();
  }
  /*
   if (keyCode != UP && keyCode != DOWN && keyCode != LEFT && keyCode != RIGHT){ DisplayData( "You clicked the " + key + " key. " );}
   if (key == 'c' || key == 'C') {selectSerialPort();}
   if (key == 'e' || key == 'E') {
   liveData = "";
   dataCounter =0;
   DisplayData("List of Keyboard Commands: ");
   DisplayData("  'H' key = Home all axes ");
   DisplayData("  'U' key = Lift Tool Up ");
   DisplayData("  'D' key = Drop Tool Down ");
   DisplayData("  'Q' key = Toggle Quiet Mode ");
   DisplayData("  'K' key = Kill Motors/Job ");
   DisplayData("  'P' key = Play/Pause Toggle ");
   DisplayData("  'C' key = Connect to Machine ");
   DisplayData("  'L' key = Load Job File ");
   DisplayData("  Arrow keys = manually move the carriage. Left/right = T axis (homing first is usually a good idea)");  
   }
   if (bConnected){
   if (!bRun) {
   if (keyCode == UP){ Tposition=Tposition+1.1 ; myPort.write("G1 X" + Tposition + " Y" + Hposition + " \n"); } //for some reason 2 is the min resolution on this axis.
   if (keyCode == DOWN){  if (Tposition >0){Tposition=Tposition-1.1 ; myPort.write("G1 X" + Tposition + " Y" + Hposition +  " \n");}}
   if (keyCode == RIGHT){ if (Hposition < 230 ){Hposition++; myPort.write("G1 X" + Tposition + " Y" + Hposition + " \n");}} //~234 is per machine limitations
   if (keyCode == LEFT){ if (Hposition >0){Hposition--; myPort.write("G1 X" + Tposition + " Y" + Hposition + " \n");}}
   if (key == 'u' || key == 'U'){ buttonPenUp();}
   //if (keyCode == KeyEvent.VK_PAGE_DOWN) {} 
   if (key == 'd' || key == 'D'){ buttonPenDown();}
   if (key == 'h' || key == 'H') { buttonGoHome(); }
   if (key == 'l' || key == 'L') {  buttonLoadJob(); }
   }//end of not-B Streaming requirement
   if (key == 'q' || key == 'Q') { toggleQuiet();}
   if (key == 'k' || key == 'K' ){ buttonKillJob(); }
   if (key == 'p' || key == 'P' ){ togglePlay();}
   }//end of 'bConnected requirement'
   */
}//end of keyPressed()



void fileSelected(File selection) { //LOAD THE CODE FROM A FILE
 
  if (selection == null) {
    //buttonReset();
    DisplayData("Window was closed or the user hit cancel. ");//Had to reset currently loaded job.

    // fileNameOriginal="none";
  } else {
     
      bPreviewLoaded = false;
      gcode = null;
      iLine = initI; 
      percentComplete=0;
      
    //storedFile = selection;
    if (bConnected) {
      //bSliderLock = false; 
      showHideButtons();
    }
    DisplayData("Loading file: " + selection.getAbsolutePath()); //display the user selected file path
    delay(50); //this delay before the next line ensures no signals get confused
    filePath = selection.getAbsolutePath();
    fileNameOriginal = fileName = selection.getName();

    if (filePath.contains(".JOB.svg")) {  
      //DisplayData("You selected " + fileName );
      // File file = new File(sketchPath(fileName));
      //if (file.exists()) {
      //DisplayData("File Found");
      //} else {
      fileCopy();
      // }
    } else { 
      DisplayData(" ");
      DisplayData(">>>Load Failed! You must select a '.JOB.svg' file type in Run mode. Make Jobs using creation mode.<<<");
      DisplayData(" ");
      return;
    }

    gcode = loadStrings(filePath); // String[] lines = loadStrings(filePath); // Load file & count number of lines
    if (gcode == null) { 
      DisplayData("File selected was empty! Try remaking it."); 
      bFileLoaded = false; 
      return;
    }

    for (int lineCount = 0; lineCount<(gcode.length-1); lineCount++) {    // PARSE gcode & remove everything upto and including "<!-- BEGIN"
      if (gcode[lineCount].contains("<!-- BEGIN") ) {
        iLine = lineCount ;//+6; //This 6 interger is determined by our fettis for file length phrases after BEGIN in the gdoce
        initI = iLine;
        break;
      }
    }

    timeEstCore = (gcode.length -initI) ;// *3/20/60;//  *(1000/iSpeed) *(1000/iAccel); // estimate 3 sec per 20 lines, 60 seconds per minute//timeEst = (gcode.length -initI) *3/20/60  *(1000/iSpeed) *(1000/iAccel); // estimate 3 sec per 20 lines, 60 seconds per minute   
    bFileLoaded = true;
    loadPreview();
    DisplayData("File Loaded Successfully.");
  }
  delay(500);
}// end of loadile()


void fileCopy() {  //If user picks file not located in processing parent folder, we copy it!
  File file = saveFile(filePath); // File to be moved (the one the user selected. And if we are in Copy then we know its in a different directory)
  /////////////////////fileName = fileName.replace(".svg",""); fileName = fileName + "-COPY" + str( (int)( random(9999) ) ) +".svg"; ///Option to extend the file name. Would only do this if it was a true file COPY instead of a move. which I cant figure out

  //This saves the file that will be loaded next time. 
  File dest = new File(savePath(sketchPath()),"system/temp.JOB.svg"); //always temp so it overwrites the previous temp
  byte[] source = loadBytes(file);
  saveBytes(dest, source);

  dest = new File(savePath(sketchPath()), "temp.JOB.svg");// fileName);// use temp so we dont fill up with crap files
  source = loadBytes(file);
  saveBytes(dest, source); 
  dest.deleteOnExit(); //dangerous!

  fileSize = source.length;
  DisplayData("Loaded filesize in bytes=" + fileSize);

  filePath = dest.getAbsolutePath();
  fileName = dest.getName();
  bFastPreview=false;
  if (fileSize>(1000000*10/6.5)){ //ratio derived from experiment job is approximated 10/6.5 times bigger than svg
        bFastPreview=true;
        DisplayData("! Imported job size is large...program will hide preview to prevent lagging. ");
        DisplayData("! (You can change the preview setting in the HELP menu.)");
      }
  boolean success = dest.exists(); 
  if (!success) { 
    DisplayData("Somethine went wrong...Make sure you only try to open '.JOB.svg' files made using creation mode.");
  }
} 


void loadPreview() {
  if (bFileLoaded == true) {
    //colorArray = new int[12]; colorArray[0] = color(0);
    // display contents in white box!  

    //preview  = loadShape(fileName); was a pgraphic PShape  
    //Ppreview =  loadShape(fileName);
    
    previewX=width/2; //centered
    previewY=207.5;////;height/4.5;//offset fixed distance
    
    if (! bFastPreview){
      Rpreview = RG.loadShape(fileName);
      Rpreview.centerIn(g, 100, 1, 1); //graphics g, float margin, float sclDamping, float trnsDamping)  //margin is just a scaling method
      Rpreview.scale (previewScale, previewScale);

      Rpreview.translate(previewX, previewY);
      bPreviewLoaded = true;
    }
  
  }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///STREAM = the only way to send out code!
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void stream() {
  //queRun();
  if (bRun == false && !bRolling) {
    return;
  } //is it even allowed to run at all

  /* if (bForceGo) { //trying to prevent getting stuck...
   bOKtoSend = true; 
   bForceGo=false;
   bshit = false;
   } */

  if (bOKtoSend == false) { 
    return;
  } 

  if (bRolling) {
    if (bRollingForward) {
      queCmd("G6\n", false);
      stream();
      return;
    } else {
      queCmd("G7\n", false);
      stream();
      return;
    }
  }


  if (bToolChange) {
    //println("MICHAEL_"+gcode[iLine]);
    gcode[iLine] = gcode[iLine].replace("M0 ", "");
    //println("MICHAEL_"+gcode[iLine]);
    String currentColorRaw = gcode[iLine];//.substring(1); //the substring 2 clips out the Q^2, the color change is entirely handled by processing!
    toolChange(currentColorRaw);//open J option pane to insert color
    buttonPlay();
    stream();
    return;
  }

  while (true) { //checking to see if done with job
    if (iLine >= gcode.length) {
      buttonPause(); 
      buttonReset();
      buttonPlay.hide(); 
      DisplayData("END OF FILE REACHED, JOB COMPLETE!!! (Automatically Reset Job, pen position will not be lost.)");
      return;
    } else break;
  }

  if (gcode[iLine].trim().contains("M0") == true) { //QQ //("Q")
      queCmd("G2\n", false); //must be set to false so it applies last
      bToolChange = true;

  } else {

    boolean bSkip = false;      
    if (gcode[iLine].trim().contains("G") == false) { //skip everythig in the JOB file that doesnt start with a command letter
        bSkip = true;
    }

    if (bSkip ==false ) {
      //myPort.write(gcode[iLine] + "\n");
      queCmd(gcode[iLine] + "\n", false);    // +" (Line #: " + (iLine+1)+")");
      //bOKtoSend = false; 
      //if (bVerbose)DisplayData(" SENT:     " + gcode[iLine] +  " (Line #: " + (iLine+1) + ")");//this displays every line of gcode sent.
      //logHold(" SENT:     " + gcode[iLine] +  " (Line #: " + (iLine+1) + ")\n");
      percentComplete = ((float)(iLine-initI)/(float)(gcode.length-initI)  )*100  ; 
      ; // where i is the current line # . iSpeed added to prevent zero err
      // println("iLine " +iLine);
      //println("initI " +initI);
      // println("gcode.length " +gcode.length);

      /*if ( gcode[iLine].indexOf("Z10") != -1 ) { 
       bPenUp =true; 
       }
       if ( gcode[iLine].indexOf("Z0") != -1 ) { 
       bPenUp =false; 
       }*/
      //bPenWasUp = bPenUp;
    } else {
      if (bVerbose)DisplayData(" LINE SKIPPED: '" + gcode[iLine] + "' (Line #: " + (iLine+1) + ")"); //this displays every line of gcode sent.

    }
    iLine++;
  }


  stream();
} //end of stream()



void buttonReset() {
  //timeHold = millis();
  buttonPlay.show();

  timeCount= 0;
  timeElapsed =0;
  timeElapsed =0;
  bPreviewLoaded = false;
  gcode = null;
  iLine = initI;    
  percentComplete =0;
  liveData = "";//resets displayed lines
  dataCounter =0;
  DisplayData("Job Reset! (Back to 0% completed.)");
  fileSelected(storedFile);
  //if (bManual){
  //   selectSerialPort();
  //}
}

void buttonConnect() {

  selectSerialPort();
 
}

void buttonLoadJob() {

  File file = null; 
  DisplayData("Use file selection menu to select a '-JOB' file.");
  selectInput("Select a '-JOB' file to process: ", "fileSelected", file);
}

void buttonPlay() {
  if (!bPaid) {
    liveData = "";
    dataCounter =0;
    DisplayData("Sorry you must aggree to the terms of use to use this feature."); //DisplayData("Sorry this feature is not available with the free license."); //DisplayData("To enable this feature, please enter a valid key in the help menu.~");
  }
  if (bConnected && bFileLoaded && bPaid) {
    if (!bRun) {//if currently paused
      bRun = true;
      DisplayData("--PLAY--  Print Job Resumed!"); 
      /*
      if ( (iLine-initI)>5 && gcode[iLine].indexOf("Z") == -1 &&  gcode[iLine].indexOf("G21") == -1 &&  gcode[iLine].indexOf("G0") == -1 &&  gcode[iLine].indexOf("Q") == -1 ) { //so as long as the last command wasnt a lift, repeat it upon playing.
       myPort.write(gcode[iLine] + "\n");
       logHold(" SENT     " + gcode[iLine]+"\n");
       bOKtoSend = false; 
       }     */

      //myPort.write("\n"); //clears buffer
      //queCmd("\n");//
     
     if ((iLine-initI) > 8){
         if (gcode[iLine-1].trim().contains("Z") == false) {
           queCmd(gcode[iLine-1] + "\n", false); 
         }else if (gcode[iLine-2].trim().contains("Z") == false) {
           queCmd(gcode[iLine-2] + "\n", false); 
         }
          
          if (bPenWasUp == false &&  (iLine-initI) > 8 ) {
            queCmd("G1 Z0\n", false);//CUT IN LINE to get babck on track b4 continuing gcode 
          } //else {
            //myPort.write("G1 Z10 \n"); //kick it off to continue on its way (pen WAS up, so tell it go up again in cse the user did something!
           // ;//queCmd("G1 Z10\n",true);//CUT IN LINE to get babck on track b4 continuing gcode 
            //if (bVerbose)DisplayData(" SENT     " + "G1 Z10 ");//this displays every line of gcode sent.
            // logHold(" SENT     " + "G1 Z10 \n");
            //bPenUp =true;
          //}
     }
      
      ////bPenWasUp = bPenUp;
      ///////NEVER EDIT  bPenWasUp within play OR pause. ONLY GCODE is to do that
      //bOKtoSend = false;
      bOKtoSend = true;
      stream();
    } else {
      DisplayData("Job is already running.");
      stream();
    }
  }
  if (bFileLoaded == false) {  
    DisplayData("Cannot play until a .JOB.svg job is loaded!");
  }
  if (bConnected == false) {   
    DisplayData("Machine not Connected. No command sent.");
  }
}

void buttonPause() {
  if (bConnected && bFileLoaded) {
    if (bRun) {
      bRun = false; //overrides streaming calls.
      DisplayData("--PAUSED-- ...Press play to resume.");

      bPenWasUp = bPenUp;

      if (!bPenUp) {
        queCmd("G1 Z10\n", false);
      }
      
      
    
      
      //if (bVerbose)DisplayData(" SENT     " + "G1 Z10");
      //logHold(" SENT     " + "G1 Z10 \n");
      //bPenUp =true; 
      // bPenWasUp = false;
      // }// else {
      //bPenWasUp=true;
      //}
      //myPort.write("\n"); //clears buffer

      //logHold("CLEARED BUFFER\n");

      //bOKtoSend = true;
      showHideButtons();
    } else {
      DisplayData("Job is already paused.");
    }
  }
  if (bFileLoaded == false) {  
    DisplayData("Cannot play until a print job is loaded!");
  }
  if (bConnected == false) {   
    DisplayData("Machine not bConnected. No command sent.");
  }
}

void buttonQuiet() {
  if (bConnected) {
    bQuietMode = true; 
    DisplayData("Quiet Mode Selected");
    queCmd("G4\n", false);//
  } else {
    DisplayData("Machine not bConnected. No command sent.");
  }
}
void buttonLoud() {
  if (bConnected) {
    bQuietMode = false; 
    DisplayData("Normal Beeping Mode Selected");
    queCmd("G5\n", false);//
  } else {
    DisplayData("Machine not bConnected. No command sent.");
  }
}

void buttonRoll() {
  if (bPaid) {
    bRolling = true;
    bRollingForward = !bRollingForward; //toggle directiong with each click
    stream();
    return;
  } else {
    liveData = "";
    dataCounter =0;
    DisplayData("Roll is not available with the free license.");
    DisplayData("This feature will otherwise roll the cup forever to aid crafting purposes");
    DisplayData("To enable this feature, please enter a valid key in the help menu.~");
  }
}

void buttonRollStop() {
  if (bPaid) {
    bRolling = false;
    stream();
    DisplayData("Stopping rolling now, this may take a moment.."); 
    return;
  } else {
    liveData = "";
    dataCounter =0;
    DisplayData("Roll is not available with the free license.");
    DisplayData("This feature will otherwise roll the cup forever to aid crafting purposes");
    DisplayData("To enable this feature, please enter a valid key in the help menu.~");
  }
}


void buttonKillJob() {
  if (bConnected ) {
    bRolling = false;

    queCmd("G99\n", false);//
    bOKtoSend = true;//dont wait, force that shit 
    buttonPause();
    //bConnected= false;

    DisplayData("Paused Running Task & Killed Motors! (Set home to re-enable) ");
    //delay(400); //Just to make sure the command is out there before alling sutther input
  } else {
    DisplayData("Machine not bConnected. No command sent.");
  }
}



void buttonSpeed() {
  JFrame frame1 = new JFrame("Input Dialog for Speed Updates");  
  frame1.setVisible(true);
  frame1.toFront();

  JTextField field1 = new JTextField(str(iSpeed), 17);
  JTextField field2 = new JTextField(str(iAccel), 17);
  JTextField field3 = new JTextField(str(iSpeedJog), 17);
  JTextField field4 = new JTextField(str(iAccelJog), 17);

  Object[] message = {
    "Drawing Speed (mm/sec):", field1, 
    " ", 
    "Drawing Acceleration (mm/sec/sec):", field2, 
    "Notes: ", 
    " For drawing we recomend speed around 20mm/sec                                                                         ", 
    " For dry engraving we recommend speed around 7mm/sec", 
    " For wet engraving we recommend speed around 10mm/sec", 
    " For all of the above an acceleration around 100 mm/sec/sec is fine.", 
    " (These values are automatically capped in the firmware so no answer is wrong.)", 
    " ", 
    "Travel Speed (mm/sec):", field3, 
    " ", 
    "Travel Acceleration (mm/sec/sec):", field4, 
    "  (Default travel settings are usually OK for everything, but if your mug is heavy glass maybe reduce accelerations a bit.)", 
  };

  String title ="Update Speed & Accleration";
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);

  if (option == JOptionPane.OK_OPTION) {
    String typedSpeed = field1.getText();
    String typedAccel = field2.getText();
    String typedSpeedJog = field3.getText();
    String typedAccelJog = field4.getText();

    try {
      //cupType = sliderGoblet.getValue();// if (value1 != null){ Integer.parseInt(value1); }  
      //if (value2 != null){ cupDiaMax = Float.parseFloat(value2); } 
      if (typedSpeed != null) { 
        iSpeed = Integer.parseInt(typedSpeed);
      }
      if (typedAccel != null) { 
        iAccel = Integer.parseInt(typedAccel);
      }
      if (typedSpeedJog != null) { 
        iSpeedJog = Integer.parseInt(typedSpeedJog);
      }
      if (typedAccelJog != null) { 
        iAccelJog = Integer.parseInt(typedAccelJog);
      }

      if (iSpeed < 1) {
        iSpeed= 1;
      };
      if (iSpeed >2000) {
        iSpeed= 2000;
      };
      if (iAccel < 1) {
        iAccel= 1;
      };
      if (iAccel >2000) {
        iAccel= 2000;
      };
      if (iSpeedJog < 1) {
        iSpeedJog= 1;
      };
      if (iSpeedJog >2000) {
        iSpeedJog= 2000;
      };
      if (iAccelJog < 1) {
        iAccelJog= 1;
      };
      if (iAccelJog >2000) {
        iAccelJog= 2000;
      };

      sendSpeed();
      sendAccel();
      sendSpeedJog();
      sendAccelJog();
    }
    catch(NumberFormatException ne) {
      JOptionPane.showConfirmDialog(null, "Invalid Input! Please input NUMBERS ONLY. Try Again.", "Input Error", JOptionPane.DEFAULT_OPTION, JOptionPane.ERROR_MESSAGE);
    }
  }
  if (option == JOptionPane.CANCEL_OPTION) {
    DisplayData(">User Clicked Cancel. (no info was updated.)<");
  }
  frame1.setVisible(false); 
  frame1.toBack();
  frame1.dispose();
}

void sendSpeed() { //value is between 10 & 100
  if (bConnected) {
    queCmd("G50 S" + iSpeed +"\n", false);//
  }
}
void sendAccel() { //value is between 10 & 100
  if (bConnected) {
    queCmd("G51 A" + iAccel +"\n", false);
  }
}
void sendSpeedJog() { //value is between 10 & 100
  if (bConnected) {
    queCmd("G60 S" + iSpeedJog +"\n", false);
  }
}
void sendAccelJog() { //value is between 10 & 100
  if (bConnected) {
    queCmd("G61 A" + iAccelJog +"\n", false);
  }
}


/*
void sliderSpeed( int value) { //value is between 10 & 100
 
 if (bConnected && !bSliderLock) {
 iSpeed = value;
 delay(500); //brief hard delay to prevnt sending multiple speed commands with a single click
 //myPort.write("\n ");
 //delay(500); //brief delay to prevnt sending multiple speed commands with a single click
 //myPort.write(" S1 P" + value +"\n");
 //buffer = buffer + " S1 P" + value +"\n";
 //bufferArray = append(bufferArray, " S1 P" + value +"\n"); iBufferIndex++; stream();
 //myPort.write("20 S" + value +"\n");  //
 sendSpeed();         
 }
 }
 
 void sliderAccel( int value) { //value is between 10 & 100
 if (bConnected && !bSliderLock) {
 iAccel = value;
 delay(500); //brief hard delay to prevnt sending multiple speed commands with a single click
 sendAccel();       
 }
 }
 */


void buttonRotate180() {
  if (bConnected && bRun != true && bFileLoaded ) {
    if (bPaid) {
      queCmd("G20\n", false);
      DisplayData(" Rotated cup exactly 180 degrees. (system didnt track the move. If you were homed before then you are still 'home'). ");//--Paused print job. Press play to resume.--
    } else {
      liveData = "";
      dataCounter =0;
      DisplayData("Rotate 180 is not available with the free license.");
      DisplayData("This button will otherwise rotate the cup so the current top face will face downward");
      DisplayData("This is useful for aligning your work when doing both faces on a cup.");
      DisplayData("To enable this feature, please enter a valid key in the help menu.~");
    }
  } 
  if (bConnected == false) {
    DisplayData("Machine not bConnected! No command sent.");
  }
  if (bRun == true) {
    DisplayData("Job in progress, wait until complete or paused!  No command sent.");
  }
  if (bFileLoaded == false) {
    DisplayData("Load .JOB.svg file first so we know how big the cup is.");
  }
}

void buttonJumpTo() {
  if (bConnected && bRun != true && bFileLoaded ) {

          JFrame frameJ = new JFrame("Input Dialog for Jump to Line #");  
          frameJ.setVisible(true);
          frameJ.toFront();
        
          JTextField field1 = new JTextField(str(iLine), 17);
          //percentComplete = ((float)(iLine-initI)/(float)(gcode.length-initI)  )*100  ; 
          Object[] message = {
            "First Gcode Line:",initI,
            "Final Gcode Line:",gcode.length,
            "Jump to line#:", field1, 
          };
        
          String title ="Jump to line #";
          int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
        
          if (option == JOptionPane.OK_OPTION) {
            String typedTargetLine = field1.getText();
        
            try {
              //cupType = sliderGoblet.getValue();// if (value1 != null){ Integer.parseInt(value1); }  
              //if (value2 != null){ cupDiaMax = Float.parseFloat(value2); } 
              if (typedTargetLine != null) { 
                iLine = Integer.parseInt(typedTargetLine);
              }
              
              while (gcode[iLine].trim().contains("M") == true || gcode[iLine].trim().contains("Z") == true ) { //QQ //("Q")
                iLine = iLine -1;
              }        
              if (iLine < initI) {
                iLine= initI+8;//add a few lines to skip initial setup so it doesnt rehome (want user to beable to keep postition!
              };
              if (iLine >=gcode.length-1) {
                iLine= gcode.length-1;
              };
              
              buttonPenUp();
              queCmd(gcode[iLine] + "\n", false);
              //move to line (expected to be mid drawing and thats OK, it will jump down when next appropriate)
              
            }
            catch(NumberFormatException ne) {
              JOptionPane.showConfirmDialog(null, "Invalid Input! Please input NUMBERS ONLY. Try Again.", "Input Error", JOptionPane.DEFAULT_OPTION, JOptionPane.ERROR_MESSAGE);
            }
          }
          if (option == JOptionPane.CANCEL_OPTION) {
            DisplayData(">User Clicked Cancel. (no info was updated.)<");
          }
          frameJ.setVisible(false); 
          frameJ.toBack();
          frameJ.dispose();
    
    
  } 
  if (bConnected == false) {
    DisplayData("Machine not bConnected! No command sent.");
  }
  if (bRun == true) {
    DisplayData("Job in progress, wait until complete or paused!  No command sent.");
  }
  if (bFileLoaded == false) {
    DisplayData("Load .JOB.svg file first so we know how big the cup is.");
  }
}




void toolChange(String colorstring ) { // make sure you are sending everythign about the color line except the Q ( do include the sign though!)
  buttonPause();
  JFrame frame1 = new JFrame("Pen color chane prompt.");  //Only need to call this if there is more than one frame i think
  frame1.setVisible(true);
  frame1.toFront();
  //frame1.setAlwaysOnTop(true);
  frame1.setLocation(xWindow/2, yWindow/2);

  Color pencolor = new Color(Integer.parseInt(colorstring)); 

  DisplayData("--Insert new color per prompt & press OK to continue.-- (color is " + pencolor.decode(colorstring) + ")");

  //println("  Sequential end color use is " + colorstring + "  " + pencolor.decode(colorstring));
  //color RGBColor = color(pencolor.getRGB());
  //print(pencolor);  this code works, I just dont want toi use it normally
  //println(" hex color is " + RGBColor); 
  //int red = RGBColor & (0xFF <<16);  
  //int green = RGBColor & (0xFF <<8); 
  //int blue = RGBColor & 0xFF;
  //println("rgb: " + red +" "+ green +" "+ blue );

  String title ="Pen color change prompt. ";

  JPanel panel1 = new JPanel();
  JPanel panel2 = new JPanel();    
  JPanel panel3 = new JPanel();
  JPanel panel4 = new JPanel();
  JPanel panel5 = new JPanel();
  panel1.setBackground(pencolor);
  panel2.setBackground(pencolor); 
  panel3.setBackground(pencolor);
  panel4.setBackground(pencolor);
  panel5.setBackground(pencolor);
  //panel1.setSize(new Dimension(500,700));    panel2.setMinimumSize(new Dimension(500,700));    panel3.setMinimumSize(new Dimension(500,700));

  Object[] message = {
    "Please insert this pen color and press OK to continue", 
    panel1, 
    panel2, 
    panel3, 
    panel4, 
    panel5, 
    "(The exact RGB color is :" + pencolor.decode(colorstring) + ")", 
  };

  JOptionPane.showMessageDialog(frame1, message, title, JOptionPane.INFORMATION_MESSAGE);

  frame1.setVisible(false); 
  //frame1.toBack();
  frame1.dispose();
  iLine++;
  bToolChange = false;

  return;
} //end of void toolChang

/*
void mouseWheel(MouseEvent event){
 if(bFileLoaded == true){
 float wheelcount = event.getCount();
 //previewScale = previewScale + wheelcount/10;
 //bPreviewLoaded = false; //chanign this shit like this make ti lag!
 //loadPreview();
 /////////Rpreview.scale (previewScale,previewScale);
 }
 } */

void buttonProgConvert() {
  String title ="Switch to DePixelizer Mode?";
  String message = "Are you sure you want to switch to DePixelizer Mode? (The currently loaded job will be reset.)";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  //frame3.setAlwaysOnTop(true);
  frame3.setLocation(xWindow/2, yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.       
    //newPath = newPath.replace("CylinDrawRunMode", "");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
    //this is the target format = launch("cd C:/Sketch/application.windows64 && Sketch.exe");
    newPath = newPath.replace("CylinDrawRunMode", "CylinDrawDePixelizer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
    newPath = "cd " + newPath + "&& CylinDrawDePixelizer.exe";
    launch(newPath); 
    logWrite(true);//commit entire log to txt file
    exit();
  }
  if (option == JOptionPane.CANCEL_OPTION) {  
    DisplayData(">User Clicked Cancel.<");
  }
  frame3.setVisible(false);
  frame3.toBack();
  frame3.dispose();
}


void buttonProgCalibrate() {
  bCalibration = !bCalibration;
  buttonReset();
  if (bCalibration) {
    bVerbose = true;
    bPreviewLoaded = false;
    gcode = null;
    iLine = initI;  
    liveData = "";
    dataCounter =0;

    DisplayData("This is 'Calibration Mode' which allows you to directly control your machine for setup & testing purposes.");
    DisplayData("Please follow these steps in order:");
    DisplayData("   0. Power on your machine, and get a pen ready to insert into the carriage when prompted to.");
    DisplayData("   1. Connect USB cable to computer & wait for the beep & confirmation message. (Connection is automatic!) ");
    DisplayData("   2. When connected, proceed through the tests in order. (press the test# button, then read the feedback prompt.");
  } else {
    bVerbose = false;
  }
}


void buttonProgCreate() { 
  String title ="Switch to CREATION Mode?";
  String message = "Are you sure you want to switch to Job Creator Mode? (The currently loaded job will be reset.)";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  //frame3.setAlwaysOnTop(true);
  frame3.setLocation(xWindow/2, yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
    //newPath = newPath.replace("CylinDrawRunMode", "");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
    //this is the target format = launch("cd C:/Sketch/application.windows64 && Sketch.exe");
    newPath = newPath.replace("CylinDrawRunMode", "CylinDrawJobCreator");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
    newPath = "cd " + newPath + "&& CylinDrawJobCreator.exe";
    launch(newPath); 
    logWrite(true);//commit entire log to txt file
    exit();
  }
  if (option == JOptionPane.CANCEL_OPTION) { 
    DisplayData(">User Clicked Cancel.<");
  }
  frame3.setVisible(false);
  frame3.toBack();
  frame3.dispose();
}


void buttonProgRun() { 
  if (bCalibration) {
    bVerbose = false; 
    bCalibration = false;
    buttonReset();

    DisplayData("This is 'Run Mode' which allows you to directly control your machine for jobs.");
    DisplayData("    -Click LOAD JOB FILE to pick a new job. ");
    DisplayData("    -Click PLAY to run that job.");
  } else {
    DisplayData("You are currently using Run Mode.");
  }
}


void buttonExit() {
  String title ="Exit program?";
  String message = "Are you sure you want to exit the program?";
  //frame.setAlwaysOnTop(true);
  surface.setLocation(xWindow/2, yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    buttonKillJob();
    if (bConnected == true) {
      myPort.clear(); 
      myPort.stop();
    } 
    logWrite(true);//commit entire log to txt file
    exit();
  }
  if (option == JOptionPane.CANCEL_OPTION) {  
    DisplayData(">User Clicked Cancel.<");
  }
}


void buttonGoHome() {
  if (bConnected) {
    if (bRun==true) {
      DisplayData("Denied, job in progress!");
      delay(10); //brief delay to preent sending multiple speed commands with a single click
    } else {
      queCmd("G3\n", false);
    }
  } else { 
    DisplayData("Machine not Connected. No command sent.");
  }
}
void buttonSetHome() {
  if (bConnected) {
    if (bRun==true) {
      DisplayData("Denied, job in progress!");
      delay(10); //brief delay to preent sending multiple speed commands with a single click
    } else {
      queCmd("G0\n", false);
    }
  } else { 
    DisplayData("Machine not Connected. No command sent.");
  }
}



void buttonPenUp() {
  if (bConnected) {
    if (bRun==true) {
      DisplayData("Denied, job in progress!");
      delay(10); //brief delay to preven sending multiple speed commands with a single click
    } else {
      queCmd("G1 Z10\n", false);
    }
  } else { 
    DisplayData("Machine not bConnected. No command sent.");
  }
}


void buttonPenDown() {
  if (bConnected) {
    if (bRun==true) {
      DisplayData("Denied, job in progress!");
      delay(10); //brief delay to prevnt sending multiple speed commands with a single click
    } else { 
      queCmd("G1 Z0\n", false);
    }
  } else { 
    DisplayData("Machine not bConnected. No command sent.");
  }
}

void buttonTester() {
  bOKtoSend = true;//act as if you have sent a command but DOMNT to test if unsitcker works
}


void buttonSupport() {

  String title ="SUPPORT MENU";

  JButton buttonAmazon = new JButton("Shop on Amazon.com");
  buttonAmazon.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://amzn.to/2SxA5Vj");
    }
  }
  ); 

  JButton buttonEbay = new JButton("Shop on Ebay.com");
  buttonEbay.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://ebay.us/z0g6Yh");
    }
  }
  );

  JButton buttonStore = new JButton("Visit our Shop");
  buttonStore.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://amzn.to/2SxA5Vj");
    }
  }
  );

  JButton buttonHomepage = new JButton("Visit CylinDraw Homepage");
  buttonHomepage.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://cylindraw.com/");
    }
  }
  );

  JButton buttonDiscord = new JButton("Visit CylinDraw Forum");
  buttonDiscord.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://discord.gg/pWGrQ9uyqD");
    }
  }
  );
  JButton buttonCoffee = new JButton("Buy Us a Coffee");
  buttonCoffee.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://www.buymeacoffee.com/MichaelGraham");
    }
  }
  );

  Object[] msg = {

    "For questions concerning your order contact us at CylinDraw@gmail.com.", 
    " ", 
    "For technical questions or to show off your work join the conversation on Discord:", buttonDiscord, 
    " ", 
    "Check out our web store for the latest kits, upgrades, replacement consumables:", buttonStore, 
    " ", 
    "Support us by buying new cups & pens from our affiliate partners", 
    buttonAmazon, buttonEbay, 
    " ", 
    "Inspire us to work harder on new features", buttonCoffee, 
    " ", 
    "Visit our website homepage:", buttonHomepage, 
    " ", 
  };


  JFrame frame33 = new JFrame("SUPPORT");  //Only need to call this if there is more than one frame i think
  frame33.setVisible(true);
  frame33.toFront();
  frame33.setLocation(xWindow/2, yWindow/2);

  JOptionPane.showConfirmDialog(null, msg, title, JOptionPane.CANCEL_OPTION, JOptionPane.INFORMATION_MESSAGE);

  frame33.setVisible(false);
  frame33.toBack();
  frame33.dispose();
}


void buttonHelp() {
  JTextField fieldLicense = new JTextField(sKey, 20);
  JTextField fieldEmail = new JTextField(sEmail, 20);

  String title ="HELP MENU";

  int defaultConnect =0;
  if (bManual) {
    defaultConnect =1;
  }
  JSlider slideManual = new JSlider(0, 1, defaultConnect);//3rd value is default

  //int defaultVerbose =0;
  //if (bVerbose){ defaultVerbose =1;}
  //JSlider slideVerbose = new JSlider(0,1,defaultVerbose);//3rd value is default

  JButton buttonLicense = new JButton("Get License Key");
  buttonLicense.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
      link("https://cylindraw.com/shop/");
    }
  }
  );  

  Object[] submsg1 ={
    buttonLicense, 
    "Enter your email address here:", fieldEmail, 
    "Enter your license key here:", fieldLicense, 
  };
  Object[] submsg2 ={
    sVersion, 
  };

  Object[] submsg3 ={
    "This is 'Run Mode' which allows you to directly control your machine. Creating custom cups is as easy as 1,2,3!", 
    "   1. Connect USB cable to computer & wait for connection-notification.", 
    "   2. Click the 'LOAD JOB FILE' button and select a '.JOB.svg' file. ", 
    "   3. To begin the job press the 'Pause/Play' button. ", 
    "Notes:   ", 
    "  -When finished please quit this program using the EXIT PROGRAM button to ensure the USB connection is cleared properly for best practice.", 
    "  -Control buttons appear only when they may be used. Otherwise they are hidden for convienence!", 
    "  -Clicking the preview image will open the stroke viewer in a separate window;", 
    "  -The drawn image will be centered on the face of the cup that is pointing up when you start the machine. The tool is the centerline!", 
    "  -Rolling your mouse wheel scales the display for viewing purposes only, it does not change the final drawing.", 
    " ", 
    "                 |<<<Auto USB Connect     vs     Manual USB Connect>>>|", 
    slideManual, 
    " ", 
    //"                 |<<<Hide Gcode     vs     Show Gcode>>>|",


  };
  //slideVerbose,


  Object[] messageUnpaid = {
    submsg1, 
    submsg2, 
    submsg3, 

  };

  Object[] messagePaid = {
    "Full License Found. You are awesome!", 
    submsg2, 
    submsg3, 
  };

  JFrame frame33 = new JFrame("INSTRUCTIONS");  //Only need to call this if there is more than one frame i think
  frame33.setVisible(true);
  frame33.toFront();
  frame33.setLocation(xWindow/2, yWindow/2);
  int option =0;
  if (!bPaid) {
    option = JOptionPane.showConfirmDialog(null, messageUnpaid, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.INFORMATION_MESSAGE);
  } else {
    bdoneOnce = true;//
    option = JOptionPane.showConfirmDialog(null, messagePaid, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.INFORMATION_MESSAGE);
  }    

  if (slideManual.getValue() ==0) {
    bManual = false;
  } else {
    bManual = true;
  }

  /* if (slideVerbose.getValue() ==0){
   bVerbose = false;
   }else{
   if (bPaid) {
   bVerbose = true;
   }else{
   DisplayData("Sorry the live 'Show Gcode' feature is only available with a full license. ");
   }
   } */

  if (option == JOptionPane.OK_OPTION) {
    //println(fieldEmail.getText());
    // println(fieldLicense.getText());
    checkLicense(fieldEmail.getText(), fieldLicense.getText()); //CHECKED LICENSE HERE to see if PAID

    if (bPaid) {
      ;
      /*
        if (! bdoneOnce){
       bdoneOnce = true;
       DisplayData ("~~~~Paid license found! Thank you for supporting our work!~~~~");
       Object[] message22 = {
       "~~~~Paid license found! Thank you for supporting our work!~~~~", 
       };
       JFrame frame12 = new JFrame("Notice");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
       frame12.setVisible(true);
       frame12.toFront(); 
       //frame12.setAlwaysOnTop(true);
       frame12.setLocation(xWindow/2, yWindow/2);
       JOptionPane.showMessageDialog(frame12, message22, "NOTICE!", JOptionPane.INFORMATION_MESSAGE);
       frame12.setVisible(false);
       frame12.toBack();
       frame12.dispose();
       } */
    } else if (bTerms) {
      Object[] message22 = {
        "~Free license found. We hope you enjoy the free version of our product!~", 
        "If you have valid license key, please click the HELP button and enter it there.", 
      };
      JFrame frame12 = new JFrame("Notice");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
      frame12.setVisible(true);
      frame12.toFront(); 
      //frame12.setAlwaysOnTop(true);
      frame12.setLocation(xWindow/2, yWindow/2);
      JOptionPane.showMessageDialog(frame12, message22, "NOTICE!", JOptionPane.INFORMATION_MESSAGE);
      frame12.setVisible(false);
      frame12.toBack();
      frame12.dispose();
    };
  }
  frame33.setVisible(false);
  frame33.toBack();
  frame33.dispose();
}


class Point { 
  float x, y, z; 
  color clr;
  float strk;
  Point(float x, float y, float z, color clr) { 
    this.x = x;
    this.y = y;
    this.z = z;
    this.clr = clr;
  }
}


boolean checkComplete() {
  String serialLatestComplete =  myPort.readStringUntil(';');// end of line indicator for a command. (buffer until symbol)
  boolean bFound = false;
  if (serialLatestComplete != null) {

    String trimmed = serialLatestComplete.trim();
    if (trimmed.length() >1 && (trimmed.contains("~") == true || trimmed.contains("@") == true)) { //line returned starts with one or the other. Tildas are just notes. @ means at a position.
      serialLatestComplete = serialLatestComplete.replace("\n", "");//because the \n being truend was what we riginally sent out. We dont bufffer until this because we want to be able to end update messages back that DOTN mean that the line is complete.
      bFound = true;

      if (trimmed.contains("Z10") == true) { 
        bPenUp =true;
      }
      if (trimmed.contains("Z0") == true) { 
        bPenUp =false;
      }
      //if (bVerbose)
      DisplayData(serialLatestComplete);//" RECEIVED:  " +  //recieved
      //logHold(" RECEIVED:  " + serialLatestComplete+"\n");
    }
  } else { 
    String serialAll = myPort.readString();
    if (serialAll != null) {
      DisplayData(serialAll);
    }
  }  
  return (bFound);
}


boolean checkAny() {

  String serialAll = myPort.readString();   
  boolean bFound = false;
  if (serialAll != null) {
    bProvenConnection= true;
    bFound = true;
    DisplayData(serialAll);
  } else {
    //if (bVerbose)DisplayData("...no responce on this port.");
  }
  return (bFound);
}


void serialEvent(Serial p) { //This function displays serial data returned from the arduino. Is called when recieving special characters
  bProvenConnection = true;
  try {    
    if (checkComplete()) {
      bOKtoSend = true;
      queRun();
    }

    stream();
  }

  catch(RuntimeException e) { 
    logHold("serial even error: "+p.readString());
    logWrite(true);
    stream();
  };//DisplayData("END OF FILE REACHED"); }// e.printStackTrace();} // THIS SECTION IS DEFINITELY THROWING ERRORS at the end of the job
}//end of serialevent

void setButtons() {
  previewX=width/2;
  loadPreview();

  if (gui != null) gui.dispose();  
  gui = new ControlP5(this);

  PFont p = createFont("Helvetica", 11); 
  ControlFont font = new ControlFont(p);

  //HEADER ROW ----------------------------------------------------
  int Xpos =5;  
  int Ypos = 5;  
  int sizeX =100; 
  int sizeY =50; 
  int xSpacing = 5; 
  int ySpacing = 0; 
  buttonProgConvert = gui.addButton("buttonProgConvert").setCaptionLabel("DePixelizer").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Xpos = Xpos + sizeX + xSpacing; 
  Ypos = Ypos+ySpacing;
  buttonProgCreate = gui.addButton("buttonProgCreate").setCaptionLabel("Creation Mode").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Xpos = Xpos + sizeX + xSpacing; 
  Ypos = Ypos+ySpacing;

  buttonProgRun = gui.addButton("buttonProgRun").setCaptionLabel("Run Mode").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);

  buttonProgCalibrate = gui.addButton("buttonProgCalibrate").setCaptionLabel("Run Mode OR\nCalibration").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);

  //RIGHT SIDE OF HEADER ROW
  Xpos = xWindow - xSpacing - sizeX; 
  Ypos = Ypos+ySpacing;
  buttonExit =  gui.addButton("buttonExit").setCaptionLabel("Exit Program").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Xpos = Xpos - sizeX - xSpacing; 
  Ypos = Ypos+ySpacing; 
  buttonHelp = gui.addButton("buttonHelp").setCaptionLabel("HELP").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Xpos = Xpos - sizeX - xSpacing; 
  Ypos = Ypos+ySpacing;
  buttonSupport = gui.addButton("buttonSupport").setCaptionLabel("SUPPORT").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);  



  sizeX = 130;
  //LEFT BUTTON ROW ----------------------------------------------------
  Xpos =5; 
  Ypos = 70;  
  sizeY =50; 
  ySpacing = sizeY +5; 
  buttonConnect = gui.addButton("buttonConnect").setPosition(Xpos, Ypos).setCaptionLabel("Manual USB\nConnect").setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);//.setColorBackground(color(222, 31, 31));   ;

  Ypos = Ypos+ySpacing;
  sizeX = (sizeX-xSpacing)/2;
  buttonReset = gui.addButton("buttonReset").setPosition(Xpos, Ypos).setCaptionLabel("Reset\nJob").setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Xpos = Xpos+sizeX +xSpacing;
  buttonLoadJob = gui.addButton("buttonLoadJob").setCaptionLabel("Load\nJob File").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Ypos = Ypos+ySpacing;
  Xpos =5; 
  buttonPause = gui.addButton("buttonPause").setCaptionLabel("Pause").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();
  Xpos = Xpos+sizeX +xSpacing;
  buttonPlay = gui.addButton("buttonPlay").setCaptionLabel("Play").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing;
  Xpos =5;   

  buttonGoHome = gui.addButton("buttonGoHome").setCaptionLabel("Go Home").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Xpos = Xpos +sizeX+xSpacing;
  buttonSetHome = gui.addButton("buttonSetHome").setCaptionLabel("Set Home").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing;  
  Xpos = 5;


  int holdsizex= sizeX= sizeX*2+xSpacing;
  //  togglePlay = gui.addToggle("togglePlay").setCaptionLabel("Pause           Play").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setSize(sizeX,sizeY).setFont(font);;
  //  gui.getController("togglePlay").getCaptionLabel().align(CENTER,CENTER);    togglePlay.hide(); //.align(ControlP5.LEFT,  ControlP5.TOP_OUTSIDE); 
  buttonKillJob = gui.addButton("buttonKillJob").setCaptionLabel("Kill Motors!").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).setColorBackground(color(222, 31, 31)).hide();   

  //LEFT BUTTON ROW 2 for cal----------------------------------------------------

  Xpos = Xpos + sizeX + xSpacing ; 
  Ypos = 74; 
  sizeX = 80;

  buttonTest1 = gui.addButton("buttonTest1").setCaptionLabel("Test #1").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing; 
  buttonTest2 = gui.addButton("buttonTest2").setCaptionLabel("Test #2").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing;
  buttonTest3 = gui.addButton("buttonTest3").setCaptionLabel("Test #3").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing;  
  buttonTest4 = gui.addButton("buttonTest4").setCaptionLabel("Test #4").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing;  
  buttonTest5 = gui.addButton("buttonTest5").setCaptionLabel("Test #5").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Ypos = Ypos+ySpacing;


  //RIGHT BUTTON ROW------------------------------------------------------------
  sizeX = holdsizex;
  sizeX = (sizeX-xSpacing)/2;
  Xpos = width -sizeX -5; 
  Ypos = 74;  
  buttonQuiet = gui.addButton("buttonQuiet").setCaptionLabel("Quiet").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();  
  Xpos = Xpos- sizeX -xSpacing;
  buttonLoud = gui.addButton("buttonLoud").setCaptionLabel("Normal\nBeeps").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();
  sizeX= sizeX*2+xSpacing;
  Xpos = width -sizeX -5;
  // toggleQuiet = gui.addToggle("toggleQuiet").setCaptionLabel("NORMAL           QUIET").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);;
  //   gui.getController("toggleQuiet").getCaptionLabel().align(CENTER,CENTER);    toggleQuiet.hide();

  //sizeY = int(sizeY * 0.9);
  // gui.addButton("buttonSpeedUpdateSlow").setCaptionLabel("Speed: Slow").setPosition(Xpos, Ypos+2*spacing).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,int(sizeY * 0.8));    
  //gui.addButton("buttonSpeedUpdateMed").setCaptionLabel("Speed: Medium").setPosition(Xpos, Ypos+2.5*spacing).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,int(sizeY * 0.8));    
  //gui.addButton("buttonSpeedUpdateFast").setCaptionLabel("Speed: Fast").setPosition(Xpos, Ypos+3*spacing).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,int(sizeY * 0.8));
  Ypos = Ypos+ySpacing;
  /*
    int cap =1000;
   int floor =1;
   int window =50;
   int maxSpeed=iSpeed+window; if (maxSpeed >cap){ maxSpeed =cap; }
   int minSpeed=iSpeed+window; if (minSpeed < floor){ minSpeed =floor; }
   int maxAccel=iAccel+window; if (maxAccel >cap){ maxAccel =cap; }
   int minAccel=iAccel-window;if (minAccel < floor){ minAccel =floor; } */
  buttonSpeed  = gui.addButton("buttonSpeed").setCaptionLabel("Update Speed").setPosition(Xpos, Ypos).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX, int(sizeY)).setFont(font).hide();
  Ypos = Ypos+ySpacing;
  //sliderSpeed = gui.addSlider("sliderSpeed").setSize(sizeX, sizeY/2).setCaptionLabel("    Speed").setPosition(Xpos, Ypos).setRange(1, iSpeed *2).setFont(font).setValue(iSpeed).hide();//.setLock(true)./.setNumberOfTickMarks(100).showTickMarks(true)
  //  gui.getController("sliderSpeed").getCaptionLabel().align(CENTER, CENTER); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);
  //sliderSpeed.setDefaultValue(iSpeed);
  //Ypos = Ypos+sizeY/2+5;
  //sliderAccel = gui.addSlider("sliderAccel").setSize(sizeX, sizeY/2).setCaptionLabel("    Acceleration").setPosition(Xpos, Ypos).setRange(10, 1000).setFont(font).setValue(iAccel).hide();//.setLock(true).//.setNumberOfTickMarks(100).showTickMarks(true)
  //  gui.getController("sliderAccel").getCaptionLabel().align(CENTER, CENTER); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);
  //sliderAccel.setDefaultValue(iAccel);
  //Ypos = Ypos+sizeY/2+5;  

  buttonRotate180 = gui.addButton("buttonRotate180").setCaptionLabel("Rotate Cup 180Deg\n    (untracked)").setPosition(Xpos, Ypos).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX, int(sizeY)).setFont(font).hide();
  Ypos = Ypos+ySpacing;

  sizeX = (sizeX-xSpacing)/2;
  Xpos = width -sizeX -5; 
  buttonPenUp= gui.addButton("buttonPenUp").setCaptionLabel("Tool\nUP").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font);
  Xpos = Xpos- sizeX -xSpacing;

  buttonPenDown= gui.addButton("buttonPenDown").setCaptionLabel("Tool\nDOWN").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font); 
  Ypos = Ypos+ySpacing;

  Xpos = width -sizeX -5; 
  buttonRoll = gui.addButton("buttonRoll").setCaptionLabel("ROLL\nFOREVER").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();
  Xpos = Xpos- sizeX -xSpacing;
  buttonRollStop = gui.addButton("buttonRollStop").setCaptionLabel("STOP\nRoll").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();

  sizeX= sizeX*2+xSpacing; //return to normal button size
  // Ypos = Ypos+ySpacing;
  // Ypos = 365;


  buttonTester = gui.addButton("buttonTester").setCaptionLabel("TEST").setPosition(Xpos, Ypos).setColorValue(100).setColorLabel(255).setSize(sizeX, sizeY).setFont(font).hide();
    Ypos = Ypos+ySpacing;

  buttonJumpTo = gui.addButton("buttonJumpTo").setCaptionLabel("Jump to Line:").setPosition(Xpos, Ypos).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX, int(sizeY)).setFont(font).hide();

  //CENTER BUTTON-------------------------------------------------------------
  // Xpos = width/2- sizeX/2;
  // Ypos = 357;
  //Ypos = Ypos+ySpacing;


  showHideButtons();
}

void mouseClicked() {
  if (bFileLoaded  == true) {  //bPreviewLoaded //Detects click only if inside image
    int prevRectWidth = 550; 
    //rect(width/2, 70+prevRectWidth/4, prevRectWidth, prevRectWidth/2); //Aspect ratio =2 as estimate. wide rect. //second two dimensions are the rectangle size
    
    //if (mouseX>(previewX -Rpreview.width/2) && mouseX<(previewX +Rpreview.width/2)  && mouseY<(previewY +Rpreview.width/2) && mouseY>(previewY -Rpreview.width/2)  ){//   || 
    if (mouseX>(previewX -prevRectWidth/2) && mouseX<(previewX +prevRectWidth/2)  && mouseY<(previewY +prevRectWidth/2) && mouseY>(previewY -prevRectWidth/2) ) {
      
      if (bVerbose)DisplayData("You clicked on the preview, opening detailed job viewer!");
      logHold("You clicked on the preview, opening detailed job viewer!\n");
      try {
        String localPath = sketchPath();
        localPath = localPath.replace("CylinDrawRunMode", "CylinDrawViewer");

        //File dest1 = new File(savePath(localPath), "\\system\\temp.JOB.svg");// fileName);// use temp so we dont fill up with crap files
        //byte[] source1 = loadBytes(storedFile);//// not sure why this was here but it existed on release 1
        //saveBytes(dest1, source1);
        //filePath = dest1.getAbsolutePath();
        //fileName = dest1.getName();

        filePath = storedFile.getAbsolutePath();
        fileName = storedFile.getName();

        //boolean success = dest1.exists(); 
        //if (!success) {
        //  DisplayData("Somethine went wrong, Could not load the viewer...Make sure you only try to open files ending with '.job.svg'.");
        //  launch(filePath);
        //} else {
        DisplayData(".JOB.svg file found. Loading code preview.");
        localPath = "cd " + localPath + "&& CylinDrawViewer.exe";
        launch(localPath);
        //}
      } 
      catch(RuntimeException e) {  
        launch(filePath);
      }
    }
  }
}


void showHideButtons() {

  if (bCalibration) {
    buttonTest1.show();
    buttonTest2.show();
    buttonTest3.show();
    buttonTest4.show();
    buttonTest5.show(); 
    buttonPause.hide(); 
    buttonPlay.hide();
  } else {
    buttonTest1.hide();
    buttonTest2.hide();
    buttonTest3.hide();
    buttonTest4.hide();
    buttonTest5.hide();
  }  

  //  boolean bPenUp  = true; //current pen state tracker, used for proper Pausing
  //boolean bPenWasUp = true;//track if pen was up priot to pausing so it doesn accidentally invert pen pos upon resume if paused whit pen was alreadu up! (start high so when you play it assumes it was and doesn try to resume a start where it wasnt 
  if (bPenUp) {
    buttonPenUp.setColorBackground(color(61, 148, 232)); //active color
    buttonPenDown.setColorBackground(color(26, 48, 90));
  } else {
    buttonPenDown.setColorBackground(color(61, 148, 232)); 
    buttonPenUp.setColorBackground(color(26, 48, 90));
  }

  if (bRolling) {
    buttonRoll.setColorBackground(color(61, 148, 232)); //active color
    buttonRollStop.setColorBackground(color(26, 48, 90));
  } else {
    buttonRollStop.setColorBackground(color(61, 148, 232)); 
    buttonRoll.setColorBackground(color(26, 48, 90));
  }


  if (bQuietMode) {
    buttonQuiet.setColorBackground(color(61, 148, 232)); //active color
    buttonLoud.setColorBackground(color(26, 48, 90));
  } else {
    buttonLoud.setColorBackground(color(61, 148, 232)); 
    buttonQuiet.setColorBackground(color(26, 48, 90));
  }
  //.setColorBackground(color(26,48,90)); is normal
  if (bConnected) {
    buttonConnect.setColorBackground(color(26, 48, 90));//normal color
    buttonKillJob.show();
    if (bFileLoaded) {
      if (!bCalibration) {
        buttonPause.show();
        buttonPlay.show();
      }
      if (bRun) {//connected, file loaded, running!
        buttonConnect.hide();
        buttonPlay.hide();
        buttonPause.show(); 
        buttonPlay.setColorBackground(color(61, 148, 232)); 
        buttonPause.setColorBackground(color(26, 48, 90)); 
        buttonQuiet.hide(); 
        buttonLoud.hide();
        buttonRoll.hide();
        buttonRollStop.hide();
        buttonSpeed.hide();//sliderSpeed.hide();sliderAccel.hide();  
        buttonGoHome.hide(); 
        buttonSetHome.hide(); 
        buttonPenUp.hide(); 
        buttonPenDown.hide(); 
        //bSliderLock =true; //toggleQuiet.hide();  
        buttonRotate180.hide();
        buttonJumpTo.hide();
        buttonReset.hide(); 
        buttonLoadJob.hide();
        return;
      } else { //connected, file loaded, not running
        buttonConnect.show();
        buttonPause.hide(); 
        buttonPlay.show();
        buttonPause.setColorBackground(color(61, 148, 232));  
        buttonPlay.setColorBackground(color(26, 48, 90));  
        buttonQuiet.show(); 
        buttonLoud.show();
        buttonRoll.show();
        buttonRollStop.show();
        buttonSpeed.show();//sliderSpeed.show(); sliderAccel.show();  
        buttonGoHome.show();  
        buttonSetHome.show(); 
        buttonPenUp.show(); 
        buttonPenDown.show(); 
        //bSliderLock =false; //toggleQuiet.show(); 
        buttonRotate180.show(); 
        buttonJumpTo.show();
        buttonReset.show(); 
        buttonLoadJob.show();
        return;
      }
    } else { //connected but no file loaded (not running)
      buttonRoll.hide();
      buttonRollStop.hide();
      buttonPause.hide(); 
      buttonPlay.hide(); 
      buttonQuiet.show(); 
      buttonLoud.show();
      buttonSpeed.show();//sliderSpeed.show(); sliderAccel.show();
      buttonGoHome.show(); 
      buttonSetHome.show(); 
      buttonPenUp.show(); 
      buttonPenDown.show();  
      //bSliderLock =false; //toggleQuiet.show(); 
      buttonRotate180.hide();  // togglePlay.hide(); 
      buttonJumpTo.hide();
      return;
    }
  } else { //not connected
    // if (bManual){ 
    buttonConnect.show();
    buttonConnect.setColorBackground(color(222, 31, 31)); //red color
    buttonRoll.hide();
    buttonRollStop.hide();
    buttonSpeed.hide();//sliderSpeed.hide();  sliderAccel.hide();  
    buttonGoHome.hide(); 
    buttonSetHome.hide(); 
    buttonPenUp.hide(); 
    buttonPenDown.hide();
    buttonRotate180.hide(); //toggleQuiet.hide();
    buttonJumpTo.hide();
    buttonKillJob.hide(); //togglePlay.hide();
  }
}


void buttonTest1() {
  String title ="TEST #1";
  Object[] message = {
    "Test#1: Check pen carriage motion & positioning (10 seconds total).", 
    "Preparations: ", 
    "  -The pen carriage should be naked, that is, remove the pen holder and dremel holder.", 
    "Pass criteria: ", 
    "  -The pen lifted & dropped smoothly without stiction 4 out of 4 times.", 
    "  -The pen reached its absolute max and absolute min positions", 
    "Troubleshooting: ", 
    "  -Ensure power is on & machine is connected. ", 
    "  -Ensure servo is plugged in in the correct orientation. (backwards won't work, but doesnt hurt anything)", 
    "  -Ensure cable ties to lifter bearings are not too tight on BOTH sides. (Ensure only one side is tight and the other side barely snug).", 
    "  -Ensure servo horn is placed correctly. Else, remove horn, click 'TOOL DOWN' then attach horn horizontally.", 
    ">>>Click OK to begin this test<<<", 
  };

  JFrame frame73 = new JFrame(title);
  frame73.setVisible(true);
  frame73.toFront();
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    DisplayData("Performing Test#1");
    //if(bVerbose)DisplayData("SENT: G11 ");
    //logHold("SENT: G11 \n");
    //myPort.write("G11 \n");
    queCmd("G11\n", false);

    // bOKtoSend = false;
    stream();
  } 
  if (option == JOptionPane.CANCEL_OPTION) { 
    DisplayData(">User Clicked Cancel.<");
  }     
  frame73.setVisible(false);
  frame73.toBack();
}
void buttonTest2() {
  String title ="TEST #2";
  Object[] message = {
    "Test#2: Verify the stepper motor motion direction (5 seconds total).", 
    "Preparations: ", 
    "  -Manually move the pen carriage to the middle of the cup. (To the approximate middle of its travel.)", 
    "Pass criteria: ", 
    "  -The linear motor (H axis) should move to the right (UP the cup)", 
    "  -The rotary motor (T axis) should roll the cup AWAY from you", 
    "Troubleshooting: ", 
    "  -Ensure power is on & machine is connected. ", 
    "  -If a motor moves the wrong direction, UNPLUG THE POWER FIRST, >THEN< flip the stepper's 4 pin connector.", 
    "  -If a motor doesnt move make sure it is connected. (Linear motor = Y driver on circuit board, Rotary axis = X driver on circuit board).", 
    ">>>Click OK to begin this test<<<", 
  };

  JFrame frame73 = new JFrame(title);
  frame73.setVisible(true);
  frame73.toFront();
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    DisplayData("Performing Test#2");
    // if(bVerbose)DisplayData("SENT: G12 ");
    //logHold("SENT: G12 \n");
    //myPort.write("G12 \n");
    queCmd("G12\n", false);
    // bOKtoSend = false;
    stream();
  } 
  if (option == JOptionPane.CANCEL_OPTION) { 
    DisplayData(">User Clicked Cancel.<");
  }     
  frame73.setVisible(false);
  frame73.toBack();
}
void buttonTest3() {
  String title ="TEST #3";
  Object[] message = {
    "Test#3: Manually verify the homing switch is functional (10 seconds total).", 
    "Preparations: ", 
    "  -Manually move the pen carriage to the middle of the cup. (To the approximate middle of its travel.)", 
    "Pass criteria: ", 
    "  -The machine should beep when you press the homing switch. (over a 10 second period when you press OK) ", 
    "  -Manually moving the carriage to the home position should trigger the switch & make a beep.", 
    "Troubleshooting: ", 
    "  -Ensure power is on & machine is connected. ", 
    "  -Note that the tool tip should align with the end of the chuck tips to prevent a crash when homing. ", 
    "  -The homing flag on the back of the carriage can be adjusted with a manual clamping knob.", 
    ">>>Click OK to begin this test<<<", 
  };

  JFrame frame73 = new JFrame(title);
  frame73.setVisible(true);
  frame73.toFront();
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    DisplayData("Performing Test#3");
    //if(bVerbose)DisplayData("SENT: G13 ");
    // logHold("SENT: G13 \n");
    //myPort.write("G13 \n");
    queCmd("G13\n", false);
    // bOKtoSend = false;
    stream();
  } 
  if (option == JOptionPane.CANCEL_OPTION) { 
    DisplayData(">User Clicked Cancel.<");
  }     
  frame73.setVisible(false);
  frame73.toBack();
}
void buttonTest4() {
  String title ="TEST #4";
  Object[] message = {
    "Test#4: Verify the repeatability of min & max extent positions(40 seconds total).", 
    "Preparations: ", 
    "  -Install pen carriage, any pen, & a paper cup. Adjust the machine to account for the taper of the cup.", 
    "  -Home the machine. (re-adjusting the homing flag may be necessary when adjusting the machine for cup taper.", 
    "Pass criteria: ", 
    "  -There should only be TWO dots at the end of this test, (otherwise there is motion slop in your system).", 
    "Troubleshooting: ", 
    "  -Verify the belt is 'taught'. If it is too tight it will be extra noisy. Adjust tension by pivoting the Haxis stepper. ", 
    "  -Verify the cup is secure in the twisting chuck, and that the chuck is secure to the motor shaft. (The tiny set screw needs to align over the flat on the motor shaft)", 
    "  -Verify that the pen is touching the cup when you press TOOL DOWN, and not touching the cup when you press TOOL UP.", 
    ">>>Click OK to begin this test<<<", 
  };

  JFrame frame73 = new JFrame(title);
  frame73.setVisible(true);
  frame73.toFront();
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    DisplayData("Performing Test#4");
    toolChange("-12303291");
    //if(bVerbose)DisplayData("SENT: G14 ");
    // logHold("SENT: G14 \n");
    //myPort.write("G14 \n");
    queCmd("G14\n", false);
    //bOKtoSend = false;
    stream();
  } 
  if (option == JOptionPane.CANCEL_OPTION) { 
    DisplayData(">User Clicked Cancel.<");
  }     
  frame73.setVisible(false);
  frame73.toBack();
}
void buttonTest5() {
  String title ="TEST #5";
  Object[] message = {
    "Test#5: Verify drawing speeds via nested 50mm square (60 seconds total).", 
    "Preparations: ", 
    "  -Install pen carriage, any pen, & a paper cup. Adjust the machine to account for the taper of the cup.", 
    "  -Home the machine. (re-adjusting the homing flag may be necessary when adjusting the machine for cup taper.", 
    "Pass criteria: ", 
    "  -Verify that the lines are drawn straight, evenly, and without skipping. ", 
    "  -The height of the rectangle should be 50mm. (Don't worry about width).", 
    "  -None of the squares should overlap or else revisit test4.", 
    "Troubleshooting: ", 
    "  -If 'bad things happen' clicking the EXIT button will stopp all motion instantly. (whereas KILL MOTORS will stop them opportunistically)", 
    "  -Change the speed if necessary & repeat this test. Its a good test for figuring out appropriate drawing speed.", 
    "  -Don't worry if the 'square' comes out as a 'rectangle', this test does not consider your present cup diameter.", 
    "  -Pulling the power cable is also a safe way to instantly stop the motors. (note I do mean power cable, not USB cable)", 
    ">>>Click OK to begin this test<<<", 
  };

  JFrame frame73 = new JFrame(title);
  frame73.setVisible(true);
  frame73.toFront();
  int option = JOptionPane.showConfirmDialog(null, message, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION) { 
    DisplayData("Performing Test#5");
    toolChange("-12303291");
    //if(bVerbose)DisplayData("SENT: G15 ");
    // logHold("SENT: G15 \n");
    //myPort.write("G15 \n");
    queCmd("G15\n", false);
    //bOKtoSend = false;
    stream();
  } 
  if (option == JOptionPane.CANCEL_OPTION) { 
    DisplayData(">User Clicked Cancel.<");
  }     
  frame73.setVisible(false);
  frame73.toBack();
}

void checkLicense(String inputEmail, String inputKey) {
  boolean bRenewFree = true;
  File file = new File(sketchPath("system/License.txt"));
  if (file.exists()) {
    try {
      String[] lines = loadStrings("system/License.txt");
      if (lines != null) { 
        bTerms = true;//a free OR paid license has been found so eula is confirmed 

        int cheat1= inputKey.indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found (This is my overriding everything key, dont use this for customers)
        int cheat2= lines[0].indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found (This is my overriding everything key, dont use this for customers)
        int cheat3= inputKey.indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found
        char k0, k1, k2, k3, k4, c0, c1, c2, c3, c4, s0, s1, s2, t0, t1, t2;

        boolean bFound1 = true; //found via typed input
        try {
          if (inputEmail.length() <6 || inputEmail.indexOf("@")==-1  || inputEmail.indexOf(".")==-1||inputKey.length() !=30 ) {
            bFound1 = false;
          } else {
            k0 = inputKey.charAt(24); //every 5th character in reverse
            k1 = inputKey.charAt(19);
            k2 = inputKey.charAt(14);
            k3 = inputKey.charAt(9);
            k4 = inputKey.charAt(4);
            c0 = inputEmail.charAt(0);
            c1 = inputEmail.charAt(1);
            c2 = inputEmail.charAt(2);
            c3 = inputEmail.charAt(3);
            c4 = inputEmail.charAt(4);
            if (c0 != k0 || c1 != k1 || c2 != k2 || c3 != k3 || c4 != k4 ) {
              bFound1 = false;
            }                
            s0=inputKey.charAt(25);
            t0 = str(inputEmail.length()).charAt(0);
            if (s0 != t0 ) {
              bFound1 = false;
            }
            if (inputEmail.length() >9) {
              s1=inputKey.charAt(26);
              t1 = str(inputEmail.length()).charAt(1);
              if (s1 != t1 ) {
                bFound1 = false;
              }
            }
            if (inputEmail.length() >99) {
              s2=inputKey.charAt(27);
              t2 = str(inputEmail.length()).charAt(2);
              if (s2 != t2 ) {
                bFound1 = false;
              }
            }
          }
        }
        catch(RuntimeException e) {
          bFound1 = false;
        };
        //1111e1111h1111c1111e1111m26000
        boolean bFound2 = true; //found via read from file
        String sKeyRead = lines[0];
        String sEmailRead = lines[1];
        try {
          sKeyRead = lines[0];
          sEmailRead = lines[1];
          if (sEmailRead.length() <5 || sEmailRead.indexOf("@")==-1  || sEmailRead.indexOf(".")==-1 || sKeyRead.length() !=30 ) {
            bFound2 = false;
          } else {
            k0 = sKeyRead.charAt(24); //every 5th character in reverse
            k1 = sKeyRead.charAt(19);
            k2 = sKeyRead.charAt(14);
            k3 = sKeyRead.charAt(9);
            k4 = sKeyRead.charAt(4);
            c0 = sEmailRead.charAt(0);
            c1 = sEmailRead.charAt(1);
            c2 = sEmailRead.charAt(2);
            c3 = sEmailRead.charAt(3);
            c4 = sEmailRead.charAt(4);
            if (c0 != k0 || c1 != k1 || c2 != k2 || c3 != k3 || c4 != k4 ) {
              bFound2 = false;
            } 
            s0=sKeyRead.charAt(25);
            t0 = str(sEmailRead.length()).charAt(0);
            if (s0 != t0 ) {
              bFound2 = false;
            }

            if (sEmailRead.length() >9) {
              s1=sKeyRead.charAt(26);
              t1 = str(sEmailRead.length()).charAt(1);
              if (s1 != t1 ) {
                bFound2 = false;
              }
            }
            if (sEmailRead.length() >99) {
              s2=sKeyRead.charAt(27);
              t2 = str(sEmailRead.length()).charAt(2);
              if (s2 != t2 ) {
                bFound2 = false;
              }
            }
          }
        }
        catch(RuntimeException e) {
          bFound2 = false;
        };

        if (cheat1 != -1 || cheat2  !=-1 || cheat3 !=-1) {
          sKey = "XCg8_XA@RA=yyN4cW4FD";
          bPaid=true;
          bRenewFree = false;
        } else if (bFound2) {//found via read from file
          sKey = sKeyRead;
          sEmail = sEmailRead;
          bPaid=true;
          bRenewFree = false;
        } else if (bFound1) { //found via typed input
          sKey = inputKey;
          sEmail = inputEmail;
          bPaid=true;
          bRenewFree = false;
          DisplayData("Valid License Key Entered! Thanks for supporting us!");
        }
      } else { //contents blank for some reason
        bRenewFree = true;  
        DisplayData("No license found, creating a free one.");
      }
    }
    catch(NumberFormatException ne) { 
      DisplayData("No license found, creating a free one.");
    }
  } else { 
    bRenewFree = true;
    DisplayData("No license found, creating a free one.");
  }

  if (bRenewFree) {
    sKey = "Free Key"; //this overwrights any incorrect bullshit anyone types in.
    sEmail = "CylinDraw@gmail.com";
    DisplayData ("~Free license found. We hope you enjoy the free version of our product!~");
    DisplayData ("~To enable speed control, please enter a valid key in the help menu.~");
  }
  bTerms = true;
  if (!bTerms) {
    String termsPath = sketchPath(); 
    termsPath = termsPath + "/system/CYLINDRAW_TERMS_OF_USE.pdf"; 
    launch(termsPath); 

    String title ="TERMS OF USE PROMPT";
    Object[] message6 = {
      "Please see the CYLINDRAW_TERMS_OF_USE.pdf that was provided to you along with the CylinDraw Control package. ", 
      "Clicking OK confirms that you have read and agree to the end user license agreement. ", 
      "(File saving will be disabled until this is complete.)", 
      "You may also find the latest copy available on www.CylinDraw.com", 
    };

    JFrame frame73 = new JFrame(title);  //Only need to call this if there is more than one frame i think
    frame73.setVisible(true);
    frame73.toFront();
    int option = JOptionPane.showConfirmDialog(null, message6, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
    if (option == JOptionPane.OK_OPTION) { 
      bTerms = true;
    } //this is the only way for this to be set to true for the first time
    if (option == JOptionPane.CANCEL_OPTION) { 
      DisplayData(">User Clicked Cancel.<");
      bTerms = false;
    }     
    frame73.setVisible(false);
    frame73.toBack();
  }

  if (bTerms) {
    sKey = "XCg8_XA@RA=yyN4cW4FD"; //This line negates the entire point of licensing. It does make the first time user aggree to pdf but it only asks them on boot until they agree.
    String storedLicense =sKey + "\n"+ sEmail +"\n"+
      "Use of this license constitutes explicit acceptance of the end user license agreement per CYLINDRAW_TERMS_OF_USE.pdf \nPlease DO NOT redistribute CylinDraw Control software or your license keys in any form. \nVisit www.CylinDraw.com to get the latest release. \n  " ;   
    String licenseName = ("system/License.txt");  
    String[] storedLicenseList = split(storedLicense, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
    saveStrings(licenseName, storedLicenseList);
  }
}

long currentTime() {
  return (System.currentTimeMillis());
} 

void logHold(String log) {//append a string to the soft log
  sLog = sLog + log;
}

void logWrite(boolean bAppend) {//commit softlog to hardlog. (without append it will fully overwright but it will take longer.)

  String sLogTemp=" ";
  String[] sLogArray;
  if (bAppend) {
    sLogArray = loadStrings("system/LogRunMode.txt");
    sLogTemp = join(sLogArray, "\n");
  } else {
    sLogTemp="Note: for this log to properly record data you must exit the program using the EXIT button to give it the chance to log the data. \n  ";
    sLogTemp=sLogTemp+sVersion+"\n";
  }
  sLog = sLogTemp +sLog+ "Current Time in ms: " + nf(currentTime(), 13, 0)+"\n";

  sLogArray = split(sLog, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
  saveStrings("system//LogRunMode.txt", sLogArray);  
  sLog = " ";
}
void logRead() {//overwrite softlog with hardlog  
  sLog ="";
  String[] sLogArray = loadStrings("system/LogRunMode.txt");
  sLog = join(sLogArray, "\n");
}

void queCmd(String sWrite, boolean bCut) {//add to top of stack (myPort command). Que will auto empyt
  if (bCut) {
    for (int step=iCmdMax; step>iCmdIndex; step--) {
      cmdQue[step] = cmdQue[step-1];
    }
    cmdQue[iCmdIndex] = sWrite;
    //iCmdMax++;
  } else {
    if (iCmdMax<500) {
      cmdQue[iCmdMax] = sWrite;
      iCmdMax++;
    }
  }

  //if (!bSent ){
  queRun();
}

void queRun() {
  if (checkComplete()) { //very important to check this here to keep commands+ responces in sync. Because the user can click buttons at any time while commands are being communicated
    bOKtoSend = true;
  }
  if (bOKtoSend && cmdQue[iCmdIndex] !=null ) { //bsent coordinates the turn taking of sending/recieving
    //bSent = true this var doesnt do its job...
    myPort.write(cmdQue[iCmdIndex]);
    if (cmdQue[iCmdIndex].contains("Z10") == true) { 
      bPenUp =true;
    }
    if (cmdQue[iCmdIndex].contains("Z0") == true) { 
      bPenUp =false;
    }
    bOKtoSend = false;
    logHold(cmdQue[iCmdIndex]);
    cmdQue[iCmdIndex]="";
    iCmdIndex ++;
  }
  if (iCmdIndex >= iCmdMax) {
    iCmdIndex = iCmdMax= 0;
    cmdQue = new String[500];
  }
  if (myPort == null) {
    iCmdIndex = iCmdMax= 0;
    cmdQue = new String[500];
    return;
  }
}
