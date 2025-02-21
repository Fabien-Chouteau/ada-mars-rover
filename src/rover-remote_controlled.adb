with Interfaces; use Interfaces;
with Rover_HAL; use Rover_HAL;

package body Rover.Remote_Controlled
with SPARK_Mode
is

   type Remote_Command is (None,
                           Forward,
                           Backward,
                           Turn_Left,
                           Turn_Right,
                           Forward_Left,
                           Forward_Right,
                           Back_Left,
                           Back_Right);

   ----------------
   -- To_Command --
   ----------------

   function To_Command (Buttons : Buttons_State)
                        return Remote_Command
   is
   begin
      if Buttons (Up) and then Buttons (Left) then
         return Forward_Left;
      elsif Buttons (Up) and then Buttons (Right) then
         return Forward_Right;
      elsif Buttons (Down) and then Buttons (Left) then
         return Back_Left;
      elsif Buttons (Down) and then Buttons (Right) then
         return Back_Right;
      elsif Buttons (Up)  then
         return Forward;
      elsif Buttons (Right) then
         return Turn_Right;
      elsif Buttons (Left) then
         return Turn_Left;
      elsif Buttons (Down) then
         return Backward;
      else
         return None;
      end if;
   end To_Command;

   ---------
   -- Run --
   ---------

   procedure Run is
      Buttons : Buttons_State;
      Dist : Unsigned_32;

      Cmd : Remote_Command := None;
      Last_Cmd : Remote_Command;

      Now : Time;
      Last_Interaction_Time : Time;
      Timeout : constant Time := Milliseconds (10_000);
   begin

      Last_Interaction_Time := Clock;

      loop
         Now := Clock;

         exit when Last_Interaction_Time + Timeout > Now;

         Buttons  := Update;
         Last_Cmd := Cmd;

         Dist                      := Sonar_Distance;

         if (for some B of Buttons => B) then
            Last_Interaction_Time := Clock;
         end if;

         if Dist < Rover.Safety_Distance then
            --  Ignore forward commands when close to an obstacle
            Buttons (Up) := False;
         end if;

         Cmd := To_Command (Buttons);

         if Cmd /= Last_Cmd then

            case Cmd is
            when None =>
               Set_Power (Left, 0);
               Set_Power (Right, 0);
            when Forward =>
               Set_Turn (Straight);
               Set_Power (Left, 100);
               Set_Power (Right, 100);
            when Backward =>
               Set_Turn (Straight);
               Set_Power (Left, -100);
               Set_Power (Right, -100);
            when Turn_Left =>
               Set_Turn (Around);
               Set_Power (Left, -100);
               Set_Power (Right, 100);
            when Turn_Right =>
               Set_Turn (Around);
               Set_Power (Left, 100);
               Set_Power (Right, -100);
            when Forward_Left =>
               Set_Turn (Left);
               Set_Power (Left, 50);
               Set_Power (Right, 100);
            when Forward_Right =>
               Set_Turn (Right);
               Set_Power (Left, 100);
               Set_Power (Right, 50);
            when Back_Left =>
               Set_Turn (Right);
               Set_Power (Left, -100);
               Set_Power (Right, -50);
            when Back_Right =>
               Set_Turn (Left);
               Set_Power (Left, -50);
               Set_Power (Right, -100);
            end case;
         end if;

         Delay_Milliseconds (30);

         pragma Loop_Invariant (Rover.Cannot_Crash);
      end loop;
   end Run;

end Rover.Remote_Controlled;
