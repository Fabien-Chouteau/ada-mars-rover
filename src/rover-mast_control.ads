with Rover_HAL; use Rover_HAL;

package Rover.Mast_Control with SPARK_Mode is

   type Mast_State is private;

   subtype Mast_Motion_Step is Mast_Angle range 1 .. 50;

   procedure Next_Mast_Angle (This     : in out Mast_State;
                              Min, Max : Mast_Angle;
                              Step     : Mast_Motion_Step)
     with Pre => Initialized
               and then
                 Min < Mast_Angle'Last - Step
               and then
                 Max > Mast_Angle'First - Step
               and then
                 Min < Max,
         Post => Initialized
               and then
                 Last_Angle (This) in Min .. Max,
         Global => (Rover_HAL.HW_State,
                    Rover_HAL.HW_Init);

   function Last_Angle (This : Mast_State) return Mast_Angle;

private

   type Mast_Direction is (Left, None, Right);

   type Mast_State is record
      Angle     : Mast_Angle := 0;
      Direction : Mast_Direction := Left;
   end record;

end Rover.Mast_Control;
