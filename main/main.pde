/*
 * Dancing with the Stars
 *
 * CSci 276: Multimedia Programming
 * Final Project
 * 12/20/2016
 * Ryan Regal, Thomas Burless, Nasko Apostolov
  
 * Put the om to continuous difference and use that image
 * to calculate the blobs. blobs are detected for collision,
 * and if true, some nice ellastic collision is applied.
 
 */

import processing.opengl.*;
import processing.video.*;
import s373.flob.*;

// gif library. can be added by going to: 
// Sketch -> Add library -> gifAnimation and clicking "install"
import gifAnimation.*;

import oscP5.*;
import netP5.*;

// allows communication with Pd  
OscP5 oscP5= new OscP5(this,12000);
NetAddress myRemoteLocation= new NetAddress("127.0.0.1",8000);

Capture video;
Flob flob; 
PImage videoinput;
PFont bodoni;

// video resolution
int videores=128, x=10;

// if it is not working on personal computer, try 
// decrementing FPS to 30
int fps = 30;

PFont font = createFont("arial",10);

// set number of stars
Ball stars[] = new Ball[25];

boolean showcamera=true;
boolean om=true,omset=false;
float velmult = 10000.0f;
int vtex=0;
boolean gameOver = false;
long start, end, t;
String yourT;

// gif object from the imported gifAnimation library
// works similarly to PImage
Gif ninja;

// messages to be sent to Pd
OscMessage toggle = new OscMessage("/toggle");
OscMessage connect = new OscMessage("/connect");
OscMessage on = new OscMessage("/on");
OscMessage off = new OscMessage("/off");
OscMessage bbang = new OscMessage("/bbang");
OscMessage loop = new OscMessage("/loop");

void setup(){

  size(880,720,OPENGL);
  frameRate(fps);
  
  // set up ninja gif to play
  ninja = new Gif(this, "ninja.gif");
  ninja.play();

  video = new Capture(this, 320, 240, fps);
  video.start();
  // record when game starts
  start = System.currentTimeMillis();
  
  // send toggle message to Pd
  toggle.add(true);
  oscP5.send(toggle, myRemoteLocation);
  // message needs to be cleared once sent
  toggle.clear();
  
  on.add(true);
  oscP5.send(on, myRemoteLocation);
  on.clear();
  
  connect.add(true);
  oscP5.send(connect, myRemoteLocation);
  connect.clear();
  
  bodoni = createFont("BodoniMTCondensed-BoldItalic-36.vlw", 48);
  
  // create one image with the dimensions you want flob to run at
  videoinput = createImage(videores, videores, RGB);

  // construct flob
  flob = new Flob(this,videores,videores, width, height);
  
  flob.setMirror(true,false);
  flob.setThresh(10);
  flob.setFade(45);
  flob.setMinNumPixels(10);
  flob.setImage( vtex );

  for(int i=0;i<stars.length;i++){
    stars[i] = new Ball();
  }
}


void draw(){
  background(0);
  if(video.available()) {   
    if(!omset){
      if(om)
        flob.setOm(flob.CONTINUOUS_DIFFERENCE);
      else
        flob.setOm(flob.STATIC_DIFFERENCE);
      omset=true;
    }
    video.read();
    
    // downscale video image to videoinput pimage
    videoinput.copy(video,0,0,320,240,0,0,videores,videores);
     
    // here is what the calc, calcsimple, or tracksimple method is defined
    // tracksimple is more accurate but heavier than calcsimple

    flob.tracksimple(  flob.binarize(videoinput) ); 
  }

  image(flob.getSrcImage(), 0, 0, width, height);
  
  // add the gif over top of the flob
  image(ninja, (width/2)-(ninja.width/2), (height/2)-(ninja.height/2));

  int numtrackedblobs = flob.getNumTBlobs();

  // detecting collision code
  float cdata[] = new float[5];
  for(int i=0;i<stars.length;i++){
    float x = stars[i].x / (float) width;
    float y = stars[i].y / (float) height;
    cdata = flob.imageblobs.postcollidetrackedblobs(x,y,stars[i].rad/(float)width);
    // detect ninja's coords, game over if a star hits him
    if ((stars[i].x >= (width/2)-(ninja.width)/2 + 25 && stars[i].x <= (width/2)+(ninja.width/2)-25) && (stars[i].y >= (height/2)-(ninja.height/2) + 25 && stars[i].y <= (height/2)+(ninja.height/2) - 25)) {
      gameOver = true;
      // send it a toggle so it can reset pd
      toggle.setAddrPattern("/toggle");
      toggle.add(false);
      
      off.setAddrPattern("/off");
      off.add(true);
      
      // send message so metronome music starts
      oscP5.send(toggle, myRemoteLocation);
      toggle.clear();
      
      // mute music in pd
      oscP5.send(off, myRemoteLocation);
      off.clear(); 
      
      stroke(255, 0, 0);
      ellipse(stars[i].x, stars[i].y, 50, 50);
      for(int j = 0; j < stars.length; j++) {
        stars[j].stop();
      }
      video.stop();
      ninja.pause();
      end = System.currentTimeMillis(); 
    }
    if(cdata[0] > 0) {
      stars[i].touched=true;
      
      // update rotation when touched
      stars[i].rot = -stars[i].rot;
      
      stars[i].vx +=cdata[1]*width*0.015;
      stars[i].vy +=cdata[2]*height*0.015;
    } 
    else {
      stars[i].touched=false; 
    }
    stars[i].run();
  }

  if (gameOver) {
      noLoop();
      // calculate ellapsed time
      t = (end - start)/1000;
      yourT = "You lasted " + t + " seconds...";
      textFont(bodoni);
      fill(255, 0, 0);
      text("Game Over.", width/2-100, height/2);
      text(yourT, width/2-200,height/2+50);
      noFill();
    } 

} 

void keyPressed(){
  // restart game if the player has lost and the space key is hit
  if (key==' ' && gameOver) {
    bbang.setAddrPattern("/bbang");
    bbang.add(true);
    oscP5.send(bbang, myRemoteLocation);
    bbang.clear();
    
    toggle.setAddrPattern("/toggle");
    toggle.add(true);
    oscP5.send(toggle, myRemoteLocation);
    toggle.clear();
    
    on.setAddrPattern("/on");
    on.add(true);
    oscP5.send(on, myRemoteLocation);
    on.clear();
    
    gameOver = false;
    
    // restart timer
    start = System.currentTimeMillis();
    video.start();
    ninja.play();
    for (int i = 0; i < stars.length; i++) {
      stars[i].init();
    }
    loop();
  }
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  int msg = theOscMessage.get(0).intValue();
  if (abs(msg) > 725) {
    loop.setAddrPattern("/loop");
    loop.add(true);
    oscP5.send(loop, myRemoteLocation); 
    loop.clear();
  }
 // increase the speed the ball can go before it begins to slow
 for(int i=0;i<stars.length;i++){
   stars[i].thresh = (abs(msg)/100.0);
 }

}

  

