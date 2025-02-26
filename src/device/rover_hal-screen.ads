private package Rover_HAL.Screen is

   Width : constant := 128;
   Height : constant := 32;

   procedure Initialize;

   procedure Update;
   procedure Clear;
   procedure Set_Pixel (X, Y : Natural; On : Boolean := True);

   Font_Width : constant := 6;
   Font_Height : constant := 8;

   procedure Print (X_Offset    : Integer;
                    Y_Offset    : Integer;
                    C           : Character);

   procedure Print (X_Offset    : Integer;
                    Y_Offset    : Integer;
                    Str         : String);

   function Left_Pressed return Boolean;
   function Right_Pressed return Boolean;
end Rover_HAL.Screen;
