with RP.Timer;
with RP.Timer.Interrupts;
with RP.GPIO;

--  A SPARK-compatible interface to the Rover HW. Not a true abstraction as we
--  are exposing the underlying HW types and - ultimately - HW globals, some
--  of which we will have to list in our SPARK depends clauses.
package Rover.HW with
   Abstract_State => (HW_State with Synchronous),
   Initializes    => (HW_State),
   SPARK_Mode,
   Always_Terminates
is
   function Clock return RP.Timer.Time with
      Global => HW_State,
      Volatile_Function;
   --  Return the current value of the `RP.Timer.Clock`.

   function Is_Set (This : in out RP.GPIO.GPIO_Point) return Boolean with
      Global => HW_State,
      Volatile_Function,
      Side_Effects;
   --  Return True if the GPIO_Point is set, False otherwise.

   procedure Configure
     (This      : in out RP.GPIO.GPIO_Point;
      Mode      : RP.GPIO.GPIO_Config_Mode;
      Pull      : RP.GPIO.GPIO_Pull_Mode := RP.GPIO.Floating;
      Func      : RP.GPIO.GPIO_Function := RP.GPIO.SIO;
      Schmitt   : Boolean := False;
      Slew_Fast : Boolean := False;
      Drive     : RP.GPIO.GPIO_Drive := RP.GPIO.Drive_4mA)
   with
      Global => HW_State;
   --  Configure a GPIO_Point.

   procedure Clear (This : in out RP.GPIO.GPIO_Point) with
      Global => HW_State;
   --  Clear a GPIO_Point.

   procedure Delay_Microseconds
     (This : in out RP.Timer.Interrupts.Delays;
      Us   : Integer)
   with
      Global => HW_State;
   --  Delay for the specified number of microseconds.

private
   pragma SPARK_Mode (Off);

   function Clock return RP.Timer.Time is (RP.Timer.Clock);
end Rover.HW;
