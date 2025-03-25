with Interfaces; use Interfaces;
with Rover_HAL; use Rover_HAL;

with Rover.Mast_Control;

package body Rover.Autonomous
with SPARK_Mode
is

   type Auto_State is record
      User_Exit : Boolean := False;

      Mast : Rover.Mast_Control.Mast_State;
   end record;

   ----------------------
   -- Check_User_Input --
   ----------------------

   procedure Check_User_Input (This : in out Auto_State)
   with
     Pre  => Initialized,
     Post => Initialized
   is
      State : Buttons_State;
   begin
      State := Update;
      This.User_Exit := (for some B in Buttons => State (B));
   end Check_User_Input;

   ----------------
   -- Go_Forward --
   ----------------

   procedure Go_Forward (This : in out Auto_State) with
     Pre  => Initialized and then
             Rover.Cannot_Crash,
     Post => Initialized
   is
      Distance : Unsigned_32;
   begin

      --  Go forward...
      Set_Turn (Straight);
      Set_Power (Left, 100);
      Set_Power (Right, 100);

      --  Rotate the mast and check for obstacle
      loop

         Check_User_Input (This);

         exit when This.User_Exit;

         Mast_Control.Next_Mast_Angle (This.Mast, -60, 70, 16);

         Distance := Sonar_Distance;

         exit when Distance < 40;

         Delay_Milliseconds (40);
      end loop;
   end Go_Forward;

   -----------------
   -- Turn_Around --
   -----------------

   procedure Turn_Around
   with
     Pre  => Initialized,
     Post => Initialized and then
             Rover.Cannot_Crash
   is
   begin
      --  Turn around, full speed
      --  TODO: Ramdom direction, keep turning if an obstacle is detected

      Set_Turn (Around);
      Set_Power (Left, -100);
      Set_Power (Right, 100);
      Delay_Milliseconds (2000);
   end Turn_Around;

   ------------------------
   -- Find_New_Direction --
   ------------------------

   procedure Find_New_Direction (This : in out Auto_State)
     with
      Pre  => Initialized,
      Post => Initialized and then
              Rover.Cannot_Crash
   is
      Left_Dist : Unsigned_32 := 0;
      Right_Dist : Unsigned_32 := 0;

      Timeout, Now : Time;

   begin
      Now := Clock;
      Timeout := Now + Milliseconds (10000);

      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

      --  Turn the mast back and forth and log the dected distance for the left
      --  and right side.
      loop
         Check_User_Input (This);
         Now := Clock;

         exit when This.User_Exit or else Now > Timeout;

         Mast_Control.Next_Mast_Angle (This.Mast, -60, 70, 4);

         if Mast_Control.Last_Angle (This.Mast) <= -40 then
            Left_Dist := Sonar_Distance;
         end if;
         if Mast_Control.Last_Angle (This.Mast) >= 40 then
            Right_Dist := Sonar_Distance;
         end if;

         Delay_Milliseconds (30);
      end loop;

      if Now > Timeout then
         if Left_Dist < 50 and then Right_Dist < 50 then
            --  Obstacles left and right, turn around to find a new direction
            Turn_Around;

         elsif Left_Dist > Right_Dist then
            --  Turn left a little
            Set_Turn (Around);
            Set_Power (Left, -100);
            Set_Power (Right, 100);
            Delay_Milliseconds (800);
         else
            --  Turn right a little
            Set_Turn (Around);
            Set_Power (Left, 100);
            Set_Power (Right, -100);
            Delay_Milliseconds (800);
         end if;
      end if;

   end Find_New_Direction;

   ---------
   -- Run --
   ---------

   procedure Run is
      State : Auto_State;
   begin

      Set_Display_Info ("Autonomous");

      --  Stop everything
      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

      while not State.User_Exit loop

         Go_Forward (State);
         Find_New_Direction (State);

         pragma Loop_Invariant (Rover.Cannot_Crash);
      end loop;

      --  Stop everything before leaving the autonomous mode
      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

   end Run;

end Rover.Autonomous;
