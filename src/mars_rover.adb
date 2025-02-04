with Rover.Autonomous;
with Rover.Remote_Controlled;

with Rover_HAL;

procedure Mars_Rover
  with SPARK_Mode
is
begin

   Rover_HAL.Initialize;

   Rover_HAL.Set_Power (Rover_HAL.Left, 100);

   --  Alternate between autonomous and remote controlled mode. Automous will
   --  run until a command is received from the remote, remote controlled will
   --  run as long as commands are received from the remote.
   loop
      Rover.Autonomous.Run;
      Rover.Remote_Controlled.Run;
   end loop;

end Mars_Rover;
