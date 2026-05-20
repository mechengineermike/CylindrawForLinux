/* Copyright (C) Graham Research LLC - All Rights Reserved
 * Unauthorized copying of this file or any part of the contents therein, via any medium is strictly prohibited
 
 
 * Proprietary and confidential
 * Written by Michael Graham <CylinDraw@gmail.com>, May 18, 2021
 */


import javax.swing.*; //fopr the jtextfield
import javax.swing.JFrame;
import javax.swing.JOptionPane; //used for pop up windowsa
import processing.svg.*;
import controlP5.*;

import javax.swing.JPanel;
import javax.swing.JButton;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.lang.System;

import javax.swing.JColorChooser;


import java.awt.Color;

String sVersion  =  "Ver: 2.01 @ DePixelizer CylinDraw Control Suite.";

ControlP5 gui;

boolean bPaid  = false;// has a license been found. UPDATE, Just set bPaid = bTerms. They get full access if agree to terms of license to cover my ass.
String  sKey ="null"; //Key = XCg8_XA@RA=yyN4cW4FD
String  sEmail ="CylinDraw@gmail.com"; //Key = XCg8_XA@RA=yyN4cW4FD

boolean bTerms  = false;// has the user agreed to the terms of use

Button buttonProgConvert;
Button buttonProgCreate; 
Button buttonProgRun;

Button buttonSupport;
Button buttonHelp;
Button buttonExit;
Button buttonLoad;
Button buttonSave; 

Button setColor1;
Button setColor2;
Button setColor3;
Button setColor4;
Button setColor5;
Button setColor6;
Button setColor7;
Button setColor8;
Button setColor9;
Button setColor10;
Button setColor11;
Button setColor12;
Bang setColorAll; //sets all colors, utilizes most to least popular the icolor limit(includive)

Button buttonToolUp;
Button buttonToolDown;
Button buttonSizeUp;
Button buttonSizeDown;

Toggle toggleInverted;  //inverted
Toggle toggleBlur; //filterBlur
Toggle toggleTrace;//filterTrace
Toggle toggleSharpen;

Toggle toggleErode;//filterErode
Toggle toggleDilate;//filterDilate
Toggle toggleSpeckle; //fuck this
Toggle toggleBackground; 
Toggle toggleDither;

Slider sliderPoster;  //iPoster
//Slider sliderBrightness;  //iPoster
//Slider sliderContrast;  //iPoster
Slider sliderColors; //iColorLimit
Slider sliderThresholdLow;//thresholdLow
Slider sliderThresholdHigh;//thresholdHigh
Slider sliderOverlap; //cancellled


File storedFile;

PImage logoHeaderImg;

int xWindow = 1500;
int yWindow = 900; 

PGraphics svg;//= createGraphics(300, 300, SVG, "output.svg");

PImage img;                         // the main image object used for displaying the original image
PImage imgOrig;                         // the main image object used for displaying the original image
int matrixsize = 1;                 // the width in pixels of the area being processed via the convo matrix
int start_matrixsize = matrixsize;  // default initial matrix size

float matrix_multiplier = 0.0;      // multiplication factor used in spatial convo processing
int num_pixels = 0;                 // number of pixels in the convo matrix
float zoomScale = 0.2;
float zoomScaleOld = zoomScale;

boolean inverted = false; //invert colors
boolean imageLoaded = false; //(transient state for if the image needs to be refreshed
boolean fileLoaded = false; //state for if a file has been loaded

boolean recordData = false;
boolean recordingData = false;
boolean verbose = false;
boolean filterBlur = false;   //https://processing.org/reference/filter_.html
boolean filterTrace = false;
boolean filterSharpen = false;
//boolean filterPoster = false;
boolean filterErode = false;
boolean filterDilate = false;
boolean filterSpeckle = false;//false = only black speckles
boolean filterBackground = false;
boolean bSliderLock = true; //prevent sliders from doing things (which cause errors when files not loaded)

boolean bExplicitExport = false;

boolean bSetAllColors= false;//transient call to get most frequent colors
boolean bSettingColors =false;
boolean bThanked =false;
int iPoster = 0;
int thresholdLow = 0;
int thresholdHigh = 255;
//int brightness =0; 
//int contrast =10;

String filePath;
String fileName = ""; // Name of the file to convert. 
String fileNameOriginal = ""; // Name of the file to convert.
String destName;
boolean pendingImageLoadFromPicker = false;
 
    int idealHeight;
    int idealWidth;
    int idealMatrix;

int   RealHeight = 100; //desired total image height in mm (user scalable, doesnt acceft height of DISPLAYED image, just output image)
int   RealWidth = RealHeight; //may not use, will be driven by aspect ratio and so will eget overwritten
float toolDia = 0.5; 
float overLap = 50;//Percent Overlap
float toolDiaOld = toolDia; 
int   NumStrokes;
int   PixelHeight =1000; //default to anything not zero to keep it from freaking out
int   PixelWidth = PixelHeight;

int   zLimit = 250; //for how much you can scale the image

color cOld; 
color c01;//what the pixel wouyld have been if not dithered
color backgroundColor;
int    iColorLimit = 2;
int    iColorLimitOld = 0;
color  c00;
color[]  colorArray =  new color[19];  //array of just the unique colors!
//color[]  colorArrayRegion =  new color[19];  //array of just the unique colors!

//color[]  colorArrayPicked =  new color[19];  //user selected colors
//float[]  fDistLimitArray; //array of the distances between colors used to sort colors into category (if in 

float[] colorPosArray =  new float [19];
  
  color cPicked = color(255,255,255); //user picked color
  Color javaColor;
  
  
 //used for determingmost frequent color
color[]  colorsTransient;
int[]   voteArray;
int cntr =0;
  
float rtit = 0.0;
float gtit = 0.0;
float btit = 0.0;
boolean bDither = false; //if true then carry the error of rounded gray squares into the next ones. Makes a LOT more dots/noise but captures that 'zoomed out detail'. Dither is bad for words but good for realistic photos.  
    
//Theory of operation
// set the image height to be anythign (within range limits) as it doesnt actually change the displayed size. SO default = 100mm
  //RealHeight/RealWidth = PixelHeight/PixelWidth
    ////RealHeight/(PixelHeight/PixelWidth) =   RealWidth  (just so it can be displayed i guess
  //divide image height over (toolwidth minus overlap of 50%)
    //Result is the number of partions to be made = NumStrokes 
    //PixelHeight/NumStrokes = matrixsize!

void settings() {
 /*  try{ size(xWindow, yWindow); //load size from a settings file TBD
   }
   catch (Exception e) {
    e.printStackTrace();
    size(1500, 900);   //load size from hard dimensions
  }  */
  // Start smaller than fullscreen so control buttons remain visible on Pi displays.
  xWindow = min(displayWidth - 80, 1200);
  yWindow = min(displayHeight - 180, 740);
  size(xWindow, yWindow, P3D); //p3d necessary because we rotate the image & use camera, but need to switrch to p2d to render faster and more accurately!. Do not attempt fullscreen. // fullScreen(P3D);   //.setResizable(true);////surface.setSize(xWindow, yWindow);surface.setLocation(0,0);
  noSmooth(); //Not sure why I said yes but smooothing does slow things down... //YES WE DO WANT TO SMOOTH AFTER DONE TROUBLESHOOTING LATER
  logoHeaderImg = requestImage("system/logoDePixelizer.png");//loadImage("logo.png"); //Header Image
  
}


void setup() {
  if (xWindow >displayWidth){xWindow = displayWidth-50;}
  if (yWindow >displayHeight){ yWindow= displayHeight-50;}
  surface.setSize(xWindow, yWindow); //THIS CAN BE USED TO RESIZE THE WINDOW HERE by loading from a file
  
  surface.setTitle("CylinDraw DePixelizer (Bitmap-to-Vector) Conversion Utility");
  
  checkLicense("","");
  cursor (HAND);
  noStroke();
  background(255);
  setButtons(); 
    imageLoaded=false;
          reloadImage(filePath);
        
  String newPath = sketchPath(); //sketch patch expludes the name of this sketch, it is just the folders leadin gup to it and the master group folder is "CylinDraw" Sub folders & programs have set names.
  newPath = newPath + "/system/temp.JPG";   //.replace("CylinDrawJobCreator", "CylinDrawViewer");//\\CylinDrawViewer.exe"); //have to use 2 backslashes to get processing to understand that just 1 backslash is there
  storedFile = new File(newPath);  
  if (storedFile.exists()) {
    println("Loading last file used......");//(load instructions gcode?)
    fileSelected(storedFile);
  }else{
     println("No local job file found to load..");
   }
  surface.setResizable(true);
  // Start maximized-sized so users do not need to click maximize manually.
  xWindow = displayWidth;
  yWindow = displayHeight;
  surface.setSize(xWindow, yWindow);
  
  //frame.dispose(); why did i do this//....??
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw(){// println(frameRate);

  if (pendingImageLoadFromPicker) {
      pendingImageLoadFromPicker = false;
      if (fileLoaded) {
        imageLoaded = false;
        reloadImage(filePath);
        thresholdLow = 0;
        thresholdHigh = 255;
        sliderThresholdLow(thresholdLow);
        sliderThresholdHigh(thresholdHigh);
        setButtons();
      }
  }

  if (recordData){
      save("system/Log_DePixelizer.png");
      recordingData = true;
      zoomScaleOld = zoomScale;
  }else{
      pushMatrix();
      translate(0,60); //pushes working area below the header buttons. But only when NOT saving. If saving we make one frame cycle different and record that.
  }
  
  if ( toolDia != toolDiaOld || imageLoaded ){
    if (toolDia < 0){ //just in case it gets set too small, just display the image unpixelized.
   
     // background(255); // clear previous image (whitewash)
      toolDia = 0;
      loadPixels(); 
      println("default image shown, tool dia too small");
      
    } else {   
    //  colorMode(RGB,255,255,255);
     background(255); // clear previous image (whitewash)
    
      if(recordingData){

          reloadImage(filePath);
          PixelHeight = idealHeight;
          PixelWidth = idealWidth;
          matrixsize = idealMatrix;
          svg = createGraphics(idealWidth,idealHeight, SVG, destName);// svgJobName); //used for prev
          if (verbose) {println("idealMatrix is " + idealMatrix);  println("zoomScale is " + zoomScale);}
          svg.smooth();
          svg.beginDraw(); //used for prev thumbnail in finished file
          svg.strokeWeight(1);// svg.stroke(0);  svg.fill(0);
          svg.beginShape();
            svg.stroke(255); svg.fill(255); //calling this shit is a wierd svg nuance that helps me in creation mode
            svg.beginShape();
            svg.vertex(0,0);
            svg.endShape();
      }
      
      if(bSetAllColors){//this process ensure that the fuull order of operations will be completedt even if the button is pressed mid cycle
        
        bSettingColors=true;//change state tot this for this cycle (will be referenced within convolution
        bSetAllColors=false;//reset transient call
        
        int iSize = PixelHeight*PixelWidth;
        colorsTransient = new color[iSize];
        voteArray = new int[iSize];
        cntr =0;
      }
       
      
      rectMode(RADIUS); //first two parameters of rect() are the shape's center , but uses the third and fourth parameters to specify half of the shapes's width and height.    
      
      
      for (int y = 1; y < PixelHeight; y+= matrixsize ) { //LOOOP TOP TO BOTTOM
        int counter =0;
        rtit=gtit=btit=0;
        boolean bPrevHit = false;
        int xmiss=0;
        boolean hit = false;
        
        cOld=color(255);
        
        if (y % 2==0){  // loop LEFT TO RIGHT through the matrix, applying the matrix filter to the pixels
          int xd = 1;
          for (int x = 1; x < PixelWidth; x+= matrixsize) {
            
            bPrevHit = hit;
            hit = false;
            color c = convolution(x, y, matrixsize);
            if (x==1) {cOld =c; }
           
            fill(c); stroke(c); 
            
            if (c == cOld && cOld != color(255)){hit= true;}
            
            if (hit && recordingData== false){    rect(x + (matrixsize/2), y + (matrixsize/2), matrixsize, matrixsize); }
            // if ( !bPrevHit && cOld != color(255)){ stroke(255);  rect(x - (matrixsize/2), y - (matrixsize/2), matrixsize, matrixsize);  }
            //attempting to remove heorzontal strokes>> if (recordingData && hit){ svg.stroke(c); svg.line(x + (matrixsize/2),y + (matrixsize/2),x + (matrixsize/2),y + (matrixsize/2));}
            
            if (recordingData){ //connect dots into lines
                 if (hit){
                    xd= (x + (matrixsize/2));
                    counter += 1;
                    if( (x + matrixsize) >= PixelWidth && counter>=1 )  { //if you are on the last line of x and there is no white pixel to trigger the above line, then draw a line through all consecutive drawable points not yet drawn
                        svg.stroke(cOld);
                        svg.line(xd-(counter)*matrixsize,y,xd,y);
                        counter =0;
                        xd=1;
                    }
                 } else { // If the pixels are not a pair..
                     if (!bPrevHit && cOld != color(255)){
                      svg.stroke(cOld);// svg.fill(cOld); 
                      if (!filterSpeckle ){
                          if (brightness(cOld)< 10){ svg.point(xmiss,y); }// 254/2   divide y / matrisSize?//cOld==colorArray[1]                            
                      }else{
                        svg.point(xmiss,y/matrixsize);
                      }
                      
                     }else if (counter>=1  ) { //If there were drawable points prior to this non drawable point then create a line from the first to last of the drawable pixels not yet drawn
                       svg.stroke(cOld);
                       svg.line(xd-(counter)*matrixsize,y,xd,y); //draw a line through all consecutive drawable points not yet drawn. We use (counter-1) because 2 points make 1 line.
                       counter =0;
                       xd=1;
                     } else { 
                       xd=1; 
                       counter =0;
                       } // if a drawable point is only 1 pixel wide then this will negate it to reduce the number of drawing points because its so small
                       xmiss = (x + (matrixsize/2));
                   }
            }//end of recording a signel data point within pixel loops
            
             cOld = c;
          }//end x pixel loop LEFT TO RIGHT
          
        }else{ //loop RIGHT TO LEFT
            int xd =  PixelWidth-1;
            for (int x = PixelWidth-1; x >=1; x-= matrixsize) {
              bPrevHit = hit;
              hit = false;
              color c = convolution(x, y, matrixsize);
              if (x==PixelWidth-1) {cOld =c; }
              
              fill(c); stroke(c); 
              if (c == cOld && cOld != color(255)){hit= true;}
                            
              if (hit && recordingData== false ){ rect(x + (matrixsize/2), y + (matrixsize/2), matrixsize, matrixsize);  }              
              //  if ( !bPrevHit && cOld != color(255)){ stroke(255);  rect(x - (matrixsize/2), y - (matrixsize/2), matrixsize, matrixsize);  }
              //attempting to remove horizontal strokes  if (recordingData && hit){ svg.stroke(c); svg.point(x + (matrixsize/2),y + (matrixsize/2));}
              
              if (recordingData){
                   if (hit){
                      xd= (x - (matrixsize/2));
                      counter += 1;
                      if( (x - matrixsize) <1  && counter>=1 )  { //if you are on the last line of x and there is no white pixel to trigger the above line, then draw a line through all consecutive drawable points not yet drawn
                         svg.stroke(cOld);// svg.fill(cOld);
                         svg.line(xd+(counter)*matrixsize,y,xd,y);
                         counter =0;
                         xd= PixelWidth-1;
                      }
                   } else { // If the pixel is not dark enough to draw then do not record a drawable point.
                       if (!bPrevHit && cOld != color(255)){ //draw a single dot
                           svg.stroke(cOld); //svg.fill(cOld);
                           if (!filterSpeckle){
                                 if ( brightness(cOld)<10 ){ svg.point(xmiss,y);}//cOld==colorArray[1],matrixsize/2);  //(xd-(counter-1)*matrixsize,y,xd,y); //draw a line through all consecutive drawable points not yet drawn. We use (counter-1) because 2 points make 1 line.
                           }else{ svg.point(xmiss,y); }
                       }else if (counter>=1 ) { //If there were drawable points prior to this non drawable point then create a line from the first to last of the drawable pixels not yet drawn
                          svg.stroke(cOld); //svg.fill(cOld); 
                          svg.line(xd+(counter)*matrixsize,y,xd,y); //draw a line through all consecutive drawable points not yet drawn. We use (counter-1) because 2 points make 1 line.
                          counter =0;
                          xd= PixelWidth-1;
                       }else { //resets record!
                         xd= PixelWidth-1;
                         counter =0;} // if a drawable point is only 1 pixel wide then this will negate it to reduce the number of drawing points because its so small
                         xmiss = (x - (matrixsize/2));
                     }
              } 
              
              cOld = c;
            }//end of x for
            
        }//end of loop RIGHT TO LEFT          
              
      }//top to bottom pixel loop
   
      if (!recordingData){
         pushMatrix();  
         translate(img.width+2,0);
         image(imgOrig, 0, 0); // SHOW ORIGINAL NEXT TO THE PREVIEW
         popMatrix();
      }
    }//else from min tool dia check
   
    toolDiaOld = toolDia; 
   

   if (recordingData){    //this is where I want to trigger the 'finished' pop up....
           svg.fill(100, 100,255); svg.stroke(100, 100,255);//specifically for text  
           float textSize = 0.5*(100/(100-overLap))* RealHeight/toolDia/11.75  ;//17 is generall but want to be smaller for low pixel count images (high tool dia, low image size)(  RealHeight/toolDia  100/.5 =200
           float textSpacing = 0.5*(100/(100-overLap))* RealHeight/toolDia/10;//20 is general.
            svg.textSize(textSize);
            svg.text("Created with CylinDraw DePixelizer",10,textSpacing); //positionx,positiony
            svg.text("Size: " + RealHeight + "mm tall x " + RealWidth + "mm wide",10,textSpacing*2);
            svg.text("Stroke Width: " + nf(toolDia, 1, 2) + "mm",10,textSpacing*3);
            svg.text("Unique Colors: " + iColorLimit,10,textSpacing*4);
            svg.text("Stroke Overlap: " + nf(overLap, 2, 0) + "%",10,textSpacing*5);
            
        recordingData = false;
        svg.endDraw();  //used to end raw svg preview.
        //String tempPath = sketchPath()+"\\temp.svg"; 
        
        File file = saveFile(destName); // File to be moved (the one the user selected. And if we are in fileCopy then we know its in a different directory)
    
        File dest = new File(savePath(sketchPath()),"system/temp.svg");// fileName);// use temp so we dont fill up with crap files
       
        byte[] source = loadBytes(file);
        saveBytes(dest, source);
        
        svg.dispose();  //used to end raw svg preview
        try{
          launch(destName);   // println("Data Recorded! File save name is: " + destName);
        }  catch(RuntimeException e) { };
          
        zoomScale = zoomScaleOld;    
        //setButtons();
         
          imageLoaded=false;
          reloadImage(filePath);
          cursor(HAND);
      }
  }

   if (!recordData){
     popMatrix(); //pop the 60mm shift below the headder buttons
   }
   if (recordData){recordData = false;}
 //
   if(bSettingColors){
        //showHideButtons(false);
        bSettingColors=false;//reset state
        
        int num1 =PixelHeight*PixelWidth-1;//next most commonly occuring
        int num2 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num3 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num4 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num5 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num6 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num7 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num8 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num9 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num10 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num11 =PixelHeight*PixelWidth-1;//most commonly occuring
        int num12 =PixelHeight*PixelWidth-1;//TOP most commonly occuring
        
       // for (int loop2=0;loop2<=12;loop2++){
         int curr;
         //println("cntr was " + cntr + "__________________________________________________");
         for (int loopy=0;loopy<=cntr;loopy++){// most common color finder
             curr= voteArray[loopy]; 
             //println("@ loopy" +loopy + " curr was " +curr);
             if(curr >voteArray[num1] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7=num6;num6=num5;num5=num4;num4=num3; num3 =num2; num2 =num1;  num1 = loopy;}//println("num0:" +num0);}
             else if(curr >voteArray[num2] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7=num6;num6=num5;num5=num4;num4=num3; num3 =num2; num2  = loopy;}//println("num2:" +num2);}
             else if(curr >voteArray[num3] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7=num6;num6=num5;num5=num4;num4=num3; num3  = loopy;}//println("num3:" +num3);}
             else if(curr >voteArray[num4] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7=num6;num6=num5;num5=num4;num4  = loopy;}//println("num4:" +num4);}
             else if(curr >voteArray[num5] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7=num6;num6=num5;num5  = loopy;}//println("num5:" +num5);}
             else if(curr >voteArray[num6] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7=num6;num6= loopy;}//println("num6:" +num6);}
             else if(curr >voteArray[num7] ){num12=num11;num11=num10;num10=num9;num9=num8;num8=num7;num7= loopy;}//println("num7:" +num7);}
             else if(curr >voteArray[num8] ){num12=num11;num11=num10;num10=num9;num9=num8;num8= loopy;}//println("num8:" +num8);}
             else if(curr >voteArray[num9] ){num12=num11;num11=num10;num10=num9;num9= loopy;}//println("num9:" +num9);}
             else if(curr >voteArray[num10] ){num12=num11;num11=num10; num10= loopy;}//println("num10 " +num10);}
             else if(curr >voteArray[num11] ){num12=num11;num11= loopy;}//println("num11 " +num11); }
             else if(curr >voteArray[num12] ){num12= loopy;}//println("num11 " +num11); }
        }
        
         //for (int d =0;d<=cntr;d++){
         //  if (voteArray[d] !=0){           println("voteArrayId#:" + d + " had " + voteArray[d] + " votes for color " + colorsTransient[d] );}
         //}  
         
         for (int rev =1; rev<iColorLimit; rev++){ //rev =0 originally
             color rrr;
                 switch(rev){
                   case 1:  rrr = colorsTransient[num1];  colorArray[1] = colorsTransient[num1];   gui.getController("setColor1").setColorBackground(rrr);  break;//println("popularity: " + rev+ " was " +rrr + " with votes = " +voteArray[num0] ); 
                   case 2:  rrr = colorsTransient[num2];  colorArray[2] = colorsTransient[num2];   gui.getController("setColor2").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num1]);break;
                   case 3:  rrr = colorsTransient[num3];  colorArray[3] = colorsTransient[num3];   gui.getController("setColor3").setColorBackground(rrr); break;// println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num2]);break;
                   case 4:  rrr = colorsTransient[num4];  colorArray[4] = colorsTransient[num4];   gui.getController("setColor4").setColorBackground(rrr); break;// println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num3]);break;
                   case 5:  rrr = colorsTransient[num5];  colorArray[5] = colorsTransient[num5];   gui.getController("setColor5").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num4]);break;
                   case 6:  rrr = colorsTransient[num6];  colorArray[6] = colorsTransient[num6];   gui.getController("setColor6").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num5]);break;
                   case 7:  rrr = colorsTransient[num7];  colorArray[7] = colorsTransient[num7];   gui.getController("setColor7").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num6]);break;
                   case 8:  rrr = colorsTransient[num8];  colorArray[8] = colorsTransient[num8];   gui.getController("setColor8").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num7]);break;
                   case 9:  rrr = colorsTransient[num9];  colorArray[9] = colorsTransient[num9];   gui.getController("setColor9").setColorBackground(rrr); break;//println("popolarity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num8]);break;
                   case 10: rrr = colorsTransient[num10];  colorArray[10] = colorsTransient[num10];   gui.getController("setColor10").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num9]);break;
                   case 11: rrr = colorsTransient[num11];  colorArray[11] = colorsTransient[num11]; gui.getController("setColor11").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num10]);break;
                   case 12: rrr = colorsTransient[num12];  colorArray[12] = colorsTransient[num12]; gui.getController("setColor12").setColorBackground(rrr); break;//println("popularity: " + rev+ " was " +rrr+ " with votes = " +voteArray[num11]);break;
                 }
         }
       //setButtons();
     // imageLoaded = false;   reloadImage(filePath);
        // voteArray[loopy]      
        // colors[cntr] 
        // cntr=0;
  }
  
  drawUI();  // draw instructions to the screen
   
  if (xWindow != width){ // if  surface.setSize(xWindow, yWindow);
      xWindow = width;
      setButtons();
      imageLoaded=false;
          reloadImage(filePath);
      //if (imageLoaded){ thresholdLow =0; thresholdHigh=255; }//;    //sliderThresholdHigh(255); } 
    }else if (yWindow != height){
      yWindow = height;
      setButtons();
      imageLoaded=false;
          reloadImage(filePath);
      //if (imageLoaded){ thresholdLow =0; thresholdHigh=255; }//
  }
   
}//END OF DRAW



void fileSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel."); 
    //imageLoaded = false;
   // fileLoaded = false;
  } else {
  
    delay(50); //this delay before the next line ensures no signals get confused
    String tempPath = selection.getAbsolutePath();
     
    if (tempPath.contains(".BMP") || tempPath.contains(".JPG") || tempPath.contains(".PNG") || tempPath.contains(".bmp") || tempPath.contains(".jpg") || tempPath.contains(".png") || tempPath.contains(".gif") ||tempPath.contains(".GIF"))  {
      filePath =tempPath;
      
      imageLoaded = false;//real quick so it stops he previous load
      zoomScale = 0.2;//
      
      fileNameOriginal = fileName = selection.getName(); //JUST THE NAME, no path

      //////////////////////////println("You selected " + filePath );//println("You selected " + filePath ); 
     // File file = new File(sketchPath("system/fileName"));
      //if (file.exists()) {
      //  println("File Found");//println("File Found");
     //   println(filePath);
     // } else {
      fileCopy();        
      //} 
      fileLoaded = true;
      pendingImageLoadFromPicker = true;
    } else {
        //fileLoaded = false;
       // imageLoaded=false;
        JFrame frame1 = new JFrame("Load Error!"); 
        frame1.setVisible(true);
        frame1.toFront();
        frame1.toBack();
        frame1.setAlwaysOnTop(true);
        frame1.setLocation(xWindow/2,yWindow/2);
        String title ="   Load Error!    ";
            Object[] message = {
              " Load Error! You MUST select a .jpg, .bmp, or .png file type!! ",
            };
          
          JOptionPane.showMessageDialog(frame1, message, title, JOptionPane.ERROR_MESSAGE);
          frame1.setVisible(false); 
          frame1.toBack();
          frame1.dispose();    
          //setButtons();
    }
  }
  //do not call this here. Causes error if try to load invalid file type. setButtons();
  //imageLoaded=false;
       //   reloadImage(filePath);
}//end of FileSelected()

void fileCopy(){  //If user picks file not located in processing parent folder, we copy it temporarily, then delete that copy on proper exit. File  
    File file = saveFile(filePath); // File to be moved (the one the user selected. And if we are in fileCopy then we know its in a different directory)
    
    //This saves the file that will be loaded next time. 
    File dest = new File(savePath(sketchPath()),"system/temp.JPG");// fileName);// use temp so we dont fill up with crap files
    byte[] source = loadBytes(file);
    saveBytes(dest, source);
    
    //This saves the working file (I dont just use this because it end up makig the folder look messy
    dest = new File(savePath(sketchPath()),"temp.JPG");// fileName);// use temp so we dont fill up with crap files
    source = loadBytes(file);
    saveBytes(dest, source); 
    dest.deleteOnExit(); //dangerous!
   
          
    filePath = dest.getAbsolutePath();
    fileName = dest.getName();
   
    boolean success = dest.exists(); 
    if (!success) {
       println("Somethine went wrong...Make sure you only try to open 'jpg, bmp, or png' files.");      //println("Somethine went wrong...Make sure you only try to open '.svg' files.");
    }
} 


void exportSelected(File selection) {
    //cursor(WAIT); //return cursor to arrow or hand
    
    //remove file selection from input criteria, 
    //Get name of file
    //generate path to proper folder
    //combine name with path  into >>>destName<<<<!!!
    

    if (selection != null){
        destName = selection.getPath();//selection.getName();//.getAbsolutePath(); 
       
        if (destName.contains(".BMP") || destName.contains(".JPG") ||destName.contains(".PNG") || destName.contains(".bmp") || destName.contains(".jpg") ||destName.contains(".png")) {      
            int index = destName.indexOf("."); //find dot & remove it from original name by only saving everything up to it
            destName = destName.substring(0,index);
            destName = destName+ ".svg";
        } 
        
        if(destName.contains(".svg") == false && destName.contains(".SVG") == false){
            destName = destName+ ".svg";
        }
        //thread("prompt"); //too annoying if its already launching
          
        //Setting theseu variables then running reload image is what actually saves it
        recordData = true; 
        imageLoaded = false;
        
        //added to try to get rid of phantom issue after saving
        
        
        
        reloadImage(filePath);  
        cursor (WAIT);
        //setButtons();
    } else {
        println("File save callback is: NULLLLLLL" );
        //int index = fileNameOriginal.indexOf("."); //find dot & remove it from original name by only saving everything up to it
        //destName = destName+ fileNameOriginal.substring(0,index);
    }
  //  cursor(HAND); //return cursor to arrow or hand
}
/*
void prompt(){
      JFrame frame1 = new JFrame("File Save Prompt");  //Only need to call this if there is more than one frame i think
      frame1.setVisible(true);
      frame1.toFront();
      //frame1.setAlwaysOnTop(true);
      frame1.setLocation(xWindow/2,yWindow/2);
      for(int i = 0;i<=iColorLimit;i++){
          println("i is " + i);
          /// println("icolorindex is " + iColorIndex);
          println("icolorlimit is " + iColorLimit);
          println("colorArray is " + colorArray[i]);
      } 
    
      String title ="File Save Prompt";
          Object[] message = {
            "File saving now. It will automatically open when complete.",
            "File Location selected: " + destName,
          };
        
      JOptionPane.showMessageDialog(frame1, message, title, JOptionPane.INFORMATION_MESSAGE);
      frame1.setVisible(false); 
      frame1.toBack();
      frame1.dispose();   
} */

void reloadImage(String path){ // set up the new image and reset resolution// called when user loads new image-
   if(fileLoaded){
    filePath = path;
    img = imgOrig = loadImage(path);
    loadPixels(); ///WHOOOO leave this here, it cures the phantom issue from when you change the screen!
    
     if (recordingData){
         idealMatrix =0;
         zoomScale = .1;
         //TO TEST
         //idealHeight = NumStrokes;
         //idealWidth= (int)((float)(PixelWidth)/((float)(PixelHeight))* (float)(idealHeight)); 
         //idealMatrix=1;
          while(idealMatrix<1){
            zoomScale = zoomScale +.001;
           idealHeight =(int)(img.height*zoomScale);
            idealWidth = (int)(img.width*zoomScale);
            idealMatrix  = (idealHeight/NumStrokes);//NO ROUNDING HERE
         }
         /*
         while(idealMatrix>1){
            zoomScale = zoomScale -.001;
           idealHeight =(int)(img.height*zoomScale);
            idealWidth = (int)(img.width*zoomScale);
            idealMatrix  = (idealHeight/NumStrokes);//NO ROUNDING HERE
         } */
         /*while(idealMatrix>=1.5){
            zoomScale = zoomScale -.0001;
            idealHeight =(int)(img.height*zoomScale);
            idealWidth = (int)(img.width*zoomScale);
            idealMatrix  = (idealHeight/NumStrokes);//NO ROUNDING HERE
          }*/
       //  img.resize(idealWidth,idealHeight);
        //  PixelHeight =(int)(img.height*zoomScale);
      //    PixelWidth = (int)(img.width*zoomScale);
     }else{
       
          while ( (int(img.height*zoomScale)) >= zLimit-57 ){ //this caps off the max size of the image you can zoom to
             zoomScale = zoomScale -.01;
           }   
      }
        
      PixelHeight =(int)(img.height*zoomScale);
      PixelWidth = (int)(img.width*zoomScale);
    
      RealWidth =  (int)((float)(PixelWidth)/((float)(PixelHeight))* (float)(RealHeight)); //Calculate it just for displaying it.

      if(toolDia<=0){
           toolDia=0;
           NumStrokes = round( (RealHeight/(.01))  );// this will give the tightest slice possible!
      }else{
           NumStrokes = round((RealHeight/(toolDia))*(100/(100-overLap))); //0.5 is the overlap between strokes
      }
      
      matrixsize  = round(PixelHeight/NumStrokes);
      //println("matrixsize is " + matrixsize);
          if (matrixsize <1 ){matrixsize =1;}; // compute size of new resolution convo matrix!! THIS IS WHERE THE RUBBER MEETS THE ROAD
 

         img.resize(PixelWidth,PixelHeight);  //
         imgOrig.resize(PixelWidth,PixelHeight); 
           
          if(verbose){println("PixelHeight " + PixelHeight);}
          if(verbose){println("PixelWidtht " + PixelWidth);}
          if(verbose){println("RealHeight " + RealHeight);}
          if(verbose){println("RealWidth " + RealWidth);}
          if(verbose){println("NumStrokes " + NumStrokes);}
          if(verbose){println("matrixsize " + matrixsize);}
          if(verbose){println("zoomscale " + zoomScale);}
          if(verbose){println(" ");}   

    updatePixels(); 
   
     if (inverted){  img.filter(INVERT);}
      //if (inverted && ! filterTrace){  img.filter(INVERT);}   
    
    if (filterErode){ img.filter(ERODE);} 
    if (filterDilate){ img.filter(DILATE);} 
  
    //if (filterPoster){ img.filter(POSTERIZE,2 );};//add in=ouyts);}  //2-255 but 2 is max intensity
    if (iPoster>0)  { 
      int val = int(map(iPoster,1,100,11,2));
      img.filter(POSTERIZE,val );
    };//add in=ouyts);}  //2-255 but 2 is max intensity
  
   if (filterBlur){ img.filter(BLUR);}
   
     if (filterSharpen){
           PImage edgeImg = createImage(img.width, img.height, RGB);
            for (int x = 0; x <  edgeImg.width; x++) {
              for (int y = 0; y <edgeImg.height; y++ ) {
                color c = sharpen(x,y,edgeImg);
                int loc = x + y*edgeImg.width;
                //loc = constrain(loc, 0, edgeImg.pixels.length-1);      // Make sure we have not walked off the edge of the pixel array
                //pixels[loc] = c;
                 edgeImg.pixels[loc] = c;
              }
          }
          edgeImg.updatePixels();
         img = edgeImg;
     }
     if (filterTrace){ //add an edge
          img.filter(OPAQUE); 
           
          //emboss
          float[][] kernel =
                      {{ -2, -1, 0}, 
                      { -1, 1, 1}, 
                      { 0, 1, 2}}; 
                      
          //edge
          /*
         float[][] kernel =
                      {{ -1, -1, -1}, 
                      { -1, 8, -1}, 
                      { -1, -1, -1}};  
                      */
          PImage edgeImg = createImage(img.width, img.height, RGB);
         
          //edgeImg.filter(POSTERIZE,2 );
          // Loop through every pixel in the image.
          for (int y = 0; y < img.height; y++) { // Skip top and bottom edges
            for (int x = 0; x < img.width; x++) { // Skip left and right edges
             
              float sum = 0; // Kernel sum for this pixel
              for (int ky = -1; ky <= 1; ky++) {
                for (int kx = -1; kx <= 1; kx++) {
                  int pos = (y + ky)*img.width + (x + kx); // Calculate the adjacent pixel for this kernel point
                  pos =constrain(pos, 0, img.pixels.length-1); 
                  float val = brightness(img.pixels[pos]); // Image is grayscale, red/green/blue are identical
                  sum += kernel[ky+1][kx+1] * val; // Multiply adjacent pixels based on the kernel values
                }
              }
              // For this pixel in the new image, set the gray value based on the sum from the kernel
              edgeImg.pixels[y*img.width + x] = color(sum, sum, sum);
            }
          }
          
           //if (inverted){  edgeImg.filter(INVERT);}
          edgeImg.updatePixels();
        // img.mask(edgeImg);
         img = edgeImg;
    }

    
   
   imgOrig = img;
    updatePixels();   //vs loadPixels
    
    
      
    imageLoaded = true;
    }
}




void drawUI(){ // show text instructions for use  
  
   float downscale = 2.6;int imgpixelwidth = 2030;int imgpixelheight = 244;imageMode(CENTER);
   image(logoHeaderImg, width/2, 30, imgpixelwidth/2/downscale, imgpixelheight/2/downscale);// 500, 500/11.73); //logo header image. The 500 sets the width & the 11.82 number is based on the image size so it has the correct aspect ratio & size when loaded.
   imageMode(CORNERS);
    
   if (fileLoaded){ 
      fill(0, 0, 255);
      textSize(18);
      int posy = 8;
      int posx = 1000;//860;//1090;
      int spacing = 23;
      int currentSpace = 0; //lower number = lower ininitial position of group
      if (iColorLimit !=2){
        if (filterBackground){
          text("Background color removed", posx, height-posy-currentSpace);     
        }else{
          text("", posx, height-posy-currentSpace);
        }
           currentSpace = currentSpace+spacing;
        if (!filterSpeckle){
          text("Only black single-dots will be present. (No preview)", posx, height-posy-currentSpace);
        }else{
          text("All colors of dots will be present. (No preview)", posx, height-posy-currentSpace);
        }
        
      }else{
         currentSpace = currentSpace+spacing;
        if (bDither ){ // && iColorLimit ==2
          text("Dither On, simulate gray with dots. (No preview)", posx, height-posy-currentSpace);
        }
       
      }
      currentSpace = currentSpace+spacing;
      if (toolDia <=0){
        text("Resolution: " + NumStrokes + " strokes. Tool diameter ignored.", posx, height-posy-currentSpace);  currentSpace = currentSpace+spacing;
      }else{
        text("Resolution: " + NumStrokes + " strokes with overlap of " + overLap + "%" , posx, height-posy-currentSpace);  currentSpace = currentSpace+spacing;
      }
      text("Stroke Width: " + nf(toolDia, 1, 2) + "mm", posx, height-posy-currentSpace);   currentSpace = currentSpace+spacing;
      text("Export Size: " + RealHeight + "mm tall x " + RealWidth + "mm wide", posx, height-posy-currentSpace);  currentSpace = currentSpace+spacing;
      //text("Brightness Threshold is: " + nf(100*thresholdLow/255,2,1) +"%", posx, height-posy-currentSpace);
      
      //currentSpace = currentSpace+spacing;//push up a bit more
    
      zLimit = height-80-96;
      fill(255, 255, 255);   stroke(3);
      line(0,zLimit, width,zLimit);
      line(0,57, width,57); //top line
      noFill();
  }
}


void mouseWheel(MouseEvent event){
  if (imageLoaded){
    toolDiaOld = 9999; //A trick for whne screen is resized but the image didnt change, to make it reappaear this forces the system to redraw
    float wheelcount = event.getCount();
    zoomScale = zoomScale + wheelcount/50; 
    
    if (zoomScale<.01){zoomScale = .01;}
    reloadImage(filePath); //println(zoomScale);
  }
}


void buttonExit(){
  String title ="Exit program?";
  String message = "Are you sure you want to exit the program? Anything not saved will be lost.";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  //frame3.setAlwaysOnTop(true);
  //frame3.setLocation(xWindow/2,yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ exit();  }
  if (option == JOptionPane.CANCEL_OPTION){ // println(">User Clicked Cancel.<");  
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
    
          "For questions concerning your order contact us at CylinDraw@gmail.com",
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
  
    JButton buttonHomepage = new JButton("Visit CylinDraw Homepage");
  buttonHomepage.addActionListener(new ActionListener()
  {
    public void actionPerformed(ActionEvent event)
    {
       link("https://cylindraw.com/");
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
      "This is the 'Depixelizer Mode'.",
          "Here we convert generic image files (png, jpg, bmp) into vector files (SVG), which can then be used by 'Creation mode' to create a drawable '.JOB.svg' file.)",
          "   1. Begin by clicking 'Load Image', then editing the image as you see fit.",
          "   2. The original image is shown on the right, a preview of the output is shown on the left",
          "   3. When done click 'EXPORT'. ",
          "Note:",
          "   -Rolling the mouse zooms the preview but has no effect on final result.",
          "   -Large previews, small strokes, large imported images, 'Sharp', & 'Trace' all make this program run slower. We are doing intense calculations in the backround! ",
          "Buttons:  ",
          "    Image Smaller vs Bigger:  Adjust the size of the real output image that will be drawn.",
          "         -Note that the size counts every pixel of the input image, not just the colored ones. (For example, both 'normal & inverted' output the same size.) ",
          "    Lower Limit, Upper Limit: Adjust the Limit of what may be considered black or white. (LowerLimit++ is darker.) (UpperLimit-- is lighter) Basically a combined version of brightness/contrast. ",
          "    Stroke Smaller vs Bigger:  Choose the exact pen/tool you will use & measure the exact width of the stroke it creates. ",
          "        -Choosing a smaller stroke than you actually might give you a tiny bit more detail but it can also bolden the final output because your tool is trying to go places it shouldnt.",//  If the image pixels are misaligned it is often a display artefact that will not appear in the output",
          "        -Choosing a larger stroke than you have will cause gaps between drawn fill lines. ",//  If the image pixels are misaligned it is often a display artefact that will not appear in the output",
          "        -Typical strokes: Engraving = 0.2mm, UltraFine Pen = 0.5mm, Thick marker =1.0mm",
          "    Normal vs Invert:  Invert black/white on the image.",
          "    Normal vs Blurred:  Apply gaussian blur which reduces detail but blens edges.",
          "    % Reduced:  Apply algorythim to consolidate colors on original image. The effect is similiar to the famous Obama Hope Poster. ",
          "    Trace:  Apply algorythim to find the edges of your image. (usually only used with2 = # colors) ",
          "    Normal vs Light: Reduce strength of dark tones only",
          "    Normal vs Dark:  Increase strength of dark tones only",
          "    Normal vs Sharp:  Apply algorythm to make edges more noticeable",
          "    Normal vs Dithered:  Apply algorythm to approximate gray using only black & white (good for images of people. Onscreen preview inherantly inaccurate for this, must export to see good preview)",
          "    # Colors: Choose how many colors the output image will have.",
          "    Color Palette-Clicking on the tiny color number boxes below the #Colors slider will allow you to change that color!",
          "         -The output image will ONLY be those colors. Our color quantization algorithm groups pixels by how similiar they are to your chosen colors.!! ",
          "         -The Job Creator program will auto sort the job by darkest to lightest pen colors so you wont smear! ",
          "         -Pure white is ignored. Anything not 100% white will be part of the SVG and will be drawn. ",
          "         -The last color always defaults to white, so if you choose 2 colors the second is automatically white. ",
          "    Auto Colors: Our algorythm sets the palette to the most frequently occuring colors in the original image. Forgive imperfections, this is much harder to calculate in a useful way than you might think!",
          "    BKGND vs None:  None removes all pixels that have the same color as the background. We assume the background to be whatever is the very top left pixel color.",
          "    Clean vs All Dots: 'Clean' only draws the darkest color of single unconnected dots to reduce noise & drawing time. 'All dots' draws every color of dot in case you want going for high detail even if noisy.",
          " ",
          "|<<Auto Name the Exported File      OR      Manually Name the Exported File >>|",
          slideExport,
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
    //println(fieldEmail.getText());
   // println(fieldLicense.getText());
     if (slideExport.getValue() ==0){
          bExplicitExport = false;
      }else{
          bExplicitExport = true;
      }
      
    checkLicense(fieldEmail.getText(),fieldLicense.getText()); //CHECKED LICENSE HERE to see if PAID

    if (bPaid) { 
      ;
    } else if (bTerms) {
      /* no more annoying prompts if they already agreed to terms. 
      Object[] message22 = {
        "~Free license found. We hope you enjoy the free version of our product!~", 
        //"If you have valid license key, please click the HELP button and enter it there.", 
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
      */
    };
  }
  frame33.setVisible(false);
  frame33.toBack();
  frame33.dispose();  
}

  
void buttonProgConvert(){println("You are currently using DePixelizer Mode.");}
    

void launchSiblingApp(String appFolderName){
  try{
    File currentAppDir = new File(sketchPath());
    File suiteRootDir = currentAppDir.getParentFile();
    File targetAppDir = new File(suiteRootDir, appFolderName);
    String launchCmd = "cd \"" + targetAppDir.getAbsolutePath() + "\" && ./" + appFolderName;
    Runtime.getRuntime().exec(new String[]{"/bin/bash", "-lc", launchCmd});
  }catch(Exception e){
    JOptionPane.showMessageDialog(null, "Unable to launch app: " + appFolderName + "\n" + e.getMessage(), "Launch Error", JOptionPane.ERROR_MESSAGE);
  }
}



void buttonProgCreate(){ 
 String title ="Switch to CREATION Mode?";
  String message = "Are you sure you want to switch to Job Creation Mode? (The currently loaded settings will be reset.)";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  //frame3.setAlwaysOnTop(true);
  //frame3.setLocation(xWindow/2,yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ 
      launchSiblingApp("CylinDrawJobCreator");
      exit();   
  }
  if (option == JOptionPane.CANCEL_OPTION){ println(">User Clicked Cancel.<");  }
  frame3.setVisible(false);
  frame3.toBack();
  frame3.dispose();
}
  
  
void buttonProgRun(){
  String title ="Switch to Run Mode?";
  String message = "Are you sure you want to switch to Run Mode? (The currently loaded settings will be reset.)";
  JFrame frame3 = new JFrame(title);  //Only need to call this if there is more than one frame i think
  frame3.setVisible(true);
  frame3.toFront();
  //frame3.setLocation(xWindow/2,yWindow/2);
  int option = JOptionPane.showConfirmDialog(null, message,title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
  if (option == JOptionPane.OK_OPTION){ 
      launchSiblingApp("CylinDrawRunMode");
      exit();   
  }
  if (option == JOptionPane.CANCEL_OPTION){  println(">User Clicked Cancel.<");  }
  frame3.setVisible(false);
  frame3.toBack();
  frame3.dispose();
}


 
void buttonToolUp(){     toolDia = toolDia +.05;  imageLoaded = false;   reloadImage(filePath); }
void buttonToolDown(){   toolDia = toolDia -.05;   if (toolDia <=0){toolDia = .05;}  imageLoaded = false;   reloadImage(filePath); }
void buttonSizeUp(){   RealHeight = RealHeight +1; imageLoaded = false;   reloadImage(filePath); }
void buttonSizeDown(){   RealHeight = RealHeight -1; if (RealHeight <10){RealHeight = 10;} imageLoaded = false;   reloadImage(filePath); }
void toggleInverted(){  inverted = toggleInverted.getBooleanValue();;  imageLoaded = false;   reloadImage(filePath); }//inverted = toggleInverted.getBooleanValue(); 
void toggleBlur(){    filterBlur =  toggleBlur.getBooleanValue();;  imageLoaded = false;   reloadImage(filePath); }
void toggleTrace(){  filterTrace =  toggleTrace.getBooleanValue();  imageLoaded = false;   reloadImage(filePath); }
void toggleSharpen(){  filterSharpen =  toggleSharpen.getBooleanValue();  imageLoaded = false;   reloadImage(filePath); }

void toggleErode(){  filterErode = toggleErode.getBooleanValue();  imageLoaded = false;   reloadImage(filePath); }
void toggleDilate(){   filterDilate =  toggleDilate.getBooleanValue();  imageLoaded = false;   reloadImage(filePath); }
void toggleSpeckle(){  filterSpeckle =  toggleSpeckle.getBooleanValue();  imageLoaded = false;   reloadImage(filePath); }
void toggleDither(){  bDither =  toggleDither.getBooleanValue(); if(bDither){overLap=0;}else{overLap=50;} imageLoaded = false;   reloadImage(filePath); }
void toggleBackground(){ filterBackground =  toggleBackground.getBooleanValue();;  imageLoaded = false;   reloadImage(filePath); }
void buttonSave(){  
  
  if (!bPaid && iColorLimit >2){
      JFrame frame172 = new JFrame("Notice");  //Only need to call this if there is more than one frame i think .  Pretty sure I did it to make sure he select inout gets pulled to the front
      frame172.setVisible(true);
      frame172.toFront(); 
      //frame172.setAlwaysOnTop(true);
      frame172.setLocation(xWindow/2,yWindow/2);
      Object[] message2 = {
            "Sorry, but you can only save 2-color svgs with the free license.", 
            "You can remove this limitation with a one time purchase of a CylinDraw Control License key.",
            "If you already have valid license key, please click the HELP button and enter it there.",
      };
      JOptionPane.showMessageDialog(frame172, message2, "NOTICE!", JOptionPane.INFORMATION_MESSAGE);
      frame172.setVisible(false);
      frame172.toBack();
      frame172.dispose();
    
  }else if (!bTerms){
      println(">>File not saved due to missing end user license agreement. Please agree & try to save again.<<");
      checkLicense("","");
  }else{
    File shit = storedFile;
    if (bExplicitExport){
        selectOutput("Name the SVG File you are about to export:", "exportSelected",shit);
    }else{
        exportSelected(storedFile );// need to modify export selected to append proper folder path
    }
  }
}
      
void buttonLoad(){
   thread("cum");
}
void cum(){
  selectInput("Select an image file to process: (usable types are .jpg, .png, .bmp, .gif)", "fileSelected",storedFile);  // selectInput("Select any 'jpg,png,bmp' an image type file to process:", "fileSelected");
}

float colorPosition(color c1){ //min value is 0 max is 441.673 when colors are constrained between 0-255
  float r = red(c1);
  float g = green(c1);
  float b = blue(c1);
  return sqrt( sq(r) + sq(g) + sq(b) );  // return  dist(red(c1), red(c2),green(c1),green(c2), blue(c1),blue(c2));
} 
float colorVariance(color c1){////tells you how not-gray a color is. (higher yoyoutput isl less gra)  //min value is 0 max is 441.673 when colors are constrained between 0-255
  float r = red(c1);
  float g = green(c1);
  float b = blue(c1);
  
  return ( max(r,g,b) - min(r,g,b) );  // return  dist(red(c1), red(c2),green(c1),green(c2), blue(c1),blue(c2));
} 

float colorDist(color c1,color c2){ //min value is 0 max is 441.673 when colors are constrained between 0-255
  return  dist(red(c1),green(c1),blue(c1),red(c2), green(c2),blue(c2));
} 



void sliderThresholdLow(int value){
  if (imageLoaded  && !bSliderLock){
    thresholdLow = value; sliderColors(iColorLimit); imageLoaded = false;   reloadImage(filePath);
  }
}


void sliderThresholdHigh(int value){
  if (imageLoaded  && !bSliderLock){
     thresholdHigh = value; sliderColors(iColorLimit); imageLoaded = false;   reloadImage(filePath);
  }
}


void sliderOverlap(int value){ //note this exists but is hidden from the user, I dont wantthem controlling it
  if (imageLoaded  && !bSliderLock){ overLap = value; imageLoaded = false;   reloadImage(filePath);}
}

void sliderPoster(int value){
  if (!bSliderLock && imageLoaded) {
    iPoster = value;
    imageLoaded = false;   reloadImage(filePath);
  }
}
/*void sliderBrightness(int value){
  if (!bSliderLock && imageLoaded) {
    brightness = value;
    imageLoaded = false;   reloadImage(filePath);
  }
}
void sliderContrast(int value){
  if (!bSliderLock && imageLoaded) {
    contrast = value;
    imageLoaded = false;   reloadImage(filePath);
  }
}*/

  
color sharpen(int x, int y, PImage imgs) {
  float[][] kernel ={
    { -1, -1, -1}, 
    { -1, 9, -1}, 
    { -1, -1, -1}
  };
  int matrixsize3 = 3;
  float rtotal = 0.0;
  float gtotal = 0.0;
  float btotal = 0.0;
  int offset = matrixsize3 / 2;
  
  for (int i = 0; i < matrixsize3; i++){
    for (int j= 0; j < matrixsize3; j++){
      // What pixel are we testing
      int xloc = x+i-offset;
      int yloc = y+j-offset;
      int loc = xloc + imgs.width*yloc;
      loc = constrain(loc,0,imgs.pixels.length-1);
      // We sum all the neighboring pixels multiplied by the values in the .
      rtotal += (red(img.pixels[loc]) * kernel[i][j]);
      gtotal += (green(img.pixels[loc]) * kernel[i][j]);
      btotal += (blue(img.pixels[loc]) * kernel[i][j]);
    }
  }
  // Make sure RGB is within range to prevent err
  rtotal = constrain(rtotal,0,255);
  gtotal = constrain(gtotal,0,255);
  btotal = constrain(btotal,0,255);
  // Return the resulting color
  return color(rtotal,gtotal,btotal);
}


void checkFrequency( color colorIn){
       boolean bNewColor =true;
       for (int loopy=0;loopy<=cntr;loopy++){
         //if(colorsTransient[loopy] == colorIn){//
         if ( colorDist(colorsTransient[loopy],colorIn) <10   ){ //if SAME COLOR detected)
           voteArray[loopy]++;
           bNewColor = false;
           break;
         }
       }
       if (bNewColor ||  cntr==0){
         colorsTransient[cntr] = colorIn;
         cntr++;
       }
}

color convolution(int x, int y, int matsize) { // uses a spatial matrix technique to apply a smoothing of pixels in a given area. // averaging the pixel colour to produce the next image
    float rtotal = 0.0;
    float gtotal = 0.0;
    float btotal = 0.0;
    float rorig = 0.0;
    float gorig = 0.0;
    float borig = 0.0;

    int target =0;
    
    ////////matsize =2;/ do NOT FORCE THIS\\\   
    int offset = matsize / 2;   // offset used to help find the pixels in the current matrixsize
  
    // a smoothing convo matrix applies an even multiplication factor for 
    // averaging for all pixels in the given area.
    // so just calculate that value now rather than use an actual matrix
    float num_pixels = matsize * matsize;//makes it a weighted average
    matrix_multiplier = 1.0 / num_pixels;
    //println("multiplier " + matrix_multiplier);
    color c00 = (255/2);// = color(rtotal, gtotal, btotal);
   // color c01 = (255/2);// = color(rtotal, gtotal, btotal);

    for (int i = 0; i < matsize; i++) {  // Loop through convo matrix
      for (int j= 0; j < matsize; j++) {
        int xloc = x+i-offset; // What pixel are we testing
        int yloc = y+j-offset;
        int loc = xloc + img.width*yloc;
        
        loc = constrain(loc, 0, img.pixels.length-1);      // Make sure we have not walked off the edge of the pixel array

       rorig += (red(img.pixels[loc]) * matrix_multiplier);
       gorig += (green(img.pixels[loc]) * matrix_multiplier);
       borig += (blue(img.pixels[loc]) * matrix_multiplier);
  
       //contrast needs to range from 0-10 here, but slider needs to be fine..
      // //brightness needs to range from -128 to 128 here
      // rtotalC = (int)(rtotal * contrast/10 + brightness); //floating point aritmetic so convert back to int with a cast (i.e. '(int)');
       //gtotalC = (int)(gtotal * contrast/10 + brightness);
      // btotalC = (int)(btotal * contrast/10 + brightness);
              
      }
    } 
    
    /*
    if (iColorLimit ==2){
        rtotal = constrain(rorig , 0, 255);  // Make sure RGB is within range
        gtotal = constrain(gorig ,0, 255);  //using the thresholdLow/high values here will make the image change to grayscale when you are trying to change the edge case
        btotal = constrain(borig ,0, 255);
      }else{
        rtotal = constrain(rorig , thresholdLow, thresholdHigh);  // Make sure RGB is within range
        gtotal = constrain(gorig ,thresholdLow, thresholdHigh);
        btotal = constrain(borig ,thresholdLow, thresholdHigh);
      }

      c01 = color((rtotal + gtotal + btotal) / 3); */
      
      if (iColorLimit ==2){
        rtotal = constrain(rorig +rtit, 0, 255);  // Make sure RGB is within range
        gtotal = constrain(gorig +gtit,0, 255);  //using the thresholdLow/high values here will make the image change to grayscale when you are trying to change the edge case
        btotal = constrain(borig +btit,0, 255);
      }else{
        rtotal = constrain(rorig +rtit, thresholdLow, thresholdHigh);  // Make sure RGB is within range
        gtotal = constrain(gorig +gtit,thresholdLow, thresholdHigh);
        btotal = constrain(borig +btit,thresholdLow, thresholdHigh);
      }
           
      c00 =  color(rtotal, gtotal,btotal); //ORIGINAL color
      
     
     
    // if (colorVariance(c00)<10 ){
     //  c00 = color(0);
    // }
       if (bSettingColors){ //used for auto set estimation
        if(colorDist (c00,color(255))>5 && (colorVariance(c00) >10 || colorDist (c00,color(0))<1)  ){//
          checkFrequency(c00);
       }
      }
     
     
    // int rand = int(random(0, 100));
      
     // if (rand %2 == 0){c00 =  color(rmax, gmax, bmax);}
     // else{ c00 =  color(rmin, gmin, bmin);}
    
      //c00 =  color(rmin, gmin, bmin);
    // c00 =  color(rmax, gmax, bmax);
     
      
     // c00 = color(hueTotal,satTotal, briTotal);  
      ////////////////c00 = toRGB(hueTotal,satTotal, briTotal); // NOT BAD
      
      //c00 = color(hueTotal);//,100,100);
      
      //colorMode(RGB, 255, 255, 255);
      
      //low variance means its white, black, or gray

      //if (satTotal<50 && briTotal <50 ){c00 = toRGB(hueTotal,100, 100); }
      // if (colorVariance(c00) <10 ){}//toRGB(hueTotal,satTotal, briTotal); }
      // c00 = toRGB(hueTotal,satTotal, briTotal)    ;  
              
         //want nearesr number! its more like color position!!  distance is a category not a scalar.  
         //colorPosArray is positon for colorarra, are fixed! ///color position min value is 0 max is 441.673. Color array is premade array of color positions
         //UPDATE  We also want to make sure its a color that WAS in the convo array, so were not adding pixelization uncertainty....
         
         //colorarrayregion
         
         
         
        float minDist=5000;
        
        if (iColorLimit ==2){
            for (int rev =1; rev<=iColorLimit; rev++){ 
                if ( minDist >= abs(colorPosArray[rev] - colorPosition(c00)) ){      ///WHY WAS THIS SET TO  >= !!!
                    minDist = abs(colorPosArray[rev] - colorPosition(c00));
                    target = rev;
                 }
            }
         }else{ //multicolor mode selection
            for (int rev =1; rev<=iColorLimit; rev++){
                if ( minDist >= colorDist(colorArray[rev],c00) ){    
                    minDist = colorDist(colorArray[rev],c00);
                    target = rev;
                 }
            } 
         }

   
     
   //if ( c00 != colorArray[target]) {c00=(255);};
   c00 = colorArray[target];
      
   if (filterBackground){
     if (x ==1 && y ==1){backgroundColor = c00;}
     if (c00 ==backgroundColor){c00 = color(255);}
   }
   
      
   // &&  recordingData
   // unsharpened edges but good for faces, dithered vs sharp edge (photo vs cartoon). //dithering, Good for faces!! Note about processing time for dither 
  if (bDither   ){ //The && is dont apply dithering error correction to white or else it will wash out the pic.  Also dont do it for multicolor // && iColorLimit ==2   && c00 != color(255) 
     //the  recording data requirement is because the preview will be inaccurate, better to not edite the preview at all. 
     rtit = rtotal-red(c00) ; 
     gtit = gtotal- green(c00);
     btit= btotal-blue(c00);  
  }else{ //normal
     rtit = gtit =btit =0;
  }
  if (iColorLimit >2 && cOld != c00 && bDither && cOld != color(255)){
      rtit = gtit =btit =0;
  }
       
  
  
  
  
   //if (bDither &&  &&  c00 != color(255)){  //this is an attempt to get a better preview. Trying to show the grayscale values. doesnt work for preview becayse they wont connect to lines & screen res wont be good enough!
   // return c01;
   //}else{
     return c00;
   //}
     

}//end of convo

void sliderColors(int value){ // input limits: 2<=value<=12
  if (value <2 || value >12 || bSliderLock){return;}
  
   iColorLimit = int( sliderColors.getValue()); 
  
   if (value >0 &&  imageLoaded  ){
      iColorLimit = value;
      
      for (int rev =1; rev<=iColorLimit; rev++){ //rev =0 originally
         
         int val = int(map(rev,1,iColorLimit,0,255)); //DEFAULT!!
         int r = val; 
         int g = val;
         int b = val;//+1; why did i add this?
         //b = constrain(b, 0, 255);
         color rrr= color(r,g,b);//,g,b);//,g,b);
         
         if (iColorLimit ==2){
           val = int(map(rev,1,iColorLimit,thresholdLow,thresholdHigh)); //DEFAULT!!
           r = val; 
           g = val;
           b = val;
           rrr= color(r,g,b);
           colorArray[rev] = rrr;
           colorPosArray[rev] = colorPosition(rrr);
           colorArray[1] = color(0);
           colorArray[2] = color(255);
         }//else{
          // thresholdHigh = int(brightness(color(int(colorArray[iColorLimit-1]))));
        // }
         
         if (iColorLimit != iColorLimitOld  ){
             
             switch(rev){
               case 1:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr; gui.getController("setColor1").setColorBackground(rrr);}break;
               case 2:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor2").setColorBackground(rrr);}break;
               case 3:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor3").setColorBackground(rrr);}break;
               case 4: if(color(255) == colorArray[rev]){ colorArray[rev] = rrr; gui.getController("setColor4").setColorBackground(rrr);}break;
               case 5:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor5").setColorBackground(rrr);}break;
               case 6: if(color(255) == colorArray[rev]){ colorArray[rev] = rrr; gui.getController("setColor6").setColorBackground(rrr);}break;
               case 7:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor7").setColorBackground(rrr);}break;
               case 8:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor8").setColorBackground(rrr);}break;
               case 9:  if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor9").setColorBackground(rrr);}break;
               case 10: if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor10").setColorBackground(rrr);}break;
               case 11: if(color(255) == colorArray[rev]){ colorArray[rev] = rrr;gui.getController("setColor11").setColorBackground(rrr);}break;
               case 12:if(color(255) == colorArray[rev]){ colorArray[rev] = rrr; gui.getController("setColor12").setColorBackground(rrr);}break;
             } 
         }
        //  println("created color is " + rev + " "+r+ " "+g+ " "+b+ " "+ colorArray[rev] );    // println(colorPosArray[rev]);
       }    
     
       for (int rev =iColorLimit; rev<=12; rev++){
         color rrr= color(255);
         if (iColorLimit != iColorLimitOld){
             colorArray[rev] = color(rrr); //defaulted to white for all unused colors (above colorlimit up to 12)
             switch(rev){
               case 1:  gui.getController("setColor1").setColorBackground(rrr);break;
               case 2:  gui.getController("setColor2").setColorBackground(rrr);break;
               case 3:  gui.getController("setColor3").setColorBackground(rrr);break;
               case 4:  gui.getController("setColor4").setColorBackground(rrr);break;
               case 5:  gui.getController("setColor5").setColorBackground(rrr);break;
               case 6:  gui.getController("setColor6").setColorBackground(rrr);break;
               case 7:  gui.getController("setColor7").setColorBackground(rrr);break;
               case 8:  gui.getController("setColor8").setColorBackground(rrr);break;
               case 9:  gui.getController("setColor9").setColorBackground(rrr);break;
               case 10: gui.getController("setColor10").setColorBackground(rrr);break;
               case 11: gui.getController("setColor11").setColorBackground(rrr);break;
               case 12: gui.getController("setColor12").setColorBackground(rrr);break;
             } 
         }
       }   
       
       iColorLimitOld = iColorLimit;
       showHideButtons(false);
   }
}  


void keyPressed(){  if (key == ESC) { key = 0; buttonExit();} }


void setButtons(){
  bSliderLock = true;
   
  background(255);//wipes ove reverythign
  if (gui != null) gui.dispose();
  gui = new ControlP5(this);

  PFont p = createFont("Helvetica",12); 
  ControlFont font = new ControlFont(p);
  
  //HEADER BUTTONS////
  pushMatrix();
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
   popMatrix();


   //FOOTER BUTTONS/////////
   pushMatrix();
    Xpos =15;  Ypos = height - 160;  xSpacing = 20; ySpacing = 50; sizeX =123; sizeY =(135)/2; 
      buttonLoad = gui.addButton("buttonLoad").setCaptionLabel("   Load Image\n(png,jpg,gif,bmp)\n").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
        Ypos = Ypos + sizeY+10; 
      
      buttonSave = gui.addButton("buttonSave").setCaptionLabel("Export \n(.svg)\n").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);    
        Xpos = Xpos + sizeX + xSpacing;  sizeY =40; 
       Ypos = height - 160;
       
      buttonSizeDown = gui.addButton("buttonSizeDown").setCaptionLabel("Image Smaller").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);      
        xSpacing = xSpacing/4;
        Xpos = Xpos + sizeX + xSpacing;
      
      buttonSizeUp = gui.addButton("buttonSizeUp").setCaptionLabel("Image Bigger").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);      
        Xpos = Xpos - sizeX - xSpacing;   
        Ypos = Ypos + ySpacing;  
   
      sliderThresholdLow = gui.addSlider("sliderThresholdLow").setSize(sizeX, sizeY).setCaptionLabel("    Lower Limit").setPosition(Xpos, Ypos).setRange(0, 255).setValue(thresholdLow).setFont(font);
        gui.getController("sliderThresholdLow").getCaptionLabel().align(CENTER,CENTER); 
        Xpos = Xpos + sizeX + xSpacing;
      
      sliderThresholdHigh = gui.addSlider("sliderThresholdHigh").setSize(sizeX, sizeY).setCaptionLabel("    Upper Limit").setPosition(Xpos, Ypos).setRange(0, 255).setValue(thresholdHigh).setFont(font);
        gui.getController("sliderThresholdHigh").getCaptionLabel().align(CENTER,CENTER); 
        Xpos = Xpos - sizeX - xSpacing;  
        Ypos = Ypos + ySpacing; 
    
      buttonToolDown = gui.addButton("buttonToolDown").setCaptionLabel("Stroke Smaller").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);
      Xpos = Xpos + sizeX + xSpacing;    
   
      buttonToolUp = gui.addButton("buttonToolUp").setCaptionLabel("Stroke Bigger").setPosition(Xpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font);

       xSpacing = xSpacing*4;
        Ypos = height - 160;  ySpacing = 50; sizeY =40;
        Xpos = Xpos + sizeX + xSpacing;   
   
      toggleInverted = gui.addToggle("toggleInverted").setCaptionLabel("Normal    Invert").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        gui.getController("toggleInverted").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing;  
              
      toggleBlur = gui.addToggle("toggleBlur").setCaptionLabel("Normal    Blured").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        gui.getController("toggleBlur").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing; 
     
     sliderPoster = gui.addSlider("sliderPoster").setSize(sizeX, sizeY).setCaptionLabel("% Reduced").setPosition(Xpos, Ypos).setRange(0, 100).setValue(0).setFont(font);//.setLock(true);//.hide();
        gui.getController("sliderPoster").getCaptionLabel().align(CENTER,CENTER);  ///  sliderSpeed.hide(); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);
        //togglePoster = gui.addToggle("togglePoster").setCaptionLabel("Normal    Poster").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        // gui.getController("togglePoster").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing;
      
      Ypos = height - 160;  ySpacing = 50; sizeY =40;
      Xpos = Xpos + sizeX + xSpacing;  
      
      toggleTrace = gui.addToggle("toggleTrace").setCaptionLabel("Normal     Trace").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        gui.getController("toggleTrace").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing;
    
      toggleDilate = gui.addToggle("toggleDilate").setCaptionLabel("Normal   Light").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        gui.getController("toggleDilate").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing;
    
      toggleErode = gui.addToggle("toggleErode").setCaptionLabel("Normal    Shaded").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        gui.getController("toggleErode").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing;
    
    
      Ypos = height - 160;   ySpacing = 50; sizeY =40;
      Xpos = Xpos + sizeX + xSpacing; 
    
      toggleSharpen = gui.addToggle("toggleSharpen").setCaptionLabel("Normal     Sharp").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
        gui.getController("toggleSharpen").getCaptionLabel().align(CENTER,CENTER);
        Ypos = Ypos + ySpacing;
        
        
      toggleDither = gui.addToggle("toggleDither").setCaptionLabel("Normal   Dither").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
         gui.getController("toggleDither").getCaptionLabel().align(CENTER,CENTER);
         Ypos = Ypos + ySpacing;
         
      //sliderBrightness = gui.addSlider("sliderBrightness").setSize(sizeX, sizeY).setCaptionLabel("Brightness").setPosition(Xpos, Ypos).setRange(-128, 128).setValue(0).setFont(font);//.setLock(true);//.hide();
      //  gui.getController("sliderBrightness").getCaptionLabel().align(CENTER,CENTER);  ///  sliderSpeed.hide(); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);
       //         Ypos = Ypos + ySpacing;

     // sliderContrast = gui.addSlider("sliderContrast").setSize(sizeX, sizeY).setCaptionLabel("Contrast").setPosition(Xpos, Ypos).setRange(0, 100).setValue(10).setFont(font);//.setLock(true);//.hide();
       // gui.getController("sliderContrast").getCaptionLabel().align(CENTER,CENTER);  ///  sliderSpeed.hide(); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);  
    
      Ypos = height - 160;   ySpacing = 50; sizeY =40;
      Xpos = Xpos + sizeX + xSpacing;    
    
    sliderColors = gui.addSlider("sliderColors").setSize(sizeX, sizeY).setCaptionLabel("# Colors").setPosition(Xpos, Ypos).setRange(2, 12).setValue(iColorLimit).setFont(font);//.setLock(true);//.hide();
      gui.getController("sliderColors").getCaptionLabel().align(CENTER,CENTER);  ///  sliderSpeed.hide(); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);
      Ypos = Ypos + ySpacing;     

     sizeX =16; sizeY =40; int localXpos = Xpos;int localSpacing =5;
    setColor1 = gui.addButton("setColor1").setCaptionLabel("1").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[1]);
      localXpos = localXpos + sizeX + localSpacing;  
    setColor2 = gui.addButton("setColor2").setCaptionLabel("2").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[2]);
      localXpos = localXpos + sizeX + localSpacing;  
    setColor3 = gui.addButton("setColor3").setCaptionLabel("3").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[3]);
      localXpos = localXpos + sizeX + localSpacing; 
    setColor4 = gui.addButton("setColor4").setCaptionLabel("4").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[4]);
      localXpos = localXpos + sizeX + localSpacing; 
    setColor5 = gui.addButton("setColor5").setCaptionLabel("5").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[5]);
      localXpos = localXpos + sizeX + localSpacing; 
    setColor6 = gui.addButton("setColor6").setCaptionLabel("6").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[6]);
      localXpos = localXpos + sizeX + localSpacing; 
      
      Ypos = Ypos + ySpacing; localXpos = Xpos;
    setColor7 = gui.addButton("setColor7").setCaptionLabel("7").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[7]);
      localXpos = localXpos + sizeX + localSpacing;  
    setColor8 = gui.addButton("setColor8").setCaptionLabel("8").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[8]);
      localXpos = localXpos + sizeX + localSpacing;  
    setColor9 = gui.addButton("setColor9").setCaptionLabel("9").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[9]);
      localXpos = localXpos + sizeX + localSpacing; 
    setColor10 = gui.addButton("setColor10").setCaptionLabel("10").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[10]);
      localXpos = localXpos + sizeX + localSpacing; 
    setColor11 = gui.addButton("setColor11").setCaptionLabel("11").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[11]);
      localXpos = localXpos + sizeX + localSpacing; 
    setColor12 = gui.addButton("setColor12").setCaptionLabel("12").setPosition(localXpos, Ypos).setColorLabel(255).setSize(sizeX,sizeY).setFont(font).setColorBackground(colorArray[12]);
      localXpos = localXpos + sizeX + localSpacing; 
      
      
      Ypos = height - 160;  ySpacing = 50;  sizeX =123;// sizeY =145;  
      Xpos = Xpos + sizeX + xSpacing; 
    
     setColorAll = gui.addBang("setColorAll").setCaptionLabel("Auto Colors").setPosition(Xpos, Ypos).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
         gui.getController("setColorAll").getCaptionLabel().align(CENTER,CENTER);  ///  sliderSpeed.hide(); //.align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE);

      Xpos = Xpos + sizeX + xSpacing; 
      
     toggleBackground= gui.addToggle("toggleBackground").setCaptionLabel("Bkgnd    None").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
      gui.getController("toggleBackground").getCaptionLabel().align(CENTER,CENTER);
      
      localXpos = localXpos + sizeX + localSpacing;
      
      Xpos = Xpos + sizeX + xSpacing; 
      
    toggleSpeckle = gui.addToggle("toggleSpeckle").setCaptionLabel("Clean   All Dots").setPosition(Xpos, Ypos).setMode(ControlP5.SWITCH).setColorCaptionLabel(color(255)).setSize(sizeX,sizeY).setFont(font);
      gui.getController("toggleSpeckle").getCaptionLabel().align(CENTER,CENTER);
    
       
     sliderOverlap = gui.addSlider("sliderOverlap").setSize(sizeX, sizeY).setCaptionLabel("    % Line Overlap").setPosition(Xpos, Ypos).setRange(0, 90).setValue(50).setFont(font).hide();//.setLock(true);//.hide();
      gui.getController("sliderOverlap").getCaptionLabel().align(CENTER,CENTER); 
  
      Xpos = Xpos + sizeX + xSpacing; 
  
  popMatrix(); 
  
  showHideButtons(false);  //println("fileLoaded " + fileLoaded);
    
  bSliderLock = false;
  
   inverted = toggleInverted.getBooleanValue();
          filterBlur= toggleBlur.getBooleanValue();
          filterBackground = toggleBackground.getBooleanValue();
          filterTrace = toggleTrace.getBooleanValue();;//
          filterSharpen = toggleSharpen.getBooleanValue();;//
          filterErode=  toggleErode.getBooleanValue();;//
          filterDilate = toggleDilate.getBooleanValue();;//
          filterSpeckle = toggleSpeckle.getBooleanValue();
          bDither = toggleDither.getBooleanValue();
          
          iPoster= int(sliderPoster.getValue());  //iPoster
          //brightness= int(sliderBrightness.getValue());
         // contrast= int(sliderContrast.getValue());
          iColorLimit = int( sliderColors.getValue()); //iColorLimit
          thresholdLow = int( sliderThresholdLow.getValue());
          thresholdHigh = int( sliderThresholdHigh.getValue());
}

void showHideButtons(boolean bHideAll){
   if (fileLoaded){ //show all
      buttonSizeDown.show();buttonSizeUp.show();   buttonToolDown.show();  buttonToolUp.show(); toggleInverted.show(); toggleBlur.show(); sliderPoster.show(); // sliderBrightness.show();sliderContrast.show(); 
     
      if (iColorLimit ==2){ 
        toggleDither.show();
        toggleBackground.hide(); filterBackground = false; setColorAll.hide();
        toggleSpeckle.hide();
      }else{ 
        // toggleDither.hide();
         toggleBackground.show(); setColorAll.show();
         toggleSpeckle.show();
      }
     sliderOverlap.hide();
      sliderThresholdLow.show(); sliderThresholdHigh.show();
      toggleDilate.show(); toggleErode.show();  sliderColors.show();   setColor1.show();  setColor2.show(); setColor3.show(); setColor4.show(); setColor5.show(); setColor6.show();
      
     setColor7.show(); setColor8.show(); setColor9.show(); setColor10.show(); setColor11.show(); setColor12.show(); buttonSave.show();   
     toggleTrace.show();toggleSharpen.show();
   }else{//hide all
     sliderOverlap.hide();
     buttonSizeDown.hide();
     buttonSizeUp.hide();  
     sliderThresholdLow.hide(); sliderThresholdHigh.hide();
     buttonToolDown.hide();  buttonToolUp.hide(); toggleInverted.hide(); 
     toggleBlur.hide();
     sliderPoster.hide(); // sliderBrightness.hide();sliderContrast.hide();
     toggleTrace.hide();toggleSharpen.hide();
     toggleDilate.hide(); toggleErode.hide();  sliderColors.hide();   setColor1.hide();  setColor2.hide(); setColor3.hide(); setColor4.hide(); setColor5.hide(); setColor6.hide(); setColorAll.hide();  toggleBackground.hide();toggleSpeckle.hide(); toggleDither.hide();
     setColor7.hide(); 
     setColor8.hide(); setColor9.hide();
     setColor10.hide();
     setColor11.hide();
     setColor12.hide();
     buttonSave.hide();
   }
   if(bHideAll){
      buttonProgConvert.hide();
      buttonProgCreate.hide();
      buttonProgRun.hide();
  
      buttonHelp.hide();  buttonSupport.hide();
      buttonExit.hide();
      buttonLoad.hide();
      buttonSave.hide();

     sliderOverlap.hide();
     buttonSizeDown.hide();
     buttonSizeUp.hide();  
     sliderThresholdLow.hide(); sliderThresholdHigh.hide();
     buttonToolDown.hide();  buttonToolUp.hide(); toggleInverted.hide(); 
     toggleBlur.hide();
     sliderPoster.hide(); // sliderBrightness.hide();sliderContrast.hide();
     toggleTrace.hide();toggleSharpen.hide();
     toggleDilate.hide(); toggleErode.hide();  sliderColors.hide();   setColor1.hide();  setColor2.hide(); setColor3.hide(); setColor4.hide(); setColor5.hide(); setColor6.hide(); setColorAll.hide();  toggleBackground.hide();toggleSpeckle.hide();  toggleDither.hide();
     setColor7.hide(); 
     setColor8.hide(); setColor9.hide();
     setColor10.hide();
     setColor11.hide();
     setColor12.hide();
     buttonSave.hide();
   }else{
      buttonProgConvert.show();
      buttonProgCreate.show();
      buttonProgRun.show();
  
      buttonHelp.show();buttonSupport.show();
      buttonExit.show();
      buttonLoad.show();
      buttonSave.show();
  }
   
}


void setColor1(){
  color rrr = colorPicker(colorArray[1]);
  gui.getController("setColor1").setColorBackground(rrr);
  colorArray[1]=rrr; //dont have to worrk about null
}
void setColor2(){ 
  color rrr = colorPicker(colorArray[2]);
  gui.getController("setColor2").setColorBackground(rrr);
  colorArray[2]=rrr; 
}
void setColor3(){
  color rrr = colorPicker(colorArray[3]);
  gui.getController("setColor3").setColorBackground(rrr);
  colorArray[3]=rrr;
}
void setColor4(){
  color rrr = colorPicker(colorArray[4]);
  gui.getController("setColor4").setColorBackground(rrr);
  colorArray[4]=rrr; 
}
void setColor5(){
  color rrr = colorPicker(colorArray[5]);
  gui.getController("setColor5").setColorBackground(rrr);
  colorArray[5]=rrr; 
}
void setColor6(){
  color rrr = colorPicker(colorArray[6]);
  gui.getController("setColor6").setColorBackground(rrr);
  colorArray[6]=rrr; 
}
void setColor7(){
  color rrr = colorPicker(colorArray[7]);
  gui.getController("setColor7").setColorBackground(rrr);
  colorArray[7]=rrr; 
}
void setColor8(){
  color rrr = colorPicker(colorArray[8]);
  gui.getController("setColor8").setColorBackground(rrr);
  colorArray[8]=rrr; 
}
void setColor9(){
  color rrr = colorPicker(colorArray[9]);
  gui.getController("setColor9").setColorBackground(rrr);
  colorArray[9]=rrr;
}
void setColor10(){
  color rrr = colorPicker(colorArray[10]);
  gui.getController("setColor10").setColorBackground(rrr);
  colorArray[10]=rrr;
}
void setColor11(){
  color rrr = colorPicker(colorArray[11]);
  gui.getController("setColor11").setColorBackground(rrr);
  colorArray[11]=rrr; 
}
void setColor12(){
  color rrr = colorPicker(colorArray[12]);
  gui.getController("setColor12").setColorBackground(rrr);
  colorArray[12]=rrr; 
}

void setColorAll(){
 // showHideButtons(true);
  bSetAllColors = !bSetAllColors;
  
  imageLoaded = false;   reloadImage(filePath);
} 

color colorPicker(color input){
  //         javaColor.setVisible(true);
   //     javaColor.toFront();
  JFrame frame111 = new JFrame("Color Picker"); 
  frame111.setVisible(true);
  frame111.toFront(); 
  //frame111.setAlwaysOnTop(true);
  frame111.setLocation(xWindow/2,yWindow/2);
  javaColor  = JColorChooser.showDialog(frame111,"Java Color Chooser",Color.white);
  frame111.setVisible(false); 
  frame111.toBack();
  frame111.dispose();
   //javaColor.setAlwaysOnTop(true);
   if(javaColor!=null){
        cPicked = color(javaColor.getRed(),javaColor.getGreen(),javaColor.getBlue());
        return cPicked;
   } else {return color(input);} 
}


void checkLicense(String inputEmail,String inputKey) {
  boolean bRenewFree = true;
  File file = new File(sketchPath("system/License.txt"));
  if (file.exists()) {
    try {
      String[] lines = loadStrings("system/License.txt");
      if (lines != null) { 
        bTerms = true;//a free OR paid license has been found so eula is confirmed 
        bPaid = bTerms;
        int cheat1= inputKey.indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found (This is my overriding everything key, dont use this for customers)
        int cheat2= lines[0].indexOf("XCg8_XA@RA=yyN4cW4FD"); //result is -1 if not found (This is my overriding everything key, dont use this for customers)
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
        
        if (cheat1 != -1 || cheat2  !=-1 ){
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
          println("Valid License Key Entered! Thanks for supporting us!");
        }
      } else { //contents blank for some reason
        bRenewFree = true;  
        println("No license found, creating a free one.");
      }
    }
    catch(NumberFormatException ne) { 
      println("No license found, creating a free one.");
    }
  } else { 
    bRenewFree = true;
    println("No license found, creating a free one.");
  }

  if (bRenewFree) {
    sKey = "Free Key"; //this overwrights any incorrect bullshit anyone types in.
    sEmail = "CylinDraw@gmail.com";
    println ("~Free license found. We hope you enjoy the free version of our product!~");
    println ("~To enable speed control, please enter a valid key in the help menu.~");
  }

  if (!bTerms) {
    String termsPath = sketchPath(); 
    termsPath = termsPath + "/system/CYLINDRAW_TERMS_OF_USE.pdf"; 
    launch(termsPath); 

    String title ="TERMS OF USE PROMPT";
    Object[] message6 = {
      "Please see the CYLINDRAW_TERMS_OF_USE.pdf that was provided to you along with the CylinDraw Control package. ", 
      "Clicking OK confirms that you have read and agree to the end user license agreement. ", 
      //"(File saving will be disabled until this is complete.)", 
      "You may also find the latest copy available on www.CylinDraw.com", 
    };

    JFrame frame73 = new JFrame(title);  //Only need to call this if there is more than one frame i think
    frame73.setVisible(true);
    frame73.toFront();
    int option = JOptionPane.showConfirmDialog(null, message6, title, JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
    if (option == JOptionPane.OK_OPTION) { 
      bTerms = true;
      bPaid = bTerms;
    } //this is the only way for this to be set to true for the first time
    if (option == JOptionPane.CANCEL_OPTION) { 
      println(">User Clicked Cancel.<");
      bTerms = false;
      bPaid = bTerms;
    }     
    frame73.setVisible(false);
    frame73.toBack();
  }

  if (bTerms) {
    sKey = "XCg8_XA@RA=yyN4cW4FD"; //This line negates the entire point of licensing. It does make the first time user aggree to pdf but it only asks them on boot until they agree. 
    String storedLicense =sKey + "\n"+ sEmail +"\n"+
      "Use of this license constitutes explicit acceptance of the end user license agreement per CYLINDRAW_TERMS_OF_USE.pdf  \n  " ; // \nPlease DO NOT redistribute CylinDraw Control software or your license keys in any form. \nVisit www.CylinDraw.com to get the latest release. \n  " ;   
    String licenseName = ("system/License.txt");  
    String[] storedLicenseList = split(storedLicense, '\n');  //use the \n characters as delineiators to turn the horizontal array into a vertical array.
    saveStrings(licenseName, storedLicenseList);
  }
}
/*long currentTime(){
    return (System.currentTimeMillis());
}*/
