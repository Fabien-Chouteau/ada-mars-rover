with Interfaces;
with Rover_HAL;
package Rover with SPARK_Mode is

   Safety_Distance : constant Interfaces.Unsigned_32 := 20;

   function Cannot_Crash return Boolean
     with
       Pre    => Rover_HAL.Initialized,
       Global => (Rover_HAL.HW_Init,
                  Rover_HAL.Power_State,
                  Rover_HAL.Turn_State),
       Ghost;
   --  Safety Requirement: The Mars Rover shall not proceed straight forward
   --  when the distance to an obstacle is less than the Safety Distance.

private
   use type Interfaces.Unsigned_32;
   use type Rover_HAL.Turn_Kind;
   use type Rover_HAL.Motor_Power;

   function Cannot_Crash return Boolean is
     (if Rover_HAL.Get_Sonar_Distance < Safety_Distance and then
         Rover_HAL.Get_Turn = Rover_HAL.Straight
      then
         Rover_HAL.Get_Power (Rover_HAL.Left)  <= 0 and then
         Rover_HAL.Get_Power (Rover_HAL.Right) <= 0);

end Rover;
