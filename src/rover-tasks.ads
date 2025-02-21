with Rover_HAL;

package Rover.Tasks
with SPARK_Mode
is

   procedure Demo
     with
      Pre  => Rover_HAL.Initialized,
      Post => Rover_HAL.Initialized and then
              Rover.Cannot_Crash;

   pragma Export (C, Demo, "mars_rover_demo_task");

end Rover.Tasks;
