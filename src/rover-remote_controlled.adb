with RP.Timer; use RP.Timer;
with RP.Device;

with Rover.Remote;
with Rover.Driving; use Rover.Driving;
with Rover.Sonar;

package body Rover.Remote_Controlled is

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

   function To_Command (Buttons : Rover.Remote.Buttons_State)
                        return Remote_Command
   is
      use Rover.Remote;
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
      Buttons : Rover.Remote.Buttons_State;
      Dist : Natural;

      Cmd, Last_Cmd : Remote_Command := None;

      Last_Interaction_Time : Time := Clock;
      Timeout : constant Time := Milliseconds (10_000);
   begin

      while Last_Interaction_Time < Clock + Timeout loop
         Buttons := Rover.Remote.Update;
         Dist := Rover.Sonar.Distance;
         Last_Cmd := Cmd;

         if (for some B of Buttons => B) then
            Last_Interaction_Time := Clock;
         end if;

         if Dist < 20 then
            --  Ignore forward commands when close to an obstacle
            Buttons (Rover.Remote.Up) := False;
         end if;

         Cmd := To_Command (Buttons);

         if Cmd /= Last_Cmd then

            case Cmd is
            when None =>
               Rover.Driving.Set_Power (Left, 0);
               Rover.Driving.Set_Power (Right, 0);
            when Forward =>
               Rover.Driving.Set_Turn (Straight);
               Rover.Driving.Set_Power (Left, 100);
               Rover.Driving.Set_Power (Right, 100);
            when Backward =>
               Rover.Driving.Set_Turn (Straight);
               Rover.Driving.Set_Power (Left, -100);
               Rover.Driving.Set_Power (Right, -100);
            when Turn_Left =>
               Rover.Driving.Set_Turn (Around);
               Rover.Driving.Set_Power (Left, -100);
               Rover.Driving.Set_Power (Right, 100);
            when Turn_Right =>
               Rover.Driving.Set_Turn (Around);
               Rover.Driving.Set_Power (Left, 100);
               Rover.Driving.Set_Power (Right, -100);
            when Forward_Left =>
               Rover.Driving.Set_Turn (Left);
               Rover.Driving.Set_Power (Left, 50);
               Rover.Driving.Set_Power (Right, 100);
            when Forward_Right =>
               Rover.Driving.Set_Turn (Right);
               Rover.Driving.Set_Power (Left, 100);
               Rover.Driving.Set_Power (Right, 50);
            when Back_Left =>
               Rover.Driving.Set_Turn (Right);
               Rover.Driving.Set_Power (Left, -100);
               Rover.Driving.Set_Power (Right, -50);
            when Back_Right =>
               Rover.Driving.Set_Turn (Left);
               Rover.Driving.Set_Power (Left, -50);
               Rover.Driving.Set_Power (Right, -100);
            end case;
         end if;

         RP.Device.Timer.Delay_Milliseconds (30);
      end loop;
   end Run;

end Rover.Remote_Controlled;
