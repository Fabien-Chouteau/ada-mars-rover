with RP.GPIO;
with RP.Device;
with RP.I2C_Master;

package body Rover_HAL.I2C is

   I2C_SDA  : RP.GPIO.GPIO_Point := (Pin => 0);
   I2C_SCL  : RP.GPIO.GPIO_Point := (Pin => 1);
   I2C_Port : RP.I2C_Master.I2C_Master_Port renames RP.Device.I2CM_0;

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
   end Initialize;

   ---------------
   -- Mem_Write --
   ---------------

   procedure Mem_Write
     (Addr          : HAL.I2C.I2C_Address;
      Mem_Addr      : HAL.UInt16;
      Mem_Addr_Size : HAL.I2C.I2C_Memory_Address_Size;
      Data          : HAL.I2C.I2C_Data;
      Status        : out HAL.I2C.I2C_Status;
      Timeout       : Natural := 1000)
   is
   begin
      I2C_Port.Mem_Write
        (Addr, Mem_Addr, Mem_Addr_Size, Data, Status, Timeout);
   end Mem_Write;

   --------------
   -- Mem_Read --
   --------------

   procedure Mem_Read
     (Addr          : HAL.I2C.I2C_Address;
      Mem_Addr      : HAL.UInt16;
      Mem_Addr_Size : HAL.I2C.I2C_Memory_Address_Size;
      Data          : out HAL.I2C.I2C_Data;
      Status        : out HAL.I2C.I2C_Status;
      Timeout       : Natural := 1000)
   is
   begin
      I2C_Port.Mem_Read
        (Addr, Mem_Addr, Mem_Addr_Size, Data, Status, Timeout);
   end Mem_Read;

end Rover_HAL.I2C;
