with Interfaces; use Interfaces;
with Rover_HAL; use Rover_HAL;

package body Rover.Autonomous
with SPARK_Mode => Off
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

   function Check_User_Input (This : in out Auto_State) return Boolean is
      State : constant Buttons_State := Update;
   begin
      This.User_Exit := (for some B in Buttons => State (B));
      return This.User_Exit;
   end Check_User_Input;

   ----------------
   -- Go_Forward --
   ----------------

   procedure Go_Forward (This : in out Auto_State) is
   begin

      --  Go forward...
      Set_Turn (Straight);
      Set_Power (Left, 100);
      Set_Power (Right, 100);

      --  Rotate the mast and check for obstacle
      while not Check_User_Input (This) loop
         Next_Mast_Pos (This, -45, 45, Milliseconds (10));

         exit when Sonar_Distance < 30;
         Delay_Milliseconds (10);
      end loop;
   end Go_Forward;

   -----------------
   -- Turn_Around --
   -----------------

   procedure Turn_Around is
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

   procedure Find_New_Direction (This : in out Auto_State) is
      Left_Dist : Unsigned_32;
      Right_Dist : Unsigned_32;

      Timeout : constant Time := Clock + Milliseconds (8000);
   begin
      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

      --  Turn the mast back and forth and log the dected distance for the left
      --  and right side.
      while not Check_User_Input (This) and then Clock < Timeout loop
         Next_Mast_Pos (This, -55, 55, Milliseconds (20));

         if This.Pos <= -40 then
            Left_Dist := Sonar_Distance;
         end if;
         if This.Pos >= 40 then
            Right_Dist := Sonar_Distance;
         end if;

         Delay_Milliseconds (10);
      end loop;

      if Clock > Timeout then
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

      --  Stop everything
      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

      while not State.User_Exit loop
         Go_Forward (State);
         Find_New_Direction (State);
      end loop;

      --  Stop everything before leaving the autonomous mode
      Set_Turn (Straight);
      Set_Power (Left, 0);
      Set_Power (Right, 0);

   end Run;

end Rover.Autonomous;
