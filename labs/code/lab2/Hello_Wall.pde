 /**
 **********************************************************************************************************************
 * @file       Haptic_Physics_Template.pde
 * @author     Steve Ding, Colin Gallacher
 * @version    V3.0.0
 * @date       27-September-2018
 * @brief      Base project template for use with pantograph 2-DOF device and 2-D physics engine
 *             creates a blank world ready for creation
 **********************************************************************************************************************
 * @attention
 *
 *
 **********************************************************************************************************************
 */
 
 
 
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

FCircle ball;
FPoly part1;
FPoly part2;
FPoly part3;
FPoly part4;
FCircle info;
FCircle c1;
FCircle c2;
FBox    start;
FBox    end;
FCircle red1;
FCircle red2;
FCircle green1;
FCircle green2;
FCircle cyan1;
FCircle cyan2;
FCircle black1;
FCircle black2;
FCircle yellow1;
FCircle yellow2;
FPoly part5;
FPoly part6;
FPoly part7;

/* define game start */
boolean           gameStart                           = false;

int               scene                               = 0;

/* text font */
PFont             f;

/* end elements definition *********************************************************************************************/



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1000, 400);
  
  f                   = createFont("Arial", 16, true);
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
  
  //println(Serial.list());
  
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
  
  
  start                  =new FBox(5,1);
  start.setFill(0,255, 0);
  start.setSensor(true);
  start.setPosition(12.5, 7);
  start.setStaticBody(true);
  start.setNoStroke();
  world.add(start);
  
  info                  =new FCircle(1.5);
  info.setNoFill();//173, 216, 230);
  info.setSensor(true);
  info.setPosition(1, 9.5);
  info.setStaticBody(true);
  info.setNoStroke();
  world.add(info);
  
  ball                   = new FCircle(1.0);
  ball.setPosition(2, 4);
  ball.setNoFill();
  ball.setDensity(18);
  ball.setNoStroke();
  world.add(ball);
  
  
  
  c1                  = new FCircle(1.5); // diameter is 2
  c1.setPosition(edgeTopLeftX+1, edgeTopLeftY+worldHeight/2.0-4);
  c1.setNoFill();//0, 255, 0);
  c1.setNoStroke();
  c1.setStaticBody(true);
  c1.setSensor(true);
  world.add(c1);
  
  /* Finish Button */
  c2                  = new FCircle(1.5);
  c2.setPosition(worldWidth-1, edgeTopLeftY+worldHeight/2.0-4);
  c2.setNoFill();//200,0,0);
  c2.setNoStroke();
  c2.setStaticBody(true);
  c2.setSensor(true);
  world.add(c2);
  
  part1              =new FPoly();
  part1.vertex(4,8);
  part1.vertex(4,2);
  part1.vertex(10,2);
  part1.vertex(10,2.5);
  part1.vertex(4.5, 2.5);
  part1.vertex(4.5, 5.5);
  part1.vertex(6, 5.5);
  part1.vertex(6, 4);
  part1.vertex(6.5, 4);
  part1.vertex(6.5, 6);
  part1.vertex(4.5, 6);
  part1.vertex(4.5, 8);  
  part1.setNoFill();
  part1.setSensor(true);
  part1.setNoStroke();
  part1.setStaticBody(true);
  world.add(part1);
  
  part2              =new FPoly();
  part2.vertex(6,10);
  part2.vertex(6,7.5);
  part2.vertex(8.5,7.5);
  part2.vertex(8.5,3.75);
  part2.vertex(10,3.75);
  part2.vertex(10,4.25);
  part2.vertex(9,4.25);
  part2.vertex(9,7.5);
  part2.vertex(12.5, 7.5);
  part2.vertex(12.5, 8);
  part2.vertex(6.5, 8);
  part2.vertex(6.5, 9.5);
  part2.vertex(18, 9.5);
  part2.vertex(18, 4);
  //part2.vertex(12, 4.5);
  //part2.vertex(12, 4);
  part2.vertex(18.5, 4);
  part2.vertex(18.5, 10);
  
  part2.setNoFill();
  part2.setNoStroke();
  part2.setSensor(true);
  part2.setStaticBody(true);
  world.add(part2);
  
  part3             =new FPoly();
  part3.vertex(11, 6);
  part3.vertex(11, 5.5);
  part3.vertex(13, 5.5);
  part3.vertex(13, 2);
  part3.vertex(15, 2);
  part3.vertex(15, 2.5);
  //part3.vertex(22, 10);
  //part3.vertex(21.5, 10);
  //part3.vertex(21.5, 2.5);
  part3.vertex(13.5, 2.5);
  part3.vertex(13.5, 5.5);
  part3.vertex(16, 5.5);
  part3.vertex(16, 6);
  part3.vertex(14.5, 6);
  part3.vertex(14.5, 7);
  part3.vertex(14, 7);
  part3.vertex(14, 6);
  part3.setNoFill();
  part3.setNoStroke();
  part3.setSensor(true);
  part3.setStaticBody(true);
  world.add(part3);
  
  part4             =new FPoly();
  part4.vertex(17, 2);
  part4.vertex(22, 2);
  part4.vertex(22, 10);
  part4.vertex(21.5, 10);
  part4.vertex(21.5, 2.5);
  part4.vertex(17, 2.5);
  part4.setNoFill();
  part4.setNoStroke();
  part4.setSensor(true);
  part4.setStaticBody(true);
  world.add(part4);
  
  end                 =new FBox(3,1);
  end.setNoFill();
  end.setSensor(true);
  end.setPosition(20, 9);
  end.setStaticBody(true);
  end.setNoStroke();
  world.add(end);
  
  red1                  = new FCircle(1); // diameter is 2
  red1.setPosition(2.75, 7);
  red1.setNoFill();//setFill(0, 255, 0);
  red1.setNoStroke();
  red1.setStaticBody(true);
  red1.setSensor(true);
  world.add(red1);
  
  red2                  = new FCircle(1); // diameter is 2
  red2.setPosition(10.75, 1.25);
  red2.setNoFill();//setFill(0, 255, 0);
  red2.setNoStroke();
  red2.setStaticBody(true);
  red2.setSensor(true);
  world.add(red2);
  
  green1                  = new FCircle(1); // diameter is 2
  green1.setPosition(9.25, 7);
  green1.setNoFill();//setFill(0, 255, 0);
  green1.setNoStroke();
  green1.setStaticBody(true);
  green1.setSensor(true);
  world.add(green1);
  
  green2                  = new FCircle(1); // diameter is 2
  green2.setPosition(19, 3);
  green2.setNoFill();//setFill(0, 255, 0);
  green2.setNoStroke();
  green2.setStaticBody(true);
  green2.setSensor(true);
  world.add(green2);
  
  cyan1                  = new FCircle(1); // diameter is 2
  cyan1.setPosition(14, 7);
  cyan1.setNoFill();//setFill(0, 255, 0);
  cyan1.setNoStroke();
  cyan1.setStaticBody(true);
  cyan1.setSensor(true);
  world.add(cyan1);
  
  cyan2                  = new FCircle(1); // diameter is 2
  cyan2.setPosition(9.5, 1.25);
  cyan2.setNoFill();
  cyan2.setNoStroke();
  cyan2.setStaticBody(true);
  cyan2.setSensor(true);
  world.add(cyan2);
  
  black1                  = new FCircle(1); // diameter is 2
  black1.setPosition(15, 9);
  black1.setNoFill();//0, 255, 0);
  black1.setNoStroke();
  black1.setStaticBody(true);
  black1.setSensor(true);
  world.add(black1);
  
  black2                  = new FCircle(1); // diameter is 2
  black2.setPosition(8, 1.25);
  black2.setNoFill();//0, 255, 0);
  black2.setNoStroke();
  black2.setStaticBody(true);
  black2.setSensor(true);
  world.add(black2);
  
  yellow1                  = new FCircle(1); // diameter is 2
  yellow1.setPosition(21, 7);
  yellow1.setNoFill();//setFill(0, 255, 0);
  yellow1.setNoStroke();
  yellow1.setStaticBody(true);
  yellow1.setSensor(true);
  world.add(yellow1);
  
  yellow2                  = new FCircle(1); // diameter is 2
  yellow2.setPosition(18, 5);
  yellow2.setNoFill();//setFill(0, 255, 0);
  yellow2.setNoStroke();
  yellow2.setStaticBody(true);
  yellow2.setSensor(true);
  world.add(yellow2);
  
  part5              =new FPoly();
  //part5.vertex(1,6);
  part5.vertex(2,8);
  part5.vertex(4,8);
  part5.vertex(4,6);
  part5.vertex(8,6);
  part5.vertex(8,8);
  part5.vertex(10,8);
  part5.vertex(10,7.5);
  part5.vertex(8.5,7.5);
  part5.vertex(8.5,5.5);
  part5.vertex(3.5,5.5);
  part5.vertex(3.5,7.5);
  part5.vertex(2, 7.5);
  part5.setNoFill();
  part5.setSensor(true);
  part5.setNoStroke();
  part5.setStaticBody(true);
  world.add(part5);
  
  part6            =new FPoly();
  part6.vertex(18,4);
  part6.vertex(20,4);
  part6.vertex(20,7.5);
  part6.vertex(22,7.5);
  part6.vertex(22,8);
  part6.vertex(19.5,8);
  part6.vertex(19.5,4.5);
  part6.vertex(18,4.5);
  part6.setNoFill();
  part6.setSensor(true);
  part6.setNoStroke();
  part6.setStaticBody(true);
  world.add(part6);
  
  part7              =new FPoly();
  part7.vertex(7,3);
  part7.vertex(12,3);
  part7.vertex(12,7.5);
  part7.vertex(15,7.5);
  part7.vertex(15,8);
  part7.vertex(11.5,8);
  part7.vertex(11.5,3.5);
  part7.vertex(7,3.5);
  
  part7.setNoFill();
  part7.setSensor(true);
  part7.setNoStroke();
  part7.setStaticBody(true);
  world.add(part7);
  
  /* Setup the Virtual Coupling Contact Rendering Technique */
  s                   = new HVirtualCoupling((0.25)); 
  s.h_avatar.setDensity(2); 
  s.h_avatar.setFill(255,0,0); 
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 
  
  /* World conditions setup */
  world.setGravity((0.0), (500.0)); //1000 cm/(s^2)
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



/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if(rendering_force == false){
  background(255);
  if (gameStart== false){
    background(173, 216, 230);
    textFont(f, 80);
    fill(0, 0, 100);
    textAlign(CENTER);
    text("Adventures of Ball-E!", width/2, 200);
    world.draw();
    textFont(f, 30);
    fill(0, 0, 0);
    textAlign(CENTER);
    text("Start", width/2, 290); 
  }
  
  if (gameStart){
    start.setNoFill();
    info.setFill(173, 216, 230);
    
    switch(scene){
      case 1:
        if (s.h_avatar.isTouchingBody(info)){
          textFont(f, 20);
          fill(0, 0, 0);
          textAlign(CENTER);
          text("Touch the GREEN button to remove gravity, and the RED button to restore it...", width/2, 55);
          text("Help Ball-E reach the red square to win this stage", width/2, 72);
          
        }
        c1.setFill(0, 255, 0);
        c2.setFill(255, 0, 0);
        ball.setFill(0,0, 255);
        part1.setFill(0, 0, 0);
        part1.setSensor(false);
        part2.setFill(0, 0, 0);
        part2.setSensor(false);
        part3.setFill(0, 0, 0);
        part3.setSensor(false);
        part4.setFill(0, 0, 0);
        part4.setSensor(false);
        end.setFill(255, 0, 0);
        
        if (s.h_avatar.isTouchingBody(c1)){
          textFont(f, 20);
          fill(0, 0, 0);
          textAlign(CENTER);
          text("Gravity deactivated", width/2, 60);
        }
        
        if (s.h_avatar.isTouchingBody(c2)){
          textFont(f, 20);
          fill(0, 0, 0);
          textAlign(CENTER);
          text("Gravity activated", width/2, 60);
        }
        
        break;
      case 2:
        
        c1.setNoFill();
        c2.setNoFill();
        part1.setNoFill();
        part1.setSensor(true);
        part2.setNoFill();
        part2.setSensor(true);
        part3.setNoFill();
        part3.setSensor(true);
        part4.setNoFill();
        part4.setSensor(true);
        
        //
      
        if (s.h_avatar.isTouchingBody(info)){
          textFont(f, 15);
          fill(0, 0, 0);
          textAlign(CENTER);
          text("The coloured circles allow you to teleport to a circle of the identical colour", width/2, 80);
          text("Help Ball-E reach the red square to win this stage", width/2, 95);
        }
        
        ball.setFill(0,0, 255);
        red1.setFill(255,0,0);
        red2.setFill(255,0,0);
        yellow1.setFill(255,255,0);
        yellow2.setFill(255,255,0);
        green1.setFill(0, 255,0);
        green2.setFill(0, 255,0);
        cyan1.setFill(0, 100, 100);
        cyan2.setFill(0, 100, 100);
        black1.setFill(0,0,0);
        black2.setFill(0,0,0);
        part5.setFill(0, 0, 0);
        part5.setSensor(false);
        part6.setFill(0, 0, 0);
        part6.setSensor(false);
        part7.setFill(0, 0, 0);
        part7.setSensor(false);
       
        break;
        
        case 3:
          background(173, 216, 230);
          textFont(f, 80);
          fill(0, 0, 100);
          textAlign(CENTER);
          text("That's it. You win!", width/2, 200);   
          
          ball.setNoFill();
          end.setNoFill();
          info.setNoFill();
        red1.setNoFill();
        red2.setNoFill();
        yellow1.setNoFill();
        yellow2.setNoFill();
        green1.setNoFill();
        green2.setNoFill();
        cyan1.setNoFill();
        cyan2.setNoFill();
        black1.setNoFill();
        black2.setNoFill();
        part5.setNoFill();
        part6.setNoFill();
        part7.setNoFill();
        
     }
      
    
    
    world.draw();
    
  
  }
}
}
/* end draw section ****************************************************************************************************/



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
      pos_ee.set(pos_ee.copy().mult(200));  
    }
    
    
    s.setToolPosition(edgeTopLeftX+worldWidth/2-(pos_ee).x+2, edgeTopLeftY+(pos_ee).y-7); 
    s.updateCouplingForce();
    f_ee.set(-s.getVCforceX(), s.getVCforceY());
    f_ee.div(20000); //
    
    torques.set(widgetOne.set_device_torques(f_ee.array()));
    widgetOne.device_write_torques();
    
    if (gameStart== false && s.h_avatar.isTouchingBody(start)){
      gameStart=true;
      scene=1;
      
    }
  
    if (gameStart){ 
      switch(scene){
        case 1:
          if (s.h_avatar.isTouchingBody(c1)){
            world.setGravity((0.0), (0.0));
          }
          
          if (s.h_avatar.isTouchingBody(c2)){
            world.setGravity((0.0), (500.0));
          }
          
          if (ball.isTouchingBody(end)){
            world.setGravity((0.0), (500.0));
            ball.setPosition(2, 8);
            end.setPosition(18, 7);
            scene=2;
            ball.setAngularDamping(10);

          }
          
          
          
          break;
        case 2:
        
          if (ball.isTouchingBody(red1)){
            ball.setPosition(10.75, 1.25);
          }
          
          /*if (ball.isTouchingBody(red2)){
            ball.setPosition(2, 8);
          }*/
          
          if (ball.isTouchingBody(green1)){
            ball.setPosition(19, 3);
            
          }
          
          /*if (ball.isTouchingBody(green2)){
            ball.setPosition(2, 8);
          }*/
          if (ball.isTouchingBody(cyan1)){
            ball.setPosition(9.5, 1.25);
          }
          /*
          if (ball.isTouchingBody(cyan2)){
            ball.setPosition(2, 8);
          }*/
          if (ball.isTouchingBody(black1)){
            ball.setPosition(8, 1.25);
            
          }
          /*
          if (ball.isTouchingBody(black2)){
            ball.setPosition(2, 8);
          }*/
          if (ball.isTouchingBody(yellow1)){
            ball.setPosition(18, 5);
          }
          /*
          if (ball.isTouchingBody(yellow2)){
            ball.setPosition(2, 8);
          }*/
          if (ball.isTouchingBody(end)){
            scene=3;
          }
          break;
      }
  }
    
    world.step(1.0f/1000.0f);
  
    rendering_force = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

/* end helper functions section ****************************************************************************************/
