with HAL; use HAL;
with RP.GPIO;
with RP.PWM; use RP.PWM;

with Rover.Servos;

package body Rover.Driving is

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

   Inside_Turn_Offset : constant := 75;
   Outside_Turn_Offset : constant := 55;

   Left_Inside_Offset  : constant := -Inside_Turn_Offset;
   Right_Inside_Offset : constant := Inside_Turn_Offset;
   Left_Outside_Offset  : constant := -Outside_Turn_Offset;
   Right_Outside_Offset : constant := Outside_Turn_Offset;

   type Servo_Positions is array (Steering_Wheel_Id, Side_Id) of Integer;

   Straight_Point : constant Servo_Positions := [Front => [Left =>  300 - 20,
                                                           Right => 300 - 15],
                                                 Back  => [Left =>  300 - 20,
                                                           Right => 300 + 00]];

   procedure Set_Turn (Turn : Turn_Kind) is
      Positions : Servo_Positions := Straight_Point;
   begin
      case Turn is
         when Straight =>
            null;
         when Left =>
            Positions (Front, Left)  := @ + Left_Inside_Offset;
            Positions (Front, Right) := @ + Left_Inside_Offset;
            Positions (Back, Left)   := @ + Right_Outside_Offset;
            Positions (Back, Right)  := @ + Right_Outside_Offset;
         when Right =>
            Positions (Front, Left)  := @ + Right_Inside_Offset;
            Positions (Front, Right) := @ + Right_Inside_Offset;
            Positions (Back, Left)   := @ + Left_Outside_Offset;
            Positions (Back, Right)  := @ + Left_Outside_Offset;
         when Around =>
            Positions (Front, Left)  := @ + Right_Inside_Offset;
            Positions (Front, Right) := @ + Left_Inside_Offset;
            Positions (Back, Left)   := @ + Left_Inside_Offset;
            Positions (Back, Right)  := @ + Right_Inside_Offset;
      end case;

      for Side in Side_Id loop
         for Wheel in Steering_Wheel_Id loop
            Servos.Set_Wheel (Wheel, Side, Positions (Wheel, Side));
         end loop;
      end loop;
   end Set_Turn;

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

end Rover.Driving;
