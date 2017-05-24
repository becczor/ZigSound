library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--*****************************
--* INPUT_DATA_MNGR interface *
--*****************************

entity INPUT_DATA_MNGR is
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;
        -- KBD_ENC --
        key_code            : in unsigned(2 downto 0);
        --  CPU --
		curr_pos_out        : out signed(17 downto 0);
		next_pos_out        : out signed(17 downto 0);
		dly_cnt             : in unsigned(2 downto 0);
        change_track        : in std_logic;
        --  GPU --
		move_req_out        : out std_logic;
		upd_sound_icon_out  : out std_logic;
		disp_goal_pos_out   : out std_logic;
		move_resp           : in std_logic;
		--  SOUND --
		sel_sound_out       : out std_logic      
        );
end INPUT_DATA_MNGR;

architecture Behavioral of INPUT_DATA_MNGR is

    -- To GPU
    signal MOVE_REQ         : std_logic := '0';  -- Move request (move_req_out)
    signal UPD_SOUND_ICON   : std_logic := '0';  -- Signal for updating sound icon
    signal CURR_POS         : signed(17 downto 0) := "000000001000000001"; -- Current Position (curr_pos_out)
    signal NEXT_POS         : signed(17 downto 0) := "000000001000000001";  -- Next Postition (next_pos_out)
    signal DISP_GOAL_POS    : std_logic := '0'; -- Display goal pos on screen (disp_goal_pos_out)
    -- To SOUND
    signal SEL_SOUND        : std_logic := '0'; -- Sound select (sel_sound_out)

    alias CURR_XPOS         : signed(5 downto 0) is CURR_POS(14 downto 9);
    alias CURR_YPOS         : signed(4 downto 0) is CURR_POS(4 downto 0);
    alias NEXT_XPOS         : signed(5 downto 0) is NEXT_POS(14 downto 9);
    alias NEXT_YPOS         : signed(4 downto 0) is NEXT_POS(4 downto 0);

begin

    --*************************
    --* Keycode (PS2cmd) Interpretation *
    --*************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                CURR_POS <= "000000001000000001";
                NEXT_POS <= "000000001000000001";
                MOVE_REQ <= '0';
                UPD_SOUND_ICON <= '0';
                DISP_GOAL_POS <= '0';
                SEL_SOUND <= '0';
            else
                if (move_resp = '1') then
                    CURR_POS <= NEXT_POS;
                end if;
                UPD_SOUND_ICON <= '0';
                MOVE_REQ <= '0';
                -- We're changing track, send move_req back to start.
                if (dly_cnt = 0 and change_track = '1') then  
                    NEXT_POS <= "000000001000000001";
                    MOVE_REQ <= '1';
                -- Not in locked mode, check for key pressed.
                elsif (dly_cnt = 0) then
                    case key_code is
                        when "001" =>  -- UP (W)
                            NEXT_XPOS <= CURR_XPOS;
                            NEXT_YPOS <= CURR_YPOS - 1;
                            MOVE_REQ <= '1';
                        when "010" =>  -- LEFT (A)
                            NEXT_YPOS <= CURR_YPOS;
                            NEXT_XPOS <= CURR_XPOS - 1;
                            MOVE_REQ <= '1';
                        when "011" =>  -- DOWN (S)
                            NEXT_XPOS <= CURR_XPOS;
                            NEXT_YPOS <= CURR_YPOS + 1;
                            MOVE_REQ <= '1';
                        when "100" =>  -- RIGHT (D)
                            NEXT_YPOS <= CURR_YPOS;
                            NEXT_XPOS <= CURR_XPOS + 1;
                            MOVE_REQ <= '1';
                        when "101" => -- DISPLAY GOAL POS TOGGLE (G)
                            DISP_GOAL_POS <= not DISP_GOAL_POS;
                        when "110" => -- SOUND TOGGLE (SPACE)
                            SEL_SOUND <= not SEL_SOUND;
                            UPD_SOUND_ICON <= '1';
                        when others =>
                            null;
                    end case;
                -- In locked mode, don't check for key pressed.
                -- Time to update sound icon
                elsif (dly_cnt = 3) then
                    UPD_SOUND_ICON <= '1';
                -- Do nothing, GPU busy
                else    
                    null;
                end if;
            end if;
        end if;
    end process;
    
    upd_sound_icon_out <= UPD_SOUND_ICON;
    move_req_out <= MOVE_REQ;
    sel_sound_out <= SEL_SOUND;
    disp_goal_pos_out <= DISP_GOAL_POS;
    next_pos_out <= NEXT_POS;
    
end Behavioral;
