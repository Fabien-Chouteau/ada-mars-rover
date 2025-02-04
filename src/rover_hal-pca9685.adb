with HAL; use HAL;
with HAL.I2C; use HAL.I2C;
with Rover_HAL.I2C; use Rover_HAL.I2C;

package body Rover_HAL.PCA9685 is

   PCA9685_Addr : constant := 16#40# * 2;

   PCA9685_MODE1_REG    : constant := 16#00#;
   --  PCA9685_MODE2_REG    : constant := 16#01#;
   --  PCA9685_SUBADR1_REG  : constant := 16#02#;
   --  PCA9685_SUBADR2_REG  : constant := 16#03#;
   --  PCA9685_SUBADR3_REG  : constant := 16#04#;
   --  PCA9685_ALLCALL_REG  : constant := 16#05#;
   PCA9685_LED0_REG     : constant := 16#06#;
   PCA9685_PRESCALE_REG : constant := 16#FE#;
   --  PCA9685_ALLLED_REG   : constant := 16#FA#;

   --  Mode1 register values
   MODE1_RESTART : constant := 16#80#;
   --  MODE1_EXTCLK  : constant := 16#40#;
   MODE1_AUTOINC : constant := 16#20#;
   MODE1_SLEEP   : constant := 16#10#;
   --  MODE1_SUBADR1 : constant := 16#08#;
   --  MODE1_SUBADR2 : constant := 16#04#;
   --  MODE1_SUBADR3 : constant := 16#02#;
   --  MODE1_ALLCALL : constant := 16#01#;

   --  Mode2 register values
   --  MODE2_OUTDRV_TPOLE : constant := 16#04#;
   --  MODE2_INVRT        : constant := 16#10#;
   --  MODE2_OUTNE_TPHIGH : constant := 16#01#;
   --  MODE2_OUTNE_HIGHZ  : constant := 16#02#;
   --  MODE2_OCH_ONACK    : constant := 16#08#;

   --------------------
   -- Write_Register --
   --------------------

   procedure Write_Register (Reg, Val : HAL.UInt8) is

      Status : HAL.I2C.I2C_Status;

   begin

      Mem_Write
        (Addr => PCA9685_Addr,
         Mem_Addr => HAL.UInt16 (Reg),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data => [1 => Val],
         Status => Status);

      if Status /= HAL.I2C.Ok then
         raise Program_Error;
      end if;
   end Write_Register;

   -------------
   -- Set_PWM --
   -------------

   procedure Set_PWM (Chan : Channel_Id; PWM : PWM_Range) is
      Reg : constant UInt8 := PCA9685_LED0_REG + UInt8 (Chan) * 4;
      Phase_Begin : constant UInt16 := 0;
      Phase_End   : constant UInt16 := UInt16 (PWM);

      Status : HAL.I2C.I2C_Status;

   begin

      Mem_Write
        (Addr => PCA9685_Addr,
         Mem_Addr => HAL.UInt16 (Reg),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data => [1 => UInt8 (Phase_Begin and 16#FF#),
                  2 => UInt8 (Shift_Right (Phase_Begin, 8) and 16#FF#),
                  3 => UInt8 (Phase_End and 16#FF#),
                  4 => UInt8 (Shift_Right (Phase_End, 8) and 16#FF#)],
         Status => Status);

      if Status /= HAL.I2C.Ok then
         raise Program_Error;
      end if;
   end Set_PWM;

   -------------------
   -- Set_Frequency --
   -------------------

   procedure Set_Frequency (Freq : Float) is
      Prescaler : Integer;
   begin

      if Freq <= 0.0 then
         return;
      end if;

      Prescaler := Integer (25_000_000.0 / (4096.0 * Freq)) - 1;
      Prescaler := Integer'Min (Prescaler, 255);
      Prescaler := Integer'Max (Prescaler, 3);

      Write_Register (PCA9685_MODE1_REG, MODE1_SLEEP); -- Sleep
      Write_Register (PCA9685_PRESCALE_REG, UInt8 (Prescaler));

      Write_Register (PCA9685_MODE1_REG, 0); -- Not Sleep
      Rover_HAL.Delay_Milliseconds (500);
   end Set_Frequency;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Set_Frequency (50.0);
      Write_Register (PCA9685_MODE1_REG, MODE1_RESTART or MODE1_AUTOINC);
   end Initialize;

end Rover_HAL.PCA9685;
