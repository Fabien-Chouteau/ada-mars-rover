
private package Rover_HAL.PCA9685 is

   type Channel_Id is range 0 .. 15;
   type PWM_Range is range 0 .. 4096;

   procedure Set_PWM (Chan : Channel_Id; PWM : PWM_Range);

   procedure Initialize;

end Rover_HAL.PCA9685;
