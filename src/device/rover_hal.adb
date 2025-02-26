with HAL; use HAL;

with RP.Clock;
with RP.Device;
with RP.GPIO;
with Pico;
with RP.Timer;

with Cortex_M.Systick;

with Rover_HAL.I2C;
with Rover_HAL.PCA9685;
with Rover_HAL.Motors;
with Rover_HAL.Sonar;
with Rover_HAL.Remote;
with Rover_HAL.Screen;
with Rover_HAL.GUI;

package body Rover_HAL
with SPARK_Mode => Off
is

   HW_Initialized : Boolean := False;

   procedure Systick;
   pragma Export (ASM, Systick, "isr_systick");

   -------------
   -- Systick --
   -------------

   procedure Systick is
   begin
      GUI.Update;
   end Systick;

   -----------------
   -- Initialized --
   -----------------

   function Initialized return Boolean is
   begin
      return HW_Initialized;
   end Initialized;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);
      RP.Clock.Enable (RP.Clock.PERI);
      RP.Device.Timer.Enable;
      Pico.LED.Configure (RP.GPIO.Output);

      Rover_HAL.I2C.Initialize;
      Rover_HAL.PCA9685.Initialize;
      Rover_HAL.Motors.Initialize;
      Rover_HAL.Remote.Initialize;
      Rover_HAL.Screen.Initialize;
      Rover_HAL.GUI.Initialize;

      --  15Hz tick
      Cortex_M.Systick.Configure
        (Cortex_M.Systick.CPU_Clock,
         Generate_Interrupt => True,
         Reload_Value       =>
           UInt24 ((RP.Clock.Frequency (RP.Clock.SYS) / 15) - 1));
      Cortex_M.Systick.Enable;

      HW_Initialized := True;
   end Initialize;

   -----------
   -- Clock --
   -----------

   function Clock return Time
   is (Time (RP.Timer.Clock));

   ------------------------
   -- Delay_Microseconds --
   ------------------------

   procedure Delay_Microseconds (Us : Unsigned_16) is
   begin
      RP.Device.Timer.Delay_Microseconds (Integer (Us));
   end Delay_Microseconds;

   ------------------------
   -- Delay_Milliseconds --
   ------------------------

   procedure Delay_Milliseconds (Ms : Unsigned_16) is
   begin
      RP.Device.Timer.Delay_Milliseconds (Integer (Ms));
   end Delay_Milliseconds;

   -----------
   -- Sonar --
   -----------

   function Sonar_Distance return Unsigned_32 is
      Result : constant Unsigned_32 := Unsigned_32 (Rover_HAL.Sonar.Distance);
   begin
      GUI.Last_Distance := Result;
      return Result;
   end Sonar_Distance;

   ----------
   -- Mast --
   ----------

   procedure Set_Mast_Angle (V : Mast_Angle) is
      use PCA9685;

      Center     : constant := 327.0;
      Move_Step  : constant := 200.0 / 90.0;

      Offset : constant Integer := Integer (-Float (V) * Move_Step);
      Pos : constant PWM_Range := PWM_Range (Integer (Center) + Offset);
   begin
      Set_PWM (0, Pos);
   end Set_Mast_Angle;

   ------------
   -- Update --
   ------------

   function Update return Buttons_State is
   begin
      return Rover_HAL.Remote.Update;
   end Update;

   ------------
   -- Wheels --
   ------------

   procedure Set_Wheel_Angle (Wheel : Steering_Wheel_Id;
                              Side  : Side_Id;
                              V     : Steering_Wheel_Angle)
   is
      use PCA9685;

      Move_Step  : constant := 200.0 / 90.0;

      Offset : constant Integer := Integer (-Float (V) * Move_Step);
      Pos : constant PWM_Range :=
        PWM_Range (Integer (GUI.Center (Wheel, Side)) + Offset);

      Chan : constant Channel_Id :=
        (case Side is
            when Left => (case Wheel is
                             when Front => 9,
                             when Back  => 11),
            when Right => (case Wheel is
                              when Front => 15,
                              when Back  => 13));
   begin
      Set_PWM (Chan, Pos);
   end Set_Wheel_Angle;

   --------------
   -- Set_Turn --
   --------------

   procedure Set_Turn (Turn : Turn_Kind) is
      type Wheels_Angle
      is array (Steering_Wheel_Id, Side_Id) of Steering_Wheel_Angle;

      Angles : Wheels_Angle;

      Inside_Angle : constant := 30;
      Outside_Angle : constant := 20;
   begin
      case Turn is
         when Straight =>
            Angles := [others => [others => 0]];
         when Left =>
            --  Inside
            Angles (Front, Left) := Inside_Angle;
            Angles (Back, Left) := -Inside_Angle;

            --  Outside
            Angles (Front, Right) := Outside_Angle;
            Angles (Back, Right) := -Outside_Angle;
         when Right =>
            --  Inside
            Angles (Front, Right) := -Inside_Angle;
            Angles (Back, Right) := Inside_Angle;

            --  Outside
            Angles (Front, Left) := -Outside_Angle;
            Angles (Back, Left) := Outside_Angle;

         when Around =>
            Angles (Front, Left) := -Inside_Angle;
            Angles (Front, Right) := Inside_Angle;

            Angles (Back, Left) := Inside_Angle;
            Angles (Back, Right) := -Inside_Angle;
      end case;

      for Side in Side_Id loop
         for Wheel in Steering_Wheel_Id loop
            Set_Wheel_Angle (Wheel, Side, Angles (Wheel, Side));
         end loop;
      end loop;
   end Set_Turn;

   ---------------
   -- Set_Power --
   ---------------

   procedure Set_Power (Side : Side_Id;
                        Pwr  : Motor_Power)
                        renames Rover_HAL.Motors.Set_Power;

end Rover_HAL;
