# Wall-Follow-Robot
This code is for a wall-following robot on treads utilizing 3 light sensors. This is performed on a custom Arduino board interface. This project was done as part of an Engineering class in Spring of 2012.

[//]: # (Image References)

[image1]: ./ArduinoPictures/GFURobot.png "Project Tank Robot"
[image2]: ./ArduinoPictures/RavenBoard.png "Project Tank Robot"
[image3]: ./ArduinoPictures/StateClearWallLeft.png "State Clear Wall Left"
[image4]: ./ArduinoPictures/StateClearWallRight.png "State Clear Wall Right"
[image5]: ./ArduinoPictures/StateCornered.png "State Cornered"
[image6]: ./ArduinoPictures/StateFollowLeft.png "State Follow Left"
[image7]: ./ArduinoPictures/StateFollowRight.png "State Follow Right"
[image8]: ./ArduinoPictures/StateLefthandCorner.png "State Lefthand Corner"
[image9]: ./ArduinoPictures/StatePivotLeft.png "State Pivot Left"
[image10]: ./ArduinoPictures/StatePivotRight.png "State Pivot Right"
[image11]: ./ArduinoPictures/StateRighthandCorner.png "State Righthand Corner"
[image12]: ./ArduinoPictures/StateStop.png "State Stop"
[image13]: ./ArduinoPictures/StateStraight.png "State Straight"
[image14]: ./ArduinoPictures/StateWallTurn.png "State Wall Turn"

### Origin of Project

This project involved using a tread based robot with light sensors pictured here:

![alt text][image1]

This robot is programmed using Arduino on a custom board pictured here:

![alt text][image2]

#### Objective

The goal of the project was to program the tank-like robot so that it could navigate through an unknown and dynamically changing obstacle course. The robot's programming must be able to navigate and know its psotion relative to the stop and statr of the obstacle course, and must navigate with no interference after being remotely started.

#### Design

As previously mentioned, this robot utilized Arduino to implement a simple state machine along with programming the sensors and movement. As the robot moved, it created a simplistic x,y pose to keep a relative knowledge of where it begin and could make sure it was always progressing towards the goal of completeing the maze. Given how the robot was designed, it was the robot in the class with the highest success right and lowest duration to finish the maze.

This robot fit a classic state machine construction which consisted of 12 states in order to navigate the maze. The states diagrams are shown below:

![alt text][image13]

![alt text][image12]

![alt text][image6]

![alt text][image7]

![alt text][image3]

![alt text][image4]

![alt text][image9]

![alt text][image10]

![alt text][image8]

![alt text][image11]

![alt text][image5]

![alt text][image14]
