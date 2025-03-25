package body Rover.Mast_Control with SPARK_Mode is

   -------------------
   -- Next_Mast_Pos --
   -------------------

   procedure Next_Mast_Angle (This     : in out Mast_State;
                              Min, Max : Mast_Angle;
                              Step     : Mast_Motion_Step)
   is
   begin
      if This.Angle < Min then
         This.Angle := Min;
      elsif This.Angle > Max then
         This.Angle := Max;
      end if;

      case This.Direction is
         when None =>
            null;
         when Left =>
            if This.Angle <= Min + Step then
               This.Direction := Right;
            else
               This.Angle := This.Angle - Step;
            end if;
         when Right =>
            if This.Angle >= Max - Step then
               This.Direction := Left;
            else
               This.Angle := This.Angle + Step;
            end if;
      end case;

      Set_Mast_Angle (This.Angle);
   end Next_Mast_Angle;

   --------------
   -- Last_Pos --
   --------------

   function Last_Angle (This : Mast_State) return Mast_Angle
   is (This.Angle);

end Rover.Mast_Control;
