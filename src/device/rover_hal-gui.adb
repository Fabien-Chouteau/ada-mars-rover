with Rover_HAL.Screen;

with RP.Flash;
with System.Storage_Elements; use System.Storage_Elements;
with Atomic.Critical_Section;

package body Rover_HAL.GUI is

   type Menu_Entries
   is (Sonar, Edit_FR, Edit_FL, Edit_BR, Edit_BL, Save, Load);

   Menu : Menu_Entries := Menu_Entries'First;
   Edit_Mode : Boolean := False;

   Prev_LB, Prev_RB : Boolean := False;
   Selected_Side : Side_Id := Side_Id'First;
   Selected_Wheel : Steering_Wheel_Id := Steering_Wheel_Id'First;

   Flash_Page_Offset : constant := 2 * 1024 * 1024 - RP.Flash.Sector_Size;
   --  Pick the last sector in the 2Mb flash of the Pico

   pragma Warnings
     (GNATprove, Off, "assuming no concurrent accesses to non-atomic object");
   Flash_Page : Storage_Array (1 .. RP.Flash.Page_Size)
     with
       Import,
       Address   => RP.Flash.To_Address (Flash_Page_Offset),
       Alignment => 8,
       Volatile;
   --  Place where data is located in Flash

   RAM_Page : Storage_Array (1 .. RP.Flash.Page_Size)
     with
       Alignment => 8,
       Volatile;
   --  Place in RAM to copy the page before writing

   type Magic_String is new String (1 .. 6);
   Magic_Keyword : constant Magic_String := "ROVER1";

   type Saved_Data is record
      Magic : Magic_String;
      FR, FL, BR, BL : PCA9685.PWM_Range;
   end record;

   In_Flash_Data : Saved_Data
     with Import, Address => Flash_Page'Address,
       Volatile;

   In_RAM_Data : Saved_Data
     with Import, Address => RAM_Page'Address,
       Volatile;

   ---------------------
   -- Load_From_Flash --
   ---------------------

   procedure Load_From_Flash is
   begin
      if In_Flash_Data.Magic = Magic_Keyword then
         --  We have valid data in flash

         Center (Front, Left) := In_Flash_Data.FL;
         Center (Front, Right) := In_Flash_Data.FR;
         Center (Back, Left) := In_Flash_Data.BL;
         Center (Back, Right) := In_Flash_Data.BR;
      end if;
   end Load_From_Flash;

   -------------------
   -- Save_To_Flash --
   -------------------

   procedure Save_To_Flash is
      use RP.Flash;
      Page_Offset : constant Flash_Offset :=
        To_Flash_Offset (Flash_Page'Address);

      Int_State : Atomic.Critical_Section.Interrupt_State;
   begin
      In_RAM_Data.Magic := Magic_Keyword;
      In_RAM_Data.FL := Center (Front, Left);
      In_RAM_Data.FR := Center (Front, Right);
      In_RAM_Data.BL := Center (Back, Left);
      In_RAM_Data.BR := Center (Back, Right);

      Atomic.Critical_Section.Enter (Int_State);
      RP.Flash.Erase (Page_Offset, Sector_Size);
      RP.Flash.Program (Page_Offset, In_RAM_Data'Address, Page_Size);
      Atomic.Critical_Section.Leave (Int_State);

   end Save_To_Flash;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Load_From_Flash;
   end Initialize;

   ------------------
   -- Flash_Vs_RAM --
   ------------------

   function Flash_Vs_RAM return String is
      FRD : constant Integer :=
        Integer (In_Flash_Data.FR) - Integer (Center (Front, Right));
      FLD : constant Integer :=
        Integer (In_Flash_Data.FL) - Integer (Center (Front, Left));
      BRD : constant Integer :=
        Integer (In_Flash_Data.BR) - Integer (Center (Back, Right));
      BLD : constant Integer :=
        Integer (In_Flash_Data.BL) - Integer (Center (Back, Left));
   begin
      return FRD'Img & FLD'Img & BRD'Img & BLD'Img;
   end Flash_Vs_RAM;

   ------------------
   -- RAM_Vs_Flash --
   ------------------

   function RAM_Vs_Flash return String is
      FRD : constant Integer :=
        Integer (Center (Front, Right)) - Integer (In_Flash_Data.FR);
      FLD : constant Integer :=
        Integer (Center (Front, Left)) - Integer (In_Flash_Data.FL);
      BRD : constant Integer :=
        Integer (Center (Back, Right)) - Integer (In_Flash_Data.BR);
      BLD : constant Integer :=
        Integer (Center (Back, Left)) - Integer (In_Flash_Data.BL);
   begin
      return FRD'Img & FLD'Img & BRD'Img & BLD'Img;
   end RAM_Vs_Flash;

   ------------------
   -- Remote_Debug --
   ------------------

   function Remote_Debug return String is
      use HAL;
      Res : String (1 .. Last_Remote_Packet'Length * 2);
      Idx : Natural := Res'First;

      function To_Hex (B : HAL.UInt4) return Character
      is (case B is
             when 0 => '0',
             when 1 => '1',
             when 2 => '2',
             when 3 => '3',
             when 4 => '4',
             when 5 => '5',
             when 6 => '6',
             when 7 => '7',
             when 8 => '8',
             when 9 => '9',
             when 10 => 'A',
             when 11 => 'B',
             when 12 => 'C',
             when 13 => 'D',
             when 14 => 'E',
             when 15 => 'F');
   begin
      for Elt of Last_Remote_Packet loop
         Res (Idx) := To_Hex (HAL.UInt4 (Elt / 2**4));
         Res (Idx + 1) := To_Hex (HAL.UInt4 (Elt and 2#1111#));
         Idx := @ + 1;
      end loop;

      return Res;
   end Remote_Debug;

   ------------
   -- Update --
   ------------

   procedure Update is
      use PCA9685;

      LB, RB : Boolean;
      L_Falling, R_Falling : Boolean;

      Wheel_Center : PWM_Range renames
        Center (Selected_Wheel, Selected_Side);

      Adjust_Step : constant := 5;

      Line1 : constant := (Screen.Font_Height + 2) * 0;
      Line2 : constant := (Screen.Font_Height + 2) * 1;
      Line3 : constant := (Screen.Font_Height + 2) * 2;
   begin
      Screen.Clear;

      LB := Screen.Left_Pressed;
      RB := Screen.Right_Pressed;
      L_Falling := LB and then not Prev_LB;
      R_Falling := RB and then not Prev_RB;

      if Edit_Mode then
         if (L_Falling and then RB) or else (R_Falling and then LB) then
            Edit_Mode := False;

         elsif L_Falling
           and then
             Wheel_Center >= PWM_Range'First + Adjust_Step
         then
            Wheel_Center := @ - Adjust_Step;

         elsif R_Falling and then
           Wheel_Center <= PWM_Range'Last - Adjust_Step
         then

            Wheel_Center := @ + Adjust_Step;
         end if;

      else
         if L_Falling then
            if Menu = Menu_Entries'Last then
               Menu := Menu_Entries'First;
            else
               Menu := Menu_Entries'Succ (Menu);
            end if;
         elsif R_Falling then
            case Menu is
               when Sonar =>
                  null;
               when Edit_FR =>
                  Selected_Wheel := Front;
                  Selected_Side := Right;
                  Edit_Mode := True;
               when Edit_FL =>
                  Selected_Wheel := Front;
                  Selected_Side := Left;
                  Edit_Mode := True;
               when Edit_BR =>
                  Selected_Wheel := Back;
                  Selected_Side := Right;
                  Edit_Mode := True;
               when Edit_BL =>
                  Selected_Wheel := Back;
                  Selected_Side := Left;
                  Edit_Mode := True;
               when Load =>
                  Load_From_Flash;
               when Save =>
                  Save_To_Flash;
            end case;
         end if;
      end if;

      if Edit_Mode then
         Screen.Print (0, Line1,
                       "  " & Selected_Wheel'Img & " " & Selected_Side'Img);
         Screen.Print (0, Line2, "(-) " &
                         Center (Selected_Wheel, Selected_Side)'Img & "  (+)");
      else
         Screen.Print (0, Line1, "> " &
                       (case Menu is
                             when Sonar => "Sonar:" & Last_Distance'Img & "cm",
                             when Edit_FR => "Front Right",
                             when Edit_FL => "Front Left",
                             when Edit_BR => "Back Right",
                             when Edit_BL => "Back Left",
                             when others => Menu'Img));

         Screen.Print
           (0, Line2, (case Menu is
               when Sonar => Display_Info,
               when Edit_FR => "Current:" & Center (Front, Right)'Img,
               when Edit_FL => "Current:" & Center (Front, Left)'Img,
               when Edit_BR => "Current:" & Center (Back, Right)'Img,
               when Edit_BL => "Current:" & Center (Back, Left)'Img,
               when Save => Center (Front, Right)'Img &
                            Center (Front, Left)'Img &
                            Center (Back, Right)'Img &
                            Center (Back, Left)'Img,
               when Load => In_Flash_Data.FR'Img &
                            In_Flash_Data.FL'Img &
                            In_Flash_Data.BR'Img &
                            In_Flash_Data.BL'Img));

         Screen.Print (0, Line3, (case Menu is
                          when Sonar => Remote_Debug,
                          when Edit_FR => "Saved:" & In_Flash_Data.FR'Img,
                          when Edit_FL => "Saved:" & In_Flash_Data.FL'Img,
                          when Edit_BR => "Saved:" & In_Flash_Data.BR'Img,
                          when Edit_BL => "Saved:" & In_Flash_Data.BL'Img,
                          when Save => Flash_Vs_RAM,
                          when Load => RAM_Vs_Flash));
      end if;

      Screen.Update;

      Prev_LB := LB;
      Prev_RB := RB;
   end Update;

end Rover_HAL.GUI;
