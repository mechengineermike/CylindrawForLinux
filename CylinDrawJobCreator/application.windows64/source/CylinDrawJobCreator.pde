////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//INITIALIZATIONS TAB
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import java.awt.event.KeyEvent;
import javax.swing.JOptionPane; //used for pop up windowsa
import geomerative.*;
import javax.swing.*; 
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import processing.svg.*;
import controlP5.*;
import processing.dxf.*;
import java.util.Arrays; //what does this do
import javax.swing.JButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.lang.System;

import java.awt.Color;
import java.awt.Dimension;
import javax.swing.JFrame;
import javax.swing.JPanel;


import javax.swing.JList;
import javax.swing.JScrollPane;

String sVersion  =  "Ver: 2.02 @ JobCreator CylinDraw Control Suite.";

ControlP5 gui;

boolean bPaid  = false;// has a license been found.
boolean bTerms  = false;// has the user agreed to the terms of use
String  sKey ="null"; //Key = XCg8_XA@RA=yyN4cW4FD
String  sEmail ="example@gmail.com"; //Key = XCg8_XA@RA=yyN4cW4FD

Button buttonSupport;
Button buttonProgConvert;
Button buttonProgCreate; 
Button buttonProgRun;
Button buttonHelp;
Button buttonExit;
Button buttonLoadSVG;
Button buttonUpdate;
Button buttonSave; 
Toggle toggleFill;
Button buttonRotateLeft;
Button buttonScaleUp;
Button buttonScaleDown;
Button buttonRotateRight;
Button buttonMoveLeft;
Button buttonMoveUp;
Button buttonMoveDown;
Button buttonMoveRight;
Toggle toggleMultiColor;
Toggle toggleOutline;

RShape mainShape;         //Shape using the geomarative library

RShape previewShape;      //Shape using the geomarative library
RShape previewShapeReset;      //Shape using the geomarative library
int fileSize =0; //size of input file in bytes. Used to prevent trying to load preview of enormous file.
boolean bFastPreview=false;//set to true to reduce laggy large files
int once =0; //makes everything faster and only truly loads the shape from file once, thereafter it copies that shape when needing to reload

String   sLog = " ";//for writing troubleshooting notes

PImage logoHeaderImg;

 int Progress = 0;
 int ProgressOld = 0;

//  USER INPUTS //All length units in mm
float cupDiaMin = 80.00; 
float cupDiaMax = 100.00; 
float cupHeight = 160.00;  //probable range 80 < H < 230
float stemHeight = 40.00;
float toolDia = .500; //could be anything here as it gets overwritten by whatever is in the settings file. 
//boolean overlap = false;
float fOverlap=50;//a non 50% overlap only used for depixelized svgs, otherwise it stays at 50(%)
//overlap only used for tradational SVGS
float xOverlap = 50.0000;//The percent overlap of fill lines to ensure that lines are dark & complete (20 means that a new fill line will overlap by 20%!!)   if it is 50 even it triggers a glitch in the library where it missses the center
float yOverlap = 50.0000;//The percent overlap of fill lines to ensure that lines are dark & complete (20 means that a new fill line will overlap by 20%!!)

boolean bBlkOutline = false; //option to add extra black outline at end of job
boolean bMultiColor = false;
boolean bFillDrawing = false; //default = false. This is the variable the user has control over.
int     cupType = 0; ///0=Cup, 1=Goblet, 2 = paper Other?
String sToolProfile="CupTool_LastUsed";
boolean bPathOptimize = true;

color  c0, c1;// c2;
color[]  colorArray;  //array of just the unique colors!
int    iChildCounter =0; int iChildCounterOld =0;
int    iMaxChildCounter =0;
int    iMaxNumColors = 0;
int    iMaxNumColorsOld = 0;
int    iColorIndex =0;
int    dataCounter = 0; //used for displaying the macimum number of liveData lines read.
float  timeEst = 0; //estimate job run time

float      yShift = 0; float xShift = 0; // distance from the left of the display window to show objects. User can shift image
float      plotxShift = 0; float plotyShift = 0;
int      iChuckGrip = 9; //length in mm of offset for baseline where chuck makes inaccessible
float    imageScaleAdjust = 0;
float    rotateAngle =0;
float    imageScale =1;//.15;   //scale for adjusting TRUE image size
float    plotScale = 1;///1.5*160/cupHeight;    // Scale just for adjusting the image **as displayed on screen only** .   If H is big then the plotscale need to be smaller. 
String   fileName = ""; // Name of the file to convert. (Ends up being the name of the working TEMP file)
String   fileNameOriginal = ""; // Name of the file to convert as it was originally  
String   destName = "";

String   filePath = ""; //full path

String   penUp= "G1 Z10 \n";    
String   penDown = "G1 Z0 \n";
boolean  penIsDown = false;
boolean  bLocallyMade = false;//was the impotedsvg file made via cylindraw depixelizer?
String   liveData = "";   //Used for displaying the latest commands sent/recieved
String   displayStatus =" "; 

float     Xmax = cupDiaMax*PI; //T axis maximum in mm 
float     Ymax = cupHeight;//H axis maximum in mm (USER INPUT)
//float[][] dotArrayX;
//float[][] dotArrayY;
//float[][] dotArrayColor;

boolean bExplicitExport = false;
//float dotArrayWidth = 0;   changed these to local variables
//int   numArrayCols = 0;
//float dotArrayHeight = 0;
//int   numArrayRows = 0;
//float shapeTopLeft;
//float shapeBottomRight;

boolean ignoringStyles = false; //if you wanted to ignore the layers & colors when displaying the svg as an image
boolean bSavingFile = false;      //REQUEST to save file
boolean bWasSavingFile = false;     //state of file saving
boolean loadTheShape = false;  //REQUEST to load the shape (Program will do this after user selects shape file)
boolean shapeLoaded = false;   //state of shape loading

File storedFile;
int  DisplayDataWindowY = 420;

ArrayList arrList;
ArrayList arrListLocal;

//ArrayList[] arrSubListsNull;// Faster than clearing each comopnent of atrray

float   iSpecleFactor =1;
int nve = 0; //sometihing to do with the number of frames shown per cycle
int speed = 10; //sometihing to do with the number of frames shown per cycle
int blending = MULTIPLY;         // DARKEST, MULTIPLY, BLEND , ...
int xWindow = 1200;
int yWindow = 900; 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SETUP TAB
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void settings() {
   size(displayWidth-50, displayHeight-50, P3D); //p3d necessary because we rotate the image & use camera, but need to switrch to p2d to render faster and more accurately!. Do not attempt fullscreen. // fullScreen(P3D);   //.setResizable(true);////surface.setSize(xWindow, yWindow);surface.setLocation(0,0);
   noSmooth(); //Not sure why I said yes but smooothing does slow things down... //YES WE DO WANT TO SMOOTH AFTER DONE TROUBLESHOOTING LATER
   logoHeaderImg = requestImage("\\system\\logoJobCreator.png");//loadImage("logo.png"); //Header Image
}


void setup(){
  hint(DISABLE_OPENGL_ERRORS);     hint(DISABLE_TEXTURE_MIPMAPS); //Both of these are meant to speed up rendering.   //hint(ENABLE_STROKE_PERSPECTIVE);
  //frame.setLocation(0,0);
  if (xWindow >displayWidth){xWindow = displayWidth-50;}
  if (yWindow >displayHeight){yWindow = displayHeight-50;}
  frame.setSize(xWindow, yWindow); //THIS CAN BE USED TO RESIZE THE WINDOW HERE by loading from a file
  frame.setLocation(displayWidth/2-width/2,displayHeight/2-height/2);  
  
  RG.init(this); //must remain in setup!
  RG.ignoreStyles(ignoringStyles);
  RG.setPolygonizer(RG.ADAPTATIVE);  //segmenterMethod - can be RG.ADAPTATIVE, RG.UNIFORMLENGTH or RG.UNIFORMSTEP segmentator type. 
     //ADAPTATIVE segmentator minimizes the number of segments avoiding perceptual artifacts like angles or cusps. Use this in order to have Polygons and Meshes with the fewest possible vertices.  This can be useful when using or drawing a lot the same Polygon or Mesh deriving from this Shape.
     //UNIFORMLENGTH segmentator is the slowest segmentator and it segments the curve on segments of equal length.  This can be useful for very specific applications when for example drawing incrementaly a shape with a uniform speed. 
     //UNIFORMSTEP segmentator is the fastest segmentator and it segments the curve based on a constant value of the step of the curve parameter, or on the number of segments wanted.  This can be useful when segmpointsentating very often a Shape or when we know the amount of segments necessary for our specific application.
     //RG.setPolygonizer(RG.UNIFORMSTEP); //uniformSTEP is faster, as long as its detailed enough on the curves then yay! (uniform length is the slowest!) might be a matter of slicing speed vs quality have to time.
     //RG.setPolygonizerAngle(0.065);// something to experiment with
  frame.setTitle("CylinDraw -CREATION MODE-"); 
  stroke(0);
  noFill();
  
  logWrite(false);//clear previous log when opening program
  
  checkLicense("","");
  loadSettings("");
  setButtons();
  
  String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
  newPath = newPath + "\\system\\temp.svg";   //.replace("CylinDrawJobCreator", "CylinDrawViewer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
  storedFile = new File(sketchPath(newPath));  
  if (storedFile.exists()) {
    DisplayData("Loading last file used......");//(load instructions gcode?)
    fileSelected(storedFile);
  }else{
     DisplayData("No local job file found to load..");
   }
  
  
  cursor(HAND);
  arrList= new ArrayList();

  mainShape = new RShape();
  previewShape = new RShape();
  colorArray = new color[101]; //(0-100 inclusive)
  frameRate(60);
  surface.setResizable(true);
  frame.setResizable(true);
}//End of Setup

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//DRAW-VIEWER SCALING-TAB
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw(){
    //yWindow = yWindow-1;
    //frame.setSize(xWindow,yWindow);

    beginCamera();
    camera(); //This sets translate commands to affect where the camera looks!
    translate(width/2-Xmax*plotScale/2+plotxShift, height/2+Ymax*plotScale/2-30+plotyShift); //Moves the CAMERA VIEW, NOT the object in space! 
    endCamera();

     background(160,219,232); //baby blue.  //if you dont reset background to zero every draw then the previous display wont clear!
    displayZero();// draws the zero axis lines on drawing space
    strokeWeight(0.5);
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //DRAW-Header & Background Texts
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    float y = -(plotScale * Ymax)-220;  float dy = 18;  //y is how far DOWN from the top of the box that the works start. dy is the spacing
    float xPosText = Xmax*plotScale/2-plotxShift;
    float yPosHeader = height/2-Ymax*plotScale/2-plotyShift-height+62;//+ moves UP
    strokeWeight(1);
    textSize(20);
    stroke(0); //blk header text
    fill(0);
    imageMode(CENTER);
    float downscale = 2.2;int imgpixelwidth = 2014;int imgpixelheight = 250;
    image(logoHeaderImg, xPosText, yPosHeader,imgpixelwidth/2/downscale,imgpixelheight/2/downscale);// 500, 500/11.73); //logo header image. The 500 sets the width & the 11.82 number is based on the image size so it has the correct aspect ratio & size when loaded.
    
    text(" ", 0, y); y += dy/2;    //  text(characters, x coordinate, y  coordinate)
    //line(-10000, yPosHeader+27, 10000, yPosHeader+27);y += dy-5; //this is the logo header line
    
    y=20; dy = 17; textSize(18);    //REDUCE TEXT SIZE & DY RIGHT HERE TO GET MORE COMMANDS VISIBLE ON SCREEN
    line(-10000, y+dy/3, 10000, y+dy/3);//y += dy;
    textAlign(CENTER);
    text(displayStatus,xPosText, y);y += dy+12; //this is stuck right below the plotted rectangle  
    fill(255);
    rectMode(CORNERS); //interprets the first two parameters of rect() as the location of one corner, and the third and fourth parameters as the location of the opposite corner.
    DisplayDataWindowY = int(height-680-2*plotyShift); //plotyShift //rect(xPosText -500, y-dy,xPosText+500,y+dy*20); //live stream system msg box window
    rect(xPosText -500, y-dy,xPosText+500,y-dy +1000);//DisplayDataWindowY-(y-dy)); //live system msg box window/ (height/2+Ymax*plotScale/2-30+plotyShift)-100);  //
    fill(0);
    textAlign(LEFT);
    text("--System Messages--", xPosText-470, y); y += dy/5;
    textAlign(LEFT);
    textSize(14);
    text(liveData, xPosText-470, y);
    
    fill(255); stroke(255); //must call before drawing the rectangle//white cup background
    rectMode(CORNERS); //interprets the first two parameters of rect() as the location of one corner, and the third and fourth parameters as the location of the opposite corner.
    rect(0, 0, Xmax*plotScale, -Ymax*plotScale); //BOUNDING BOX OF IMAGE. Y has to be invered because processing operates with y = 0 at the top!!
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //DRAW-Background Display Window- 
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    if (cupType ==0 || cupType ==2) { 
      fill(100); stroke(100);  strokeWeight(1); // draw polygon 
      beginShape();//rIGHT oFF LIMITS scpae
      vertex((cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI, 0); vertex(Xmax * plotScale,-Ymax* plotScale); vertex(Xmax * plotScale,0);
      endShape(CLOSE);
      beginShape();// LEFT OFF LIMITS TRIANGLE
      vertex( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI,0); vertex(0,-Ymax* plotScale); vertex(0,0);
      endShape(CLOSE);
      
      stroke(255, 100, 100); //strokeWeight(2); //red boundary line
      line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI,0,0,-Ymax* plotScale); //left anlgledline
      line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI, 0, Xmax * plotScale,-Ymax* plotScale); //right angled line
      
      rectMode(CORNERS);fill(100); //interprets the first two parameters of rect() as the location of one corner, and the third and fourth parameters as the location of the opposite corner.
      rect(0, 0, Xmax*plotScale, -iChuckGrip*plotScale); //BOUNDING BOX OF OFF-LIMIT. 
      if (cupType ==0){ 
        stroke(255, 100, 100); strokeWeight(2); //chuck boundary line
        line(0, -iChuckGrip*plotScale, Xmax* plotScale, -iChuckGrip*plotScale); //long horizontal line from x = 0 to x = xMax
        stroke(100, 100, 255);// strokeWeight(2); //BLUE boundary line
        line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/3* plotScale,0,(cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI-(cupDiaMin*PI/3* plotScale), 0 ); //bottom blue line
        line( 0+cupDiaMax*PI/3* plotScale,-Ymax* plotScale, Xmax * plotScale-(cupDiaMax*PI/3* plotScale),-Ymax* plotScale ); //top blue line
        //line( Xmax* plotScale/2,0,Xmax* plotScale/2,-Ymax* plotScale); //Vertical Center Line
        line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/3* plotScale,0,0+cupDiaMax*PI/3* plotScale,-Ymax* plotScale); //left anlgledline
        line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI-(cupDiaMin*PI/3* plotScale), 0, Xmax * plotScale-(cupDiaMax*PI/3* plotScale),-Ymax* plotScale); //right angled line
      }
    }else{ //draw a wineglass stem //draw goblet
        fill(100); stroke(100);  strokeWeight(1); // draw polygon 
        beginShape();//rIGHT oFF LIMITS scpae
        vertex((cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI, 0); vertex(Xmax * plotScale,-Ymax* plotScale); vertex(Xmax * plotScale,0);
        endShape(CLOSE);
        beginShape();// LEFT OFF LIMITS TRIANGLE
        vertex( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI,0); vertex(0,-Ymax* plotScale); vertex(0,0);
        endShape(CLOSE);
      
       rectMode(CORNERS);fill(100); //interprets the first two parameters of rect() as the location of one corner, and the third and fourth parameters as the location of the opposite corner.
       rect(0, 0, Xmax*plotScale, (-stemHeight)*plotScale); //BOUNDING BOX OF OFF-LIMIT.//-0.25*Ymax
       stroke(255, 100, 100); strokeWeight(2); //red boundary line
       line(0, -iChuckGrip*plotScale, Xmax* plotScale, -iChuckGrip*plotScale); //chuck boundary long horizontal line from x = 0 to x = xMax
       line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI,0,0,-Ymax* plotScale); //left anlgledline
       line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI, 0, Xmax * plotScale,-Ymax* plotScale); //right angled line
       stroke(100, 100, 255); //strokeWeight(2); //BLUE boundary line
       line( Xmax/2*plotScale,-1,((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/4* plotScale,-1); //base left
       line( Xmax/2*plotScale,-1,((cupDiaMax+cupDiaMin)/2)*plotScale*PI-cupDiaMin*PI/4* plotScale,-1); //base right.
       line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/4* plotScale,-1,((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/4* plotScale,-0.1875*stemHeight*plotScale); //base up left
       line( ((cupDiaMax+cupDiaMin)/2)*plotScale*PI-cupDiaMin*PI/4* plotScale,-1,((cupDiaMax+cupDiaMin)/2)*plotScale*PI-cupDiaMin*PI/4* plotScale,-0.1875*stemHeight* plotScale); //base up right
       line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/4* plotScale,-0.1875*stemHeight*plotScale,Xmax/2*plotScale-(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale); //base canted  left
       line( ((cupDiaMax+cupDiaMin)/2)*plotScale*PI-cupDiaMin*PI/4* plotScale,-0.1875*stemHeight*plotScale,Xmax/2*plotScale+(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale); //base canted  right
       line( Xmax/2*plotScale-(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale,Xmax/2*plotScale-(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale-(stemHeight-(0.09375*stemHeight)-0.375*stemHeight)*plotScale); //stem left
       line( Xmax/2*plotScale+(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale,Xmax/2*plotScale+(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale-(stemHeight-(0.09375*stemHeight)-0.375*stemHeight)*plotScale); //stem right
       line( Xmax/2*plotScale-(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale-(stemHeight-(0.09375*stemHeight))*plotScale+(0.375*stemHeight*plotScale),((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/3* plotScale,-stemHeight*plotScale); //undrawable round bottom of glass left
       line( Xmax/2*plotScale+(0.03*Xmax*plotScale),-0.25*stemHeight*plotScale-(stemHeight-(0.09375*stemHeight))*plotScale+(0.375*stemHeight*plotScale),((cupDiaMax+cupDiaMin)/2)*plotScale*PI-cupDiaMin*PI/3* plotScale,-stemHeight*plotScale); //undrawable round bottom of glass left
       line( ((cupDiaMax-cupDiaMin)/2)*plotScale*PI+cupDiaMin*PI/3* plotScale,-stemHeight*plotScale,0+cupDiaMax*PI/3* plotScale,-Ymax* plotScale); //left anlgledline
       line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*plotScale*PI-(cupDiaMin*PI/3* plotScale),-stemHeight*plotScale, Xmax * plotScale-(cupDiaMax*PI/3* plotScale),-Ymax* plotScale); //right angled line
       line( 0+cupDiaMax*PI/3* plotScale,-Ymax* plotScale, Xmax * plotScale-(cupDiaMax*PI/3* plotScale),-Ymax* plotScale  ); //TOP line
    }   
    stroke(0);strokeWeight(0.7); noFill(); //these are the seetings the preview shape will be drawn to
    
    if (loadTheShape == true && bSavingFile == false){ loadShapes();  }
           
    //****Draw the shape for visual display purposes ONLY****/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
    if (shapeLoaded == true && arrList != null ){//no need to display big shit if on a save cycle 
        if (bFillDrawing && bSavingFile == false){
          previewShape.draw();// Draws the shape exactly with filled spacess too!  //RG.shape(previewShape); alternative way to draw?
        }  
         arrListLocal = new ArrayList(arrList); //due to threadding to prevent sudden wipeout, this in part allows us to display teh arr as its being built
          nve = arrListLocal.size();
          if (bSavingFile == true){ //no push or pop we want this shit to apply to the following:
            noFill();
            stroke(0); //draw image in black strokes
            scale(plotScale,-plotScale); //Nullified with the new loadshape call only when updates//Important, this scales the view as seen in draw ONLY. In reality the image is smaller, upsidedown, & not drawn
          }
          if(!(bFastPreview && bSavingFile)){  //again this is an attempt to prevent freezing system while displaying a huge SVG job. If save takes too long people will exit system. 
              //generattes svg that will be displayed to screen live
              for (int p1 = 0; p1 < nve; p1++) {
                if (((Point) arrListLocal.get(p1)).z == -10.0 ){   //Removes 'travel' moves, -10z = beginning of drawn path, -20z end of path
                    beginShape();
                    vertex( ((Point) arrListLocal.get(p1-1)).x, ((Point) arrListLocal.get(p1-1)).y );
                }else if ( ((Point) arrListLocal.get(p1)).z == -20.0) {
                    endShape();
                }else{
                  if (bMultiColor == true  ) {
                     stroke(((Point) arrListLocal.get(p1)).clr); //  This will halfsclae the colors >> stroke( grayScale(((Point) arrList.get(p)).clr));
                  } else{stroke(color(2));  }//nt zero because it will say color none//fill(color(2));
                  vertex( ((Point) arrListLocal.get(p1)).x, ((Point) arrListLocal.get(p1)).y );
                }
              }//end of p-for loop
          }
    }
      
      //********************
        // if (nve < arrList.size()) { //keep this shit for displaying the machine paths if you want to show in real time (comment out  nve =arrList.size(); above)
       //     nve = min(arrList.size(), nve + speed);
       //  } else {nve = 1; };
       
      if (bSavingFile == true){
            if (bSavingFile != bWasSavingFile) { frameRate(1);bWasSavingFile = bSavingFile;}
            Progress = (int)((float)iChildCounter/(float)(iMaxChildCounter)*100);
            if (Progress > (ProgressOld) ){
                liveData = "";//cleares previous display feed
                dataCounter =0;
                if (bTerms){
                  DisplayData("Preparing File.... A preview will popup when save is complete.");
                  //if (bFillDrawing){ DisplayData("...Thank you for your patience. Note: Image-fill, extra outlines, & small tool diameters increase processing time..");  }
                  //DisplayData("Save Progress Estimate: approximately " + Progress + "% Complete...");
                }else{
                  DisplayData("File not saved due to missing end user license agreement. Please agree thenf try to save again.<<");
                }
                ProgressOld = Progress;
            }
      } else {
        if (bSavingFile != bWasSavingFile) { frameRate(60);bWasSavingFile = bSavingFile; Progress = 0; ProgressOld = 0; }
      }
  
     
       if (iMaxNumColors != iMaxNumColorsOld) {
          //this is not a useful prompt & is wrong since I consolidate ...DisplayData( "Total number of pen changes detected: "  + iMaxNumColors );//+ "  (includes unique colors + inefficient tool changes if present in file)");
          iMaxNumColorsOld = iMaxNumColors;
        }
      
    // if ( bSaveFile && shapeLoaded ){bSaveFile = false;  saveFile();  }  //load a second time becase all info is pulled for the save file command when used
    if (xWindow != width){ // if  frame.setSize(xWindow, yWindow);
      xWindow = width;
      setButtons();
    }else if (yWindow != height){
      yWindow = height;
      plotyShift = int(height/2-Ymax*plotScale/2-height+62+550);
      setButtons();      
    }
    
     camera(); //I dont remember why we call this here...
}//end of draw loop

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//VOID FUNCTIONS -TAB
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void loadShapes(){
      iColorIndex = 0;
      iChildCounter =0;
     
  if (shapeLoaded == false ) {
    // RPoint centerPoint;
     if (bSavingFile == true){ //only have to bother with mainshape on a save sequence!
       imageScale = toolDia* (1-fOverlap/100);// was originally (toolDia/2) when overlap was fixed at 50%. now allowing for 0-90% overlap. if 0 then imageScale =toolDia
       mainShape = RG.loadShape(fileName);// load the svg
       
      // centerPoint = mainShape.getCenter();
     //  xShift = -centerPoint.x/2;
      // yShift = -centerPoint.y/2;
       //mainShape.centerIn(g, 100, 1, 1); //graphics g, float margin, float sclDamping, float trnsDamping)  //margin is just a scaling method
      // RPoint centerPoint = mainShape.getCenter();
        //previewShapeReset.
        //previewShapeRese
       
      //xShift = -centerPoint.x/2;
      // yShift = -centerPoint.y/2;       
       pushMatrix();
       mainShape.rotate(rotateAngle,0,0); //This rotates the drawing in radians!f
       mainShape.scale (imageScale+imageScaleAdjust,-imageScale-imageScaleAdjust);//(x,y)  Negaive Y to reorient image per processings invered Y system
       //mainShape.translate(Xmax/2+xShift,Ymax/2-yShift+iChuckGrip); //(float tx,float ty) This centers the drawing
       RPoint newCenterPoint = mainShape.getCenter();

       mainShape.translate(Xmax/2-newCenterPoint.x+xShift,Ymax/2-newCenterPoint.y+iChuckGrip-yShift); //(float tx,float ty) This centers the drawing BUT FOR THE PREVIEW IT ALSO SHIFTS YOU THE CORRECT DISTANCE OF THE GRIP LENGTH
       //mainShape.translate(xShift,-yShift+iChuckGrip); //(float tx,float ty) This centers the drawing BUT FOR THE PREVIEW IT ALSO SHIFTS YOU THE CORRECT DISTANCE OF THE GRIP LENGTH
       //previewShape.translate(xShift,-yShift+iChuckGrip);
       popMatrix();
       //once =0;
       if (!bMultiColor){ inVert(mainShape);} //convert all shape colors to black
     }     
    
     //topLeft = mainShape.getBottomLeft();
     //bottomRight = mainShape.getTopRight();
     //mainShape.draw();//only for troubleshooting
     
       ////////There is a glitch in the source library that makes me have to do this preview operation seperately from the main or else they get linked!//////////
      if (once <1 && bSavingFile == false){ //iMaxNumColors
        once = 2;
        if (bFastPreview && bSavingFile ==false){//3000000           
           previewShapeReset =  RG.loadShape(fileName);
           //RPoint bl = previewShapeReset.getBottomLeft();
           RPoint br = previewShapeReset.getBottomRight();
           RPoint tl = previewShapeReset.getTopLeft();
           RPoint tr = previewShapeReset.getTopRight();         
            // x - x coordinate of the top left corner of the shape
            //y - y coordinate of the top left of the shape
           // w - width of the rectangle
          //  h - height of the rectangle
           //getRect(float x, float y, float w, float h)
           RShape BOUNDS = RG.getRect(tl.x,tl.y,tr.x-tl.x,tr.y-br.y);// previewShapeReset.getBounds();
           previewShapeReset =BOUNDS;
           rotateAngle =0; xShift=0;yShift =0;  imageScaleAdjust =0; 
           imageScale =toolDia* (1-fOverlap/100);// toolDia/2;
        }else{
          
          // imageScale = toolDia/4; //imageScale = 1;
          rotateAngle =0; xShift=0;yShift =0;  imageScaleAdjust =0; 
          
          previewShapeReset =  RG.loadShape(fileName);//mainShape; //important to grab preview shape NOW, before the next inversion below for display purposes.
          //previewShapeReset =  RG.getRect(previewShapeReset.getBounds());
          
               //previewShapeReset =  RG.getRect(previewShapeReset.getBounds());
          
          //  RG.shape(previewShapeReset.getBounds());
  
          // Create and draw a cutting line
          //float strokes = previewShapeReset.getHeight();
          //println("Job stroke count is " + strokes);
          //float trueHeight = toolDia/2*strokes;
          //println("SVG true height is " + trueHeight + " mm"); //ASSUMG TOOL DIA IS CORRECT & IMAGE SCALE IS 1ssssss
          imageScale = toolDia* (1-fOverlap/100);//
          // imageScale = strokes/trueHeight;
  
         // centerPoint = previewShapeReset.getCenter();
          //previewShapeReset.
          //previewShapeRese
         
        //  xShift = -centerPoint.x/2;
         // yShift = -centerPoint.y/2;
         // previewShapeReset.centerIn(g, 100, 1, 1); //graphics g, float margin, float sclDamping, float trnsDamping)  //margin is just a scaling method
        }
      }
      previewShape = new RShape(previewShapeReset); 
      
      pushMatrix();
      previewShape.rotate(rotateAngle,0,0); //This rotates the drawing in radians!f
      //previewShape.scale (1,-1);//(x,y)  Negaive Y to reorient image per processings invered Y system
      previewShape.scale (imageScale+imageScaleAdjust,-imageScale-imageScaleAdjust);//(x,y)  Negaive Y to reorient image per processings invered Y syste

      RPoint newCenterPoint = previewShape.getCenter();

      previewShape.translate(Xmax/2-newCenterPoint.x+xShift,Ymax/2-newCenterPoint.y+iChuckGrip-yShift); //(float tx,float ty) This centers the drawing BUT FOR THE PREVIEW IT ALSO SHIFTS YOU THE CORRECT DISTANCE OF THE GRIP LENGTH
      previewShape.scale(plotScale,-plotScale); //THIS IS THE KEY LINE<<<<< The only difference between mainshape & preview shape (reorient & resize for display purposes)
      popMatrix();
      
      if (!bMultiColor){ inVert(previewShape);} //convert all shape colors to black
      if (!bLocallyMade){toggleFill.show(); toggleMultiColor.show();}    
      buttonSave.show();buttonRotateLeft.show(); buttonRotateRight.show();buttonMoveLeft.show();buttonMoveUp.show();buttonMoveDown.show();buttonMoveRight.show(); 
      if(! bLocallyMade){buttonScaleUp.show();buttonScaleDown.show();}
      shapeLoaded = true;
  }
  
  arrList.clear(); //arrList.clear(); 

  if (bSavingFile  == false){ //DISPLAY ONLY
      exVert(previewShape, c0,true,false); //Never display the infill strokes, always only display outlines in draw.   //Exvet Inputs: The RShape you want to parse, a color, bool parse outlines, bool pase infill)
  }else { //SAVING ONLY
      penIsDown = false; //pen starts out homed, this global variable tracks it suring slicing
      if(bBlkOutline){ //yes saving, yes outline (yes-fill is implied)
        exVert(mainShape, c0,false,true); //no outline, yes fill
        exVert(mainShape, c0,true,false); //yes outline, no fill
      }else { // yes saving, no outline, fill tbd
        exVert(mainShape, c0,true,bFillDrawing); //yes outline, yes fill (The outline will be the same color as the fill in this case)
      }
      
   
        hone();//before saving
     
      
      saveFile();
    }
 
}//end of  loadsshapes


void saveFile(){
    if (!bPaid){
          JFrame frame172 = new JFrame("Notice");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
          frame172.setVisible(true);
          frame172.toFront(); 
          Object[] message2 = {
            "Sorry but you have reached a free license limitation!", 
            "This feature is available when you enter a CylinDraw Full License key.",
            "For more information, click the HELP button.",
          };
          JOptionPane.showMessageDialog(frame172, message2, "NOTICE!", JOptionPane.INFORMATION_MESSAGE);
          frame172.setVisible(false);
          frame172.toBack();
          frame172.dispose();
          cursor(HAND); //return cursor to arrow or hand
          bSavingFile = false;
          
    }else if (! bTerms){
          DisplayData(">>File not saved due to missing end user license agreement. Please agree & try to save again.<<");
          checkLicense("","");
          cursor(HAND); //return cursor to arrow or hand
          bSavingFile = false;
    }else{
     
      cursor (WAIT); //create wating symbol for cursor to show stuff is loading
      String gcodecommand ="//Filename: " + fileNameOriginal + " \n//Cup Type: " + cupType + "\n//Fill Drawing?: " +bFillDrawing + "\n//Cup Dimensions are: " + cupDiaMax + "mm Major dia x " + cupDiaMin + "mm Minor dia x " + Ymax + "mm tall \n" + "//Stroke Width: " + toolDia + "mm \n";
      gcodecommand = gcodecommand + "G21 H" + Ymax + " B" + cupDiaMin + " D" + cupDiaMax + "\n";
      gcodecommand = gcodecommand + "G0 \n"; //homing command
      gcodecommand = gcodecommand + penUp; //ensure there is a lift to combat oddbal glitch where pen drops after home
      boolean penIsDown1 = false; //local version of the global var
      boolean penWasDown1 = false;
      
      String svgJobName = destName;//.replace(".svg",".job.svg");// fileNameOriginal.replace(".svg",".g.svg");  //used for prev
      noFill();
      
      DisplayData("Writing to file...");
      PGraphics svg = createGraphics((int)(Xmax),(int)(Ymax), SVG, svgJobName); //used for prev
      
      svg.beginDraw(); //used for prev thumbnail in finished file
      svg.stroke(0); svg.strokeWeight(0.2); //////FUCKT THIS svg.background(255); MAKE THE RESULT APPEAR SOLID BLACK WHEN RELOADED IN RUNMODE //used for prev, white background
      svg.scale(1,-1);
      svg.translate(0,-Ymax);
      svg.noFill();
      
      iMaxChildCounter = arrList.size();//+10; //ghetto shit for makign the progress update work nicely
      iChildCounter = 0;
      c0= 124578; 
      float xOld =0, yOld=0, xNew=0, yNew=0;
      color localNew = color(2);
      color localOld = color(255);
      boolean bStarted=false;;
      
      if (!bFastPreview){             
            for (int p = 0; p < arrList.size(); p++) {
                iChildCounter++;//just used for the progress bar
                
                if (((Point) arrList.get(p)).z == -10.0 ){   // -10z = beginning of path, -20z end of bath
                    gcodecommand = gcodecommand + penDown; //penIsDown1 = true; penWasDown1 = false; // a moveto command....(Should this be j ==0?
                    
                    if(bStarted){svg.endShape(); bStarted = false;}
                    svg.beginShape(); bStarted = true;
                    svg.vertex( xOld, yOld);
                    
                }else if ( ((Point) arrList.get(p)).z == -20.0) {
                    if(bStarted){svg.endShape(); bStarted = false;}
                    gcodecommand = gcodecommand + penUp;// penIsDown1 =false; penWasDown1 = true; //adding penUp between seperate paths
                }else{
                  if (bMultiColor == true ) { //DO NOT REMOVE THIS LINE OR ELSE IT FUCKS UP PREVIEW WHEN VIEWED IN RUN MODE
                      localNew = ((Point) arrList.get(p)).clr; //grab the color of this point
                  }
                      svg.stroke(localNew); //? svg.fill(localNew); 
                      if (localNew != localOld ){// && !(bBlkOutline && bMultiColor && !bFillDrawing)  ){  //All three of these statements on the right is equivilant to none of them, gets rid of color change for black outline when its only a black outlined perimeter, to prevent double save
                        if(bStarted){svg.endShape(); bStarted = false;}
                        gcodecommand = gcodecommand +"M0 " + localNew+ "\n"; //QQthis is internal g code signifier of color change                      
                        localOld = localNew;
                        Color wild = new Color (localNew);
                        String fuck = str(localNew);
                        println("  Sequential end color use is " + localNew + "  " + wild.decode(fuck)); //dont display this too cryptic
                      }
                  
                  gcodecommand = gcodecommand + "G1 X"+ str( ((Point) arrList.get(p)).x)+" Y"+str( ( (Point) arrList.get(p)).y) +"\n";
                  
                  
                  xNew =  ((Point) arrList.get(p)).x;
                  yNew =  ((Point) arrList.get(p)).y;
                  svg.vertex( xNew, yNew);   
                  
                  xOld =  ((Point) arrList.get(p)).x;
                  yOld =  ((Point) arrList.get(p)).y;
                  
                }
            }//end of arrList parsing loop
            if(bStarted){svg.endShape(); bStarted = false;}
        }else{ //same but excl svg
              //PImage img1; //too big
              //PShape img1;
              //img1 = loadImage("\\system\\temp.svg"); 
              //img1 = requestImage("\\system\\temp.svg");
               //img1 = loadShape("\\system\\temp.svg"); 
               //svg.image(img1,100,100);
               //  shape(bot, 110, 90, 100, 100);  // Draw at coordinate (110, 90) at size 100 x 100
              //shape(bot, 280, 40);            // Draw at coordinate (280, 40) at the default size
               //try to use this method to displaY LIGHTEWR PREVIEW..
               
               
                for (int p = 0; p < arrList.size(); p++) {
                    iChildCounter++;//just used for the progress bar
                    
                    if (((Point) arrList.get(p)).z == -10.0 ){   // -10z = beginning of path, -20z end of bath
                        gcodecommand = gcodecommand + penDown; //penIsDown1 = true; penWasDown1 = false; // a moveto command....(Should this be j ==0?
                                   
                    }else if ( ((Point) arrList.get(p)).z == -20.0) {
                        gcodecommand = gcodecommand + penUp;// penIsDown1 =false; penWasDown1 = true; //adding penUp between seperate paths
                    }else{
                      if (bMultiColor == true ) { //DO NOT REMOVE THIS LINE OR ELSE IT FUCKS UP PREVIEW WHEN VIEWED IN RUN MODE
                          localNew = ((Point) arrList.get(p)).clr; //grab the color of this point
                      }
                          if (localNew != localOld ){// && !(bBlkOutline && bMultiColor && !bFillDrawing)  ){  //All three of these statements on the right is equivilant to none of them, gets rid of color change for black outline when its only a black outlined perimeter, to prevent double save                  
                            gcodecommand = gcodecommand +"M0 " + localNew+ "\n"; //QQthis is internal g code signifier of color change                      
                            localOld = localNew;
                            Color wild = new Color (localNew);
                            String fuck = str(localNew);
                            println("  Sequential end color use is " + localNew + "  " + wild.decode(fuck)); //dont display this too cryptic
                          }
                      
                      gcodecommand = gcodecommand + "G1 X"+ str( ((Point) arrList.get(p)).x)+" Y"+str( ( (Point) arrList.get(p)).y) +"\n";
                    }
                }//end of arrList parsing loop
            
        }
            
            
            svg.stroke(255, 100, 100); svg.strokeWeight(1);svg.fill(255, 100, 100);
            if (cupType ==0 || cupType ==2  ) {  //This draws the boundary (RED lines) for prev
               svg.line(0, 0, Xmax,0);   
               svg.line(Xmax,0, Xmax,Ymax);   
               svg.line(Xmax,Ymax, 0,Ymax);   
               svg.line(0,Ymax, 0,0);  
               if (cupType ==0 ){
                   svg.line(0, -iChuckGrip, Xmax, -iChuckGrip); 
                   svg.line( ((cupDiaMax-cupDiaMin)/2)*PI,0,0,Ymax);  //angled line
                   svg.line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*PI, 0, Xmax,Ymax); //angled line
                   svg.line( ((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/3,0,0+cupDiaMax*PI/3,Ymax); //left anlgledline
                   svg.line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*PI-(cupDiaMin*PI/3), 0, Xmax -(cupDiaMax*PI/3),Ymax); //right angled line
                }
            } else{ //draw goblet
               svg.line(0, 0, Xmax,0);   
               svg.line(Xmax,0, Xmax,Ymax);   
               svg.line(Xmax,Ymax, 0,Ymax);   
               svg.line(0,Ymax, 0,0);  
               svg.line( ((cupDiaMax-cupDiaMin)/2)*PI,0,0,-Ymax*-1); //left anlgledline
               svg.line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*PI, 0, Xmax ,-Ymax*-1); //right angled line
               svg.line( Xmax/2,-1*-1,((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/4,-1*-1); //base left
               svg.line( Xmax/2,-1*-1,((cupDiaMax+cupDiaMin)/2)*PI-cupDiaMin*PI/4,-1*-1); //base right.
               svg.line( ((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/4,-1*-1,((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/4,-0.1875*stemHeight*-1); //base up left
               svg.line( ((cupDiaMax+cupDiaMin)/2)*PI-cupDiaMin*PI/4,-1*-1,((cupDiaMax+cupDiaMin)/2)*PI-cupDiaMin*PI/4,-0.1875*stemHeight*-1); //base up right
               svg.line( ((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/4,-0.1875*stemHeight*-1,Xmax/2-(0.03*Xmax),-0.25*stemHeight*-1); //base canted  left
               svg.line( ((cupDiaMax+cupDiaMin)/2)*PI-cupDiaMin*PI/4,-0.1875*stemHeight*-1,Xmax/2+(0.03*Xmax),-0.25*stemHeight*-1); //base canted  right
               svg.line( Xmax/2-(0.03*Xmax),-0.25*stemHeight*-1,Xmax/2-(0.03*Xmax),(-0.25*stemHeight-(stemHeight-(0.09375*stemHeight)-0.375*stemHeight))*-1 ); //stem left
               svg.line( Xmax/2+(0.03*Xmax),-0.25*stemHeight*-1,Xmax/2+(0.03*Xmax),(-0.25*stemHeight-(stemHeight-(0.09375*stemHeight)-0.375*stemHeight))*-1 ); //stem right
               svg.line( Xmax/2-(0.03*Xmax),(-0.25*stemHeight-(stemHeight-(0.09375*stemHeight))+(0.375*stemHeight))*-1,((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/3,-stemHeight*-1); //undrawable round bottom of glass left
               svg.line( Xmax/2+(0.03*Xmax),(-0.25*stemHeight-(stemHeight-(0.09375*stemHeight))+(0.375*stemHeight))*-1,((cupDiaMax+cupDiaMin)/2)*PI-cupDiaMin*PI/3,-stemHeight*-1); //undrawable round bottom of glass left
               svg.line( ((cupDiaMax-cupDiaMin)/2)*PI+cupDiaMin*PI/3,-stemHeight*-1,0+cupDiaMax*PI/3,-Ymax*-1); //left anlgledline
               svg.line( (cupDiaMin+(cupDiaMax-cupDiaMin)/2)*PI-(cupDiaMin*PI/3),-stemHeight*-1, Xmax -(cupDiaMax*PI/3),-Ymax*-1); //right angled line
               svg.line( 0+cupDiaMax*PI/3,-Ymax*-1, Xmax -(cupDiaMax*PI/3),-Ymax*-1  ); //TOP line
            }
             
            svg.scale(1,-1);  //specifically for text  //
            svg.fill(100, 100,255); //specifically for text
            svg.stroke(100, 100,255);
            int textSize = int(Ymax/20);
            svg.textSize(textSize);
            //float textSize = RealHeight/toolDia/11.75  ;//17 is generall but want to be smaller for low pixel count images (high tool dia, low image size)(  RealHeight/toolDia  100/.5 =200
            //float textSpacing = RealHeight/toolDia/10;//20 is general.
            
            //svg.textSize(textSize);
            String[] storedSettingsList = loadStrings("\\system\\CupTool_LastUsed.txt");//loading words to display over svg
            int offsett = 1; //bigger number = more dist from top
            int spacing =textSize;
            svg.text("Created with CylinDraw JobCreator",5,-Ymax+spacing +offsett);
            //t lenHeader = storedSettingsList.length;
            ///if (cupType != 1){lenHeader=lenHeader-2;};//remove stem height
            int iliney =2;
            if (cupType==0){
              svg.text("Object Type:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(" Cylinder/Cup",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Max Cup Diameter in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(cupDiaMax,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Min Cup Diameter in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(cupDiaMin,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Cup Height in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(Ymax,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Stroke Thickness in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(toolDia,5,-Ymax+(iliney)*spacing+offsett);iliney++;
            }
            if (cupType==1){
              svg.text("Object Type:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(" Goblet",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Max Diameter in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(cupDiaMax,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Min Diameter in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(cupDiaMin,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Total Height in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(Ymax,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Stem Height in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(stemHeight,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Stroke Thickness in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(toolDia,5,-Ymax+(iliney)*spacing+offsett);iliney++;
            }
            if (cupType==2){
              svg.text("Object Type:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(" Paper",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Paper Width in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(3.14*cupDiaMax,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Paper Height in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(Ymax,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Stem Height in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(stemHeight,5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text("Stroke Thickness in mm:",5,-Ymax+(iliney)*spacing+offsett);iliney++;
              svg.text(toolDia,5,-Ymax+(iliney)*spacing+offsett);iliney++;
            }
       
            
           // for(int setIndex = 3 ; setIndex < lenHeader ; setIndex++){ //grab settings to display in file preview.
           //     svg.text(storedSettingsList[setIndex],5,-Ymax+(setIndex-1)*spacing+offsett);
            //}
            
           // PShape thing = loadShape("temp.svg");
            //svg.shapeMode(CENTER);
            //svg.shape(thing,0,0);    //playing with embedding the original image in for a preview.       
            svg.dispose();  //used to end raw svg preview
            svg.endDraw();  //used to end raw svg preview.
            
            gcodecommand = "<!-- BEGIN \n" + gcodecommand + "G100 \n" + "-->" ; //M84 = Home & Kill all motors 
            
            String[] gcodecommandlist = split(gcodecommand, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
           
            String[] svgPreviewStrings = loadStrings(svgJobName); //Reopen the SVG preview we just created and load it as an array of strings 
           
            String[] allSvgCodeCombinedList =   concat( svgPreviewStrings , gcodecommandlist); //combine SVG preview with the GCODE FOLLOWING
          
            saveStrings(svgJobName, allSvgCodeCombinedList); /////THIS LINE TAKES A LONG TIME!//////////////////////////////////////////////////////////////////////////////////////////          //DisplayData("JOB file was saved here: " + svgJobName);     //DisplayData("File is saved here: " + sketchPath());
            
            timeEst = (gcodecommandlist.length-1) *2.5/20/60;  // estimate 2 sec per 20 lines, 60 seconds per minute
            DisplayData("Total Estimated Job Time is: " + timeEst + "minutes.");
            
            File svgJob = new File(svgJobName);// fileName);// use temp so we dont fill up with crap files
            launchViewer(svgJob);
            delay(2);
            /*          
                JFrame frame12 = new JFrame("Notice");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
                frame12.setVisible(true);
                frame12.toFront();
               
                Object[] message2 = {
                  "Job file successfully saved!", 
                  "Job file saved here:  " + svgJobName,
                  //"Job file was saved to this folder:  ",
                  //"  " + sketchPath(),
                 };
                JOptionPane.showMessageDialog(frame, message2, "File Saved!", JOptionPane.INFORMATION_MESSAGE);
                frame12.setVisible(false);
                frame12.toBack();
                frame12.dispose();
            */
            DisplayData("Save Complete!");
            DisplayData("File saved to: " + svgJobName);
            
            //svg.draw(); //experimental https://github.com/rikrd/geomerative/blob/master/examples/Tutorial_16_HelloSVGtoPDF/Tutorial_16_HelloSVGtoPDF.pde
            
         cursor(HAND); //return cursor to arrow or hand
         bSavingFile = false;
         iMaxChildCounter = 0;
         
         

         fileName = destName = svgJobName ="temp.svg";
         shapeLoaded = true;//call to refresh the shape in the viewer
         loadTheShape = true;
         /* this is annoying why did i do this part
           //RELOAD SAME THING SO IT CAN BE USED AGAIN IN SAME SESSION
            arrList= new ArrayList();
            colorArray = new color[101];
            shapeLoaded = false;
            iMaxNumColors = 0;
            iMaxChildCounter = 0;
            String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
            newPath = newPath + "\\system\\temp.svg";   //.replace("CylinDrawJobCreator", "CylinDrawViewer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
            storedFile = new File(sketchPath(newPath));  
            if (storedFile.exists()) {
              //DisplayData("Reoading last file used......");//(load instructions gcode?)
              fileSelected(storedFile);
            }else{
               DisplayData("No local default job file found to load..");
             }
             */
             
  } //end of bpaid     
           
}// End of saveFile()

void mousePressed(){
  stroke(255/2);
  ellipse( mouseX, mouseY, 25, 25 );
    float displayXpos = (abs(mouseX) - (width - abs(Xmax*plotScale) )/2 -plotxShift  )/plotScale     - abs(Xmax/2) ; 
    float displayYpos =  map( ((abs(mouseY) - (height - abs(Ymax*plotScale) )/2 -plotyShift +30)/plotScale    ), 0,Ymax,Ymax,0)  ;
    String displayXposString = nf(  displayXpos ,3,1); //nf converts floats to runcated strings
    String displayYposString = nf( displayYpos ,3,1);
    if (  displayXpos>-Xmax/2 && displayXpos <Xmax/2 && displayYpos>0 && displayYpos <Ymax){
       DisplayData ("Position of your cursor on the cup is:   X: " + displayXposString + "mm  Y:   Yposition is " + displayYposString + "mm " );   // DisplayData ("Xmax is " + abs(Xmax) + "     Ymax is " + abs(Ymax) );
    }
} 

void mouseWheel(MouseEvent event){
  /*
  iSpecleFactor = iSpecleFactor + wheelcount;
  DisplayData(" speckle factor = " + iSpecleFactor); */
  
  if (bSavingFile == false) { //dont interrupt
      float wheelcount = event.getCount();
      plotScale = plotScale + wheelcount/10;
      if (plotScale <.1){ plotScale =.1; }
      plotyShift = int(0+plotScale*Ymax*.5-height/2+200);
      shapeLoaded = false; 
  }
}

void keyPressed(){
    if (key == ESC) { key = 0; buttonExit();}
    if (keyCode != LEFT && keyCode != RIGHT && keyCode != UP && keyCode != DOWN){ DisplayData( "You clicked the '" + key + "' key" );}
    //if (key == 'g' || key == 'G') {buttonLoadSVG();  }
    //if (key == 'e' || key == 'E' ) {enterCupDimensions2();}  
    if (keyCode == LEFT){plotxShift=plotxShift-4; DisplayData( "You clicked the 'LEFT arrow Key'. Display Area Moved LEFT");}
    if (keyCode == RIGHT){plotxShift=plotxShift+4;DisplayData( "You clicked the 'RIGHT Arrow Key'. Display Area Moved RIGHT");}
    if (keyCode == UP){ plotyShift=plotyShift-4; DisplayData( "You clicked the 'UP Arrow Key'. Display Area Moved UP");} //(float tx,float ty) This centers the drawing
    if (keyCode == DOWN){plotyShift=plotyShift+4; DisplayData("ploty shift is " + plotyShift);}// DisplayData( "You clicked the 'DOWN Arrow Key' Display Area Moved Down");}
    /*if (shapeLoaded == true){
      if (key == 's' || key == 'S' ) {buttonSave();}
      if (keyCode == 4){xShift--; DisplayData( "Drawing Moved LEFT");}
      if (keyCode == 6){xShift++ ;DisplayData( "Drawing  Moved RIGHT");}
      if (keyCode == 8){ yShift--; DisplayData( "Drawing Moved UP");} //(float tx,float ty) This centers the drawing
      if (keyCode == 2){yShift++; DisplayData( "Drawing Moved Down");}
      if (key == 'i' || key == 'I' ) {imageScaleAdjust += 0.001; DisplayData( "Drawing Scaled Larger");}
      if (key == 'o' || key == 'O' ) {imageScaleAdjust -= 0.001; DisplayData( "Drawing Scaled Smaller");}
      if (key == 'r' || key == 'R' ) {rotateAngle += 10*PI/180; DisplayData( " Drawing Rotated +10 deg. Total angle is: " + rotateAngle*180/PI + " degrees");}
      if (key == 'l' || key == 'L' ) {rotateAngle -= 10*PI/180; DisplayData( " Drawing Rotated -10 deg. Total angle is: " + rotateAngle*180/PI + " degrees");}
      if (key == 'f' || key == 'F' ) {bFillDrawing = !bFillDrawing; DisplayData( "Toggled infill path");}
    }//end of shapeloaded requirement   */
    
} //end of void Keypressed()

void fileSelected(File selection) {
  if (selection == null) {
    DisplayData("Window was closed or the user hit cancel.");
  } else {
     once =0;
     shapeLoaded = false;
     iMaxNumColors = 0;
     iMaxChildCounter = 0;
      
    delay(100); //this delay before the next line ensures no signals get confused
    //NON NO NO NNONONONOstoredFile = selection;
    filePath = selection.getAbsolutePath();
    fileNameOriginal = fileName = selection.getName();
    
    if (filePath.contains(".JOB.svg")) {
       DisplayData("Launching Preview");
       launchViewer(selection);

    } else if (filePath.contains(".svg")) {
      DisplayData("Importing FileName: " + fileName );
      DisplayData("Located at FilePath:" + filePath );      
      //filePath = filePath.replace("\" + fileName,"");
      //filePath = dataPath(filePath);
      //String filePath = selection.getPath() ;
     // File file = new File(sketchPath("\\system\\" +fileName));
      //if (file.exists()) {
       // DisplayData("File Found");
        ////filePath = file.getAbsolutePath();
        //fileName = file.getName();
     // } else {
        //extraneous information
       // DisplayData("Temporary copy of selected file moved to this program folder so we can work with it."); 
        
        //DON NEED TO FILE COPY UNLESS USING A MANUAL IMPORT DIRECTORY!??
       //to limit what it does to save time...
        fileCopy();
     // } 
      loadTheShape = true; //request to load the shape
      shapeLoaded = false;
      once=0;
      
      String[] linesRaw = loadStrings(filePath);
      bPathOptimize = bLocallyMade = false; 
      for (int lineCount = 0; lineCount<linesRaw.length - 1; lineCount++) {   // PARSE gcode & remove everything upto and including "<!-- BEGIN"
          if (linesRaw[lineCount].contains("DePixelizer")) {
              DisplayData("~~Detected that this SVG was generated using CylinDraw Depixelizer!"); 
              bLocallyMade = true;
              if (! bFastPreview){   //default will optimize if locally made, but not optimize if fast preview...
                bPathOptimize =true;
              }
          }
          
          if (linesRaw[lineCount].contains("Stroke Width: ")) {
             int index1= linesRaw[lineCount].indexOf("Stroke Width: "); //result is -1 if not found
             String rawValue =  linesRaw[lineCount].substring(index1+14,index1+4+14);//4 characters (ex1.34) includes decimal
             //DisplayData("Found      =" +rawValue);
             rawValue = rawValue.replace(",", ".");//for non US systems!
             toolDia = Float.parseFloat(rawValue);
             DisplayData("~~Detected the Stroke Width is: " +  toolDia);
             DisplayData("~~(The system will not let you change stroke width within JobCeator on an SVG from Depixelizer.)");
          }
          
          if (linesRaw[lineCount].contains("Unique Colors: ")) {
             int index2= linesRaw[lineCount].indexOf("Unique Colors: "); //result is -1 if not found
             String rawValue =  linesRaw[lineCount].substring(index2+15,index2+1+15);//1 characters
             //DisplayData("Found      =" +rawValue);
             int iNumColors = int(Float.parseFloat(rawValue));
             if ( iNumColors>2 ){
               bMultiColor = true;
             }else{
               bMultiColor = false;
             }
             DisplayData("~~Detected number of unique colors was: " +  iNumColors);
          }
          
          if (linesRaw[lineCount].contains("Stroke Overlap: ")) {
             int index3= linesRaw[lineCount].indexOf("Stroke Overlap: "); //result is -1 if not found
             String rawValue =  linesRaw[lineCount].substring(index3+16,index3+2+16);//2 characters, a whole number percent 00-90, no decimal
             if (rawValue != null){
               //DisplayData("Found      =" +rawValue);
               fOverlap = Float.parseFloat(rawValue);
               
               DisplayData("~~Detected stroke overlap was: " +  fOverlap+"%");
             }
          }
          
          
          
      }
      
      if (bLocallyMade){
          //turned off rescaling here anyway. DisplayData("~~Note if you want to rescale the size of this image please remake in DePixelizer mode. ");// that we do NOT recomend rescaling this image.");
          displayStatus ="Cup Dimensions: Major dia:" + cupDiaMax + "mm. x Minor dia:" + cupDiaMin + "mm. x Cup Height:" + cupHeight + "mm tall.  Stroke:" + nf(toolDia,0,2) + "mm"; //
      }
            
      
      setButtons();
   
    }else { DisplayData(" Load Error! You MUST select an '.svg' file type!! ");}
  }  
}//end of FileSelected()


void launchViewer(File selectedFile){
   String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
       
        //MOVE THE File TO view. (WONT NEED TO DO WHEN COMPLETE WITH PROJECT!
       // newPath = newPath.replace("CylinDrawJobCreator", "CylinDrawRunMode");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
        //this is the target format = launch("cd C:/Sketch/application.windows64 && Sketch.exe");
        
        File dest1 = new File(savePath(newPath),"\\system\\temp.JOB.svg");// fileName);// use temp so we dont fill up with crap files
         
        byte[] source1 = loadBytes(selectedFile);
        saveBytes(dest1, source1);
        ///////////////////////////////////////////////////////////////////
   
        newPath = newPath.replace("CylinDrawRunMode", "CylinDrawViewer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
        //this is the target format = launch("cd C:/Sketch/application.windows64 && Sketch.exe");
        
        File dest = new File(savePath(newPath),"\\system\\temp.JOB.svg");// fileName);// use temp so we dont fill up with crap files
         
        byte[] source = loadBytes(selectedFile);
        saveBytes(dest, source);
        //dest.deleteOnExit(); 
         
        filePath = dest.getAbsolutePath();
        fileName = dest.getName();
       
        boolean success = dest.exists(); 
        if (!success) {
           DisplayData("Somethine went wrong...Make sure you only try to open '.svg' files.");
           launch(filePath);
        }else{
           DisplayData(".JOB.svg file found. Loading preview.");
           newPath = "cd " + newPath + "&& CylinDrawViewer.exe";
           launch(newPath); 
        }
}

void fileCopy(){  //If user picks file not located in processing parent folder, we copy it temporarily, then delete that copy on proper exit.  
  File file = saveFile(filePath); // File to be moved (the one the user selected. And if we are in fCopy then we know its in a different directory)
  ////////////////////////////////////////////////////////////fileName = fileName.replace(".svg",""); fileName = fileName + "-COPY" + str( (int)( random(9999) ) ) +".svg"; ///Option to extend the file name. Would only do this if it was a true file COPY instead of a move. which I cant figure out
  
  //This saves the file that will be loaded next time. 
  File dest = new File(savePath(sketchPath()),"\\system\\temp.svg");// fileName);// use temp so we dont fill up with crap files
  byte[] source = loadBytes(file);
  saveBytes(dest, source);//BE VERY CAREFUL WITH YOUR FILEPATHS. THIS PROGRAM CAN BLUESCREEN YOUR PC IF YOU MESS UP.
    
  fileSize = source.length;
  DisplayData("Loaded filesize in bytes=" + fileSize);
  if (fileSize <10000000){
      if (fileSize>1000000){
        bFastPreview=true;
        DisplayData("! Imported file size is large...program is auto-setting preview to a bounding box to keep from lagging. !");
        DisplayData("! (You can change the preview setting in the HELP menu.)");

      }
      //This saves the working file (I dont just use this because it end up makig the folder look messy
      dest = new File(savePath(sketchPath()),"temp.svg");// fileName);// use temp so we dont fill up with crap files
      source = loadBytes(file);
      
      
      saveBytes(dest, source); 
      dest.deleteOnExit(); //dangerous! But necessary! Basically if you choose any file there becomes 3 copys whol ethe program is open, but 1 of them is destroyed. The original is never moved.
    
      filePath = dest.getAbsolutePath();
      fileName = dest.getName();
     
      boolean success = dest.exists(); 
      if (!success) {
         DisplayData("Somethine went wrong...Make sure you only try to open '.svg' files.");
      }
  } else{
     DisplayData("Error. Filesize is too big! The program simply cannot load all that info.");
     DisplayData("Please remake the file with a lower resolution.");
  }
 // boolean success =  file.renameTo(dest); // MOVE NOT COPY THE FILE 
 // if (!success) { DisplayData("Somethine went wrong...Make sure you only try to open '.svg' files.");   }
} //end of copy()


void displayZero(){  // draw the zero axis X & Y lines 
    stroke(10);//(255, 255, 255); // axis lines   
    strokeWeight(1);
    line(0, 0, Xmax* plotScale, 0); //long horizontal line from x = 0 to x = xMax 
    line(0, 0, 0 , - Ymax* plotScale); //long vertical line from y = 0 to y = yMax 
    for(int i = 0 ; i < Xmax ; i++){ //horizontal zero reference line
      line( (float( i) * plotScale),0, ( float(i) * plotScale),- 3);  //3 is the LONG Line width. 
      if((i % 10) == 0) line( (float( i) * plotScale), 0, ( float(i) * plotScale), - 8); //8 is the tick mark length 
    } 
     for(int i = 0 ; i < Ymax ; i++){ //vertical zero reference line
      line(0, - (float(i)* plotScale), 3, - (float(i)* plotScale) ); //
      if((i % 10) == 0) line(0 , - (float(i)* plotScale),  8, - (float(i)* plotScale) ); //
    }  
}//end of drawZero()


void DisplayData(String in){ //Used to show serial data within the user application window
   // println(in); // Println IS ONLY USEFUL FOR DISPLAYING IN PROCSSINGS COMMAND WINDOW BELOW. It is darn slow and unecessary for displaing within Draw so its commented out.
    liveData = liveData + "\n" + in;
    
    logHold(in+"\n");
    
    int lineLimit = int((DisplayDataWindowY-17/5)/25);
   // println("DisplayedData " + in);
    dataCounter++; //# of lines of displayable data
    if (dataCounter>=lineLimit){  liveData = "\n" + in;  dataCounter = 0;} //note this 13 is used in the live system message window
    
} //end of DisplayData()

/*
void enterCupDimensions(){// this is the future nice interface   google  JOptionPane   complexMsg[]
     Object[] selectionValues = {
       "Pandas", "Dogs", "Horses", 
     };
     Object complexMsg[] = { 
         "Above Message", 
         new ImageIcon("yourFile.gif"), 
         new JButton("Hello"),
          new JSlider(),
         new ImageIcon("yourFile.gif"), 
         "Below Message" };

    JOptionPane optionPane = new JOptionPane();
    
    optionPane.setMessage(complexMsg);
    
      JFrame frame1 = new JFrame("Input Dialog for Cup Dimensions");  //Only need to call this if there is more than one frame i think
      frame1.setVisible(true);
      frame1.toFront();

    //JDialog dialog = optionPane.createDialog(null, "Width 100");
   // dialog.setVisible(true);
      
    String initialSelection = "Dogs";
    
   //Object selection = JOptionPane.showInputDialog(null, "What are your favorite animals?","Zoo Quiz", JOptionPane.QUESTION_MESSAGE, null, selectionValues, initialSelection
        
   // System.out.println(selection);
    
   String title ="Update Cup/Tool Dimensions.";
   int option = JOptionPane.showConfirmDialog(null, complexMsg,title, JOptionPane.OK_CANCEL_OPTION ); //, null, selectionValues, initialSelection);
   System.out.println(option);
  
  if (option == JOptionPane.CANCEL_OPTION || option == JOptionPane.OK_OPTION){
    frame1.setVisible(false); 
  frame1.toBack();
  }
} */

void checkLicense(String inputEmail,String inputKey) {
  boolean bRenewFree = true;
  File file = new File(sketchPath("\\system\\License.txt"));
  if (file.exists()) {
    try {
      String[] lines = loadStrings("\\system\\License.txt");
      if (lines != null) { 
        bTerms = true;//a free OR paid license has been found so eula is confirmed 
        
        int cheat1= inputKey.indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found (This is my overriding everything key, dont use this for customers)
        int cheat2= lines[0].indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found (This is my overriding everything key, dont use this for customers)
        int cheat3= inputKey.indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found
        char k0,k1,k2,k3,k4,c0,c1,c2,c3,c4,s0,s1,s2,t0,t1,t2;
        
        boolean bFound1 = true; //found via typed input
        try{
          if (inputEmail.length() <6 || inputEmail.indexOf("@")==-1  || inputEmail.indexOf(".")==-1||inputKey.length() !=30 ){
            bFound1 = false;
          }else{
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
                if (c0 != k0 || c1 != k1 || c2 != k2 || c3 != k3 || c4 != k4 ) {bFound1 = false;}                
                s0=inputKey.charAt(25);
                t0 = str(inputEmail.length()).charAt(0);
                if(s0 != t0 ) {bFound1 = false;}
                if (inputEmail.length() >9){
                  s1=inputKey.charAt(26);
                  t1 = str(inputEmail.length()).charAt(1);
                  if(s1 != t1 ) {bFound1 = false;}
                }
                if (inputEmail.length() >99){
                  s2=inputKey.charAt(27);
                  t2 = str(inputEmail.length()).charAt(2);
                  if(s2 != t2 ) {bFound1 = false;}
                }
          }
        }catch(RuntimeException e) {bFound1 = false;};
        //1111e1111h1111c1111e1111m26000
        boolean bFound2 = true; //found via read from file
        String sKeyRead = lines[0];
        String sEmailRead = lines[1];
        try{
          sKeyRead = lines[0];
          sEmailRead = lines[1];
          if (sEmailRead.length() <5 || sEmailRead.indexOf("@")==-1  || sEmailRead.indexOf(".")==-1 || sKeyRead.length() !=30 ){
            bFound2 = false;
          }else{
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
                if (c0 != k0 || c1 != k1 || c2 != k2 || c3 != k3 || c4 != k4 ) {bFound2 = false;} 
                s0=sKeyRead.charAt(25);
                t0 = str(sEmailRead.length()).charAt(0);
                if(s0 != t0 ) {bFound2 = false;}
                
                if (sEmailRead.length() >9){
                  s1=sKeyRead.charAt(26);
                  t1 = str(sEmailRead.length()).charAt(1);
                  if(s1 != t1 ) {bFound2 = false;}
                }
                if (sEmailRead.length() >99){
                  s2=sKeyRead.charAt(27);
                  t2 = str(sEmailRead.length()).charAt(2);
                  if(s2 != t2 ) {bFound2 = false;}
                }
          }
        }catch(RuntimeException e) {bFound2 = false;};
        
        if (cheat1 != -1 || cheat2  !=-1 || cheat3 !=-1){
          sKey = "XCg8_XA@RA=yyN4cW4FD";
          bPaid=true;
          bRenewFree = false;
        }else if(bFound2) {//found via read from file
          sKey = sKeyRead;
          sEmail = sEmailRead;
          bPaid=true;
          bRenewFree = false;
        }else if(bFound1){ //found via typed input
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
    sEmail = "example@gmail.com";
    DisplayData ("~Free license found. We hope you enjoy the free version of our product!~");
    DisplayData ("~To enable speed control, please enter a valid key in the help menu.~");
  }

  if (!bTerms) {
    String termsPath = sketchPath(); 
    termsPath = termsPath + "\\system\\CYLINDRAW_TERMS_OF_USE.pdf"; 
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
    String storedLicense =sKey + "\n"+ sEmail +"\n"+
      "Use of this license constitutes explicit acceptance of the end user license agreement per CYLINDRAW_TERMS_OF_USE.pdf \nPlease DO NOT redistribute CylinDraw Control software or your license keys in any form. \nVisit www.CylinDraw.com to get the latest release. \n  " ;   
    String licenseName = ("system\\License.txt");  
    String[] storedLicenseList = split(storedLicense, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
    saveStrings(licenseName, storedLicenseList);
  }
}


void enterCupDimensions2(){
  loadSettings(sToolProfile);
  JFrame frame1 = new JFrame("Input Dialog for Cup Dimensions");  //Only need to call this if there is more than one frame i think
  frame1.setVisible(true);
  frame1.toFront();
  
  JSlider sliderGoblet = new JSlider(0,2);
  sliderGoblet.setValue(cupType) ;
  //JTextField field1 = new JTextField(str(cupType), 20); //The last number is the field width
  JTextField field1 = new JTextField(sToolProfile, 17);
  JTextField field2 = new JTextField(str(cupDiaMax), 17);
  JTextField field3 = new JTextField(str(cupDiaMin), 17);
  JTextField field4 = new JTextField(str(cupHeight), 17);
  JTextField field5 = new JTextField(str(toolDia), 17);
  JTextField field6 = new JTextField(str(stemHeight), 17);
  //JTextField field7 = new JTextField(str(bMultiColor), 20);
  Object[] msgGoblet  ={
     "If Goblet, Enter Stem Height (mm):",field6,
     " ",
  };
  
  Object[] message = {
      "Cup/Tool Profile:",field1,
      " ",
      "Major Cup Diameter (mm):",field2,
      " ",
      "Minor Cup Diameter (mm):",field3,
      " ",
      "Total Cup Height (mm):", field4,
      " ",
      "Stroke Thickness (mm):",field5,
      " ",
      "|<< Clinder              Goblet              Paper >>|",      
      sliderGoblet,     // "Enter '0' for Cup or '1' for Goblet:",field1,
      " ",
     msgGoblet,
  };
 
  String title ="Update Cup/Tool Dimensions.";
  
  Object[] options = {"OK","CANCEL","LOAD PROFILE","SAVE PROFILE"}; 
  int option = JOptionPane.showOptionDialog(null,    //int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE); //THIS IS THE ORIGINAL
            message,
            title,
            JOptionPane.YES_NO_CANCEL_OPTION,
            JOptionPane.QUESTION_MESSAGE,
            null,
            options,
            options[0]); //select default options, 0 is OK make that default so you can click enter     
    
  cupType =sliderGoblet.getValue();
  if (cupType == 2){
   iChuckGrip = 0;
   field3 = field2; //set minor width to mahor width(paper has no taper)
  }else{iChuckGrip =9;}
  
  if (option == 0 || option == 3){// JOptionPane.OK_OPTION){
      String value1 = field1.getText();
      String value2 = field2.getText();
      String value3 = field3.getText();
      String value4 = field4.getText();
      String value5 = field5.getText();
      String value6 = field6.getText();
      //String value7 = field7.getText(); 
      try{ 
         cupType = sliderGoblet.getValue();// if (value1 != null){ Integer.parseInt(value1); }
         if (value1 != null){ sToolProfile = cleanString(value1); }else{sToolProfile="CupTool_LastUsed";}
         if (value2 != null){cupDiaMax = Float.parseFloat(value2);}
         if (value3 != null){ cupDiaMin = Float.parseFloat(value3); } 
         if (value4 != null){ cupHeight = Float.parseFloat(value4); } 
         if (value5 != null  && ! bLocallyMade ){ toolDia = Float.parseFloat(value5); } //Dont overwright if locally made !       no, just dont load OVER it if locally made
         if (value6 != null){ stemHeight = Float.parseFloat(value6); }
         if (stemHeight < iChuckGrip){stemHeight= iChuckGrip;};
         if (stemHeight > cupHeight){stemHeight= cupHeight;};
        // if (value7 != null){ bMultiColor = Integer.parseInt(value7); } 
         Xmax = cupDiaMax*PI; //T axis maximum in mm 
         Ymax = (cupHeight);
         displayStatus ="Cup Dimensions: Major dia:" + cupDiaMax + "mm. x Minor dia:" + cupDiaMin + "mm. x Cup Height:" + cupHeight + "mm tall.  Stroke:" + nf(toolDia,0,2) + "mm"; // 
         DisplayData("Cup/Tool Dimensions Updated!");
         
         String storedSettings = sToolProfile;//"This file exists to store your cup & tool dimensions when the program is closed. ";
         String contents = "\n Cup Type (0 = cylinder, 1 = goblet, 2= paper) \n" + cupType + "\n Max Cup Diameter in mm \n" + cupDiaMax + "\n Min Cup Diameter in mm \n" + cupDiaMin + "\n Cup Height in mm \n" + Ymax + "\n Stroke Thickness in mm \n" + toolDia  + "\n Goblet Stem Height in mm \n" + stemHeight;//+ "\n Line Overlap Percentage \n";// + overlap + "\n MultiColor \n" + bMultiColor + "\n";
         storedSettings = storedSettings + contents;
         
         String settingsName = ("system//CupTool_LastUsed.txt");  //DEFAULT
         String[] storedSettingsList = split(storedSettings, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
         saveStrings(settingsName, storedSettingsList); 
      
         if (option == 3){ //save tool  profile
           if (sToolProfile != "CupTool_LastUsed"){
               if (! sToolProfile.contains("CupTool_")){
                 sToolProfile = "CupTool_"+sToolProfile ;
               }
               settingsName = ("system//"+ sToolProfile+".txt");  
               String pathTo =sketchPath(settingsName);
               storedSettingsList = split(storedSettings, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
               saveStrings(settingsName, storedSettingsList); 
               
                  Object[] messageOK = {
                    sToolProfile,
                    "Tool Profile saved for future use at: ",
                    pathTo,
                  };
                  JFrame frame12 = new JFrame("Notice");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
                  frame12.setVisible(true);
                  frame12.toFront(); 
                  //frame12.setAlwaysOnTop(true);
                  frame12.setLocation(xWindow/2, yWindow/2);
                  JOptionPane.showMessageDialog(frame12, messageOK, "NOTICE!", JOptionPane.INFORMATION_MESSAGE);
                  frame12.setVisible(false);
                  frame12.toBack();
                  frame12.dispose();
             
              frame1.setVisible(false); 
              frame1.toBack();
              frame1.dispose();
              DisplayData("Saved new tool profile: " +sToolProfile);
              enterCupDimensions2();
            }
          }
         
         
         plotScale = 2.3*160/cupHeight;  //experimentally determined to procude a default scale that fits everything on screen. The scale can still adjust with the mouse.      
      }catch(NumberFormatException ne){
            JOptionPane.showConfirmDialog(null,"Invalid Input! Please input NUMBERS ONLY. Try Again.","Input Error", JOptionPane.DEFAULT_OPTION, JOptionPane.ERROR_MESSAGE);
      }
      //once = 0; //reset the preview display loader 
  }
    
  frame1.setVisible(false); 
  frame1.toBack();
  frame1.dispose();
  
  if (option == 1){//JOptionPane.CANCEL_OPTION){
    DisplayData(">User Clicked Cancel. (no info was updated.)<");
  }
  if (option == 2){//load tool profile
    
    DefaultListModel dlm = new DefaultListModel();  
    String path = sketchPath("\\system");//"C:/New folder"; 
    String files;
    File folder = new File(path);
    File[] listOfFiles = folder.listFiles(); 
    for (int i = 0; i < listOfFiles.length; i++) { 
         //println(i);
         if (listOfFiles[i].isFile()) {
               files = listOfFiles[i].getName();
               //println(files);
               if (files.endsWith(".txt") && files.contains("CupTool_") )   {
                   dlm.addElement(files);
               }
         }    
    }
    
    JList list = new JList(dlm);
    JOptionPane.showMessageDialog(null,  new JScrollPane(list));
    String selectedTool ="";
    if (list.getSelectedValue() !=null) {
      selectedTool =list.getSelectedValue().toString();//System.out.println(list.getSelectedValue());
      selectedTool = selectedTool.replace(".txt","");
    }
    println("selected:"+selectedTool);
    
    loadSettings(selectedTool); //here23
    enterCupDimensions2();
  }

  //Copied from mouse wheel interaction to ensure screen centers rectangle display
      if (plotScale <.1){ plotScale =.1; }
      plotyShift = int(0+plotScale*Ymax*.5-height/2+200);
      shapeLoaded = false; 
  
} //end of void EnterCupDimensions()


void loadSettings(String sCupToolFile){ //open CupTool_LastUsed 'settings.txt'. Collect info and update dimensions. Do this when first opening this program.
  if (sCupToolFile.length() <1 ){ ///here23
    sCupToolFile ="CupTool_LastUsed";
  }

  plotxShift=0;  //leave at zero so its centered
  plotyShift = int(0+plotScale*Ymax*.5-height/2+200);
  sCupToolFile=sCupToolFile.replace(".txt","");//remove in case it was already here
  sCupToolFile = "\\system\\"+sCupToolFile+".txt";
  File file = new File(sketchPath(sCupToolFile));//"\\system\\CupTool_LastUsed.txt"));
    if (file.exists()) {
     try{
        String[] lines = loadStrings(sCupToolFile);//"\\system\\CupTool_LastUsed.txt");
        if (lines != null){
          sToolProfile= lines[0]; //update the global variable!
          cupType = int(lines[2]);//The zero line is the header line so we skip it. & there are note lines so we skip every other line 
          cupDiaMax = float(lines[4]);
          cupDiaMin= float(lines[6]);
          cupHeight = float(lines[8]);
          if (!bLocallyMade){ toolDia = float(lines[10]); }
          stemHeight = float(lines[12]);
          
          //round((RealHeight/(toolDia))*(100/(100-overLap))); //overlap.....
          
          //bMultiColor = int (lines[14]);

          Xmax = cupDiaMax*PI; 
          Ymax = (cupHeight);
          displayStatus ="Cup Dimensions: Major dia:" + cupDiaMax + "mm. x Minor dia:" + cupDiaMin + "mm. x Cup Height:" + cupHeight + "mm tall. Stroke:" + nf(toolDia,0,2) + "mm"; // 
          DisplayData ("Default cup dimensions loaded using previous settings.");
             // for (int i = 0 ; i < lines.length; i++) {//println(lines[i]);  //}
      }
      }catch(NumberFormatException ne){ DisplayData("No saved settings available");}
    } else { displayStatus ="(No 'CupTool_LastUsed.txt' file found, click 'Cup/Tool Dimensions' then 'OK' to create one!)";}// DisplayData("No 'CupTool_LastUsed.txt' file found, click 'Update Cup/Tool Dimensiosn to create one!");}
    
}//end of LoadSetings
 
 
 
 
 
void buttonLoadSVG(){
     
      DisplayData("Select a file to load: ");
      selectInput("Select a file to process: ", "fileSelected", storedFile); //selectInput(prompt, callback, file)  DO NOT CHANGE the phrase "fileSelected". It it not just text but returns a call to a function!
     // thread("cum");//attempt to ensure shit will pop up on top!
}

void cum(){
      //File file = null; 
      DisplayData("Select a file to load: ");
     // JFrame frame32 = new JFrame("Input Dialog");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
     // frame32.setVisible(true);
      //frame32.toFront();
    // / frame32.isAlwaysOnTop();
      selectInput("Select a file to process: ", "fileSelected", storedFile); //selectInput(prompt, callback, file)  DO NOT CHANGE the phrase "fileSelected". It it not just text but returns a call to a function!
     // frame32.setVisible(false);
     // frame32.toBack();   
      //frame32.dispose();
}


void buttonUpdate(){ enterCupDimensions2(); shapeLoaded = false; } 
  
void buttonSave(){  
  File shit = storedFile;
   if (bExplicitExport){
       selectOutput("Name the OUTPUT file :", "exportSelected",shit);
   }else{
       exportSelected(shit );// need to modify export selected to append proper folder path
   }
}


void exportSelected(File selection) {
    if (selection != null){
        destName = selection.getPath();//selection.getName();//.getAbsolutePath(); 
    } else {
        println("File save callback is: NULLLLLLL" );
        DisplayData("Error please try again...");
        int index = fileNameOriginal.indexOf("."); //find dot & remove it from original name by only saving everything up to it
        destName = destName+ fileNameOriginal.substring(0,index);
        return;
    }
    
    if (destName.contains(".BMP") || destName.contains(".JPG") ||destName.contains(".PNG") || destName.contains(".bmp") || destName.contains(".jpg") ||destName.contains(".png")) {      
        int index = destName.indexOf("."); //find dot & remove it from original name by only saving everything up to it
        destName = destName.substring(0,index);
        destName = destName+ ".JOB.svg";
    } 
    
    if(destName.contains(".JOB")|| destName.contains(".job") == false){
        int index = destName.indexOf("."); //find dot & remove it from original name by only saving everything up to it
        destName = destName.substring(0,index);
        destName = destName+ "";
    }
     if (destName.contains(".svg") || destName.contains(".SVG") ) {      
        int index = destName.indexOf("."); //find dot & remove it from original name by only saving everything up to it
        destName = destName.substring(0,index);
        destName = destName+ "";
    } 

    if(destName.contains(".JOB.svg") == false && destName.contains(".JOB.SVG") == false){
        destName = destName+ ".JOB.svg";
    }
    cursor (WAIT);
    bSavingFile = true;
    shapeLoaded = false;
    thread("loadShapes");
}



void toggleFill(){   
  if (shapeLoaded == true){
    shapeLoaded = false;
   // bFillDrawing = !bFillDrawing; 
   bFillDrawing = toggleFill.getBooleanValue();
    if (bFillDrawing == false){DisplayData( "Infill Disabled"); toggleOutline.hide(); if(bBlkOutline){toggleOutline.setValue(0);bBlkOutline = false; }  }
    else
      DisplayData( "Infill Enabled");
       if ( bMultiColor) {toggleOutline.show();}
  }
}

void toggleMultiColor(){   
  if (shapeLoaded == true){
    shapeLoaded = false;
   // bMultiColor = !bMultiColor; 
   bMultiColor = toggleMultiColor.getBooleanValue();
    if (bMultiColor== false){
      DisplayData( "MultiColor Disabled"); toggleOutline.hide(); if(bBlkOutline){toggleOutline.setValue(0);bBlkOutline = false; }  }
    else 
      DisplayData( "MultiColor Enabled");
      if ( bFillDrawing) {toggleOutline.show();}
  }
}

void toggleOutline(){   
  if (shapeLoaded == true){
    shapeLoaded = false;
   // bBlkOutline = !bBlkOutline; 
   bBlkOutline = toggleOutline.getBooleanValue();
    if (bBlkOutline == false){DisplayData( "Extra outline Disabled");}
    else {DisplayData( "Extra outline Enabled");}
  }
}

void buttonRotateLeft(){     if (shapeLoaded == true){shapeLoaded = false; rotateAngle -= 5*PI/180; DisplayData( " Drawing Rotated -5 deg. Total angle is: " + rotateAngle*180/PI + " degrees");}}

void buttonScaleUp(){    if (shapeLoaded == true){shapeLoaded = false; imageScaleAdjust = imageScaleAdjust+ (imageScale+imageScaleAdjust)*0.05; DisplayData( "Drawing Scaled Larger");}}

void buttonScaleDown(){    if (shapeLoaded == true){shapeLoaded = false; imageScaleAdjust = imageScaleAdjust- (imageScale+imageScaleAdjust)*0.05; DisplayData( "Drawing Scaled Smaller");}}

void buttonRotateRight(){    if (shapeLoaded == true){shapeLoaded = false; rotateAngle += 5*PI/180; DisplayData( " Drawing Rotated +5 deg. Total angle is: " + rotateAngle*180/PI + " degrees");}}

void buttonMoveLeft(){ if (shapeLoaded == true){shapeLoaded = false; xShift--; DisplayData( "You clicked the 'LEFT arrow Key'. Drawing Moved LEFT");}} 

void buttonMoveUp(){  if (shapeLoaded == true){shapeLoaded = false; yShift--; DisplayData( "You clicked the 'UP Arrow Key'. Drawing Moved UP");} }

void buttonMoveDown(){  if (shapeLoaded == true){shapeLoaded = false; yShift++; DisplayData( "Drawing Shifted 'DOWN Arrow Key' Drawing Moved Down");}}

void buttonMoveRight(){  if (shapeLoaded == true){shapeLoaded = false; xShift++ ;DisplayData( "You clicked the 'RIGHT Arrow Key'. Drawing Moved RIGHT");}}

void buttonExit(){
  String title ="Exit program?";
  String message = "Are you sure you want to exit the program? Anything not saved will be lost.";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ 
    logWrite(true);//commit entire log to txt file
    exit();  
  }
  if (option == JOptionPane.CANCEL_OPTION){  DisplayData(">User Clicked Cancel.<");  
      frame3.setVisible(false);
      frame3.toBack();
      frame3.dispose();
  }
}//end of ButtonExit

void buttonSupport(){
  
  String title ="SUPPORT MENU";
 
  JButton buttonAmazon = new JButton("Shop on Amazon.com");
  buttonAmazon.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://amzn.to/2SxA5Vj");
    }
  }); 
  
   JButton buttonEbay = new JButton("Shop on Ebay.com");
  buttonEbay.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://ebay.us/z0g6Yh");
    }
  });
  
    JButton buttonStore = new JButton("Visit our Shop");
  buttonStore.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://amzn.to/2SxA5Vj");
    }
  });
  
  JButton buttonHomepage = new JButton("Visit CylinDraw Homepage");
  buttonHomepage.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://cylindraw.com/");
    }
  });
  
    JButton buttonDiscord = new JButton("Visit CylinDraw Forum");
  buttonDiscord.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://discord.gg/pWGrQ9uyqD");
    }
  });
    JButton buttonCoffee = new JButton("Buy Us a Coffee");
  buttonCoffee.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://www.buymeacoffee.com/MichaelGraham");
    }
  });

  Object[] msg = {
    
          "For questions concerning your order contact us at CylinDraw@gmail.com.",
          " ",
          "For technical questions or to show off your work join the conversation on Discord:",buttonDiscord,
          " ",
          "Check out our web store for the latest kits, upgrades, replacement consumables:",buttonStore,
          " ",
          "Support us by buying new cups & pens from our affiliate partners",
          buttonAmazon, buttonEbay,
          " ",
          "Inspire us to work harder on new features",buttonCoffee,
          " ",          
          "Visit our website homepage:",buttonHomepage,
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
  
  int defaultExport =0;
  if (bExplicitExport){defaultExport =1;}
  JSlider slideExport = new JSlider(0,1,defaultExport);//3rd value is default
  
  int defaultPreview =0;
  if (bFastPreview){defaultPreview =1;}
  JSlider slideFastPreview = new JSlider(0,1,defaultPreview);//3rd value is default
  
  int defaultHone =1;
  if (bPathOptimize){defaultHone =0;}
  JSlider slideHone = new JSlider(0,1,defaultHone);//3rd value is default
  
  JTextField fieldLicense = new JTextField(sKey, 20);
  JTextField fieldEmail = new JTextField(sEmail, 20);
  
  String title ="HELP MENU";
    
  JButton buttonLicense = new JButton("Get License Key");
  buttonLicense.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://cylindraw.com/shop/");
    }
  });
  
  Object[] msg1 = {
      buttonLicense,
      "Enter your email address here:", fieldEmail, 
      "Enter your license key here:", fieldLicense, 
  };
  Object[] msg2 = {
      sVersion, 
  };
  Object[] msg3 = {
      "This is 'Job Creation Mode'.",
          "Here we convert generic '.svg' files into defined '.JOB.svg' files that your machine can draw in RUN MODE ",
          " INSTRUCTIONS: ",
          "  1. Begin by pressing the 'LOAD SVG' button to load an '.svg' file.",
          "  2. Then press 'UPDATE DIMENSIONS' to adjust the cup & tool size. (Settings will be saved for next time.)",
          "  3. Manipulate image as needed, then press 'SAVE JOB'. ",
          "  4. Then switch over to the 'Run Mode' to run that job!",
          "About the Display Preview Box: ",
          "  -In the box the white area is the working area. The blue lines show the visible front face of the cup. Red lines show usable boundaries (basically the cup surface unwrapped).",
          "  -Rolling your mouse wheel or pressing arrow keys is for view adjusting purposes only, it does not change the final output.",
          "A note on the toggle options:",
          "  -'Mono vs Multicolor': create a job that prompts you to change pen color to match the svg file.",
          "  -'Normal vs Black Outline': add an extra black outline at the very end of the job for artistic purposes. ",
          "  -'No Fill vs Fill': Fill draws objects solid as shown in the preview. (This takes more time to draw.)",
          " ",
          "|<<Auto Name Exported File      OR      Manually Name Exported File >>|",
          slideExport,
           " ",
          "|<<Display Full Preview      OR      Display Bounding box only>>|",
          slideFastPreview,
           " ",
          "|<<Enable Path Optimization      OR      Disable Path Optimization>>|",
          slideHone,
           "(Note: Path optimization makes saving files take longer but drawing them should take less time.)", 
           " ",
           
  };
 
 Object[] messageUnpaid = {
      msg1,
      msg2,
      msg3,
        
    };
     Object[] messagePaid = {
      "Full License Found, You are awesome!",
      msg2,
      msg3,
         
    };
  
  JFrame frame33 = new JFrame("INSTRUCTIONS");  //Only need to call this if there is more than one frame i think
  frame33.setVisible(true);
  frame33.toFront();
  frame33.setLocation(xWindow/2, yWindow/2);
  int option =0;
  if (!bPaid){
    option = JOptionPane.showConfirmDialog(null, messageUnpaid, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.INFORMATION_MESSAGE);
  }else{
    option = JOptionPane.showConfirmDialog(null, messagePaid, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.INFORMATION_MESSAGE);
  }    
 
  if (option == JOptionPane.OK_OPTION) {
      if (slideExport.getValue() ==0){
          bExplicitExport = false;
      }else{
          bExplicitExport = true;
      }
      
      if (slideFastPreview.getValue() ==0){
          bFastPreview = false;
      }else{
          bFastPreview = true;
      }
      if (slideFastPreview.getValue() != defaultPreview ){ once = 0;} //cause the preview to reload
      
      if (slideHone.getValue() ==0){
          bPathOptimize = true;
      }else{
          bPathOptimize = false;
      }  
      
    //println(fieldEmail.getText());
   // println(fieldLicense.getText());
    checkLicense(fieldEmail.getText(),fieldLicense.getText()); //CHECKED LICENSE HERE to see if PAID
    
    if (bPaid) { 
      ;
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

 
void buttonProgConvert(){
  String title ="Switch to DePixelizer Mode?";
  String message = "Are you sure you want to switch to DePixelizer Mode? (The currently loaded job will be reset.)";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ 
      String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.       
      //newPath = newPath.replace("CylinDrawRunMode", "");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
        //this is the target format = launch("cd C:/Sketch/application.windows64 && Sketch.exe");
      newPath = newPath.replace("CylinDrawJobCreator", "CylinDrawDePixelizer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
      newPath = "cd " + newPath + "&& CylinDrawDePixelizer.exe";
      launch(newPath); 
      logWrite(true);//commit entire log to txt file
      exit();   
  }
  if (option == JOptionPane.CANCEL_OPTION){  DisplayData(">User Clicked Cancel.<");  }
  frame3.setVisible(false);
  frame3.toBack();
  frame3.dispose();
}


void buttonProgCreate(){  DisplayData("You are currently using Creation Mode."); }


void buttonProgRun(){
  String title ="Switch to Run Mode?";
  String message = "Are you sure you want to switch to Run Mode? (The currently loaded job will be reset.)";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ 
      String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
         
      //newPath = newPath.replace("CylinDrawRunMode", "");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
        //this is the target format = launch("cd C:/Sketch/application.windows64 && Sketch.exe");
      newPath = newPath.replace("CylinDrawJobCreator", "CylinDrawRunMode");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
      newPath = "cd " + newPath + "&& CylinDrawRunMode.exe";
      launch(newPath); 
      logWrite(true);//commit entire log to txt file
      exit();   
  }
  if (option == JOptionPane.CANCEL_OPTION){  DisplayData(">User Clicked Cancel.<");  }
  frame3.setVisible(false);
  frame3.toBack();
  frame3.dispose();
}

/*
float colorDist(color c1, color c2)
{
  float rmean =(red(c1) + red(c2)) / 2;
  float r = red(c1) - red(c2);
  float g = green(c1) - green(c2);
  float b = blue(c1) - blue(c2);
  // equall weighted average
      //rmean =  ((red(c1) + red(c2))/2 + (green(c1) + green(c2))/2 + (blue(c1) - blue(c2))/2 )/3;
  // average by Luminance  0.3 R + 0.59 G + 0.11 B
      //rmean = (.3*(red(c1) + red(c2))/2 + .59*(green(c1) + green(c2))/2 + .11*(blue(c1) - blue(c2))/2 )/3;
  return  sqrt((int(((512+rmean)*r*r))>>8)+(4*g*g)+(int(((767-rmean)*b*b))>>8));  //(767 is max value)
} //end of colorDist()
*/

float colorDist(color c1,color c2){ //min value is 0 max is 441.673 when colors are constrained between 0-255
  return  dist(red(c1),green(c1),blue(c1),red(c2), green(c2),blue(c2));
} 



void inVert(RShape s ) {  //Convert all shape colors to black
  RShape[] ch; // children
  int n, i; 
  n = s.countChildren();
  if (n > 0) {
    ch = s.children;
    for (i = 0; i < n; i++) {
      if (ch[i].getStyle().fill){
        RStyle shit = new RStyle();
        shit.setFill(color(0));
        ch[i].setStyle(shit);
      }
      inVert(ch[i]);
    }
  }
}


void exVert(RShape s, color c, boolean bPerimeter, boolean bFill) {  // Inputs: The RShape you want to parse, a color, bool parse outlines, bool pase infill)
  RShape[] ch; // children
  int n, i; 
  n = s.countChildren();
  iChildCounter++;   if( iMaxChildCounter < iChildCounter){iMaxChildCounter = iChildCounter;}
  
  RPoint LocaltopLeft = s.getBottomLeft();
  RPoint LocalbottomRight = s.getTopRight();
  
 /*
  if (s.getStyle().stroke || s.getStyle().fill){ //imsplied else is that c0 uses he same color so it is skipped automatically. This process is just for telling us how many unique colors there are.
        if (s.getStyle().stroke){
          c = s.getStyle().strokeColor;
        }  else if (s.getStyle().fill ){
          c = s.getStyle().fillColor;
        } //else { c = color(0,0,0);} //CANNOT BE (0,0,0)...?       
  }///else { c = color(0,0,0);}  */
  c0=c;
 // println("color #" + iColorIndex + " is " + c0);
  if (n > 0) {
    ch = s.children;
    for (i = 0; i < n; i++) {      
      
      if (ch[i].getStyle().stroke || ch[i].getStyle().fill){ //imsplied else is that c0 uses he same color so it is skipped automatically. This process is just for telling us how many unique colors there are.
      
        if (ch[i].getStyle().stroke){
          c0 = ch[i].getStyle().strokeColor;
        }  else if (ch[i].getStyle().fill ){
          c0 = ch[i].getStyle().fillColor;
        } //else { c0 = color(0,0,0); } //CANNOT BE (0,0,0)...?
        
        //println("color #" + iColorIndex + " is " + c0);
        if (iColorIndex > 0){// && bBlkOutline == false ) {
          int rev =0;
          boolean bNewColor = true;
          for (rev =0; rev<=iColorIndex; rev++){
             if(colorDist(c0,colorArray[rev]) < 1 ){// (767/12)<< Will seperate the 12 as a max number of unique colors parameter<<<<<<<<<<<<<<<<<<<<<<< //if( c0 == colorArray[rev] ){// reduces pen changes if same color detected on another layer.   == result in more unique colors, the color dist statement reduces to a controllable number of colors
                c0 = colorArray[rev];//if the color is too similiar to a previous one, just call it that and go //println("...Essentially the same color detected. Copy color & break....");
                bNewColor = false;
                break;  
              }
           }
           if (bNewColor){//(rev>=iColorIndex){ //if true then it broke cycle early and we have a new color  //println("New color detected ............................................................................");
              iColorIndex++;     //  println("iColorIndex is " + iColorIndex);
              //println("color #" + iColorIndex + " is " + c0);
              if( iMaxNumColors <= iColorIndex){iMaxNumColors = iColorIndex;}
              if(bBlkOutline){iMaxNumColors = iColorIndex+1;}
              colorArray[iColorIndex] = c0;
           }
        } else { //exception for very first color detected (could be any color not just black)
           colorArray[0] = c0;
           iColorIndex++;
           iMaxNumColors = 1; //hard set to 1
        }
      }//then no fill detected, use same color as last detected
      
      if (bBlkOutline && bPerimeter){c0=color(0);}
      exVert(ch[i], c0, bPerimeter,bFill );
      
    }
  } else { // no children -> that means it IS a path, work on vertexes
  
  
    //println("s shape cyclecount: " + iChildCounter);
    
    ///////////////////////////////////////////////////////////////////////////////////
    //////////////////////PERIMETER infill paths - TAB
    ///////////////////////////////////////////////////////////////////////////////////
     if (bPerimeter){
         penIsDown = true;//just assume it is down before doing a perimeter
          if (penIsDown){ //moving from something else to a fill, ensure pen is up
              arrList.add(new Point(0,0, -20.0, c)); //LIFT
              penIsDown = false;  
          }
          RPoint[][] pa = s.getPointsInPaths();  //experimental //getHandlesInPaths    //getTangentsInPaths
         int ccc =0, a=0, b=0; 
          try{
            if (pa != null) { ccc = pa.length;} 
            for (a=0; a<ccc; a++) { //perimeter of local shape
              if (pa[a] !=null)for (b=0; b<pa[a].length; b++) {
                if (b==0) {
                  arrList.add(new Point(pa[a][b].x, pa[a][b].y, 0, c));  // z = -10z :beginn of a path
                  arrList.add(new Point(0, 0, -10.0, c));  // DROP z = -10z :beginn of a drawing path (drop pen)
                  penIsDown = true;
                } else {
                  if (b==pa[a].length-1) {
                    arrList.add(new Point(pa[a][b].x, pa[a][b].y, 0, c)); // z = -20z :end of a path final point
                    arrList.add(new Point(0,0, -20.0, c)); //LIFT
                    penIsDown = false;
                  } else {         
                    arrList.add(new Point(pa[a][b].x, pa[a][b].y, 0.0, c));
                  }
                }
              }
            } //end of Perimeter of local shape 
          }catch(NumberFormatException ne){ DisplayData("File Load error ID 25...");}
          
          
          if (penIsDown){ //moving from something else to a fill, ensure pen is up
              arrList.add(new Point(0,0, -20.0, c)); //LIFT
              penIsDown = false;  
          }
     }
     
    ///////////////////////////////////////////////////////////////////////////////////
    //Now to create infill paths - TAB
    ///////////////////////////////////////////////////////////////////////////////////
    //void exVert
    if ( bFill && !bLocallyMade ){ //Infill of THIS localshape (also only process this on a save file cycle because its slow!
          //println("Shape Change----------- ");
          // penIsDown = false; 
          if (penIsDown){ //moving from something else to a fill, ensure pen is up
            arrList.add(new Point(0,0, -20.0, c)); //LIFT
            penIsDown = false;  
          } 
          
          float dotArrayWidth = abs(LocalbottomRight.x - LocaltopLeft.x)+.5;
          int numArrayCols = (int)(dotArrayWidth/((toolDia/2)*(100-xOverlap)/100));//(toolDia*plotScale)); The 0.5 is becuase i set this to be an integer 
          
          float dotArrayHeight  = abs(LocalbottomRight.y - LocaltopLeft.y)+.5;
          int numArrayRows = (int)(dotArrayHeight/(toolDia/2*(100-yOverlap)/100));//(toolDia*plotScale)); 
          //dotArrayX = new float[numArrayRows][numArrayCols]; //Create an array of points spaced in X & Y evenly by the tool diameter. Placed here because you will need a new array for every new path
         // dotArrayY = new float[numArrayRows][numArrayCols];  
          stroke(c); strokeWeight(0.5); 
          
          int iGroupsMax = 9999;
          
          
          int countNodes =0;
          int countNodesOld =0;
          
          boolean swoopUp = true;
          
          float[] oldYup = new float[iGroupsMax];//used to check if connection is out of reasonable range for a (if connect moves to to lower than the lower point you ject cae from then jump there instead
          float[] oldYdown = new float[iGroupsMax];//used to check if connection is out of reasonable range for a (if connect moves to to lower than the lower point you ject cae from then jump there instead
          float[] oldXup = new float[iGroupsMax];//used to check if connection is out of reasonable range for a (if connect moves to to lower than the lower point you ject cae from then jump there instead
          float[] oldXdown = new float[iGroupsMax];//used to check if connection is out of reasonable range for a (if connect moves to to lower than the lower point you ject cae from then jump there instead

          float[] nullY =new float[iGroupsMax];

          boolean[] arrInit = new boolean[iGroupsMax];// = false by default;

          ArrayList[] arrSubLists = new ArrayList[iGroupsMax]; //THIS WILL NEED TO BE LIKE 9999, but is there a way I can figure out how many groups there will be ....
          ArrayList[] arrGroupLists = new ArrayList[iGroupsMax]; //THIS WILL NEED TO BE LIKE 9999, but is there a way I can figure out how many groups there will be ....
         
          for (int ddd =0; ddd<iGroupsMax;ddd++){
              arrSubLists[ddd]  = new ArrayList();
              arrGroupLists[ddd]  = new ArrayList();
          }

          for (float cc = 0; cc <numArrayCols; cc++) {//ONE SHAPE! //Starting at the top LEFT X point (c) on the bounding box, iterate through columns for the given row.
              
              float xPositionConst =  (float)(cc)*toolDia*(100.0-xOverlap)/100.0 +(LocaltopLeft.x); //constant for this loop of cc, saves some calculations
              float yminny =  Ymax  + (LocalbottomRight.y) - (Ymax-dotArrayHeight); //do basic maths here so we dont have to repeat same operations within loop for this shape!
              float ymaxxy = ((Ymax - (float)(numArrayRows)*toolDia*(100.0-yOverlap)/100.0)) + (LocalbottomRight.y) - (Ymax-dotArrayHeight);
              RShape cuttingLine = RG.getLine(xPositionConst, yminny, xPositionConst, ymaxxy); 
             
              RPoint[] intersectionList = s.getIntersections(cuttingLine); // Get the intersection points between the current local shape 's' and the line we generated

              //countNodes =0;
              if (intersectionList != null ) {
                countNodes = intersectionList.length; 
                                           
                  float[] tempListYold = new float[countNodes];//
                  for (int pnt=0; pnt<countNodes; pnt++) {
                    tempListYold[pnt] = intersectionList[pnt].y;                
                  }
                                  
                  tempListYold =  sort(tempListYold);//arrange y points in assending order, this is key, it works because we are looking at a 1D array
                  
                  float[] tempListY = new float[countNodes];//
                  float[] tempListX = new float[countNodes];//
                  
                  int cnt =0;
  
                  for (int pnt=0; pnt<countNodes; pnt++) {  
                      tempListX[cnt] = intersectionList[pnt].x;
                      tempListY[cnt] = tempListYold[pnt];
                      cnt++;
                  }
                  
                  ////All above is for a single line intersection, testing countnodes for cases 1-5 & removing cases where we dont want to draw them!
                  //THis temporary line notifies us if a correction is made 
                  if (countNodes != cnt  & cnt >1){println("countNodes was " + countNodes);println("countNodes IS " + cnt); countNodes = cnt;}  //is not triggered most of the time 
                  if (countNodes ==1){println("countNodes was ONE! BAD " + countNodes);}
                     
                    if ((int)(cc) % 2 != 0){ //if cc is ODD then swoop UP..... EVEN swoop DOWN 
                      swoopUp = true;////////cuttingLine = RG.getLine(xPositionConst, yminny, xPositionConst, ymaxxy); 
                    } else{swoopUp = false;}/////cuttingLine = RG.getLine(xPositionConst, ymaxxy, xPositionConst, yminny); }   // RG.shape(cuttingLine); //draw line
                  
                  
                  if (swoopUp ){//&& countNodes > 1
                    for (int pnt=0; pnt<countNodes; pnt++) {
                      //if(pnt==0 && countNodesOld != countNodes){ arrInit[int(pnt/2)] = false;}
                     // if( countNodesOld != countNodes){ arrInit[int(pnt/2)] = false;countNodesOld = countNodes;}
                     // if (int(pnt) %2==0  ){ arrInit[int(pnt)] = false;}
                      ///////////////////OLD/if (pnt % 2 ==0 && abs(tempListY[pnt]) > abs(oldYdown[int(pnt/2)])) {arrInit[int(pnt/2)] = false;} //Transfer move-CHECK Y. if transfer move is greater than the actual move. THIS COULD STILL BE USEFUL IF IT DOESNT CAUSE ERRORS... 
                      if (pnt % 2 ==0 && abs(abs(tempListY[pnt]) - abs(oldYdown[int(pnt/2)])) > toolDia ) {arrInit[int(pnt/2)] = false;} //Transfer move-CHECK Y. if transfer move is greater than the actual move
                      if (pnt % 2 ==0 && abs(tempListX[pnt]) >(abs(oldXdown[int(pnt/2)])+ 1.00*toolDia*(100.0-xOverlap)/100.0   )) {arrInit[int(pnt/2)] = false; }//Transfer move-CHECK X
                      //reversing algorythm
                      //if (pnt % 2 ==0 && abs(tempListX[pnt]) >(abs(oldXdown[int(pnt/2)])+ 0.49*toolDia*(100.0-xOverlap)/100.0   )) {arrInit[int(pnt/2)] = false; }//Transfer move-CHECK X//

                      if (arrInit[int(pnt/2)] == false ) { //(initilalize the use of this arraylist if it is new)
                        //if (penIsDown){ //moving from something else to a fill, ensure pen is up
                          arrSubLists[int(pnt/2)].add(new Point(0,0, -20.0, c)); //LIFT
                          penIsDown = false;  
                        //}
                        arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c)); 
                        arrSubLists[int(pnt/2)].add(new Point(0,0, -10.0, c)); //-10z DROP
                        penIsDown =true;
                        arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c)); //go to the same point as above for svg display reasons
                        arrInit[int(pnt/2)] = true; 
                        penIsDown = true;
                      }else{ arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c)); }
                      if (pnt % 2 != 0){oldYup[int(pnt/2)] = tempListY[pnt]; oldXup[int(pnt/2)] = tempListX[pnt];}  // When moving UP the even numbered points are the target location of the transfer, and the odd is the end of the line
                      //if ((pnt+1)>=countNodes  && countNodesOld != countNodes ){
                      //  countNodesOld = countNodes;
                       //  arrSubLists[int((pnt+1)/2)].add(new Point(0,0, -20.0, c)); //LIFT
                        // arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c)); 
                         
                      //}
                    } oldYdown = nullY;
                    
                   }else{ //if ( countNodes > 1){ //Swooping DOWN
  
                      for (int pnt=countNodes-1; pnt>=0; pnt--) {
                       // if (pnt %2!=0 ){ arrInit[int(pnt)] = false;}
                       // if (pnt %2==0 ){ arrInit[int(pnt/2)] = false;}
                        //if(pnt==countNodes-1  && countNodesOld != countNodes){ arrInit[int(pnt/2)] = false;}'
                        //if( countNodesOld != countNodes){ arrInit[int(pnt/2)] = false;countNodesOld = countNodes;}
                        ///////////////OLD/if (pnt % 2 !=0 && abs(tempListY[pnt]) < abs(oldYup[int(pnt/2)])) {arrInit[int(pnt/2)] = false;}
                        if (pnt % 2 !=0 && abs(abs(tempListY[pnt]) - abs(oldYup[int(pnt/2)]))>toolDia ) {arrInit[int(pnt/2)] = false;}
                        if (pnt % 2 !=0 && abs(tempListX[pnt]) >  (abs(oldXup[int(pnt/2)])+ 1.00*toolDia*(100.0-xOverlap)/100.0      ) ) { arrInit[int(pnt/2)] = false;}                     //    println("new x pos is " + abs(tempListX[pnt]));                         //   println("  old x pos is " + abs(oldXup[int(pnt/2)]));
                        //reversing algorythm 
                        //if (pnt % 2 !=0 && abs(tempListX[pnt]) >  (abs(oldXup[int(pnt/2)])+ 0.49*toolDia*(100.0-xOverlap)/100.0      ) ) { arrInit[int(pnt/2)] = false;}                     //    println("new x pos is " + abs(tempListX[pnt]));                         //   println("  old x pos is " + abs(oldXup[int(pnt/2)]));
                        
                        if (arrInit[int(pnt/2)] == false ) { //(initilalize the use of this arraylist if it is new)
                          //if (penIsDown){ //moving from something else to a fill, ensure pen is up
                            arrSubLists[int(pnt/2)].add(new Point(0,0, -20.0, c)); //LIFT
                            penIsDown = false;  
                          //}
                          arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c));
                          arrSubLists[int(pnt/2)].add(new Point(0,0, -10.0, c)); //-10z drop pen-
                          penIsDown = true;
                          arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c)); //go to the same point as above for svg display reasons
                          arrInit[int(pnt/2)] = true; 
                          
                        } else { arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c));}
                        if (pnt % 2 ==0){oldYdown[int(pnt/2)] = tempListY[pnt]; oldXdown[int(pnt/2)] = tempListX[pnt];}// When moving down the odd numbered points are the target location of the transfer, and the even is the end of the line
                        //if ( (pnt-1) <0  && countNodesOld != countNodes){//if on last one jump
                         //countNodesOld = countNodes;
                      //  arrSubLists[int((pnt-1)/2)].add(new Point(0,0, -20.0, c)); //LIFT
                        // arrSubLists[int(pnt/2)].add(new Point(tempListX[pnt], tempListY[pnt], 0.0, c));
                        //}
                        
                      } oldYup = nullY;
                   }                   
   
              }                     
            }//end of individual shape (for cc loop), now combine arrays!

            for (int arrayNum = 0; arrayNum <iGroupsMax;arrayNum++){
               arrList.addAll(arrSubLists[arrayNum]);
               // arrList.add(new Point(0,0, -20.0, c)); //LIFT
              // arrSubLists[arrayNum].clear();
            }
            
            //OMIT THE FOLLOWING PRE OPTIMIZATION SINCE IT MAKES YOU MISS THE LAST SHAPE FILL FOR SOME REASON....?
             /*
            //PATH OPTIMIZATION, GREEDY ALGORYTHM//////////////////////////
           int groupIndex=0;
           for (int arrayNum = 0; arrayNum <iGroupsMax;arrayNum++){
             // if (arrInit[arrayNum] == true){
                  for (int pointId = 0; pointId < arrSubLists[arrayNum].size(); pointId++) {
                    if (((Point) arrSubLists[arrayNum].get(pointId)).z == -20){
                      groupIndex++;
                    }else{
                      arrGroupLists[groupIndex].add(arrSubLists[arrayNum].get(pointId));
                    }
                  }
                  arrSubLists[arrayNum].clear();
             // }else{ break;}
            }
            
            
            for (int ddd =0; ddd<iGroupsMax;ddd++){ 
              arrInit[ddd]  = true; //now this will be a stand in for if the group was used or not
            }  
            
           int groupsAdded =0;
           int holdId =0;
           //println("groupIndex is " + groupIndex);
             while (groupsAdded <= groupIndex){
                 //println("groupsAdded is " + groupsAdded);
                 
                  //get final point of current group starting with group zero
                 float xLast = ((Point) arrGroupLists[holdId].get( arrGroupLists[holdId].size()-1 )).x;
                 float yLast = ((Point) arrGroupLists[holdId].get( arrGroupLists[holdId].size()-1 )).y;
                // println("xLast + yLast is " + xLast + "  " + yLast );
                 float xDist =99999; float yDist =99999;
                 boolean bSkipLift = false;
                 
                 for (int groupId =0; groupId<=groupIndex;groupId++){
                     if (arrInit[groupId]){
                       //println("groupId is " + groupId);
                         float xFirst = ((Point) arrGroupLists[groupId].get(0)).x;
                         float yFirst = ((Point) arrGroupLists[groupId].get(0)).y;
                         
                        
                        // if ( abs(xFirst-xLast) <= toolDia   && abs(yFirst-yLast) < toolDia*2 ) { // the 1.01 is to get rid of rounding error   1.05*toolDia*(100.0-xOverlap)/100.0
                        //   bSkipLift = true;
                         //  holdId = groupId;
                        //   println("                                     JUMP SKIPPED!!!! group id  = " +groupId);
                         //  break;
                        // } 
                         if (xFirst == xLast && yFirst==yLast ){println(" JUMP SKIPPED!!!! x= " +xFirst+"   y = "+yFirst ); holdId = groupId; bSkipLift =true; break;}
                         
                         if ( ( abs(xFirst-xLast) + abs(yFirst-yLast) )  <( yDist + xDist ) ) {//     abs(xFirst-xLast) < xDist && abs(yFirst-yLast)  < yDist ) {    //evaluate seperately to avoid local maximum                         
                           //println("xFirst + yFirst is " + xFirst + "  " + yFirst );
                            //println("holdId = " +groupId);
                            xDist = abs(xFirst-xLast);
                            yDist = abs(yFirst-yLast);
                            
                            //skipping is causing errors
                            holdId = groupId;  
                         }
                     }
                 }
                 
                 if (bSkipLift == false) {arrList.add(new Point(0,0, -20.0, c));  }//LIFT println("added lift ");  
                 arrList.addAll(arrGroupLists[holdId]);
                 arrInit[holdId] = false;
                 groupsAdded++;
             } 
             /////////////////////END OF PATH OPTIMIZATION
             
             
             
               /* this was not in use IDK, OLD OLD
           for (int arrayNum = 0; arrayNum <iGroupsMax;arrayNum++){
              if (arrInit[arrayNum] == true){ //may not actually need
                  arrInit[arrayNum] = false;
                  arrList.addAll(arrSubLists[arrayNum]);
                  arrSubLists[arrayNum].clear();
              }else{ break;}
            }  
            */
            
               //for (int pointId = 0; pointId < arrGroupLists[groupId].size(); pointId++) {
                //   arrGroupLists[groupId].
               //}

           //Greedy algorythim
             //arrInit == true for any group <> null
             //arrSubLists == array of groups each containing drawing points that dont require lifts
           //int groupIdNearest =0; 
           //for int groupCnt=0; groupCnt <=groupIndex; groupCnt++{ 
             //if arrInit[groupCnt] {
                 //if distcurr<distOld{
                     //arrInit[groupCnt] =false;
                     //groupIdNearest = croupCnt;
               //  }
             //}
             //arrSubLists[groupCnt]
           //} end of for loop
          /*
           println("got herer!! groupindex is " + groupIndex);
           for (int arrayNum = 0; arrayNum <groupIndex;arrayNum++){
             // if (arrInit[arrayNum] == true){ //may not actually need
              //    arrInit[arrayNum] = false;
                  arrList.addAll(arrSubLists[arrayNum]);
                  arrList.add(new Point(0,0, -20.0, c)); //LIFT
                  arrSubLists[arrayNum].clear();
             // }
            }
           println("got herer!!free and clear!");
        */

            
            

       if (penIsDown){ //moving from something else to a fill, ensure pen is up for the next shape
          arrList.add(new Point(0,0, -20.0, c)); //LIFT
          penIsDown = false;  
        }      
      
      }//End of Infill pattern for this local shape 
      
     // if (penIsDown){ //moving from something else to a fill, ensure pen is up for the next shape
      //  arrList.add(new Point(0,0, -20.0, c)); //LIFT
      //  penIsDown = false;  
     // }
      
      
  } //end of if n>0 (determies is this cycle has chilren or paths(no children)
}//end of Exvert
  
  
  
void hone(){  //final code clean up prior to save 
   DisplayData("Optimizing tool paths now...");
  //create lists sorted by color 0-100 = 101 pieces
    ArrayList[] arrColorLists = new ArrayList[101];   //to replace with number of oclors...
    for (int ddd =0; ddd<=100;ddd++){
        arrColorLists[ddd]  = new ArrayList();
    } 
    
    //REMEMBER DEFINTION colorArray = new color[101]; //(0-100 inclusive)
 
    //sort by colors to draw in order of brightness. Sort thourgh color list, put contents into new lists. This also consolidates tool changes by color
   // colorArray =sort(colorArray);
   // colorArray = reverse(colorArray); //this works but you have to move black to the end...!
    
    
    // doesnt freeze but doesn tget order right
    color[]  tempColorArray; 
    tempColorArray = new color[101]; //(0-100 inclusive)
    boolean[] aColorUsed = new boolean[101];
    for (int iter =0;iter<=100;iter++){
    //for (int iter =100;iter>=0;iter--){
        float minDist=5000;
        int target =0;
       // color ctemp = colorArray[iter];
        
        for (int rev =0; rev<=100; rev++){
          if(! aColorUsed[rev]){
              if ( minDist > colorDist(color(255),colorArray[rev]) ){//brightness(ctemp) ){//    
                      minDist =colorDist(color(255),colorArray[rev]);//brightness(ctemp);// 
                      target = rev;
              }
          }
        } 
        tempColorArray[iter]=colorArray[target];
        aColorUsed[target]= true;
    }
    
    colorArray = tempColorArray;
    
    /*
    
    println(tempColorArray);      
    //println(iMaxNumColors);
    for(int j = 0;j<=100;j++){
      print("color # " + j + " is " + tempColorArray[j] + " is also ");
      Color wild = new Color(int(tempColorArray[j]));
      String fuck = str(tempColorArray[j]);
      println(wild.decode(fuck));
    }
    */
    
    color c5678;
    for (int p = 0; p < arrList.size(); p++) {
        c5678 = ((Point) arrList.get(p)).clr; //grab the color of current point
        //println("color order is " + c5678);   
        for(int j = 0;j<=100;j++){//check every color in the colorArray{max 99 to prevent freeze even if only 12 used)
            //if(colorDist(c5678,color(0)) < (1) ){//must BE black to get into this category  
            //    arrColorLists[100].add(arrList.get(p));//put black into place X, which will be added last so
            //    break;
            //}else 
            if (colorDist(c5678,colorArray[j])< (767/767)){ 
                arrColorLists[j].add(arrList.get(p));
                break;
            }
        }
    }
 
 
   float xMin=9999; //hold max min boundaries of job for bounding box at beginning
   float xMax=0;
   float yMin=9999;
   float yMax=0;
   for (int p = arrList.size()-1; p>=1; p--) { //not hitting p =0 or error because Im checking points at p-1...  
        if( ((Point) arrList.get(p)).x > xMax){
            xMax =((Point) arrList.get(p)).x;
        }
        if( ((Point) arrList.get(p)).x < xMin && ((Point) arrList.get(p)).x >0 ){
            xMin =((Point) arrList.get(p)).x;
        }
        if( ((Point) arrList.get(p)).y > yMax){
            yMax =((Point) arrList.get(p)).y;
        }
        if( ((Point) arrList.get(p)).y < yMin && ((Point) arrList.get(p)).y >0){
            yMin =((Point) arrList.get(p)).y;
        }
    }
    
    arrList.clear(); //destroy original to overwrite it
    color ccc=255;
    //arrList.add(new Point(0,0, -20.0,ccc));  //LIFT println("added lift "); search G21, added penup at start there  
    arrList.add(new Point(xMin,yMin, 2,ccc)); 
    arrList.add(new Point(xMax,yMin, 0,ccc)); 
    arrList.add(new Point(xMax,yMax, 0,ccc)); 
    arrList.add(new Point(xMin,yMax, 0,ccc)); 
    arrList.add(new Point(xMin,yMin, 0,ccc)); 
    
    //add bounding box... here22
    //arrList.add(new Point(0,0, -20.0,c));  }//LIFT println("added lift "); 
    //bl br tr tl

    if (bPathOptimize){ //only hone if locally made image, some svgs are already optimized and I might make it worse.
        color c;
        //println("got here");
        //loop through colors
        for (int arrayNum = 0; arrayNum <101;arrayNum++){ //combine sub lists in decending order  //for (int arrayNum = 0; arrayNum <12;arrayNum++){     //for (int arrayNum = 99; arrayNum >=0;arrayNum--){  //combine sub lists in decending order  //for (int arrayNum = 0; arrayNum <12;arrayNum++){
            // if (arrayNum ==101){arrayNum=0;}//put black at end but remember to reset back to 101 at end of loop!!
             c = colorArray[arrayNum];
             int iGroupsMax = arrColorLists[arrayNum].size();
           //  println("got arrayNum " + arrayNum); 
             
             if (iGroupsMax >0){
                 //println("iGroupsMax " + iGroupsMax); 
                 boolean[] arrInit = new boolean[iGroupsMax];// = false by default;
                 ArrayList[] arrGroupLists = new ArrayList[iGroupsMax];
                   
                for (int ddd =0; ddd<iGroupsMax;ddd++){
                    arrGroupLists[ddd]  = new ArrayList();
                }
               // println("got here1111");
                
                boolean bSkip = false;
                int groupIndex=0;
                    for (int pointId = 0; pointId < arrColorLists[arrayNum].size(); pointId++) { 
                        if (((Point) arrColorLists[arrayNum].get(pointId)).z == -20){
                            if (arrGroupLists[groupIndex].size() <= 0) {bSkip = true;} //skip if we dont have something in this one already
                            if (! bSkip){ groupIndex++; }
                            //bSkip = true;
                        }else{
                            bSkip = false;
                            arrGroupLists[groupIndex].add(arrColorLists[arrayNum].get(pointId));
                            arrInit[groupIndex]  = true;
                        }
                     }
                     arrColorLists[arrayNum].clear();
                  
                 int holdId =0;
                 int prevHoldID=99999;
                 //for (int ddd =0; ddd<groupIndex;ddd++){ 
                //   if(arrGroupLists[ddd].size() >0){ holdId = ddd; break;}
                // }
                    
                 int groupsAdded =0;
                // println("groupIndex is " + groupIndex);
                 while (groupsAdded <= groupIndex && groupIndex >0){
                   //  println("groupsAdded is " + groupsAdded);
                     //if (arrGroupLists[holdId].size() <=0){;} //arrInit[holdId] = false; holdId++;}
                     //if (arrGroupLists[groupsAdded].size() <=0){groupsAdded++;}//arrInit[holdId] = false; holdId++;}
                     //else{
                               // println("holdID is " + holdId);
      
                                  //get final point of current group starting with group zero
                     float xLast = ((Point) arrGroupLists[holdId].get( arrGroupLists[holdId].size()-1 )).x;
                     float yLast = ((Point) arrGroupLists[holdId].get( arrGroupLists[holdId].size()-1 )).y;
                     // println("xLast + yLast is " + xLast + "  " + yLast );
                     float xDist =99999; float yDist =99999;
                     boolean bSkipLift = false;
                                 
                     for (int groupId =0; groupId<=groupIndex;groupId++){
                         if (arrInit[groupId]){ //if(arrGroupLists[groupId].size() <=0){arrInit[holdId] = false; }else{
                              //println("groupId is " + groupId);
                              float xFirst = ((Point) arrGroupLists[groupId].get(0)).x;
                              float yFirst = ((Point) arrGroupLists[groupId].get(0)).y;
                              
                              //if (xFirst == xLast && yFirst==yLast ){println(" JUMP SKIPPED!!!! x= " +xFirst+"   y = "+yFirst ); holdId = groupId; bSkipLift =true; break;}
                              //Poitns will never be equal, need ot check if within 1 dool daimeter apart
                              //if (  abs(xFirst-xLast)<=toolDia/2 && + abs(yFirst-yLast)<=toolDia/2  ){ holdId = groupId; bSkipLift =true; break;}//println(" JUMP SKIPPED!!!! x= " +xFirst+"   y = "+yFirst );
                                             
                              if ( ( abs(xFirst-xLast) + abs(yFirst-yLast) )  <( yDist + xDist ) ) {//     abs(xFirst-xLast) < xDist && abs(yFirst-yLast)  < yDist ) {    //evaluate seperately to avoid local maximum                         
                                  //println("xFirst + yFirst is " + xFirst + "  " + yFirst );
                                  //println("holdId = " +groupId);
                                  xDist = abs(xFirst-xLast);
                                  yDist = abs(yFirst-yLast);
                                                    
                                  holdId = groupId; 
                                  if ( xDist<=1.5*toolDia*fOverlap/100 && + yDist<=1.5*toolDia*fOverlap/100){bSkipLift =true;}
                              }
                          }
                      }
                      float xDist2=9999;
                      float yDist2=9999;
                      int holdId2=holdId;
                      if (!bSkipLift){
                        for (int groupId =0; groupId<=groupIndex;groupId++){
                           if (arrInit[groupId]){ //if(arrGroupLists[groupId].size() <=0){arrInit[holdId] = false; }else{
                                //println("groupId is " + groupId);
                                float xFirst = ((Point) arrGroupLists[groupId].get( arrGroupLists[groupId].size()-1 )).x;
                                float yFirst =  ((Point) arrGroupLists[groupId].get( arrGroupLists[groupId].size()-1 )).y;
             
                                if ( ( abs(xFirst-xLast) + abs(yFirst-yLast) )  <( yDist2 + xDist2 ) ) {//     abs(xFirst-xLast) < xDist && abs(yFirst-yLast)  < yDist ) {    //evaluate seperately to avoid local maximum                         
                                    //println("xFirst + yFirst is " + xFirst + "  " + yFirst );
                                    //println("holdId = " +groupId);
                                    xDist = abs(xFirst-xLast);
                                    yDist = abs(yFirst-yLast);
                                                      
                                    holdId2 = groupId; 
                                    //if ( xDist<=1.001*toolDia && + yDist<=1.001*toolDia){bSkipLift =true;}
                                }
                            }
                        }
                        
                      }
                      if (( yDist2 + xDist2 )  <( yDist + xDist )){
                         ArrayList arrGroupListo = new ArrayList();
                         for (int qq =0 ;qq<=arrGroupListo.size()-1;qq++ ){
                             if (((Point)arrGroupLists[holdId2].get(qq)).z == -20){
                                  if (arrGroupLists[groupIndex].size() <= 0) {bSkip = true;} //skip if we dont have something in this one already
                                  if (! bSkip){ groupIndex++; }
                                  //bSkip = true;
                              }else{
                                  bSkip = false;
                                  arrGroupLists[groupIndex].add(arrColorLists[arrayNum].get(qq));// CHANGED 22 DEC 2021 FROM pointId 
                                  arrInit[groupIndex]  = true;
                              }
                         }
                        
                      }
                      
                      
                      if(holdId !=prevHoldID){
                          if ( xDist<=1.5*toolDia*fOverlap/100 && + yDist<=1.5*toolDia *fOverlap/100 ){bSkipLift =true; } //// 1x*fOverlap/100 (was in release v2.0), switched to 1.5 to include hypotenuece of diagonal moves, reduce overall jumps!               //println(" JUMP SKIPPED!!!! x= " +xFirst+"   y = "+yFirst );
                          //1.01*toolDia*(100.0-xOverlap)/100.0 
                          if (bSkipLift == false) {arrList.add(new Point(0,0, -20.0,c));  }//LIFT println("added lift ");  
                           arrList.addAll(arrGroupLists[holdId]);
                          
                          if (bSkipLift == false) {arrList.add(new Point(0,0, -10.0,c));  }//DROP println("added lift ");
                          arrInit[holdId] = false;
                      }prevHoldID = holdId;
                      groupsAdded++;
                             
                 }//end of while
                 arrList.add(new Point(0,0, -20.0, c)); //LIFT
              }
         
        // arrList.addAll(arrColorLists[arrayNum]);
       // if (arrayNum==0){arrayNum=101;}
        }//end of optmization algo
      }else{
         //This was the original recombination of the colors. Used here for non bLocallyMade svg files, as they are usually have intented paths
          for (int arrayNum = 0; arrayNum <=100;arrayNum++){  //combine sub lists in decending order  //for (int arrayNum = 0; arrayNum <12;arrayNum++){     //for (int arrayNum = 99; arrayNum >=0;arrayNum--){  //combine sub lists in decending order  //for (int arrayNum = 0; arrayNum <12;arrayNum++){
              arrList.addAll(arrColorLists[arrayNum]);
           }
     }
   
   
   
    //loop to ensure clean non repeating code
    
    for (int p = arrList.size()-1; p>=1; p--) { //not hitting p =0 or error because Im checking points at p-1... Looping backwards because im removing points.
       if (((Point) arrList.get(p)).z != 0 &&   ((Point) arrList.get(p)).z == ((Point) arrList.get(p-1)).z    ){
          //println("Hone-Removed duplicate Z point");
          arrList.remove(p);
        }else  if( ((Point) arrList.get(p)).x == 0    && ((Point) arrList.get(p)).y == 0 &&  ((Point) arrList.get(p)).z == 0 ){
         //println("Hone-Removed Zero Point"); not sure what this would be doing in there
          arrList.remove(p);
        }else if ( ((Point) arrList.get(p)).x == ((Point) arrList.get(p-1)).x    && ((Point) arrList.get(p)).y == ((Point) arrList.get(p-1)).y ){ 
          //println("Hone-Removed duplicate XY point");
          arrList.remove(p-1); 
        }
    }
   boolean bunknown = true;
   boolean bUp = false;
    for (int p =1; p<= arrList.size()-1; p++) { //not hitting p =0 or error because Im checking points at p-1...
    
       if (((Point) arrList.get(p)).z == -20){
          if (bUp == true && !bunknown){arrList.remove(p);}    //println("Hone-Removed duplicate Z LIST");
          bUp = true;    bunknown = false;         
       }else if (((Point) arrList.get(p)).z == -10){
          if (bUp == false && !bunknown){arrList.remove(p);}    //println("Hone-Removed duplicate Z LIST");
          bUp = false;  bunknown = false;        
       }
    }
    
    
  arrList.trimToSize(); //remove spaces
  
  colorArray = new color[101]; //I guess Im resetting the  color array here because Im already done using it from above and i need to reset it for next time...
  
}//end of hone

  
  
  
// Class for a 3D point + color
class Point {   //'travel' moves, -10z = beginning of drawn path, -20z end of path
  float x, y, z; 
  color clr;
 // float strk;
  Point(float x, float y, float z, color clr) { 
    this.x = x;
    this.y = y;
    this.z = z;
    this.clr = clr;
  }
}   
  
  
void printColors (color rgb) {
 
  float red = rgb >> 16 & 0xFF;  
  float green = rgb >> 8 & 0xFF; 
  float blue = rgb & 0xFF;
  //float alpha = rgb >> 24 & 0xFF;
  println("rgba: " + red +" "+ green +" "+ blue );//+" " + alpha);
}
/*
color grayScale (color rgb) {
  float red = rgb >> 16 & 0xFF;  
  float green = rgb >> 8 & 0xFF; 
  float blue = rgb & 0xFF;
  //float alpha = rgb >> 24 & 0xFF; 
  float grayValue = (0.2989 * red + 0.5870* green + 0.1140* blue); // weighted b/w conversion
  color gray = color(grayValue);//, alpha);
  return gray;
} */



void setButtons(){
   if (gui != null) gui.dispose();
   gui = new ControlP5(this);
 
  //gui.addScrollableList("1","22");
   PFont p = createFont("Helvetica",11); 
  ControlFont font = new ControlFont(p);
  //HEADER ROW ----------------------------------------------------

    int Xpos =5;  int Ypos = 5;  int xSpacing = 5; int ySpacing = 5; int sizeX =100; int sizeY =40; 
  buttonProgConvert  = gui.addButton("buttonProgConvert").setCaptionLabel("Depixelizer").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
      Xpos = Xpos + sizeX + xSpacing;
  buttonProgCreate = gui.addButton("buttonProgCreate").setCaptionLabel("Creation Mode").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    Xpos = Xpos + sizeX + xSpacing;
  buttonProgRun = gui.addButton("buttonProgRun").setCaptionLabel("Run Mode").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    
   sizeX =100;       Xpos = width - xSpacing - sizeX;// farthest right button
  buttonExit = gui.addButton("buttonExit").setCaptionLabel("Exit Program").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    Xpos = Xpos - sizeX - xSpacing;
  buttonHelp = gui.addButton("buttonHelp").setCaptionLabel("HELP").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    Xpos = Xpos - sizeX - xSpacing;
  buttonSupport = gui.addButton("buttonSupport").setCaptionLabel("SUPPORT").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    Xpos = Xpos - sizeX - xSpacing;
  
 sizeY =40;  Ypos = 70; ySpacing = sizeY +5; 
  //CENTER-LEFT BUTTONS
  
     sizeY =26; ySpacing = sizeY +5;
      Xpos = width/2-237;//int(sizeX*1.5/2*2/3)-sizeX*2-xSpacing;// -( sizeX/2 + ySpacing);
      sizeX =90;
    // Xpos = Xpos - (int)(sizeX);
//multicolors were here


    //FAR LEFT BUTTONS
     Ypos = 70;  sizeY =41;  ySpacing = sizeY +5; 
  //Xpos = (int)(width/2-sizeX*3.4); 
     Xpos = Xpos - sizeX/2 -xSpacing;
  buttonLoadSVG = gui.addButton("buttonLoadSVG").setCaptionLabel("Load .SVG File").setPosition(Xpos, Ypos).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
    Ypos =  Ypos + ySpacing;
  buttonUpdate = gui.addButton("buttonUpdate").setCaptionLabel("Cup/Tool \nDimensions").setPosition(Xpos, Ypos).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
   Xpos = Xpos + sizeX + xSpacing;     
   sizeY =88; Ypos = 70; 
  buttonSave = gui.addButton("buttonSave").setCaptionLabel("Save Job").setPosition(Xpos, Ypos).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonSave.hide();
    Xpos = Xpos+(int)(sizeX)+xSpacing;
    
  //CENTER BUTTONS
  sizeX =80;
    sizeX =sizeX*2/3;  sizeY =40; ySpacing = sizeY +5;  Xpos = width/2-sizeX/2 -( sizeX/2 + ySpacing);    Ypos = 31 ;
    
    
  buttonRotateLeft = gui.addButton("buttonRotateLeft").setCaptionLabel("CCW").setPosition(Xpos, Ypos+ySpacing*3/2).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonRotateLeft.hide();
    Xpos = Xpos+(int)(sizeX*1.08);

   
  buttonMoveLeft = gui.addButton("buttonMoveLeft").setCaptionLabel("Left").setPosition(Xpos, Ypos+ySpacing*3/2).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonMoveLeft.hide();
    Xpos = Xpos+(int)(sizeX*1.08);
  buttonMoveUp = gui.addButton("buttonMoveUp").setCaptionLabel("Up").setPosition(Xpos, Ypos+ySpacing).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonMoveUp.hide();
  buttonMoveDown = gui.addButton("buttonMoveDown").setCaptionLabel("Down").setPosition(Xpos, Ypos+ySpacing*2).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonMoveDown.hide();
    Xpos = Xpos+(int)(sizeX*1.08);
  buttonMoveRight = gui.addButton("buttonMoveRight").setCaptionLabel("Right").setPosition(Xpos, Ypos+ySpacing*3/2).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonMoveRight.hide();

    Xpos = Xpos+(int)(sizeX*1.08);
  buttonRotateRight = gui.addButton("buttonRotateRight").setCaptionLabel("CW").setPosition(Xpos, Ypos+ySpacing*3/2).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonRotateRight.hide();
    // sizeX =sizeX*3/2;
    
  //CENTER-RIGHT BUTTONS
    //Xpos = xWindow- xWindow/4 -sizeX - xSpacing; //Xthis posotions wbuttons FROM the right
    Xpos = Xpos + (int)(sizeX) +xSpacing;
   // sizeX =sizeX*2/3; 
   

  buttonScaleUp = gui.addButton("buttonScaleUp").setCaptionLabel("Bigger").setPosition(Xpos, Ypos+ySpacing).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonScaleUp.hide();
  buttonScaleDown = gui.addButton("buttonScaleDown").setCaptionLabel("Smaller").setPosition(Xpos, Ypos+ySpacing*2).setColorValue(100).setColorCaptionLabel(color(0)).setColorLabel(255).setSize(sizeX,sizeY).setFont(font); buttonScaleDown.hide();
    Xpos = Xpos+(int)(sizeX)+xSpacing;
     sizeX =sizeX*3/2; 
     
    Ypos = 70;  
    sizeX =100; 
    sizeY =26;ySpacing = sizeY +5; 
  toggleMultiColor = gui.addToggle("toggleMultiColor").setCaptionLabel("MonoColor   MultiColor").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(int(sizeX*1.5),sizeY).setFont(font);toggleMultiColor.hide();
    gui.getController("toggleMultiColor").getCaptionLabel().align(CENTER,CENTER);
    Ypos =  Ypos + ySpacing;
  toggleOutline = gui.addToggle("toggleOutline").setCaptionLabel("   Normal        Blk-Outline").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(int(sizeX*1.5),sizeY).setFont(font);toggleOutline.hide();
    gui.getController("toggleOutline").getCaptionLabel().align(CENTER,CENTER);
    Ypos =  Ypos + ySpacing;   
  toggleFill = gui.addToggle("toggleFill").setCaptionLabel("No-Fill            Fill       ").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(int(sizeX*1.5),sizeY).setFont(font); toggleFill.hide();
    gui.getController("toggleFill").getCaptionLabel().align(CENTER,CENTER);//.align(ControlP5.LEFT,  ControlP5.TOP_OUTSIDE); //
  
  

  if (shapeLoaded){
      if (!bLocallyMade){toggleFill.show(); toggleMultiColor.show(); }  
      buttonSave.show();buttonRotateLeft.show();buttonRotateRight.show();buttonMoveLeft.show();buttonMoveUp.show();buttonMoveDown.show();buttonMoveRight.show(); 
      if(! bLocallyMade){buttonScaleUp.show();buttonScaleDown.show();}
      
  }
  plotyShift = int(0+plotScale*Ymax*.5-height/2+200);
  
  if (! bLocallyMade){   bBlkOutline = toggleOutline.getBooleanValue(); bMultiColor = toggleMultiColor.getBooleanValue(); bFillDrawing = toggleFill.getBooleanValue(); }
}

String cleanString(String sCleanMe){
  sCleanMe = sCleanMe.replace("/","");//  //s.replace(old, new)  
  sCleanMe = sCleanMe.replace("?","");//
  sCleanMe = sCleanMe.replace(".","");//
  sCleanMe = sCleanMe.replace("'","_");//
  sCleanMe = sCleanMe.replace("\\","");//
  sCleanMe = sCleanMe.replace("\"","");//
  sCleanMe = sCleanMe.replace("|","");//
  sCleanMe = sCleanMe.replace("+","");//
  sCleanMe = sCleanMe.replace("=","");//
  sCleanMe = sCleanMe.replace("'","");//
  sCleanMe = sCleanMe.replace(":","");//
  sCleanMe = sCleanMe.replace(";","");//
  sCleanMe = sCleanMe.replace(">","");//
  sCleanMe = sCleanMe.replace("<","");//
  sCleanMe = sCleanMe.replace("?","");//
  sCleanMe = sCleanMe.replace("!","");//
  sCleanMe = sCleanMe.replace("@","");//
  sCleanMe = sCleanMe.replace("#","");//
  sCleanMe = sCleanMe.replace("$","");//
  sCleanMe = sCleanMe.replace("%","");//
  sCleanMe = sCleanMe.replace("^","");//
  sCleanMe = sCleanMe.replace("&","");//
  sCleanMe = sCleanMe.replace("*","");//
  sCleanMe = sCleanMe.replace("(","");//
  sCleanMe = sCleanMe.replace(")","");//
  sCleanMe = sCleanMe.replace("[","");//
  sCleanMe = sCleanMe.replace("]","");//
  sCleanMe = sCleanMe.replace("{","");//
  sCleanMe = sCleanMe.replace("}","");//
  return(sCleanMe);
}

long currentTime(){
    return (System.currentTimeMillis());
} 

void logHold(String log){//append a string to the soft log
    sLog = sLog + log;
}

void logWrite(boolean bAppend){//commit softlog to hardlog. (without append it will fully overwright but it will take longer.)
    
    String sLogTemp=" ";
    String[] sLogArray;
    if (bAppend){
      sLogArray = loadStrings("\\system\\LogJobCreator.txt");
      sLogTemp = join(sLogArray,"\n");
    }else{
      sLogTemp="Note: for this log to properly record data you must exit the program using the EXIT button so give it the chance to log the data. \n  ";
      sLogTemp=sLogTemp+sVersion+"\n";
    }
   sLog = sLogTemp +sLog+ "Current Time in ms: " + nf(currentTime(),13,0)+"\n";
  
   sLogArray = split(sLog, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
   saveStrings("system//LogJobCreator.txt", sLogArray);  
   sLog = " ";
}
void logRead(){//overwrite softlog with hardlog  
    sLog ="";
    String[] sLogArray = loadStrings("\\system\\LogJobCreator.txt");
    sLog = join(sLogArray,"\n");
}
