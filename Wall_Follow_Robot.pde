//  Final Robot Code
//  Oh, Look! A Code that goes through a maze!
//
//  Authors: Daniel Roberts and Josiah Sweeney
// 
//  Usage:
//    This program uses sensors on the the Puma
//    to "navigate" an unknown course.

//Sensor position defines for the Puma
#define FRONT_LEFT 3
#define FRONT_CENTER 2
#define FRONT_RIGHT 1
#define BACK_LEFT 5
#define BACK_CENTER 6
#define BACK_RIGHT 7
#define SIDE_LEFT 4
#define SIDE_RIGHT 0


#define BITVAL(A) 1<<(A)


//Modify these values to adjust how far away from the Wall the Puma wants to be
#define SENSOR_TARGET 0x60 // decimal 48
#define SENSOR_MARGIN 0x10 // decimal 16

//Pin defines for Digital Writes
#define GREEN_LED 11
#define YELLOW_LED 12

//Chirps Core library, required for any Chirps project
#include "Chirps_Core.h"

//Board Library
#include "Chirps_Roadrunner.h"              
#include "Chirps_Owl.h"

//Board Declarations
Roadrunner MyRR(0b0000);
Owl MyOwl(0x0);

//State Enumerations
enum states {
             STATE_FOLLOW_RIGHT,
             STATE_FOLLOW_LEFT,
             STATE_STRAIGHT,
             STATE_STOP,
             STATE_CLEARWALL_LEFT,
             STATE_CLEARWALL_RIGHT,
             STATE_PIVOT_LEFT,
             STATE_PIVOT_RIGHT,
             STATE_CORNERED,
             STATE_WALL_TURN,
             STATE_PIVOT_LEFT2,
             STATE_PIVOT_RIGHT2,
             STATE_VEER_BEGIN,
             STATE_WALL_TURN2,
            };


//Global Variables
uint8_t sensors;
uint8_t current_state,next_state,prev_state;
uint16_t sensor_data;
//Counting variables for direction, xy coordinates, and turning lengths
//pivot counter
int count=0;
//Clear wall counter
int count1=0;
//Counter that makes sure the robot doesn't pivot twice in a row
int count3=0;
//The counter that checks if the robot has traveled over 12 feet
int count6=0;
//The lights
int light=0;
int light1=0;
//left/right variable
int x=0;
//forward/back variable
int y=0;
//direction is straight
int dir=2;
//Tells the robot which way to turn in wallturn
int stateturn=0;


void setup()                    // run once, when the sketch starts
{ 
    Serial.begin(57600);
  
    Chirps.begin(RAVEN);
  
    //Startup printout to alert us that everything is initialized and what to do
    Serial.println("Josiah and Daniel's Robot ;)");
    Serial.println("Type 'start' for a fun time");
    Serial.println("Type 'stop' if it's not fun anymore"); 
  
    //Initialization commands for the Owl 
    MyOwl.setSensitivity(100);
    MyOwl.setThreshold(50);
    MyOwl.setUpdateMode(50,1,((BITVAL(SIDE_LEFT)) | (BITVAL(SIDE_RIGHT))));
   
    //LEDs on top of robot to indicate state
    pinMode(GREEN_LED, OUTPUT);
    pinMode(YELLOW_LED, OUTPUT);
    digitalWrite(GREEN_LED, LOW);
    digitalWrite(YELLOW_LED, LOW);
   
    //Initialize variable to enter switch case
    next_state = STATE_VEER_BEGIN;
   
}

void loop()                     // run over and over again
{ 
  //the following line loops for as long as run_enable is 0. Use this to prevent code from running after a 'stop' is sent.
   do {
     Chirps.serialListen();
   } while(!Chirps.checkRunEnable());
  prev_state = current_state;
  current_state = next_state;
 
  sensors = MyOwl.getSensors() & 0x1f;      //Read sensors
  //Switch case that has all of the different robot states
  switch(current_state){
    //The state that the robot will be in when no sensor get hits
     case STATE_STRAIGHT:
     //If the direction of the bot was left, and it went too far left, it will pivot right to get to the goal
        if(dir==1&&x<=-1){
          next_state = STATE_PIVOT_RIGHT;
          stateturn=0;
        }
        //If the direction of the bot was right, and it went too far right, it will pivot left to get to the goal
        else if(dir==3&&x>=104){
          stateturn=1;
          next_state = STATE_PIVOT_LEFT;
        }
       //Both lights on
        digitalWrite(GREEN_LED, HIGH);
        digitalWrite(YELLOW_LED, HIGH);
        //If only left side gets hit, go to follow left state
        if(sensors == BITVAL(SIDE_LEFT)){
           next_state = STATE_FOLLOW_LEFT;
        }
        //If only right side sensor gets hit, go to follow right state
        else if(sensors == BITVAL(SIDE_RIGHT)){
           next_state = STATE_FOLLOW_RIGHT;
        }
        //If EVERY SINGLE SENSOR gets a hit, go to state stop
        else if(sensors){
           next_state = STATE_STOP;
        }
        //Otherwise, go straight
        go_straight(); 
        //Print the state
        Serial.println("STRAIGHT");
        break;
        //This is the default state that switches to other states. It is basically a "relay" state.  
     case STATE_STOP:
     //pivot count goes to 0
        count=0;
        //Both lights off
        digitalWrite(GREEN_LED, LOW);
        digitalWrite(YELLOW_LED, LOW);
        //If only left side gets hit, go to follow left state
        if(sensors == (BITVAL(SIDE_LEFT))){
           next_state = STATE_FOLLOW_LEFT;
        }
        //If only right side sensor gets hit, go to follow right state
        else if(sensors == BITVAL(SIDE_RIGHT)){
           next_state = STATE_FOLLOW_RIGHT;
        }
        //If only the right and left side get hits, go to state cornered. This will will never happen 
        else if(MyOwl.getSensor(SIDE_LEFT)&&MyOwl.getSensor(SIDE_RIGHT)){ 
          next_state = STATE_CORNERED;
        }
        //If any of the front sensors get a hit
        if(((MyOwl.getSensor(FRONT_LEFT))&&(MyOwl.getSensor(FRONT_CENTER))&&(MyOwl.getSensor(FRONT_RIGHT)))||((MyOwl.getSensor(FRONT_LEFT))&&(MyOwl.getSensor(FRONT_CENTER)))||((MyOwl.getSensor(FRONT_CENTER))&&(MyOwl.getSensor(FRONT_RIGHT)))||(MyOwl.getSensor(FRONT_LEFT))||(MyOwl.getSensor(FRONT_RIGHT))){
         //If the robot goes over 7 feet, stateturn switches and the state goes to wallturn 
          if(count6>=48){
            stateturn=1-stateturn;
            next_state = STATE_WALL_TURN;
          }
          next_state = STATE_WALL_TURN;
        }
        //If no sensor gets a hit, go to state straight
        else if(!sensors){
           next_state = STATE_STRAIGHT;
        }
        //Print the state
        Serial.println("STOP");
        stop();
        break;
        //Following the left wall
     case STATE_FOLLOW_LEFT: 
     //Green light off, yellow light on
        digitalWrite(GREEN_LED, LOW);
        digitalWrite(YELLOW_LED, HIGH);
        sensor_data = MyOwl.getSensorValue(SIDE_LEFT);
        //Pivot counter to 0
        count=0;
        //If the x direction is negative, switch stateturn and turn around
        if(x<=-1){
          stateturn=1-stateturn;
          next_state = STATE_PIVOT_LEFT2;
        }
        //If the x direction is too high, switch stateturn and turn around
        else if(x>=104){
          stateturn=1-stateturn;
          next_state = STATE_PIVOT_RIGHT2;
        }
        else if(!sensors){
          //If all of the sudden, no sensors get a hit, go to clear wall state
           next_state = STATE_CLEARWALL_LEFT;
        }
        //If the robot gets too far away from the wall, get closer to the wall
        else if(sensor_data < (SENSOR_TARGET - SENSOR_MARGIN)){
           veer_left();
        }
        //If the bot is too close, get farther away
        else if(sensor_data > (SENSOR_TARGET + SENSOR_MARGIN)){
           veer_right();
        }
        //If the robot approaches a corner, it will turn right
        else if(MyOwl.getSensor(FRONT_CENTER)){ 
          next_state = STATE_PIVOT_RIGHT;
        }
        //If any other sensors get hits, go to state stop
        else if (sensors != (BITVAL(SIDE_LEFT))){
           count=0;
           next_state = STATE_STOP;
        }
        else{
          //Otherwise, go straight
           go_straight();
           //If the robot is going either right or left, count6 increases
           if(dir==1||dir==3){
             count6=count6+1;
           }
        } 
        //Print the state
        Serial.println("FOLLOW LEFT");
        break;
        
     case STATE_FOLLOW_RIGHT:
        count=0;
        //green light on yellow light off
        digitalWrite(GREEN_LED, HIGH);
        digitalWrite(YELLOW_LED, LOW);
        sensor_data = MyOwl.getSensorValue(SIDE_RIGHT);
        //If the x direction is negative, switch stateturn and turn around
        if(x<=-1){
          stateturn=1-stateturn;
          next_state = STATE_PIVOT_LEFT2;
        }
        else if(x>=104){
        //If the x direction is too high, switch stateturn and turn around
          stateturn=1-stateturn;
          next_state = STATE_PIVOT_RIGHT2;
        }
        else if(!sensors){
          //If all of the sudden, no sensors get a hit, go to clear wall right state
           next_state = STATE_CLEARWALL_RIGHT;
        }
        //If the robot gets too far away from the wall, get closer to the wall
        else if(sensor_data < (SENSOR_TARGET - SENSOR_MARGIN)){
           veer_right();
        }
        //If the bot is too close, get farther away
        else if(sensor_data > (SENSOR_TARGET + SENSOR_MARGIN)){
           veer_left();
        }
        //If the robot approaches a corner, it will turn left
        else if(MyOwl.getSensor(FRONT_CENTER)){ 
          count=0;
          next_state = STATE_PIVOT_LEFT;
        }
        //If any other sensors get hits, go to state stop
        else if(sensors != (BITVAL(SIDE_RIGHT))){
          count=0; 
          next_state = STATE_STOP;
        }
        else{
          //otherwise go straight
           go_straight();
           //If the robot is going either right or left, count6 increases
           if(dir==1||dir==3){
             count6=count6+1;
           }
        }
        //print state
        Serial.println("FOLLOW RIGHT");
        break; 
       
     case STATE_CLEARWALL_LEFT: //This state goes forward a clearing distance after nothing is found on the leftside sensor
	digitalWrite(GREEN_LED,LOW);
	digitalWrite(YELLOW_LED,HIGH);
        if(dir==2){ //If the robot is already going forward, it will continue going forward
          next_state = STATE_STRAIGHT;
        }
        else if(x<=-1){ //If the robot goes off the course to the left it will go into state pivot left 2 in order to turn around
          next_state = STATE_PIVOT_LEFT2;
        }
        else if(x>=104){ //If the robot goes off the course to the left it will go into state pivot right 2 in order to turn around
          next_state = STATE_PIVOT_RIGHT2;
        }
        else if(count3==1){ //If the robot has just previously done a clearwall, it will exit clearwall
                next_state = STATE_STOP;
        }
        else if(sensors){ //If all the sensors are hit, the robot goes into state straight
		next_state = STATE_STRAIGHT;
	}
        else{
                count1=count1+1; //This counts the clearing of the wall
                if(count1 > 8) next_state = STATE_PIVOT_LEFT;	//Once the wall is cleared the robot goes into pivot right
	}
        count=0;//Once the wall is cleared the robot goes into pivot right
        go_straight();
        Serial.println("CLEARWALL LEFT");//This prints the state
	break;

     case STATE_CLEARWALL_RIGHT: //This state goes forward a clearing distance after nothing is found on the rightside sensor
	digitalWrite(GREEN_LED,HIGH);
	digitalWrite(YELLOW_LED,LOW);
        if(dir==2){ //If the robot is already going forward, it will continue going forward
          next_state = STATE_STRAIGHT;
        }
        else if(x<=-1){ //If the robot goes off the course to the left it will go into state pivot left 2 in order to turn around
          next_state = STATE_PIVOT_LEFT2;
        }
        else if(x>=104){ //If the robot goes off the course to the left it will go into state pivot right 2 in order to turn around
          next_state = STATE_PIVOT_RIGHT2;
        }
        else if(count3==1){ //If the robot has just previously done a clearwall, it will exit clearwall
                next_state = STATE_STOP;
        }
        else if(sensors){ //If all the sensors are hit, the robot goes into state straight
		next_state = STATE_STRAIGHT;
        }
        else{
                count1=count1+1; //This counts the clearing of the wall
                if(count1 > 8) next_state = STATE_PIVOT_RIGHT;	//Once the wall is cleared the robot goes into pivot right
	}
        count=0; //This resets the pivot count
        go_straight();
        Serial.println("CLEARWALL");//This prints the state
	break;

     case STATE_PIVOT_LEFT: // This state pivots the robot 90 degrees to the left
	digitalWrite(GREEN_LED,LOW);
	digitalWrite(YELLOW_LED,HIGH);
        count1=0; //The counter for clearwall is reset here
        count=count+1; //The counter to turn 90 degrees is counted here
          if(dir==1){ //If the robot is going left initially, the robot will completely turn around.
            next_state = STATE_PIVOT_LEFT2;
          }
          if(count > 7){ //When the robot is done turning, it goes into state stop
            next_state = STATE_STOP;
            dir=dir-1; //Each time the robot turns the direction changes
            if(prev_state==6){ // This makes sure the robot does not get stuck around an island
              count3=1;
            }		
	  }
        pivot_left();
        Serial.println("PIVOT LEFT");
	break;

     case STATE_PIVOT_RIGHT: // This state pivots the robot 90 degrees to the right
	digitalWrite(GREEN_LED,HIGH);
	digitalWrite(YELLOW_LED,LOW);
        count1=0; //The counter for clearwall is reset here
        count=count+1; //The counter to turn 90 degrees is counted here
        if(dir==3){ //If the robot is going right initially, the robot will completely turn around.
          next_state = STATE_PIVOT_LEFT2;
        }
        else if(count > 7){ //When the robot is done turning, it goes into state stop
            next_state = STATE_STOP;
            dir=dir+1; //Each time the robot turns the direction changes
            if(prev_state==5){ // This makes sure the robot does not get stuck around an island
            count3=1;
            }		
	}
        pivot_right();
        Serial.println("PIVOT RIGHT"); //This prints the state that it is in
	break;
    case STATE_CORNERED: //This state backs out of a parking space if found in the maze
        digitalWrite(GREEN_LED,light);
        digitalWrite(YELLOW_LED,light1);
        if(!MyOwl.getSensor(SIDE_RIGHT)){ //If when backing out the sensors read clear on the right, the robot will back out and turn to the right
          next_state = STATE_PIVOT_RIGHT;
        }
        else if(!MyOwl.getSensor(SIDE_LEFT)){ //If when backing out the sensors read clear on the left, the robot will back out and turn to the left
          next_state = STATE_PIVOT_LEFT;
        }
        else if(!sensors){ //If no sensors are sensed, the robot will go into state stop
          next_state = STATE_STOP;
        }
        light=1-light;
        light1=1-light1;
        Serial.println("CORNERED"); //Printing the state
        straight_back();
      break;
    case STATE_WALL_TURN: // This state turns a certain direction when it hits a wall
        Serial.println("WALL TURN"); // Printing the state
        if(dir==2&&stateturn==0){ //If the robot is going straight and the state of the turn is 0, the robot goes right
          count6=0;
          next_state = STATE_PIVOT_RIGHT;
        }
        else if(dir==2&&stateturn==1){ //If the robot is going straight and the state of the turn is 0, the robot goes right
          count6=0;
          next_state = STATE_PIVOT_LEFT;
        }
        else if(dir==1){ //If the robot hits a wall while going left, it pivots to go forward
          next_state = STATE_PIVOT_RIGHT;
        }
        else if(dir==3){ //If the robot hits a wall while going right, it pivots to go forward
          next_state = STATE_PIVOT_LEFT;
        }
        count=0; //Counters are reset
        count3=0;
      break;
      
case STATE_PIVOT_LEFT2: // This state turns right completely around
  digitalWrite(GREEN_LED,LOW);
  digitalWrite(YELLOW_LED,HIGH);
  if(count > 14){ //Once it has finished turning, the robot goes into state stop
     next_state = STATE_STOP;
     dir=3; //The direction is set to going left
  }
  count1=0; //Resetting the clearwall count 
  count=count+1;
  pivot_left();
  Serial.println("PIVOT LEFT 2"); //Printing the state
  break;
  
case STATE_PIVOT_RIGHT2: //This state turns left completely around
  digitalWrite(GREEN_LED,LOW);
  digitalWrite(YELLOW_LED,HIGH);
  if(count > 14){ //Once it has finished turning, the robot goes into state stop
     next_state = STATE_STOP;
     dir=1; // The direction is set to going right
  }
  count1=0; //Resetting the clearwall
  count=count+1;
  pivot_right();
  Serial.println("PIVOT RIGHT 2"); //Printing the state
  break;
  
  case STATE_VEER_BEGIN: // This is the state that the robot begins in. It veers until it is perpendicular to the first wall.
  //There is no way to enter this state
    digitalWrite(GREEN_LED, HIGH);
    digitalWrite(YELLOW_LED, HIGH);
    if(MyOwl.getSensor(FRONT_CENTER)){ //When the robot senses the wall, it goes into a special wall turn.
      next_state = STATE_WALL_TURN2;
    }
    dir=1;
    veer_left();
    Serial.println("VEER BEGIN"); //This prints the state
    break;
  
  case STATE_WALL_TURN2://This state turns to pivot right and it never goes into another state
    Serial.println("WALL TURN 2"); //Printing the states
    next_state = STATE_PIVOT_RIGHT; //This state immediately goes into state pivot right
    count=0; //Resetting pivot counters
    count3=0;
    break;
      
     
  }
  //These next 3 if statements make up the directional system
if(dir==1){//When the robot is going dir=1, it is going left and detracts from it's x value
  Serial.println("LEFT");//Printing direction
  if(next_state==1||next_state==2||next_state==3||next_state==5||next_state==6){//It also never detracts unless it is going straight
    x=x-1;
  }
}
else if(dir==2){//When the robot is going dir=2, it is going forward and it adds to it's y value
  Serial.println("FORWARD");//Printing direction
  if(next_state==1||next_state==2||next_state==3||next_state==5||next_state==6){//It also never adds unless it is going straight
    y=y+1;
  }
}
else if(dir==3){//When the robot is going dir=3, it is going right and add to it's x value
  Serial.println("RIGHT");//Printing direction
  if(next_state==1||next_state==2||next_state==3||next_state==5||next_state==6){//It also never adds unless it is going straight
   x=x+1;
  }
}
Serial.println("x = "); //Here we print the x coordinate
Serial.print(x);
Serial.println("y = "); //Here we print the y coordinate
Serial.print(y);



  Chirps.step(100); //It takes 100ms to run through each iteration of the program
}

//Maneuver functions. The following functions perform basic maneuvers using the two
// motors controlled by the Roadrunner.

void stop(){
  MyRR.stopMotors();
}

void go_straight(){
  MyRR.setMotors(251,255);
}

void straight_back(){
  MyRR.setMotors(-251,-255); 
}

void pivot_right(){
  MyRR.setMotors(246,-250); 
}

void pivot_left(){
  MyRR.setMotors(-246,250); 
}

void back_left(){
  MyRR.setMotors(0,-255); 
}

void back_right(){
  MyRR.setMotors(-255,0); 
}

void turn_right(){
  MyRR.setMotors(255,0); 
}

void turn_left(){
  MyRR.setMotors(0,255); 
}

void veer_right(){
  MyRR.setMotors(255,127); 
}

void veer_left(){
  MyRR.setMotors(127,255); 
}
