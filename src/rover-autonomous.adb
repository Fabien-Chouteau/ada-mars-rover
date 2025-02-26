with Interfaces; use Interfaces;
with Rover_HAL; use Rover_HAL;

package body Rover.Autonomous
with SPARK_Mode
is

   type Mast_Direction is (Left, None, Right);

   type Auto_State is record
      User_Exit : Boolean := False;
      Pos : Mast_Angle := 0;
      Direction : Mast_Direction := Left;
      Last_Mast_Update : Time := 0;
   end record;

   -------------------
   -- Next_Mast_Pos --
   -------------------

   procedure Next_Mast_Pos (This : in out Auto_State;
                            Min, Max : Mast_Angle;
                            Period : Time)
   with
     Pre  => Initialized,
     Post => Initialized
   is
      Now : constant Time := Clock;
   begin
      if Now < This.Last_Mast_Update + Period then
         return;
      end if;

      case This.Direction is
         when None =>
            null;
         when Left =>
            if This.Pos <= Min then
               This.Direction := Right;
            else
               This.Pos := This.Pos - 1;
            end if;
         when Right =>
            if This.Pos >= Max then
               This.Direction := Left;
            else
               This.Pos := This.Pos + 1;
            end if;
      end case;

      Set_Mast_Angle (This.Pos);
      This.Last_Mast_Update := Now;
   end Next_Mast_Pos;

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

         Next_Mast_Pos (This, -55, 55, Milliseconds (10));

         Distance := Sonar_Distance;

         exit when Distance < 30;

         Delay_Milliseconds (10);
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
      Timeout := Now + Milliseconds (8000);

      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

      --  Turn the mast back and forth and log the dected distance for the left
      --  and right side.
      loop
         Check_User_Input (This);
         Now := Clock;

         exit when This.User_Exit or else Now > Timeout;

         Next_Mast_Pos (This, -55, 55, Milliseconds (20));

         if This.Pos <= -40 then
            Left_Dist := Sonar_Distance;
         end if;
         if This.Pos >= 40 then
            Right_Dist := Sonar_Distance;
         end if;

         Delay_Milliseconds (10);
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
