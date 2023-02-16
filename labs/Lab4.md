---
title: Controlled actuation using PID 
---
### Introduction
This blog outlines my experience with tuning a PID controller for the Haply 2diy, implementing path tracking and understanding the effect of controller update rates and delays.

### Tuning the PID controller
I thought the starter code was really helpful to get started with the PID tuning. I noticed quickly, however, that the keyboard control of the variables hadn't been set up to reflect in the otherwise awesome UI. Thankfully, the code was well structured and I only needed to make some minor changes to add it in. This made the rest of the tuning and documentation process much easier. 

#### P Controller
I had already used a P controller for the previous lab. However, unlike my previous experience where I'd handpicked points since the target point was random (and sometimes far away) in this case. Hence, the abrupt bursts of force of the P controller were more apparent. 
Even with a value of 0.01, while the graphics seemed to indicate that the end effector could approximately reach the desired point, I noticed that this was not the case for the physical end effector. There was only occasional overshoot in the virtual end effector, but the physical end effector often overshot, especially when the distance between the starting point and target was large. The behaviour was much smoother when I gently held the end effector.

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/P.mp4" type="video/mp4">
</video>


#### PD controller
I noticed that the response of the physical end effector was much smoother as I added in the D value. With the P value still at 0.01, I noticed that the overshoot of the physical end effector was no longer a problem with a D value of around 1.0, but the end effector was no longer reaching the target. I observed that the movement became increasingly damped or 'reluctant' with an increase in the D value. The D parameter seemed to have a similar effect as me holding the end effector. 
Also, as I increased the D value to 1.5, I encountered occasional vibrations and they increased and became more frequent as the D value was increased further. The [Gain tuning video](https://www.youtube.com/watch?v=uXnDwojRb1g&t=263s) on the Tips and Tricks page turned out to be especially helpful at this stage. After a few trials, I ultimately set P=0.03 and D=1.2 to get a fairly good stable response. 

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/PD.mp4" type="video/mp4">
</video>

#### PID controller
The tuning of the I value was admittedly the most challenging. When I increased the value of I to 0.01 and then to 0.02 with the previously selected PD values the end effector always reached the final position, however, the movement after the initial burst was fairly slow. The system became unstable as I tried increasing the I value to 0.03. Therefore, I decided to tune the PD values again to make the response faster with 0.02. Since I wanted to make the initial burst larger and reduce the damping I varied the P and D values accordingly. I was able to get a good response with P=0.04, I=0.03 and D=1.15.

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/PID.mp4" type="video/mp4">
</video>

#### Path tracking
I implemented a circular path for the 'path tracking' exercise with a radius of 0.35. The destination was set to update at 0.1 degrees per 500μs which set the speed of rotation roughly to one rotation every 1.8 seconds. Even at this low speed, the end effector was lagging with the previously set PID parameters, and hence I had to tune the values again. I was able to achieve good path tracking with P=0.1, I=0.02 and D=1.0. I've added in hotkeys k, l and o to set the PID value and initial point, start the movement along the path and stop the movement respectively. 

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/Path.mp4" type="video/mp4">
</video>

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/Endeffector.mp4" type="video/mp4">
</video>

Holding the end effector with my hand seemed to have the expected damping effect even in this case. I was able to reduce the D value and increase the P value to make the end effector follow the path more closely.

Also, I had initially set the radius to 0.4. With this radius, I noticed that the end effector seemed to lag slightly at the top of the circle, near the joint where the arms of the Haply connect to the motors. On further examination, I noticed that owing to the mechanical structure this portion of the Haply seems to be slightly harder to navigate and required more force. Although a little lag at the top of the circle is still noticeable if you were to look for it carefully, when I reduced the radius value to 0.35 I observed that this lag was consequently reduced since the end effector no longer has to move as close to the joint as in the case of the 0.4 radius circle. 

#### Varying the loop time
I initially tried varying the loop time with the path tracking I'd implemented. When I set the loop time to 250μs, I noticed that my computer was able to achieve roughly just over 3.3kHz although I constantly received warnings of speed drops. This meant the loop was actually running with a loop time of 300μs. The end effector had a very smooth motion and was able to reliably follow the path as long as the loop speed didn't have a significant drop suddenly (which was a very rare but observed situation).
I then tried increasing the loop time to values above 500μs. I noticed that the end effector started lagging with each step increase in the loop time parameter and the movement became less smooth. When the loop time was increased to 1500μs the end effector was no longer able to follow the path reliably.

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/loop.mp4" type="video/mp4">
</video>

#### Randomizing the loop time
To randomize the loop time I added two further key events to enable and disable random loop times (keys n and m respectively).

    if (random)
        looptime= times[new Random().nextInt(times.length)]*250;

Here 'times' was,

    int[] times= IntStream.rangeClosed(1, 16).toArray();

Hence, when 'random' was true, the looptime was set to a random value within a range of 250 to 4000 (with a step size of 250) at each loop. 
The randomized loop times made the end effector spin out of control almost immediately. The short intervals when the end effector appears to be stable in the video are owing to me manually stabilizing the end effector only to have it destabilize almost instantly as I released my grip again. Even though I tried a little parameter tuning I wasn't able to get a reasonable path-tracking performance and it became apparent that the occasional loops when the value was set to values at or below 1250μs (for which a reasonably stable path-tracking was previously observed) weren't able to compensate for the instability caused by the larger loop times and the accumulated error. 

<video height="100%" controls>
  <source src="../assets/images/labs/lab4/random.mp4" type="video/mp4">
</video>

### Reflections
The PID tuning exercise was useful to understand the contribution of the various parameters that make up the PID controller. While I was initially slightly irked about the fact that the tuning didn't seem to have a more straightforward approach than 'trial and error' by the end of the exercise I could understand to a fair extent what needed to be varied to obtain a better response. Further, it was nice to understand and appreciate the effect the user's grip has on the end-effector movement and it also got me thinking about how this could affect the user experience in situations where the grip was suddenly released.

Besides just the concepts of PID itself, I think this exercise was useful to understand the quirks of the Haply device such as the slight variations in performance over the workspace, and the possible causes of instability and erratic behaviour. Also, although we had come across the importance of the haptic looptime and why it was necessary to keep the more computationally intensive visual updates separate in one of the earlier readings I think I only understand the importance of this now. 

You can find the code for this lab here: [Controlled actuation using PID Source Code](https://github.com/VenissaCarolQuadros/CanHap501/tree/main/labs/code/lab4/sketch_PID_GUI).