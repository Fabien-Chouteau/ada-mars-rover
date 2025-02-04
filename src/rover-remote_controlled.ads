with Rover_HAL;

package Rover.Remote_Controlled
with SPARK_Mode
is

   procedure Run
     with Pre => Rover_HAL.Initialized;

end Rover.Remote_Controlled;
