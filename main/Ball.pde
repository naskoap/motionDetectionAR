/*
 * Dancing with the Stars
 *
 * CSci 276: Multimedia Programming
 * Final Project
 * 12/20/2016
 * Ryan Regal, Thomas Burless, Nasko Apostolov
 *
 */

/**************
 * Ball Class *
 **************/

class Ball{
  // define state: coordinates, velocity, etc.
  float x,y,vx,vy,mult,thresh;
  float g = 1.1, rad= 25;
  boolean touched=false;
  PImage blob;
  float rot = 0;

Ball(){ 
    init();
  }
  void init(){
    // velocity of the x-var
    vx = random(-1.1,1.1);
    // velocity in the y-var
    vy = random(1.5); 
    
    // initial starting points
    x = random(width);
    y = random(-10,0);
    
    mult = .9;
    
    thresh = 3.0;
    
    // load up our image
    blob = loadImage("star2.png");
    
  }
  void update(){
    
    // code for rotating each individual object
    // still a bit buggy, but every blob is now rotating
    pushMatrix();
    translate(x,y);
    rotate(rot);
    image(blob, 0-rad,0-rad, rad*2, rad*2);
    translate(-x,-y);
    popMatrix(); 
    rot += vx;
    
    x+=vx;
    y+=vy;
    
    // if either x or y exceed a certain velocity,
    // multiply it by a factor to slow it down
    if(abs(vx)>thresh)
      vx*=mult;
    if(abs(vy)>thresh)
      vy*=mult;

    // determines when it hits the edge
    if(x<-rad+15){
      x=-rad+15;
      vx = -vx;
    }
    if(x>width){
      x=width;
      vx = -vx;
    }
    if(y<-10){
      y=-10;
      vy = -vy;
    }
    if(y>height){
      y=height;
      vy = -vy;
    }


  }
  
  void stop() {
    vx = 0;
    vy = 0;
  }
  
  PImage getImg() {
    return blob;
  }
  
  void draw(){
     
  }
  
  void run(){
    update(); 
    draw(); 
  }
}
