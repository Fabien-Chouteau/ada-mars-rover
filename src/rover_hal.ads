with Interfaces; use Interfaces;

package Rover_HAL
with
  Abstract_State => (HW_Init,
                     (HW_State with Synchronous),
                     Power_State,
                     Turn_State),
  Initializes    => (HW_State, Power_State, Turn_State),
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
     (T : Unsigned_32)
      return Time
   is ((Ticks_Per_Second / 1_000) * Time (T));
   --  Return the number of Time ticks per milliseconds

   procedure Delay_Microseconds (Us : Unsigned_16)
     with
       Pre => Initialized,
       Global => (HW_State, HW_Init);

   procedure Delay_Milliseconds (Ms : Unsigned_16)
     with
       Pre => Initialized,
       Global => (HW_State, HW_Init);

   -----------
   -- Sonar --
   -----------

   function Sonar_Distance return Unsigned_32
     with
       Pre    => Initialized,
       Post   => Get_Sonar_Distance = Sonar_Distance'Result,
       Global => (HW_State, HW_Init),
       Side_Effects,
       Volatile_Function;

   function Get_Sonar_Distance return Unsigned_32
     with
      Pre    => Initialized,
      GLobal => (HW_Init),
      Ghost,
      Import;
   --  Return the value of the last Sonar Distance obtained by calling
   --  `Sonar_Distance`.

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
       Post => Initialized and then
               Get_Turn = Turn,
       Global => (Input  => (HW_State, HW_Init),
                  In_Out => Turn_State);

   function Get_Turn return Turn_Kind
     with
       Pre => Initialized,
       Global => (HW_Init, Turn_State),
       Ghost,
       Import;
   --  Return the value set in the last call to `Set_Turn`.

   type Motor_Power is new Interfaces.Integer_8 range -100 .. 100;

   pragma Unevaluated_Use_Of_Old (Allow);
   procedure Set_Power (Side : Side_Id;
                        Pwr  : Motor_Power)
     with
       Pre  => Initialized,
       Post => Initialized and then
               Get_Power (Side) = Pwr and then

               (if Side = Left then
                  Get_Power (Right) = Get_Power (Right)'Old
                else
                  Get_Power (Left) = Get_Power (Left)'Old),
       Global => (Input  => (HW_State, HW_Init),
                  In_Out => Power_State);
   pragma Unevaluated_Use_Of_Old (Error);

   function Get_Power (Side : Side_Id) return Motor_Power
     with
       Pre => Initialized,
       Global => (HW_Init, Power_State),
       Ghost,
       Import;
   --  Return the value set in the last call to `Set_Power`.

   -------------
   -- Display --
   -------------

   Display_Text_Length : constant := 128 / 7;

   procedure Set_Display_Info (Str : String)
     with Pre => Str'Length <= Display_Text_Length;

end Rover_HAL;
