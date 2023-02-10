 /* library imports *****************************************************************************************************/ 
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
/* end library imports *************************************************************************************************/  


/* scheduler definition ************************************************************************************************/ 
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/ 


/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 3;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           rendering_force                     = false;
/* end device block definition *****************************************************************************************/

/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 120;

/* end framerate definition ********************************************************************************************/ 



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40.0;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           pos_ee                              = new PVector(0, 0);
PVector           f_ee                                = new PVector(0, 0); 

/* World boundaries */
FWorld            world;
float             worldWidth                          = 25.0;  
float             worldHeight                         = 10.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;


/* Initialization of virtual tool */
HVirtualCoupling  s;

/* Words bodies*/
FCircle w1;
FBox w2;
FBox w3;
FBox w4;
FBox w5;

/* General variables*/
PFont f;
int mode=1;
float x;
float y;

/*Mode 1 variables*/
boolean joint= false;
float dist;
ArrayList<FContact> contact;

/*Mode 2 variables*/
float lastChange = Float.NEGATIVE_INFINITY;

/*Mode 3 variables*/
float lastMove= Float.NEGATIVE_INFINITY;
int stepDuration=100; 
int index;
PVector[] locations = {new PVector(-0.015,0.06),new PVector(-0.011,0.05),new PVector(-0.0067,0.04),new PVector(-0.0034,0.035),new PVector(0.0,0.044),new PVector(0.007,0.06),
                        new PVector(0.0075,0.08),new PVector(0.005,0.055),new PVector(-0.002,0.042),new PVector(-0.01,0.041),new PVector(-0.014,0.055),new PVector(-0.015,0.06)};

/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1000, 400);
  
  
  /* device setup */
  
  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */
  haplyBoard          = new Board(this, "COM8", 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();

  
  widgetOne.set_mechanism(pantograph);
  
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1);
  
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
  widgetOne.device_set_parameters();
  
  
  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerCentimeter); 
  world               = new FWorld();
  
  f                   = createFont("Arial", 16, true);

  w1= new FCircle(2);
  w1.setPosition(12.5,5);
  w1.setNoFill();
  w1.setNoStroke();
  w1.setSensor(false);
  w1.setStatic(true);
  world.add(w1);
  
  
  w2= new FBox(0.5, 10);
  w3= new FBox(0.5, 10);
  w4= new FBox(25, 0.5);
  w5= new FBox(25, 0.5);
  
  FBody[] bodies={w2, w3, w4, w5};
  for (FBody b : bodies)
  {
    b.setNoFill();
    b.setNoStroke();
    b.setSensor(false);
    b.setStatic(true);
  }
  
  
  
  /* Setup the Virtual Coupling Contact Rendering Technique */
  s                   = new HVirtualCoupling((1)); 
  s.h_avatar.setDensity(2); 
  s.h_avatar.setNoFill(); 
  s.h_avatar.setNoStroke();
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
  
  /* World conditions setup */
  world.setGravity((0.0), (0.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0.5);
  
  world.draw();
  
  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/





/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  background(0);
  textFont(f, 80);
  fill(0, 0, 100);
  textAlign(CENTER);
  text("Mode: "+Integer.toString(mode), width/2, height/2); 
  
  world.draw(); 
}
/* end draw section ****************************************************************************************************/

void keyPressed(){
  if (key=='1'){
    mode=1;
    //print("1");
    world.add(w1);
  }
  if (key=='2'){
    mode=2;
    //print("2");
    world.remove(w1);
    w2.setPosition(2,5);
    w3.setPosition(23,5);
    w4.setPosition(12.5,0);
    w5.setPosition(12.5,10);
    world.add(w2);
    world.add(w3);
    world.add(w4);
    world.add(w5);
  }
  if (key=='3'){
    mode=3;
    //print("3");
  }
  
}


/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{
  
  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    rendering_force = true;
    
    if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();
    
      angles.set(widgetOne.get_device_angles()); 
      pos_ee.set(widgetOne.get_device_position(angles.array()));
      if (mode==3)
          pos_ee.set(device_to_graphics(pos_ee)); 
      else
        {
          pos_ee.set(pos_ee.copy().mult(200));
          s.setToolPosition(edgeTopLeftX+worldWidth/2-(pos_ee).x+2, edgeTopLeftY+(pos_ee).y-7); 
          s.updateCouplingForce();
          f_ee.set(-s.getVCforceX(), s.getVCforceY());
          f_ee.div(20000); 
        }
    }
    
    torques.set(widgetOne.set_device_torques(f_ee.array()));
    widgetOne.device_write_torques();
    
    if (mode==1){
      w2.removeFromWorld();
      w3.removeFromWorld();
      w4.removeFromWorld();
      w5.removeFromWorld();
      if (s.h_avatar.isTouchingBody(w1)){
        contact= w1.getContacts();
        x=contact.get(0).getX();
        y=contact.get(0).getY();
        s.h_avatar.setDamping(1100);     
        joint = true;
        
      }
      if (joint)
      {
        dist=Math.abs(x-s.h_avatar.getX())+Math.abs(y-s.h_avatar.getY());
        if ((1000-250*dist)>0)
        {
          s.h_avatar.setDamping(1000-250*dist);
        }
        else 
        {
          s.h_avatar.setDamping(0.0);
          joint=false;
        }
      }
    }
    if (mode==2){
      //removing other world conditions
      joint=false;
      w1.removeFromWorld();
      s.h_avatar.setDamping(0.0);
        
      if (millis() - lastChange > 2000)
        {    
          x=s.h_avatar.getX();
          y=s.h_avatar.getY();
          
          if (w3.getX()-w2.getX()>3)
          {
            w2.adjustPosition((x-w2.getX())/2, 0);
            w3.adjustPosition((x-w3.getX())/2, 0);
            lastChange = millis();
          }
          if (w5.getY()-w4.getY()>1.5)
          {
            w5.adjustPosition(0,(y-w5.getY())/2);
            w4.adjustPosition(0,(y-w4.getY())/2);
            lastChange = millis();
          }
        }
     if (millis() - lastChange > 5000)
          {
            w2.setPosition(2,5);
            w3.setPosition(23,5);
            w4.setPosition(12.5,0);
            w5.setPosition(12.5,10);
            lastChange=millis();
          }
        
    }
    if (mode==3){
      w1.removeFromWorld();
      w2.removeFromWorld();
      w3.removeFromWorld();
      w4.removeFromWorld();
      w5.removeFromWorld();
      
      PVector force = new PVector(0, 0);

        if (millis() - lastMove > stepDuration) 
        {
          
          index++;
          if (index == locations.length)
            index = 0;
          
          lastMove = millis();
        }

          PVector xDiff = (pos_ee.copy()).sub(locations[index]);
          force.set(xDiff.mult(-400)); 
          f_ee.set(graphics_to_device(force)); 
       
    }
    
  
  
    world.step(1.0f/1000.0f);
  
    rendering_force = false;
  }
}
/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/
PVector device_to_graphics(PVector deviceFrame){
  return deviceFrame.set(-deviceFrame.x, deviceFrame.y);
}

PVector graphics_to_device(PVector graphicsFrame){
  return graphicsFrame.set(-graphicsFrame.x, graphicsFrame.y);
}
/* end helper functions section ****************************************************************************************/
