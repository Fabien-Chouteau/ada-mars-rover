with Rover.Autonomous;
with Rover.Remote_Controlled;

package body Rover.Tasks
with SPARK_Mode
is

   ----------
   -- Demo --
   ----------

   procedure Demo is
   begin
      Rover_HAL.Set_Power (Rover_HAL.Left, 100);

      --  Alternate between autonomous and remote controlled mode. Automous
      --  will run until a command is received from the remote, remote
      --  controlled will run as long as commands are received from the remote.
      loop
         Rover.Autonomous.Run;
         Rover.Remote_Controlled.Run;

         pragma Loop_Invariant (Rover.Cannot_Crash);
      end loop;
   end Demo;

end Rover.Tasks;
