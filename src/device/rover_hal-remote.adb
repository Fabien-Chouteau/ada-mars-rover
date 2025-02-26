with HAL; use HAL;
with RP.GPIO; use RP.GPIO;
with Pico;
with RP.Timer;
with Rover_HAL.GUI;

package body Rover_HAL.Remote is

   CLK  : GPIO_Point renames Pico.GP18;
   Data : GPIO_Point renames Pico.GP19;
   Cmd  : GPIO_Point renames Pico.GP16;
   CS   : GPIO_Point renames Pico.GP17;
   Ack  : GPIO_Point renames Pico.GP20;

   CS_Delay_Us : constant := 15;
   Inter_Byte_Delay_Us : constant := 15;

   ------------------
   -- Busy_Wait_US --
   ------------------

   procedure Busy_Wait_US (Us : UInt32) is
      use type RP.Timer.Time;
   begin
      RP.Timer.Busy_Wait_Until (RP.Timer.Clock + RP.Timer.Time (Us));
   end Busy_Wait_US;

   ---------------
   -- Attention --
   ---------------

   procedure Attention is
   begin
      CS.Clear;
      Cmd.Clear;
      Busy_Wait_US (CS_Delay_Us);
   end Attention;

   ------------------
   -- No_Attention --
   ------------------

   procedure No_Attention is
   begin
      Busy_Wait_US (CS_Delay_Us);
      CS.Set;
      Cmd.Set;
      CLK.Set;
   end No_Attention;

   --------------
   -- Transfer --
   --------------

   procedure Transfer (Output :     UInt8;
                       Input  : out UInt8)
   is
   begin
      Input := 0;

      for X in 0 .. 7 loop
         CLK.Clear;
         if (Output and Shift_Left (UInt8 (1), X)) /= 0
         then
            Cmd.Set;
         else
            Cmd.Clear;
         end if;

         Busy_Wait_US (2);

         CLK.Set;
         Input := Input or Shift_Left ((if Data.Set
                                       then UInt8 (1)
                                       else UInt8 (0)),
                                       X);

         Busy_Wait_US (2);

      end loop;
      Cmd.Clear;
      Busy_Wait_US (Inter_Byte_Delay_Us);
   end Transfer;

   --------------
   -- Transfer --
   --------------

   procedure Transfer (Output :     UInt8_Array;
                       Input  : out UInt8_Array)
   is
   begin
      if Input'Length /= Output'Length then
         raise Program_Error;
      end if;

      Attention;

      for Cnt in 0 .. Input'Length - 1 loop
         Transfer (Output (Output'First + Cnt),
                   Input (Input'First + Cnt));
      end loop;

      No_Attention;
   end Transfer;

   ----------
   -- Test --
   ----------

   function Update return Buttons_State is
      Cmd : constant UInt8_Array := [16#01#, 16#42#, 16#00#, 16#00#, 16#00#];
      Data : UInt8_Array (1 .. Cmd'Length);
      Result : Buttons_State := [others => False];
   begin
      Transfer (Cmd, Data);

      if Data (1) /= 16#FF#
        or else
         Data (3) /= 16#5A#
      then
         return Result;
      end if;

      if (Data (5) and 16#20#) = 0 then
         Result (A) := True;
      end if;
      if (Data (5) and 16#40#) = 0 then
         Result (B) := True;
      end if;
      if (Data (5) and 16#80#) = 0 then
         Result (C) := True;
      end if;
      if (Data (5) and 16#10#) = 0 then
         Result (D) := True;
      end if;

      if (Data (4) and 16#80#) = 0 then
         Result (Left) := True;
      end if;
      if (Data (4) and 16#10#) = 0 then
         Result (Up) := True;
      end if;
      if (Data (4) and 16#20#) = 0 then
         Result (Right) := True;
      end if;
      if (Data (4) and 16#40#) = 0 then
         Result (Down) := True;
      end if;

      if (Data (5) and 16#08#) = 0 then
         Result (R1) := True;
      end if;
      if (Data (5) and 16#02#) = 0 then
         Result (R2) := True;
      end if;
      if (Data (5) and 16#04#) = 0 then
         Result (L1) := True;
      end if;
      if (Data (5) and 16#01#) = 0 then
         Result (L2) := True;
      end if;

      if (Data (4) and 16#01#) = 0 then
         Result (Sel) := True;
      end if;
      if (Data (4) and 16#08#) = 0 then
         Result (Start) := True;
      end if;

      GUI.Last_Remote_Packet := Data;
      return Result;
   end Update;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      CLK.Configure (Output, Pull_Up);
      Cmd.Configure (Output, Pull_Down);
      CS.Configure (Output, Pull_Up);

      Data.Configure (Input, Floating);
      Ack.Configure (Input, Floating);

      CLK.Set;
      Cmd.Clear;
      CS.Set;
   end Initialize;

end Rover_HAL.Remote;
