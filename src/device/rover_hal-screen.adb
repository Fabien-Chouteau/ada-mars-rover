with RP.GPIO;
with RP.I2C_Master;
with RP.Device;
with HAL; use HAL;
with HAL.I2C; use HAL.I2C;

package body Rover_HAL.Screen is

   I2C_SDA  : RP.GPIO.GPIO_Point := (Pin => 26);
   I2C_SCL  : RP.GPIO.GPIO_Point := (Pin => 27);
   I2C_Port : RP.I2C_Master.I2C_Master_Port renames RP.Device.I2CM_1;

   Left_Btn  : RP.GPIO.GPIO_Point := (Pin => 20);
   Right_Btn : RP.GPIO.GPIO_Point := (Pin => 21);

   Frame_Buffer : UInt8_Array (1 .. (Width * Height) / 8);

   SSD1306_I2C_Addr : constant := 16#78#;

   Font_Data : constant HAL.UInt8_Array (1 .. 412) :=
     [
      187, 214, 205, 231, 125, 253, 255, 255, 255, 141, 59, 130, 11, 38, 136,
      241, 255, 251, 123, 140, 17, 70, 12, 64, 116, 113, 56, 239, 92, 132,
      17, 70, 224, 156, 115, 14, 196, 30, 247, 207, 223, 255, 247, 239, 247,
      251, 246, 252, 255, 255, 255, 255, 255, 255, 255, 255, 207, 157, 255,
      174, 53, 176, 118, 239, 222, 251, 255, 127, 93, 118, 119, 250, 254,
      156, 203, 121, 255, 237, 156, 115, 206, 122, 239, 220, 190, 214, 19,
      231, 156, 115, 110, 59, 231, 156, 123, 189, 223, 250, 251, 247, 255,
      253, 245, 253, 255, 125, 255, 255, 255, 255, 127, 255, 255, 255, 255,
      125, 223, 191, 43, 208, 183, 222, 125, 213, 254, 255, 111, 179, 223,
      174, 208, 95, 231, 114, 238, 224, 190, 231, 156, 119, 222, 123, 183,
      175, 246, 138, 57, 231, 156, 223, 206, 185, 90, 111, 223, 215, 253,
      29, 101, 76, 113, 7, 153, 111, 219, 84, 70, 24, 74, 136, 206, 57, 230,
      64, 223, 183, 239, 95, 227, 222, 127, 223, 8, 62, 248, 91, 237, 123,
      237, 131, 59, 134, 255, 253, 127, 183, 1, 232, 29, 132, 2, 236, 203,
      189, 82, 14, 58, 24, 183, 115, 106, 239, 221, 247, 253, 255, 63, 230,
      141, 139, 142, 237, 91, 183, 98, 206, 185, 236, 183, 115, 110, 182, 235,
      247, 83, 251, 131, 213, 171, 223, 87, 237, 252, 255, 102, 123, 63, 240,
      220, 118, 47, 231, 14, 238, 86, 206, 121, 231, 189, 115, 251, 106, 239,
      140, 243, 74, 191, 237, 156, 170, 187, 247, 125, 255, 255, 193, 121, 7,
      118, 112, 251, 230, 173, 156, 131, 161, 199, 237, 156, 218, 115, 247,
      125, 239, 255, 21, 58, 246, 239, 222, 123, 255, 220, 221, 238, 238, 58,
      183, 221, 205, 123, 255, 253, 149, 115, 206, 122, 239, 220, 182, 214,
      59, 231, 188, 181, 110, 187, 74, 220, 246, 253, 222, 255, 191, 115, 206,
      249, 253, 220, 182, 117, 43, 231, 252, 235, 111, 153, 170, 242, 238,
      125, 223, 191, 127, 221, 79, 250, 215, 255, 239, 63, 247, 24, 65, 188,
      49, 238, 152, 127, 191, 191, 239, 232, 96, 196, 192, 7, 23, 179, 3, 206,
      69, 159, 92, 220, 113, 59, 183, 65, 188, 241, 131, 31, 98, 12, 113, 71,
      23, 115, 139, 202, 69, 255, 58, 188, 105, 87, 195, 193, 220, 249, 251];

   Font_W : constant := 470;
   Font_H : constant := 7;
   type Bit_Array is array (Positive range <>) of Boolean
     with Pack;

   Bit_Data : Bit_Array (1 .. Font_W * Font_H)
     with Address => Font_Data'Address;

   --------------
   -- Commands --
   --------------

   DEACTIVATE_SCROLL     : constant := 16#2E#;
   SET_CONTRAST          : constant := 16#81#;
   DISPLAY_ALL_ON_RESUME : constant := 16#A4#;
   --  DISPLAY_ALL_ON        : constant := 16#A5#;
   NORMAL_DISPLAY        : constant := 16#A6#;
   INVERT_DISPLAY        : constant := 16#A7#;
   DISPLAY_OFF           : constant := 16#AE#;
   DISPLAY_ON            : constant := 16#AF#;
   SET_DISPLAY_OFFSET    : constant := 16#D3#;
   SET_COMPINS           : constant := 16#DA#;
   SET_VCOM_DETECT       : constant := 16#DB#;
   SET_DISPLAY_CLOCK_DIV : constant := 16#D5#;
   SET_PRECHARGE         : constant := 16#D9#;
   SET_MULTIPLEX         : constant := 16#A8#;
   --  SET_LOW_COLUMN        : constant := 16#00#;
   --  SET_HIGH_COLUMN       : constant := 16#10#;
   SET_START_LINE        : constant := 16#40#;
   MEMORY_MODE           : constant := 16#20#;
   COLUMN_ADDR           : constant := 16#21#;
   PAGE_ADDR             : constant := 16#22#;
   --  COM_SCAN_INC          : constant := 16#C0#;
   COM_SCAN_DEC          : constant := 16#C8#;
   SEGREMAP              : constant := 16#A0#;
   CHARGE_PUMP           : constant := 16#8D#;

   -------------------
   -- Write_Command --
   -------------------

   procedure Write_Command (Cmd : UInt8)
   is
      Status : I2C_Status;
   begin

      I2C_Port.Mem_Write
        (SSD1306_I2C_Addr,
         0,
         HAL.I2C.Memory_Size_8b,
         [0 => Cmd],
         Status);

      if Status /= Ok then
         --  No error handling...
         raise Program_Error;
      end if;
   end Write_Command;

   ----------------
   -- Write_Data --
   ----------------

   procedure Write_Data (Data : UInt8_Array)
   is
      Status : I2C_Status;
   begin
      I2C_Port.Master_Transmit (Addr    => SSD1306_I2C_Addr,
                                Data    => Data,
                                Status  => Status);
      if Status /= Ok then
         --  No error handling...
         raise Program_Error;
      end if;
   end Write_Data;

   ----------------------
   -- Write_Raw_Pixels --
   ----------------------

   procedure Write_Raw_Pixels (Data : HAL.UInt8_Array)
   is
   begin
      Write_Command (COLUMN_ADDR);
      Write_Command (0);                   --  from
      Write_Command (UInt8 (Width - 1));  --  to

      Write_Command (PAGE_ADDR);
      Write_Command (0);                           --  from
      Write_Command (UInt8 (Height / 8) - 1); --  to

      Write_Data ([1 => 16#40#] & Data);
   end Write_Raw_Pixels;

   -----------------------
   -- Initialize_Screen --
   -----------------------

   procedure Initialize_Screen (External_VCC : Boolean := False)
   is
   begin

      Write_Command (DISPLAY_OFF);

      Write_Command (SET_DISPLAY_CLOCK_DIV);
      Write_Command (16#80#);

      Write_Command (SET_MULTIPLEX);
      Write_Command (UInt8 (Height - 1));

      Write_Command (SET_DISPLAY_OFFSET);
      Write_Command (16#00#);

      Write_Command (SET_START_LINE or 0);

      Write_Command (CHARGE_PUMP);
      Write_Command ((if External_VCC then 16#10# else 16#14#));

      Write_Command (MEMORY_MODE);
      Write_Command (16#00#);

      Write_Command (SEGREMAP or 1);

      Write_Command (COM_SCAN_DEC);

      Write_Command (SET_COMPINS);
      pragma Warnings (Off, "is always false");
      if Height > 32 then
         Write_Command (16#12#);
      else
         Write_Command (16#02#);
      end if;
      pragma Warnings (On, "is always false");

      Write_Command (SET_CONTRAST);
      Write_Command (16#8F#);

      Write_Command (SET_PRECHARGE);
      Write_Command ((if External_VCC then 16#22# else 16#F1#));

      Write_Command (SET_VCOM_DETECT);
      Write_Command (16#40#);

      Write_Command (DISPLAY_ALL_ON_RESUME);
      Write_Command (NORMAL_DISPLAY);
      Write_Command (DEACTIVATE_SCROLL);

      Write_Command (DISPLAY_ON);
   end Initialize_Screen;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      use RP.GPIO;

   begin
      I2C_SDA.Configure (Output, Pull_Up, RP.GPIO.I2C);
      I2C_SCL.Configure (Output, Pull_Up, RP.GPIO.I2C);
      I2C_Port.Configure
        (Baudrate =>  100_000,
         Address_Size =>  RP.I2C_Master.Address_Size_7b);

      Initialize_Screen;
      Update;

      Left_Btn.Configure (Input, Pull_Up);
      Right_Btn.Configure (Input, Pull_Up);

   end Initialize;

   ------------
   -- Update --
   ------------

   procedure Update is
   begin
      Write_Raw_Pixels (Frame_Buffer);
   end Update;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Frame_Buffer := [others => 0];
   end Clear;

   ---------------
   -- Set_Pixel --
   ---------------

   procedure Set_Pixel (X, Y : Natural; On : Boolean := True) is
      IX : constant Natural := Width - 1 - X;
      IY : constant Natural := Height - 1 - Y;
      Index : constant Natural := IX + (IY / 8) * Width;
      Byte  : UInt8 renames Frame_Buffer (Frame_Buffer'First + Index);
   begin

      if On then
         Byte := Byte or Shift_Left (1, IY mod 8);
      else
         Byte := Byte and not (Shift_Left (1, IY mod 8));
      end if;
   end Set_Pixel;

   -----------
   -- Print --
   -----------

   procedure Print (X_Offset    : Integer;
                    Y_Offset    : Integer;
                    C           : Character)
   is
      Index : constant Integer := Character'Pos (C) - Character'Pos ('!');
      Bitmap_Offset : constant Integer := Index * 5;

      function Color (X, Y : Integer) return Boolean;

      -----------
      -- Color --
      -----------

      function Color (X, Y : Integer) return Boolean is
      begin
         if Index in 0 .. 93 and then X in 0 .. 4 and then Y in 0 .. 6 then
            return not Bit_Data (1 + X + Bitmap_Offset + Y * Font_W);
         else
            return False;
         end if;
      end Color;

   begin
      Draw_Loop : for X in 0 .. 5 loop
         for Y in 0 .. 6 loop

            if Y + Y_Offset in 0 .. Screen.Height - 1 then
               if X + X_Offset > Screen.Width - 1 then
                  exit Draw_Loop;
               elsif X + X_Offset >= 0
                 and then
                   Y + Y_Offset in 0 .. Screen.Height - 1
               then
                  Screen.Set_Pixel (X + X_Offset,
                                    Y + Y_Offset,
                                    Color (X, Y));
               end if;
            end if;
         end loop;
      end loop Draw_Loop;
   end Print;

   -----------
   -- Print --
   -----------

   procedure Print (X_Offset    : Integer;
                    Y_Offset    : Integer;
                    Str         : String)
   is
      X : Integer := X_Offset;
   begin
      for C of Str loop
         Print (X, Y_Offset, C);
         X := X + Font_Width;
      end loop;
   end Print;


   ------------------
   -- Left_Pressed --
   ------------------

   function Left_Pressed return Boolean
   is (not Left_Btn.Set);

   -------------------
   -- Right_Pressed --
   -------------------

   function Right_Pressed return Boolean
   is (not Right_Btn.Set);

end Rover_HAL.Screen;
