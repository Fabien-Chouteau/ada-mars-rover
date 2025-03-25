with Interfaces; use Interfaces;
with Rover_HAL; use Rover_HAL;

with Rover.Mast_Control;

package body Rover.Remote_Controlled
with SPARK_Mode
is
   type Remote_Command is (Invalid,
                           None,
                           Forward,
                           Backward,
                           Turn_Left,
                           Turn_Right,
                           Forward_Left,
                           Forward_Right,
                           Back_Left,
                           Back_Right);

   function Img (Cmd : Remote_Command) return String
   is (case Cmd is
          when Invalid       => "Invalid",
          when None          => "None",
          when Forward       => "Forward",
          when Backward      => "Backward",
          when Turn_Left     => "Turn Left",
          when Turn_Right    => "Turn Right",
          when Forward_Left  => "Fwd Left",
          when Forward_Right => "Fwd Right",
          when Back_Left     => "Bwd Left",
          when Back_Right    => "Bwd Right")
        with Post => Img'Result'Length <= 13;

   ----------------
   -- To_Command --
   ----------------

   function To_Command (Buttons : Buttons_State)
                        return Remote_Command
   is
      (if Buttons (Up) and then Buttons (Left) then
         Forward_Left
      elsif Buttons (Up) and then Buttons (Right) then
         Forward_Right
      elsif Buttons (Down) and then Buttons (Left) then
         Back_Left
      elsif Buttons (Down) and then Buttons (Right) then
         Back_Right
      elsif Buttons (Up)  then
         Forward
      elsif Buttons (Right) then
         Turn_Right
      elsif Buttons (Left) then
         Turn_Left
      elsif Buttons (Down) then
         Backward
      else
         None)
   with
      Annotate => (GNATprove, Inline_for_Proof);

   ---------
   -- Run --
   ---------

   procedure Run is
      Buttons : Buttons_State;
      Dist : Unsigned_32;

      Cmd : Remote_Command := Invalid;
      Last_Cmd : Remote_Command;

      Now : Time;
      Last_Interaction_Time : Time;
      Timeout : constant Time := Milliseconds (10_000);

      M_State : Mast_Control.Mast_State;
   begin

      Set_Mast_Angle (0);

      Last_Interaction_Time := Clock;

      loop
         Now := Clock;

         exit when Last_Interaction_Time + Timeout < Now;

         Buttons  := Update;
         Last_Cmd := Cmd;

         Dist := Sonar_Distance;

         if (for some B of Buttons => B) then
            Last_Interaction_Time := Clock;
         end if;

         if Dist < Rover.Safety_Distance then
            --  Ignore forward commands when close to an obstacle
            Buttons (Up) := False;
         else

            --  Only turn the mast when there is no detected obstacle.
            --  Otherwise, the sensor may look away from the obstacle and
            --  not detect it anymore.
            Mast_Control.Next_Mast_Angle (M_State, -55, 55, 16);

            pragma Assert (Mast_Control.Last_Angle (M_State) in -55 .. 55);
         end if;

         Cmd := To_Command (Buttons);

         Set_Display_Info ("Remote: " & Img (Cmd));

         if Cmd /= Last_Cmd then

            case Cmd is
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
               Set_Turn (Left);
               Set_Power (Left, -50);
               Set_Power (Right, -100);
            when Back_Right =>
               Set_Turn (Right);
               Set_Power (Left, -100);
               Set_Power (Right, -50);
            when others =>
               Set_Power (Left, 0);
               Set_Power (Right, 0);
            end case;
         end if;

         Delay_Milliseconds (30);

         --  Carry the information about the relationship between Cmd and the
         --  turn and power settings around the loop, since when Cmd = Last_Cmd
         --  these values are retained.
         pragma Loop_Invariant (if Cmd /= Forward then
                                   Get_Turn /= Straight or else
                                   (Get_Power (Left) <= 0 and then
                                    Get_Power (Right) <= 0));

         --  Establish our safety property.
         pragma Loop_Invariant (Rover.Cannot_Crash);
      end loop;
   end Run;

end Rover.Remote_Controlled;
