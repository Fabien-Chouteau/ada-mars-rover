with Rover_HAL.PCA9685;

private package Rover_HAL.GUI is

   Center : array (Steering_Wheel_Id, Side_Id) of PCA9685.PWM_Range :=
     [Front => [Left =>  300,
                Right => 300],
      Back  => [Left =>  300,
                Right => 300]]
     with Atomic_Components;

   Last_Distance : Unsigned_32 := 0
     with Atomic;

   procedure Initialize;
   procedure Update;

end Rover_HAL.GUI;
