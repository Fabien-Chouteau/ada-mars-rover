with RP.Device;
with RP.Timer;
with RP.GPIO; use RP.GPIO;
with Pico;

with Rover.HW;

package body Rover.Sonar with SPARK_Mode is

   Pin  : GPIO_Point renames Pico.GP3;

   use type RP.Timer.Time;
   Timeout : constant RP.Timer.Time := RP.Timer.Ticks_Per_Second / 1_000 * 50;
   --  The original definition used `RP.Timer.Milliseconds (50);`, but SPARK
   --  has no insight into how that value is computed, so we can't prove
   --  anything related to timeouts. To fix this, we'd need to make the
   --  definition of the `Milliseconds` expression function visible in the spec
   --  of `RP.Timer`.

   --------------
   -- One_Shot --
   --------------

   function One_Shot return Natural with
      Volatile_Function,
      Side_Effects,
      Global => (
         Input  => Rover.HW.HW_State,
         In_Out => (
            Pin,
            RP.Device.Timer))
   is
      T1, T2, T3 : RP.Timer.Time;
      Tick : RP.Timer.Time with Relaxed_Initialization;

      Pin_Set : Boolean;
   begin
      Rover.HW.Configure (Pin, Output, Floating);
      Pin_Set := Rover.HW.Is_Set (Pin);
      Rover.HW.Delay_Microseconds (RP.Device.Timer, 10);

      Rover.HW.Clear (Pin);
      Rover.HW.Configure (Pin, Input, Floating);
      T1 := Rover.HW.Clock;

      Pin_Set := False;
      while not Pin_Set loop
         Pin_Set := Rover.HW.Is_Set (Pin);
         Tick := Rover.HW.Clock;
         if Tick > T1 + Timeout then
            return 0;
         end if;
      end loop;
      T2 := Tick;

      Pin_Set := False;
      while not Pin_Set loop
         Pin_Set := Rover.HW.Is_Set (Pin);
         Tick := Rover.HW.Clock;
         if Tick > T2 + Timeout then
            return 0;
         end if;
      end loop;
      T3 := Tick;

      --  require monotonicity of calls to Clock, which is not actually
      --  guaranteed, since the timer could (eventually) wrap around - but
      --  practically speaking, this is not a concern.
      pragma Assume (T3 >= T2);
      return Natural (T3 - T2);
   end One_Shot;

   --------------
   -- Distance --
   --------------

   function Distance return Natural is
      Raw : Natural;
      Raw_Cm : Float;
   begin
      Raw := One_Shot;
      Raw_Cm := (Float (Raw) * 0.034) / 2.0;

      --  These pragmas allow the range check on the conversion to Natural to
      --  be proved at level=1. Without them, the check is unproved at any
      --  level. The difficulty here arises from the combination of
      --  floating-point and integer theories.
      pragma Assert (Raw_Cm >= 0.0);
      pragma Assert (Raw_Cm < Float (Integer'Last));
      return Natural (Raw_Cm);
   end Distance;

end Rover.Sonar;
