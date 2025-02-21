with Rover_HAL;

package Rover.Autonomous
with SPARK_Mode
is

   procedure Run
     with
      Pre => Rover_HAL.Initialized,
      Post => Rover_HAL.Initialized and then
              Rover.Cannot_Crash;
   --  Run the autonomous routine until a button is pressed on the remote

end Rover.Autonomous;
