import controlP5.*;
import java.awt.event.KeyEvent;
import javax.swing.JOptionPane;
//import processing.serial.*;
import java.io.*;
import javax.swing.JFrame;

import java.awt.Color;
ControlP5 gui;

Button buttonViewSVG;
Button buttonLoadFile;
Button buttonReset; 
Button buttonHelp;
Button buttonExit;
Slider sliderDist;
Button buttonDistUp;
Button buttonDistDown;
Button buttonShowLift;
Button buttonShowCut;
Button buttonShowHeat;

String sVersion  =  "Version: 2.00 Viewer @ CylinDraw Control Suite.";

String[]  lines;
String[]  linesRaw;

int iLine;//idk?
float iprop;//proportionof way though i range 

float imgXMax;
float imgYMax;

int xWindow = 1200;
int yWindow = 800; 

int command;
float plotScale = 2;
boolean bFollowMouse = false;
float yShift = yWindow-20; // distance from the top of the display window to show objects. (Didnt use height because its not initialzed at this point
float xShift = 20; // distance from the left of the display window to show objects
float xValue=0, yValue=0, zValue=0.2, lastX = xShift, lastY = yShift, offsetX=0, offsetY=0;
float lastXvalue = 0, lastYvalue = 0;
float iValue = 0, jValue = 0;
boolean refresh = true, drawZero = true, drawLift = true, drawCut = true, drawArrow = false, bReset = false, drawHeat = false;   ///SHOULD ADD A BUTTON TO TOGGLE MOTION LINES WITH DRAWLIFT
boolean terminateLine = false, incrementalIJ = true;
boolean inches = false;
boolean singleStep = false; //apparently prints the code as you scan it
color track[] = {color(0, 0, 0), color(170, 0, 0), color(0, 192, 0), color(40, 40, 255) };
Color wild;
color wild2;
int trackColour = 0, farToDraw = 3, lineLimitLow =0, lineLimitHigh =3;
float inTOmm = 25.4;
File file = null; 
String filePath ="";
String loadPathCode = "";

float mouseValueX =0;
float mouseValueY =0;


int timeEst = 0;
boolean proceed = false;

PImage logoHeaderImg;

boolean allowLoad = false;

void settings() {
  size(displayWidth-50, displayHeight-50);//, P3D);
  //size(xWindow, yWindow);//, P3D); 
  // surface.setSize(xWindow, yWindow);  
  logoHeaderImg = requestImage("\\system\\logoViewer.png");//loadImage("logo.png"); //Header Image
}


void setup() {
  cursor (HAND);
  if (xWindow >displayWidth) {
    xWindow = displayWidth-50;
  }
  if (yWindow >displayHeight) {
    yWindow = displayHeight-50;
  }
  frame.setSize(xWindow, yWindow); 

  surface.setResizable(true); 
  surface.setLocation(displayWidth/2-width/2, displayHeight/2-height/2); //  surface.setLocation(0,0);

  //background(0,0);
  background(160, 219, 232);
  stroke(255);//white

  //CHECK temp for contents on boot.
  // delete temp on exit.
  //else see select input
  //  Other program needs to writte thefilepath to a text file called TEMP 
  
  String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
  newPath = newPath + "\\system\\temp.JOB.svg";   //.replace("CylinDrawJobCreator", "CylinDrawViewer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
  File fileDefault = new File(sketchPath(newPath));
  

   if (fileDefault.exists()) {
     println(newPath);
     println("Loading default file");//(load instructions gcode?)
     fileSelected(fileDefault);
     
     //bReset=true;
     //refresh=true;
     //allowLoad = true;
    // loadPathCode = fileDefault.getAbsolutePath();
     proceed = true;//proof that a file is loaded.
   }
   setButtons();
  
  
  surface.setTitle("CylinDraw -VIEWER-"); 
  cursor(HAND);
}


void draw() {
  
  if (bReset){
        yShift = yWindow-20; // distance from the top of the display window to show objects. (Didnt use height because its not initialzed at this point
        xShift = 20; // distance from the left of the display window to show objects
        xValue=0; yValue=0; zValue=0.2; lastX = xShift; lastY = yShift; offsetX=0; offsetY=0; iValue = 0; jValue = 0;
        plotScale =2;bFollowMouse = false; bReset = false;
        background(160, 219, 232); //clears the view
  }

  if (proceed == true) {
    if (!allowLoad){ //reloading the gcode is intensive but necessary if changing the sliderDist
      allowLoad = true; 
      loadGcode();
    }

    //   lines = loadStrings("arc5.gcode");       // auto load for development comment out above line
    //   lines = loadStrings("arc6.gcode");       // auto load for development 
    //   lines = loadStrings("CircleTest.gcode");       // auto load for development
    if (refresh) {
      yWindow = height; 
      xWindow = width;
      background(160, 219, 232);

      trackColour = 0; // restore default colour for tracks
      lastX = xShift-offsetX; 
      lastY = yShift-offsetY; // clear out last values

      if (drawZero) draw_Zero();
      scanGcode();  // draw the file
    }
    if (bFollowMouse) {

      xShift =mouseX-(width*plotScale/20)-(xValue/2)*plotScale+offsetX;
      
      yShift = yValue*plotScale/2+mouseY+50*plotScale-yValue/2+offsetY; // distance from the top of the display window to show objects. (Didnt use height because its not initialzed at this point

      //xShift -=width/2-mouseX;
      //yShift -=height/2-mouseY;
      //  xShift = 0; 
      //  yShift = mouseY- ( height/2 - (yValue*plotScale));
      //xShift = mouseX - (xValue/plotScale)/2;
      // bFollowMouse = !bFollowMouse;
    }else{
      refresh = false;
    }
  }
  
  imageMode(CENTER);
  float downscale = 2.2;   int imgpixelwidth = 1690;int imgpixelheight = 248;
   image(logoHeaderImg, width/2, 45, imgpixelwidth/2/downscale, imgpixelheight/2/downscale);// 500, 500/11.73); //logo header image. The 500 sets the width & the 11.82 number is based on the image size so it has the correct aspect ratio & size when loaded.
  
  if (xWindow != width){ // if  frame.setSize(xWindow, yWindow);
      setButtons();
      xWindow = width;
    }else if (yWindow != height){
      setButtons();
      yWindow = height;
  }
}//end of DRAW





void draw_Zero() {  // draw the zero axis
  stroke(255, 255, 0);
  line(xShift, yShift, (xShift + xWindow)*plotScale, yShift);//X axis line
  line(xShift, yShift, (xShift), yShift - (yWindow)*plotScale); 
  // put tick marks on
  for (int i = 0; i < xWindow; i++) { //X AXIS
    line(xShift + (float( i) * plotScale), yShift, xShift +( float(i) * plotScale), yShift - 3);
    if ((i % 10) == 0) line(xShift + (float( i) * plotScale), yShift, xShift +( float(i) * plotScale), yShift - 7);
  } 
  for (int i = 0; i < yWindow; i++) { //Y AXIS
    line(xShift, yShift - (float(i)* plotScale), xShift + 3, yShift - (float(i)* plotScale) );
    if ((i % 10) == 0) line(xShift, yShift - (float(i)* plotScale), xShift + 7, yShift - (float(i)* plotScale) );
  }
}


void   loadGcode() { //HAPPENS EVERY CYCLE, 
  lines = linesRaw = loadStrings(loadPathCode);
  lineLimitHigh = lines.length - 1;
  for (int lineCount = 0; lineCount<lines.length - 1; lineCount++) {    // PARSE gcode & remove everything upto and including "<!-- BEGIN"
    if (lines[lineCount].contains("G0") || lines[lineCount].contains("G28")) {
        lineLimitLow = lineCount; 
        break;
    } 
  }
  //farToDraw = lines.length - 1; //lineLimitHigh = lines.length - 1 is the MAX value of fartodraw, min value of lets say 100
  incrementalIJ = true;
  trackColour = 0;
}


void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    //lineLimitLow = 0;
    proceed = false;
    allowLoad = false; //allows for loading gcode during draw
    
    println("User selected " + selection.getAbsolutePath()); //display the user selected file path
    delay(10);
    loadPathCode = selection.getAbsolutePath();
    
    loadGcode();
    /*
    String[] slines =  loadStrings(loadPathCode); // Load file & count number of lines
    lineLimitHigh = slines.length - 1;
    timeEst =    + slines.length *2/20/60;  // estimate 3 sec per 20 lines, 60 seconds per minute    
    println("Estimated Drawing Time is " + timeEst  + " minutes"); //display the user selected file path
*/
    proceed = true;//proof that a file is loaded.
    setButtons();
    
  } 
}


void gatherCommand(int i, int j) {   // gets the next paramater from the line
  float x, y, z;
  switch(lines[j].charAt(i)) {
      case'M': //Now its 'M0 '//QQ  this has to be a SINGLE letter that it recognizes by and thats why its a single Q.           
          Color wild = new Color(int(getValue(j, i+2)));  //grabbing the color by paracing the text.
          //this is correct>>
          if (!drawHeat){
            wild2 = color(wild.getRGB()); //extracting usable RGB color type (system doesnt like to do this & previous step in one step so it is seperated here)
            ///////wild2 = color(255* iprop,0,(255 * (1-iprop)));
          }
         
          
          //print(wild);  this code works, I just dont want toi use it normally
          //println(" hex color is " + wild2); 
          //int red = wild2 & (0xFF <<16);  
          //int green = wild2 & (0xFF <<8); 
          //int blue = wild2 & 0xFF;
          //println("rgb: " + red +" "+ green +" "+ blue );
      
          break;
      case'G':
          command = int(getValue(j, i)*10);
          if (command < 900) command /= 10;     //sets command = command/10         
          break;
      case'X':
          xValue = getValue(j, i);
          if (inches) xValue *= inTOmm; 
          if (xValue > imgXMax) { 
            imgXMax = xValue;
          } 
          break;
      case'Y':
          yValue = getValue(j, i);
          if (inches) yValue *= inTOmm; 
          if (yValue > imgYMax) { 
            imgYMax = yValue;
          } 
          break;
      case'Z':
          zValue = getValue(j, i);
          if (inches) zValue *= inTOmm; 
          break;
      case'I':
          iValue = getValue(j, i);
          if (inches) iValue *= inTOmm; 
          break;
      case'J':
          jValue = getValue(j, i);
          if (inches) jValue *= inTOmm; 
          break;
      case';':
      case'(':
          terminateLine=true;
          break;  
      default:
          break;
  }  // end of switch structure               
  if (lines[j].length() -1  <= i) {
    // println("found one");
  }
}//end of gathercommand


void scanGcode() {
  boolean bInvalid = true; //have to prove that the file has valid gcode.
  for (int lineCount = 0; lineCount<lines.length - 1; lineCount++) {    // PARSE gcode & remove everything upto and including "<!-- BEGIN"
    //coul could parse it here for the cup dimensions etc...FUTURE PLANS
    if (lines[lineCount].contains("G0") || lines[lineCount].contains("G28")) {
        bInvalid = false;
        iLine = lineCount; 
        break;
    } 
  }
  if (bInvalid) {
      if (loadPathCode.contains(".JOB.svg")) {
         Object[] message2 = {
           " File failed to load: " + loadPathCode,
           "Something went wrong!",
           "It appears you have loaded the correct file type, ",
           " but for some reason it is not properly formatted!",
           "Please remake the file using the CylinDrawJobCreator",
           "Sorry for the inconvience.",
         };
         frame.setLocation(xWindow/2,yWindow/2);
         JOptionPane.showMessageDialog(frame, message2, "Error...", JOptionPane.ERROR_MESSAGE);

      }else if (loadPathCode.contains(".svg")) {
          Object[] message2 = {
           " File loaded: " + loadPathCode,
           "This file has not been made into a drawable job yet. ",
           "To create a '.JOB.svg' drawing file import the file you just tried to open with CylynDraw JobCreator",
           "For now you can still view it as a regular svg, opening now...",
         };
         frame.setLocation(xWindow/2,yWindow/2);
         JOptionPane.showMessageDialog(frame, message2, "Notice", JOptionPane.INFORMATION_MESSAGE);
         launch(loadPathCode);
        // PShape thing = loadShape(loadPathCode);
         //shape(thing,0,0); //playing with embedding the original image in for a preview.   
      }

      print("Invalid File");
      proceed = false; 
      bReset = true;      
      return;  
  }
  
  
  //if VALID proceed
  for (int j = iLine; j <= farToDraw; j++) {
        iprop = abs(float(lineLimitHigh-lineLimitLow -j)/(lineLimitHigh-lineLimitLow));   //proportion of the way though, from 1 to 0, for displaying slice order
          //(RGB range)blue to red (0,0,255) to (255,0,255) to (255,0,0)
         // (iRange -iprop)/irange  = how far through we are
         if (drawHeat){
           wild2 = color(255* iprop,0,(255 * (1-iprop)));
           // if (iprop<farToDraw/3){ wild2 = color(255* iprop*3,0,(255 * (1-iprop*3)));}
            //else if (iprop>farToDraw/3 && iprop<farToDraw*2/3){ wild2 = color(0,(255 * (1-iprop)),(255 * (iprop)) );}
            //else if (iprop>farToDraw*2/3 && iprop<farToDraw){ wild2 = color( (255 * (1-iprop)),(255 * (iprop)),0 );}

         }
        //print(1-iprop + "    " );
        //  println(wild2);
          
    //     println(lines[j]);  // remove comments for fault finding as it printes the whole recieved file
    if (singleStep)println(lines[j]);
    if (lines[j].length() > 0) {
      terminateLine = false;
      lastXvalue = xValue;
      lastYvalue = yValue;
      if (!(( lines[j].charAt(0) == '(') || (lines[j].charAt(0) == ';')) ) {    // if not a comment
        for (int i = 0; i < lines[j].length(); i++) {
      
          
          gatherCommand(i, j);
          if (terminateLine) i = lines[j].length();   // abandon the est of the line because we found a ( or ; comment
        }  // end of i for loop - looked at all the charactors in the line
        drawCommand(); // draw it using the parameters gathered
      } else { // it is a comment
      }
    } // end of if not a blank line
  }  // end of j for loop
}//end of scangcod


float getValue(int j, int i) {
  String element = "";
  boolean stop = false;
  int k=1;
  element = "";             
  while ( (i+k) < lines[j].length() && !stop) {
    if (((int)lines[j].charAt(i+k) >= 0x30) && ((int)lines[j].charAt(i+k) <= 0x39) || ((int)lines[j].charAt(i+k) =='.') || ((int)lines[j].charAt(i+k) =='-') || ((int)lines[j].charAt(i+k) == ' '))
      element = element + lines[j].charAt(i+k); 
    else stop = true;
    k++;
  }
  return(Float.valueOf(element).floatValue());
}


void drawCommand() {  // draw based on globle values gathered earler
  noFill();
  stroke(128);
  float xPlot = xShift + (xValue * plotScale);
  float yPlot = yShift - (yValue * plotScale);
  float iPlot = xShift + (iValue * plotScale);
  float jPlot = yShift - (jValue * plotScale);

  if (incrementalIJ) {
      iPlot = xShift + ((iValue+lastXvalue) * plotScale);
      jPlot = yShift - ((jValue+lastYvalue) * plotScale) ;
  }
  if ( ((zValue > 0) && drawLift) || ((zValue <= 0) && drawCut) ) {
    
    if (zValue <= 0){stroke( wild2); 
    }else {stroke(255); }  //// track[trackColour])
    
    float weight = plotScale/5.5;
    if( weight<1){weight =1;}      
    strokeWeight(weight);

    switch(command) {
        case 0:
               dline(lastX, lastY, xPlot, yPlot); //if (lastX != xShift && lastY != yShift){  
            lastX = xPlot;
            lastY = yPlot;
            break;
        case 1:
            dline(lastX, lastY, xPlot, yPlot); 
            lastX = xPlot;
            lastY = yPlot;
            break;
        case 2:
            // stroke(0,255,0);  // draw a line as well as the arc
            // dline(lastX, lastY, xPlot , yPlot); // uncomment to debug
            // stroke(255,0,0);
            drawArc(iPlot, jPlot, lastX, lastY, xPlot, yPlot, true);  // clockwise arc
            // stroke(0);
            lastX = xPlot;
            lastY = yPlot;
            break; 
        case 3:
            // stroke(0,0,255);  // draw a line as well as the arc
            // dline(lastX, lastY, xPlot , yPlot);  // uncomment to debug
            // stroke(0,196,255);   
            drawArc(iPlot, jPlot, lastX, lastY, xPlot, yPlot, false);  // anti clockwise
            // stroke(0);
            lastX = xPlot;
            lastY = yPlot;
            break;
        case 20: // use inches
            inches = true;
            break;
        case 21: // use mm
            inches = false;
            break;
        case 901:
            incrementalIJ = false;
            println("in JK absoloute mode");
            break;
        case 911:
            incrementalIJ = true; //  println("in JK relative mode");
            break;
        case 912:
        case 913:
        case 914:
        case 915:
            trackColour = command - 912; // set the colour of the track
            break;
    }
  } else {
      lastX = xPlot;
      lastY = yPlot;
  }
  command = -1; // wipe out command
}//end of drawCommmand


void dline(float x1, float y1, float x2, float y2) {
  if (drawArrow && ( abs(x1 - x2) > 0.1 || abs(y1-y2) > 0.1) ) {    // don't draw the arrow if it is a null line
    arrow(int(x1), int(y1), int(x1+(x2-x1)/2), int(y1+(y2-y1)/2) );
    line( (x1+(x2-x1)/2), (y1+(y2-y1)/2), x2, y2 );
  } else line(x1, y1, x2, y2);
}

void arrow(int x1, int y1, int x2, int y2) {
  line(x1, y1, x2, y2);
  pushMatrix();
  translate(x2, y2);
  float a = atan2(x1-x2, y2-y1);
  rotate(a);
  line(0, 0, -8, -8);
  line(0, 0, 8, -8);
  popMatrix();
} 


void drawArc(float xC, float yC, float xS, float yS, float xF, float yF, boolean cw) { // draw a helical arc
  //    stroke(255,128,196); // draw a line from start point to center
  //    line(xC,yC, xS, yS); // uncomment to debug
  //    stroke(255,0,0);  
  int smoothness = 16;
  float x=xS, y=yS;
  float toX=0, toY=0, theta;
  float radiusStart = sqrt( sq(abs(xC - xS)) + sq(abs( yC - yS)) );
  float radiusFinish = sqrt( sq(abs(xC - xF)) + sq(abs( yC - yF)) );
  ;
  float deltaRadius =  (radiusFinish - radiusStart) / smoothness;
  float thetaStart = atan2( yS-yC, xS-xC);
  float thetaFinish = atan2( yF-yC, xF-xC);
  float deltaTheta = thetaStart - thetaFinish;
  if (cw) deltaTheta =  thetaFinish - thetaStart;
  if (deltaTheta < 0 ) { 
    deltaTheta = (TWO_PI + deltaTheta);
  }
  if (deltaTheta == 0) deltaTheta = TWO_PI;
  deltaTheta /= smoothness;
  theta = thetaStart; 
  for (int i = 0; i <= smoothness; i++) {
    toX= xC + ( radiusStart ) * cos(theta);
    toY= yC + ( radiusStart ) * sin(theta);
    line(xS, yS, toX, toY); 
    xS = toX; 
    yS = toY;  
    if (cw) theta += deltaTheta; 
    else theta -= deltaTheta;  // for plot direction
    radiusStart += deltaRadius;
  }
  //    stroke(255,128,0);   // deaw a circle round the centre and line to end point
  //    arc(xC,yC, 6, 6, 0, TWO_PI); // uncomment to debug
  //    line(xC,yC, xF, yF);
}


void mouseWheel(MouseEvent event) {
  float wheelcount = event.getCount();
  plotScale = plotScale + wheelcount/6; 
  refresh = true;
}

void mousePressed() {
  // mouseValueX=-abs(mouseX-lastX);
  // mouseValueY=-abs(mouseY-lastY);
  if (mouseY>105){
    bFollowMouse = !bFollowMouse;
  }
  refresh = true;
} 


void keyPressed() {
  refresh = true;
 /*
 if(key == '1') { 
 if(farToDraw <= lines.length - 2)farToDraw++; 
 refresh = true;
 if(singleStep) { // skip over comments and blank lines
  while(( lines[farToDraw].charAt(0) == '(') || (lines[farToDraw].charAt(0) == ';') && (farToDraw != lines.length - 1) )farToDraw++; 
 }  
 } 
 if(key == '2') { 
 if(farToDraw > 3)farToDraw--; 
 refresh = true;
 }
 */  
  //if (key == ESC) { key = 0; buttonExit();} dont want hesitation on this program
  if (keyCode == LEFT) {
    xShift=xShift-5;
    offsetX=offsetX-5;
  }
  if (keyCode == RIGHT) {
    xShift=xShift+5;
    offsetX=offsetX+5;
  }
  if (keyCode == UP) { 
    yShift=yShift-5;
    offsetY=offsetY-5;
  } //(float tx,float ty) This centers the drawing
  if (keyCode == DOWN) {
    yShift=yShift+5;
    offsetY=offsetY+5;
  }
} //end of void Keypressed()




void setButtons(){
   if (gui != null) gui.dispose();
   gui = new ControlP5(this);
 
  //gui.addScrollableList("1","22");
   PFont p = createFont("Helvetica",11); 
  ControlFont font = new ControlFont(p);
  //HEADER ROW ----------------------------------------------------

    int Xpos =5;  int Ypos = 5;  int xSpacing = 5; int ySpacing = 5; int sizeX =74; int sizeY =40; 
  buttonLoadFile  = gui.addButton("buttonLoadFile").setCaptionLabel("Load File").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
      Xpos = Xpos + sizeX + xSpacing;
  buttonViewSVG  = gui.addButton("buttonViewSVG").setCaptionLabel("Details").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();
    Xpos = Xpos + sizeX + xSpacing;
  buttonShowLift  = gui.addButton("buttonShowLift").setCaptionLabel("Hide/Travel").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();
    Xpos = Xpos + sizeX + xSpacing;
  buttonShowCut  = gui.addButton("buttonShowCut").setCaptionLabel("Hide/Draw").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();
    Xpos = Xpos + sizeX + xSpacing;
  buttonShowHeat  = gui.addButton("buttonShowHeat").setCaptionLabel("HeatMap").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();
    Xpos = Xpos + sizeX + xSpacing;
       
 sizeX =110;
 
  Xpos =35; Ypos = Ypos + sizeY + ySpacing+30; sizeY = sizeY/2;
  sliderDist = gui.addSlider("sliderDist").setSize(width -Xpos*2, sizeY).setCaptionLabel("Progress View").setPosition(Xpos, Ypos).setRange(lineLimitLow, lineLimitHigh).setValue(lineLimitHigh).setFont(font).hide();
    gui.getController("sliderDist").getCaptionLabel().align(CENTER,CENTER); 

    Xpos = 5; sizeX =25;
  buttonDistDown = gui.addButton("buttonDistDown").setCaptionLabel(" - ").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();

    Xpos = width-5-sizeX;
  buttonDistUp = gui.addButton("buttonDistUp").setCaptionLabel(" + ").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();
    


   Xpos =5;  Ypos = 5;  xSpacing = 5; ySpacing = 5; sizeX =110; sizeY =40; 
   Xpos = width - xSpacing - sizeX;// farthest right button
  buttonExit = gui.addButton("buttonExit").setCaptionLabel("Exit Program").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    Xpos = Xpos - sizeX - xSpacing;
  buttonHelp = gui.addButton("buttonHelp").setCaptionLabel("HELP").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); //hiding because its not in use right now.
    Xpos = Xpos - sizeX - xSpacing;
  buttonReset = gui.addButton("buttonReset").setCaptionLabel("Reset View").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).hide();
    Xpos = Xpos - sizeX - xSpacing;

  if (proceed == true){
    buttonViewSVG.show(); buttonShowLift.show();buttonReset.show();sliderDist.show();buttonShowCut.show();buttonDistUp.show();buttonDistDown.show();buttonShowHeat.show();
  }else {
        buttonViewSVG.hide(); buttonShowLift.hide();buttonReset.hide();sliderDist.hide();buttonShowCut.hide();buttonDistUp.hide();buttonDistDown.hide();buttonShowHeat.hide();
  }
   refresh = true;
}
 
void buttonLoadFile(){
      bFollowMouse = false;
      File file = null; 
      JFrame frame2 = new JFrame("Input Dialog");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
      frame2.setVisible(true);
      frame2.toFront();
      //frame2.setAlwaysOnTop(true);
      frame2.setLocation(xWindow/2,yWindow/2);
      selectInput("Select a '.JOB.svg file to view: ", "fileSelected", file); //selectInput(prompt, callback, file)  DO NOT CHANGE the phrase "fileSelected". It it not just text but returns a call to a function!
      frame2.setVisible(false);
      frame2.dispose();
      refresh = true;
}

void buttonReset(){
  bFollowMouse = false;
  bReset = true; 
  sliderDist(lineLimitHigh);
  refresh = true;
}


void buttonExit(){
  bFollowMouse = false;
  String title ="Exit program?";
  String message = "Are you sure you want to exit the program?";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  //frame3.setAlwaysOnTop(true);
  frame3.setLocation(xWindow/2,yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ exit();  }
  if (option == JOptionPane.CANCEL_OPTION){  
    //DisplayData(">User Clicked Cancel.<");  
      frame3.setVisible(false);
      frame3.toBack();
      frame3.dispose();
  }
  refresh = true;
}//end of ButtonExit


void buttonHelp(){
      String title ="Help Window";
      JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
      frame3.setVisible(true);
      frame3.toFront();
     // frame3.setAlwaysOnTop(true);
      frame3.setLocation(xWindow/2,yWindow/2);
      Object[] message2 = {
         sVersion,
         " INSTRUCTIONS: ",
         "  This program lets you to view SVG files so you can see the detailed movements of the CylinDraw tool.",
         "  1. Begin by pressing the 'LOAD SVG' button.",
         "      -If you select a '.JOB.svg' file then that is a drawable and you can view the strokes here.",
         "      -If you select a '.svg' file then this program will open your default svg viewer. (We recommend google chrome.)",
         "  2. You can use your mouse to click-follow and zoom. You can also use keyboard arrow keys to move the view.",
         " For more info see www.CylinDraw.com",
         " File currently loaded is: " + loadPathCode,
       };
      JOptionPane.showMessageDialog(frame3, message2, "INSTRUCTIONS", JOptionPane.INFORMATION_MESSAGE);
      frame3.setVisible(false);
      frame3.toBack();
      frame3.dispose();
      refresh = true;
}


void buttonViewSVG(){
  bFollowMouse = false;
  if (proceed){
     launch(loadPathCode);
  }  
  refresh = true;
}


void sliderDist(int value){
  farToDraw = value;
  refresh = true;
}  
void buttonDistUp(){
  if (farToDraw <=lineLimitHigh-1){farToDraw++; sliderDist(farToDraw);sliderDist.setValue(farToDraw);  }
}
void buttonDistDown(){
  if (farToDraw >= lineLimitLow+1){farToDraw--;sliderDist(farToDraw);sliderDist.setValue(farToDraw);}
}



void buttonShowLift(){
  drawLift = !drawLift;
  refresh = true;
}

void buttonShowCut(){
  drawCut = !drawCut;
  refresh = true;
}
void buttonShowHeat(){
 drawHeat = !drawHeat;
 refresh=true;
}
