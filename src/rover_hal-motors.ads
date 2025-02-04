private package Rover_HAL.Motors is

   procedure Set_Power (Side : Side_Id;
                        Pwr  : Motor_Power);

   procedure Initialize;

end Rover_HAL.Motors;
