package Rover.Sonar with SPARK_Mode is

   function Distance return Natural with
      Side_Effects,
      Volatile_Function;
   --  Return the detected distance in centimeter

end Rover.Sonar;
