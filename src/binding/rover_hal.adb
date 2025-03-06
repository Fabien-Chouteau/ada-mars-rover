package body Rover_HAL
with
  SPARK_Mode => Off
is

   -----------------
   -- Initialized --
   -----------------

   function Initialized return Boolean is
   begin
      return True;
   end Initialized;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is null;

   -----------
   -- Timer --
   -----------

   function Clock return Time is
      function Clock_Import return Unsigned_64;
      pragma Import (C, Clock_Import, "mars_rover_clock");
   begin
      return Time (Clock_Import);
   end Clock;

   ------------------------
   -- Delay_Microseconds --
   ------------------------

   procedure Delay_Microseconds (Us : Unsigned_16) is
      procedure Delay_Microsecsonds_Inport (Us : Unsigned_16);
      pragma Import (C, Delay_Microsecsonds_Inport,
                     "mars_rover_delay_microseconds");
   begin
      Delay_Microsecsonds_Inport (Us);
   end Delay_Microseconds;

   ------------------------
   -- Delay_Milliseconds --
   ------------------------

   procedure Delay_Milliseconds (Ms : Unsigned_16) is
      procedure Delay_Milliseconds_Import (Ms : Unsigned_16);
      pragma Import (C, Delay_Milliseconds_Import,
                     "mars_rover_delay_milliseconds");
   begin
      Delay_Milliseconds_Import (Ms);
   end Delay_Milliseconds;

   -----------
   -- Sonar --
   -----------

   function Sonar_Distance return Unsigned_32 is
      function Sonar_Distance_Import return Unsigned_32;
      pragma Import (C, Sonar_Distance_Import, "mars_rover_sonar_distance");

   begin
      return Sonar_Distance_Import;
   end Sonar_Distance;

   ----------
   -- Mast --
   ----------

   procedure Set_Mast_Angle (V : Mast_Angle) is
      procedure Set_Mast_Angle_Import (V : Integer_8);
      pragma Import (C, Set_Mast_Angle_Import, "mars_rover_set_mast_angle");
   begin
      Set_Mast_Angle_Import (Integer_8 (V));
   end Set_Mast_Angle;

   ------------
   -- Remote --
   ------------

   function Update return Buttons_State is
      function Controller_State_Import return Unsigned_16;
      pragma Import (C, Controller_State_Import,
                     "mars_rover_controller_state");

      Raw : constant Unsigned_16 := Controller_State_Import;
      Result : Buttons_State;
   begin
      for B in Buttons loop
         Result (B) := (Raw and Unsigned_16 (2**Buttons'Pos (B))) /= 0;
      end loop;
      return Result;
   end Update;

   ------------
   -- Wheels --
   ------------

   procedure Set_Wheel_Angle (Wheel : Steering_Wheel_Id;
                              Side  : Side_Id;
                              V     : Steering_Wheel_Angle)
   is
      procedure Set_Wheel_Angle_Inport (Wheel : Unsigned_8;
                                        Side  : Unsigned_8;
                                        V     : Integer_8);
      pragma Import (C, Set_Wheel_Angle_Inport, "mars_rover_set_wheel_angle");
   begin
      Set_Wheel_Angle_Inport (Wheel'Enum_Rep, Side'Enum_Rep, Integer_8 (V));
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
   is
      procedure Set_Power_Import (Side : Unsigned_8;
                                  Pwr  : Integer_8);
      pragma Import (C, Set_Power_Import, "mars_rover_set_power");
   begin
      Set_Power_Import (Side'Enum_Rep, Integer_8 (Pwr));
   end Set_Power;

   ----------------------
   -- Set_Display_Info --
   ----------------------

   procedure Set_Display_Info (Str : String) is null;
   --  Display not available on the simulator
end Rover_HAL;
