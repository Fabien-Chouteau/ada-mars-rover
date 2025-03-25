with RP.GPIO; use RP.GPIO;
with Pico;
with Atomic.Critical_Section;

package body Rover_HAL.Sonar is

   Pin  : GPIO_Point renames Pico.GP6;

   Timeout : constant Time := Ticks_Per_Second / 1_000 * 50;

   --------------
   -- One_Shot --
   --------------

   function One_Shot return Natural is
      IE : Atomic.Critical_Section.Interrupt_State;
      T1, T2, T3, Tick : Time;
   begin
      Atomic.Critical_Section.Enter (IE);

      Configure (Pin, Output, Floating);
      Set (Pin);
      Rover_HAL.Delay_Microseconds (10);
      Clear (Pin);

      Configure (Pin, Input, Floating);

      T1 := Clock;

      while not Set (Pin) loop
         Tick := Clock;
         if Tick > T1 + Timeout then
            return 0;
         end if;
      end loop;
      T2 := Tick;

      while Set (Pin) loop
         Tick := Clock;
         if Tick > T2 + Timeout then
            return 0;
         end if;
      end loop;
      T3 := Tick;

      Atomic.Critical_Section.Leave (IE);

      if T3 <= T2 then
         return 0;
      else
         return Natural (T3 - T2);
      end if;
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
      return Natural (Raw_Cm);
   end Distance;

end Rover_HAL.Sonar;
