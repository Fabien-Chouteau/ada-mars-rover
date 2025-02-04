with HAL; use HAL;
with RP.GPIO;
with RP.PWM; use RP.PWM;

package body Rover_HAL.Motors is

   M1_A_GPIO  : RP.GPIO.GPIO_Point := (Pin => 12);
   M1_B_GPIO  : RP.GPIO.GPIO_Point := (Pin => 13);
   M2_A_GPIO  : RP.GPIO.GPIO_Point := (Pin => 14);
   M2_B_GPIO  : RP.GPIO.GPIO_Point := (Pin => 15);

   M1_A_Point : constant RP.PWM.PWM_Point := RP.PWM.To_PWM (M1_A_GPIO);
   M1_B_Point : constant RP.PWM.PWM_Point := RP.PWM.To_PWM (M1_B_GPIO);
   M2_A_Point : constant RP.PWM.PWM_Point := RP.PWM.To_PWM (M2_A_GPIO);
   M2_B_Point : constant RP.PWM.PWM_Point := RP.PWM.To_PWM (M2_B_GPIO);

   M1_Slice : constant RP.PWM.PWM_Slice := M1_A_Point.Slice;
   M2_Slice : constant RP.PWM.PWM_Slice := M2_A_Point.Slice;

   Interval : constant := 10_000;
   Interval_Pecent : constant := Interval / 100;

   --------------------
   -- Set_Duty_Cycle --
   --------------------

   procedure Set_Duty_Cycle (P    : RP.PWM.PWM_Point;
                             Duty : RP.PWM.Period)
   is
   begin
      Set_Duty_Cycle (P.Slice, P.Channel, Duty);
   end Set_Duty_Cycle;

   ---------------
   -- Set_Power --
   ---------------

   procedure Set_Power (Side : Side_Id;
                        Pwr  : Motor_Power)
   is
      Duty : RP.PWM.Period;
      Forward : Boolean := True;
   begin
      case Pwr is
         when 0 =>
            Duty := 0;
         when 1 .. 100 =>
            Forward := True;
            Duty := UInt16 (Pwr) * Interval_Pecent;
         when -100 .. -1 =>
            Forward := False;
            Duty := UInt16 (-Pwr) * Interval_Pecent;
      end case;

      case Side is
         when Left =>
            if Forward then
               Set_Duty_Cycle (M2_A_Point, Duty);
               Set_Duty_Cycle (M2_B_Point, 0);
            else
               Set_Duty_Cycle (M2_A_Point, 0);
               Set_Duty_Cycle (M2_B_Point, Duty);
            end if;

         when Right =>
            if Forward then
               Set_Duty_Cycle (M1_A_Point, Duty);
               Set_Duty_Cycle (M1_B_Point, 0);
            else
               Set_Duty_Cycle (M1_A_Point, 0);
               Set_Duty_Cycle (M1_B_Point, Duty);
            end if;
      end case;

   end Set_Power;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin

      pragma Assert (M1_A_Point.Slice = M1_B_Point.Slice);
      pragma Assert (M2_A_Point.Slice = M2_B_Point.Slice);

      RP.PWM.Initialize;

      M1_A_GPIO.Configure (RP.GPIO.Output, RP.GPIO.Pull_Down, RP.GPIO.PWM);
      M1_B_GPIO.Configure (RP.GPIO.Output, RP.GPIO.Pull_Down, RP.GPIO.PWM);
      M2_A_GPIO.Configure (RP.GPIO.Output, RP.GPIO.Pull_Down, RP.GPIO.PWM);
      M2_B_GPIO.Configure (RP.GPIO.Output, RP.GPIO.Pull_Down, RP.GPIO.PWM);

      Set_Mode (M1_Slice, Free_Running);
      Set_Mode (M2_Slice, Free_Running);

      Set_Frequency (M1_Slice, 10_000_000);
      Set_Frequency (M2_Slice, 10_000_000);

      Set_Interval (M1_Slice, Interval);
      Set_Interval (M2_Slice, Interval);

      Set_Duty_Cycle (M1_A_Point, 0);
      Set_Duty_Cycle (M1_B_Point, 0);
      Set_Duty_Cycle (M2_A_Point, 0);
      Set_Duty_Cycle (M2_B_Point, 0);

      Enable (M2_Slice);
      Enable (M1_Slice);
   end Initialize;

end Rover_HAL.Motors;
