with Interfaces; use Interfaces;

package Rover_HAL
with
  Abstract_State => (HW_Init, (HW_State with Synchronous)),
  Initializes    => (HW_State),
  SPARK_Mode,
  Always_Terminates
is

   function Initialized return Boolean
     with Global => HW_Init;

   procedure Initialize
     with
       Global => (Output => HW_Init),
       Post   => Initialized;

   -----------
   -- Timer --
   -----------

   type Time is new Interfaces.Unsigned_64;
   Ticks_Per_Second : constant := 1_000_000;

   function Clock return Time with
     Pre => Initialized,
     Global => (HW_State, HW_Init),
     Volatile_Function;
   --  Monotonic clock running at Ticks_Per_Seconds

   function Milliseconds
     (T : Natural)
      return Time
   is ((Ticks_Per_Second / 1_000) * Time (T));
   --  Return the number of Time ticks per milliseconds

   procedure Delay_Microseconds (Us : Integer)
     with
       Pre => Initialized,
       Global => (HW_State, HW_Init);

   procedure Delay_Milliseconds (Ms : Integer)
     with
       Pre => Initialized,
       Global => (HW_State, HW_Init);

   -----------
   -- Sonar --
   -----------

   function Sonar_Distance return Natural
     with
       Pre => Initialized,
       Global => (HW_State, HW_Init),
       Side_Effects,
       Volatile_Function;

   ----------
   -- Mast --
   ----------

   type Mast_Angle is new  Interfaces.Integer_8 range -90 .. 90;

   procedure Set_Mast_Angle (V : Mast_Angle)
     with
       Pre  => Initialized,
       Post => Initialized,
       Global => (HW_State, HW_Init);

   ------------
   -- Remote --
   ------------

   type Buttons is (Up, Down, Left, Right,
                    A, B, C, D,
                    L1, L2, R1, R2,
                    Sel, Start);

   type Buttons_State is array (Buttons) of Boolean;
   --  True if the button is pressed

   function Update return Buttons_State
     with
       Pre  => Initialized,
       Global => (HW_State, HW_Init),
       Side_Effects,
       Volatile_Function;

   ------------
   -- Wheels --
   ------------

   type Side_Id is (Left, Right)
     with Size => 8;

   for Side_Id use (Left => 0,
                    Right => 1);

   type Wheel_Id is (Front, Back, Mid)
     with Size => 8;

   for Wheel_Id use (Front => 0,
                     Back  => 1,
                     Mid   => 2);

   subtype Steering_Wheel_Id is Wheel_Id range Front .. Back;

   type Steering_Wheel_Angle is new Interfaces.Integer_8 range -40 .. 40;

   procedure Set_Wheel_Angle (Wheel : Steering_Wheel_Id;
                              Side  : Side_Id;
                              V     : Steering_Wheel_Angle)
     with
       Pre  => Initialized,
       Post => Initialized,
       Global => (HW_State, HW_Init);

   type Turn_Kind is (Straight, Left, Right, Around)
     with Size => 8;
   for Turn_Kind use (Straight => 0,
                      Left => 1,
                      Right => 2,
                      Around => 3);

   procedure Set_Turn (Turn : Turn_Kind)
     with
       Pre  => Initialized,
       Post => Initialized,
       Global => (HW_State, HW_Init);

   type Motor_Power is new Interfaces.Integer_8 range -100 .. 100;

   procedure Set_Power (Side : Side_Id;
                        Pwr  : Motor_Power)
     with
       Pre  => Initialized,
       Post => Initialized,
       Global => (HW_State, HW_Init);

end Rover_HAL;
