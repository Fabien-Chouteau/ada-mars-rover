with Rover_HAL;

package Rover.Remote_Controlled
with SPARK_Mode
is

   procedure Run
     with
      Pre  => Rover_HAL.Initialized and then
              Rover.Cannot_Crash,
      Post => Rover_HAL.Initialized and then
              Rover.Cannot_Crash;

end Rover.Remote_Controlled;
