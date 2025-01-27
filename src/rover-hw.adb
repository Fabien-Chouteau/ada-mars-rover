package body Rover.HW with SPARK_Mode => Off is
   function Is_Set (This : in out RP.GPIO.GPIO_Point) return Boolean is begin
      return This.Set;
   end Is_Set;

   procedure Configure
     (This      : in out RP.GPIO.GPIO_Point;
      Mode      : RP.GPIO.GPIO_Config_Mode;
      Pull      : RP.GPIO.GPIO_Pull_Mode := RP.GPIO.Floating;
      Func      : RP.GPIO.GPIO_Function := RP.GPIO.SIO;
      Schmitt   : Boolean := False;
      Slew_Fast : Boolean := False;
      Drive     : RP.GPIO.GPIO_Drive := RP.GPIO.Drive_4mA)
   is begin
      This.Configure (Mode, Pull, Func, Schmitt, Slew_Fast, Drive);
   end Configure;

   procedure Clear (This : in out RP.GPIO.GPIO_Point) is begin
      This.Clear;
   end Clear;

   procedure Delay_Microseconds
     (This : in out RP.Timer.Interrupts.Delays;
      Us   : Integer)
   is begin
      This.Delay_Microseconds (Us);
   end Delay_Microseconds;
end Rover.HW;
