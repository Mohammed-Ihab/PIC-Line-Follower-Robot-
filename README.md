# Line Follower Robot with Obstacle Detection – PIC Assembly Project

This is a college project developed using assembly language for the PIC16F877A microcontroller. The robot is designed to follow a black line using infrared sensors and intelligently avoid obstacles using both digital and analog proximity sensors. An LCD provides real-time feedback on the robot's status.

## 👨‍💻 Author

*Mohammed Ihab*  
College Project – Microprocessors Systems (PIC Assembly)  
Year: 2025

---

## 🚗 Project Overview

The robot performs the following functions:

- *Line Following*  
  Using two *infrared sensors*, the robot detects and follows a line on the ground.

- *Obstacle Avoidance*  
  - A *photoelectric switch (E18-B03N1)* acts as a digital proximity sensor. It triggers an *interrupt* when an obstacle is detected.
  - A *Sharp analog infrared sensor* provides distance-based detection:
    - *Red LED: Obstacle is **very close*
    - *Yellow LED: Obstacle is at **mid-range*
    - *Green LED: Obstacle is at a **safe distance*

- *LCD Display*  
  An *alphanumeric LCD* displays the robot's current status (e.g., "LINE FOLLOWING", "STOP  OBJECT DETECTED", etc.).

---

## 🛠 Tools Used

- *Assembly Language* (MPLAB / MPASM)
- *Proteus* for simulation
- *PIC16F877A* microcontroller
