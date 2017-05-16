--------------------------------------------------------------------------------
-- VGA MOTOR
-- ZigSound
-- 04-apr-2017
-- Version 0.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VGA_MOTOR is
    port (
    clk	    	    		    : in std_logic;
    rst		        		    : in std_logic;
    data		    		    : in unsigned(7 downto 0);
    goal_pos                    : in signed(17 downto 0);
    goal_reached                : in std_logic;
    showing_goal_msg_out        : out std_logic;
    disp_goal_pos               : in std_logic;
    addr		    		    : out unsigned(10 downto 0);
    vgaRed		        	    : out std_logic_vector(2 downto 0);
    vgaGreen	        	    : out std_logic_vector(2 downto 0);
    vgaBlue		        	    : out std_logic_vector(2 downto 1);
    Hsync		        	    : out std_logic;
    Vsync		        	    : out std_logic
    );
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is
    
    --alias goal_x : signed(6 downto 0) is goal_pos(15 downto 9);
    --alias goal_y : signed(5 downto 0) is goal_pos(5 downto 0);
    alias goal_x : signed(5 downto 0) is goal_pos(14 downto 9);
    alias goal_y : signed(4 downto 0) is goal_pos(4 downto 0);
    
    signal Xpixel	        : unsigned(9 downto 0);     -- Horizontal pixel counter
    signal Ypixel	        : unsigned(9 downto 0);		-- Vertical pixel counter
    signal ClkDiv	        : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
    signal Clk25			: std_logic;			    -- One pulse width 25 MHz signal
    signal pixel            : std_logic_vector(7 downto 0);	-- Tile pixel data
    signal tileAddr         : unsigned(12 downto 0);	-- Tile address
    signal blank            : std_logic;                -- blanking signal
    signal spriteAddrRb       : unsigned(10 downto 0);     -- The sprite addr
    signal isRbSprite       : std_logic;                -- '1' if VGA should show sprite '0' if tile
    signal sprite_x_offset_rb  : unsigned(9 downto 0);     -- xPixel - start of sprite x-position
    signal sprite_y_offset_rb  : unsigned(9 downto 0);     -- yPixel - start of y-position
    signal sprite_xstart_g    : unsigned(9 downto 0);
    signal sprite_xend_g      : unsigned(9 downto 0);
    signal sprite_ystart_g    : unsigned(9 downto 0);
    signal sprite_yend_g      : unsigned(9 downto 0);
    signal spriteAddrG        : unsigned(7 downto 0);
    signal isGoalSprite       : std_logic;
    
    signal sprite_y_offset_c  : unsigned(9 downto 0);     -- yPixel - start of y-position
    signal spriteAddrc       : unsigned(10 downto 0);     -- The sprite addr
    signal isCSprite           : std_logic;                -- '1' if VGA should show sprite '0' if tile
    
    
    -- signals for score
    signal x_s_limit    : unsigned(10 downto 0);     -- The limit of shown score in x-pos
    signal tileIndex    : unsigned(4 downto 0);
    signal score        : unsigned(4 downto 0) := "00000";
    -- Test animation
    signal time_cnt             : unsigned(20 downto 0);
    signal x_cnt                : unsigned(9 downto 0);       
    
    -- Sprite memory type
    type ram_s_r is array (0 to 2047) of std_logic_vector(7 downto 0);
    

    type ram_s_c is array (0 to 2047) of std_logic_vector(7 downto 0);

    type ram_s_goal is array (0 to 255) of std_logic_vector(7 downto 0);

    -- Sprite memory RAINBOW
    signal spriteMemRb : ram_s_r := 
    (
    x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"FC",x"FC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"54",x"54",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"EC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"54",x"54",x"5A",x"5A",x"54",x"54",x"54",x"54",x"54",x"FC",x"FC",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"5A",x"5A",x"5A",x"5A",x"5A",x"5A",x"5A",x"54",x"54",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"2A",x"2A",x"2A",x"2A",x"2A",x"5A",x"5A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"62",x"62",x"62",x"2A",x"2A",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"A6",x"A6",x"62",x"62",x"62",x"62",x"62",x"2A",x"5A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",x"A6",x"A6",x"A6",x"A6",x"A6",x"62",x"2A",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",x"EA",x"EA",x"EA",x"EA",x"EA",x"EA",x"A6",x"62",x"62",x"62",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"62",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"A6",x"62",x"62",x"2A",x"2A",x"5A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"EA",x"A6",x"A6",x"62",x"62",x"2A",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"A6",x"A6",x"62",x"62",x"62",x"62",x"2A",x"5A",x"5A",x"5A",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"A6",x"A6",x"A6",x"A6",x"62",x"2A",x"2A",x"2A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"EC",x"FC",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"EA",x"EA",x"A6",x"62",x"62",x"62",x"2A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"A6",x"62",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"EA",x"A6",x"62",x"62",x"2A",x"2A",x"2A",x"5A",x"54",x"FC",x"FC",x"FC",x"EC",x"E0",x"E0",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"62",x"62",x"62",x"2A",x"5A",x"54",x"54",x"54",x"FC",x"EC",x"E0",x"E0",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"EC",x"FC",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"62",x"A6",x"EA",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"A6",x"A6",x"A6",x"62",x"2A",x"5A",x"5A",x"5A",x"54",x"FC",x"EC",x"EC",x"E0",x"E0",x"FE",x"FE",
x"FE",x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"EA",x"A6",x"62",x"2A",x"2A",x"2A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",x"E0",x"FE",
x"FE",x"FE",x"FE",x"E0",x"EC",x"EC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"62",x"62",x"62",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"EC",x"E0",x"E0",x"FE",
x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"A6",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",x"FE",
x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"62",x"A6",x"EA",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"EA",x"A6",x"62",x"2A",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"EC",x"E0",x"FE",
x"FE",x"FE",x"E0",x"E0",x"EC",x"FC",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"62",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",
x"FE",x"FE",x"E0",x"EC",x"EC",x"FC",x"54",x"5A",x"2A",x"2A",x"62",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"62",x"2A",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"E0",x"E0",
x"FE",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"62",x"62",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"A6",x"62",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"EC",x"E0",x"E0",
x"FE",x"E0",x"E0",x"EC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"A6",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"62",x"2A",x"2A",x"5A",x"54",x"FC",x"EC",x"EC",x"E0",
x"FE",x"E0",x"E0",x"EC",x"FC",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"A6",x"62",x"62",x"2A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",
x"E0",x"E0",x"EC",x"EC",x"FC",x"54",x"5A",x"2A",x"2A",x"62",x"A6",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"A6",x"A6",x"62",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"E0",
x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"62",x"A6",x"EA",x"EA",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EA",x"EA",x"A6",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"EC",x"E0"

              
          );
          
               
    signal spriteMemGoal : ram_s_goal := 
    (     
    x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"E0",x"E0",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",
    x"FE",x"FE",x"FE",x"FE",x"FE",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FE",x"FE",x"FE",x"FE"
    );


signal spriteMemC : ram_s_c :=
(
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"FE",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"2C",x"FE",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"FE",x"2C",x"FE",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"2C",x"FE",x"FE",x"2C",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"FE",x"2C",x"2C",x"2C",x"FE",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"2C",x"2C",x"2C",x"FE",x"FE",x"FE",x"2C",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"2C",x"2C",x"2C",x"FE",x"2C",x"2C",x"2C",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EC",x"2C",x"2C",x"2C",x"2C",x"2C",x"FE",x"2C",x"FE",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"A8",x"EC",x"EC",x"2C",x"2C",x"2C",x"2C",x"2C",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"EC",x"EC",x"A8",x"EC",x"EC",x"EC",x"2C",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"A8",x"EC",x"EC",x"EC",x"EC",x"A8",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"A6",x"A6",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"FE",x"FE",x"FE",x"A6",x"A6",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"EC",x"A8",x"EC",x"EC",x"EC",x"A8",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A8",x"EC",x"EC",x"EC",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FE",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"EC",x"EC",x"EC",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FE",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A8",x"EC",x"EC",x"A8",x"EC",x"A8",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"EC",x"EC",x"EC",x"A8",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"EC",x"EC",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"EC",x"A8",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"EC",x"EC",x"EC",x"A8",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"00",x"00",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"EC",x"EC",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",
x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"A6",x"A6",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE",x"FE"
);


    

    -- Tile memory type
    type ram_t is array (0 to 2559) of std_logic_vector(7 downto 0);

    -- Tile memory
    -- There is room for 32 different tiles.
    signal tileMem : ram_t := 
        (
        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"00" GRASS
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",
        x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"BE",x"90",x"94",x"BE",x"DA",x"BE",x"94",
        x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"94",x"BE",x"90",x"90",x"BE",x"94",x"DA",x"DA",    
        x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"DA",x"94",x"DA",x"90",
        x"94",x"DA",x"94",x"94",x"94",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"94",x"DA",x"DA",x"94",x"DA",
        x"DA",x"90",x"90",x"DA",x"90",x"DA",x"90",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"94",x"DA",    
        x"BE",x"94",x"90",x"DA",x"94",x"90",x"BE",x"BE",x"DA",x"90",x"90",x"94",x"BE",x"BE",x"DA",x"94",
        x"BE",x"DA",x"DA",x"90",x"94",x"90",x"94",x"DA",x"BE",x"94",x"94",x"94",x"94",x"DA",x"DA",x"94",
        x"DA",x"DA",x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"90",x"DA",x"DA",x"94",x"94",x"90",x"DA",    
        x"90",x"94",x"DA",x"94",x"DA",x"BE",x"BE",x"94",x"90",x"90",x"94",x"DA",x"94",x"DA",x"90",x"DA",
        x"DA",x"90",x"DA",x"90",x"90",x"94",x"BE",x"DA",x"90",x"94",x"94",x"BE",x"DA",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"94",x"BE",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"94",x"94",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"BE",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",
        

        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"EA",    -- x"01" BLUINICORN  
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"EA",x"94",    -- WITH GRASS
        x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"02",x"02",x"02",x"EA",x"EA",x"BE",x"94",
        x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"02",x"02",x"9B",x"9B",x"9B",x"EA",x"DA",x"DA",
        x"DA",x"DA",x"02",x"90",x"DA",x"DA",x"BE",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"90",
        x"94",x"02",x"02",x"02",x"94",x"DA",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"DA",
        x"DA",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"DA",
        x"BE",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"BE",x"DA",x"94",
        x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"DA",x"DA",x"94",
        x"02",x"02",x"90",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"94",x"90",x"DA",
        x"90",x"94",x"DA",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"DA",x"90",x"DA",
        x"DA",x"90",x"DA",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"DA",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"9B",x"9B",x"94",x"BE",x"DA",x"DA",x"DA",x"9B",x"9B",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"9B",x"9B",x"90",x"DA",x"94",x"DA",x"DA",x"9B",x"9B",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"9B",x"9B",x"94",x"DA",x"94",x"94",x"DA",x"9B",x"9B",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"02",x"02",x"94",x"90",x"DA",x"BE",x"BE",x"02",x"02",x"DA",x"BE",x"BE",x"90",

        
        x"BE",x"BE",x"94",x"BE",x"94",x"96",x"96",x"BE",x"BE",x"DA",x"96",x"DA",x"DA",x"DA",x"90",x"90",    -- x"02" TREE 1
        x"90",x"DA",x"DA",x"96",x"96",x"1A",x"1A",x"96",x"96",x"96",x"1A",x"12",x"12",x"BE",x"DA",x"94",    -- WITH GRASS
        x"94",x"BE",x"BE",x"10",x"10",x"96",x"96",x"1A",x"10",x"1A",x"96",x"1A",x"18",x"12",x"BE",x"94",
        x"94",x"94",x"96",x"10",x"96",x"18",x"96",x"10",x"1A",x"96",x"10",x"18",x"1A",x"D6",x"12",x"DA",            
        x"DA",x"96",x"10",x"1A",x"1A",x"96",x"10",x"18",x"96",x"D6",x"18",x"1A",x"18",x"12",x"DA",x"90",
        x"94",x"10",x"10",x"96",x"96",x"D6",x"10",x"18",x"10",x"10",x"D6",x"18",x"1A",x"D6",x"12",x"DA",
        x"DA",x"96",x"10",x"10",x"10",x"10",x"D6",x"10",x"18",x"18",x"10",x"1A",x"18",x"18",x"18",x"12",
        x"BE",x"10",x"96",x"10",x"D6",x"10",x"10",x"1A",x"1A",x"10",x"1A",x"18",x"1A",x"1A",x"18",x"12",
        x"10",x"96",x"1A",x"1A",x"10",x"10",x"1A",x"18",x"1A",x"18",x"18",x"1A",x"10",x"18",x"12",x"94",
        x"DA",x"10",x"10",x"10",x"D0",x"D6",x"18",x"18",x"18",x"18",x"1A",x"10",x"18",x"18",x"1A",x"12",
        x"90",x"94",x"10",x"10",x"DA",x"D0",x"D0",x"18",x"1A",x"D0",x"1A",x"18",x"18",x"12",x"12",x"DA",
        x"DA",x"90",x"10",x"90",x"90",x"D0",x"D0",x"18",x"D0",x"12",x"18",x"12",x"12",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"94",x"D0",x"D0",x"DA",x"DA",x"12",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"D0",x"D0",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"D0",x"D0",x"D0",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"D0",x"D0",x"D0",x"D0",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",
        
        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"96",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",  -- x"03" TREE 2
        x"90",x"DA",x"DA",x"94",x"96",x"96",x"12",x"96",x"1A",x"96",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",  -- WITH GRASS
        x"94",x"BE",x"96",x"12",x"18",x"12",x"D6",x"12",x"96",x"12",x"1A",x"12",x"BE",x"1A",x"BE",x"94",
        x"94",x"96",x"96",x"12",x"18",x"18",x"96",x"12",x"18",x"18",x"12",x"1A",x"12",x"1A",x"DA",x"DA",
        x"DA",x"96",x"12",x"18",x"96",x"18",x"12",x"18",x"1A",x"12",x"18",x"D6",x"1A",x"18",x"DA",x"90",
        x"96",x"12",x"96",x"18",x"D6",x"12",x"1A",x"1A",x"12",x"18",x"D6",x"1A",x"19",x"DA",x"94",x"DA",
        x"12",x"18",x"18",x"D6",x"96",x"96",x"18",x"12",x"12",x"1A",x"12",x"18",x"18",x"1A",x"94",x"DA",
        x"96",x"96",x"12",x"96",x"18",x"18",x"1A",x"D6",x"1A",x"12",x"18",x"18",x"1A",x"12",x"1A",x"94",
        x"BE",x"96",x"12",x"12",x"1A",x"1A",x"18",x"1A",x"1A",x"18",x"1A",x"1A",x"12",x"1A",x"DA",x"94",
        x"DA",x"DA",x"96",x"12",x"18",x"18",x"18",x"1A",x"18",x"1A",x"18",x"1A",x"12",x"1A",x"90",x"DA",
        x"90",x"94",x"12",x"94",x"1A",x"1A",x"1A",x"D0",x"1A",x"D0",x"D0",x"1A",x"18",x"DA",x"90",x"DA",
        x"DA",x"90",x"DA",x"90",x"90",x"1A",x"BE",x"D0",x"D0",x"D0",x"1A",x"18",x"1A",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"94",x"D0",x"D0",x"D0",x"DA",x"94",x"1A",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"D0",x"D0",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"D0",x"D0",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"D0",x"D0",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",

        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"92",x"B6",x"B6",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",  -- x"04" ROCK
        x"90",x"DA",x"DA",x"94",x"90",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"DA",x"BE",x"BE",x"DA",x"94",  -- WITH GRASS
        x"94",x"BE",x"92",x"B6",x"BE",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"BE",x"DA",x"BE",x"94",
        x"94",x"94",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"94",x"DA",x"DA",
        x"DA",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"DA",x"90",
        x"94",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"DA",
        x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"DA",
        x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"92",x"B6",
        x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",
        x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"92",x"B6",x"92",x"B6",x"B6",
        x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"94",
        x"DA",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"DA",
        x"DA",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"94",
        x"90",x"DA",x"DA",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"BE",x"BE",x"90",      
        
        x"BE",x"BE",x"94",x"BE",x"94",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"DA",x"DA",x"90",x"90", -- x"05" TOGGLE CURRPOS
        x"90",x"DA",x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"DA",x"94",
        x"94",x"BE",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"94",
        x"94",x"94",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"DA",x"DA",
        x"DA",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"90",    
        x"94",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",
        x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",
        x"BE",x"94",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"94",
        x"BE",x"DA",x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"DA",x"94",
        x"DA",x"DA",x"90",x"90",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"94",x"94",x"90",x"DA",
        x"90",x"94",x"DA",x"94",x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"94",x"DA",x"90",x"DA",    
        x"DA",x"90",x"DA",x"90",x"90",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"DA",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"E0",x"E0",x"E0",x"E0",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"E0",x"E0",x"E0",x"E0",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"E0",x"E0",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",       
        
        x"D6",x"D6",x"92",x"92",x"92",x"96",x"9A",x"D6",x"D6",x"96",x"9A",x"96",x"96",x"96",x"9A",x"9A",    -- x"06" TOGGLE GOALPOS
        x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
        x"9A",x"9A",x"96",x"D6",x"96",x"96",x"9A",x"96",x"D6",x"D6",x"96",x"96",x"96",x"D6",x"D6",x"D6",

        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"2C",x"DA",x"2C",x"DA",x"2C",x"2C",x"90",x"2C",    -- x"07" CARROT 
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"2C",x"2C",x"DA",x"2C",x"2C",x"BE",x"DA",x"2C",    -- WITH GRASS
        x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"2C",x"BE",x"2C",x"94",x"BE",x"2C",x"2C",x"2C",
        x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"EC",x"2C",x"2C",x"2C",x"2C",x"BE",x"2C",x"DA",x"DA",
        x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"A8",x"EC",x"2C",x"2C",x"DA",x"2C",x"94",x"DA",x"2C",
        x"94",x"DA",x"94",x"94",x"94",x"DA",x"EC",x"EC",x"EC",x"A8",x"2C",x"2C",x"2C",x"2C",x"2C",x"2C",
        x"DA",x"90",x"90",x"DA",x"90",x"A8",x"EC",x"EC",x"EC",x"EC",x"EC",x"2C",x"2C",x"BE",x"94",x"DA",
        x"BE",x"94",x"90",x"DA",x"94",x"EC",x"EC",x"EC",x"A8",x"EC",x"EC",x"EC",x"BE",x"BE",x"DA",x"94",
        x"BE",x"DA",x"DA",x"90",x"A8",x"EC",x"EC",x"EC",x"EC",x"A8",x"EC",x"94",x"94",x"DA",x"DA",x"94",
        x"DA",x"DA",x"90",x"EC",x"EC",x"A8",x"EC",x"EC",x"EC",x"90",x"DA",x"DA",x"94",x"94",x"90",x"DA",
        x"90",x"94",x"A8",x"EC",x"EC",x"EC",x"EC",x"EC",x"A8",x"90",x"94",x"DA",x"94",x"DA",x"90",x"DA",
        x"DA",x"90",x"EC",x"A8",x"EC",x"EC",x"EC",x"DA",x"90",x"94",x"94",x"BE",x"DA",x"DA",x"94",x"94",
        x"DA",x"EC",x"EC",x"EC",x"EC",x"EC",x"BE",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"EC",x"A8",x"EC",x"EC",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"EC",x"EC",x"EC",x"A8",x"DA",x"94",x"DA",x"94",x"94",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"EC",x"EC",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"BE",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",

        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"07" AUTUMN GRASS
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",
        x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"BE",x"90",x"94",x"BE",x"DA",x"BE",x"94",
        x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"94",x"BE",x"90",x"90",x"BE",x"94",x"DA",x"DA",    
        x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"DA",x"94",x"DA",x"90",
        x"94",x"DA",x"94",x"94",x"94",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"94",x"DA",x"DA",x"94",x"DA",
        x"DA",x"90",x"90",x"DA",x"90",x"DA",x"90",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"94",x"DA",    
        x"BE",x"94",x"90",x"DA",x"94",x"90",x"BE",x"BE",x"DA",x"90",x"90",x"94",x"BE",x"BE",x"DA",x"94",
        x"BE",x"DA",x"DA",x"90",x"94",x"90",x"94",x"DA",x"BE",x"94",x"94",x"94",x"94",x"DA",x"DA",x"94",
        x"DA",x"DA",x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"90",x"DA",x"DA",x"94",x"94",x"90",x"DA",    
        x"90",x"94",x"DA",x"94",x"DA",x"BE",x"BE",x"94",x"90",x"90",x"94",x"DA",x"94",x"DA",x"90",x"DA",
        x"DA",x"90",x"DA",x"90",x"90",x"94",x"BE",x"DA",x"90",x"94",x"94",x"BE",x"DA",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"94",x"BE",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"94",x"94",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"BE",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",

        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"08" GRASS
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",
        x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"BE",x"90",x"94",x"BE",x"DA",x"BE",x"94",
        x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"94",x"BE",x"90",x"90",x"BE",x"94",x"DA",x"DA",    
        x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"DA",x"94",x"DA",x"90",
        x"94",x"DA",x"94",x"94",x"94",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"94",x"DA",x"DA",x"94",x"DA",
        x"DA",x"90",x"90",x"DA",x"90",x"DA",x"90",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"94",x"DA",    
        x"BE",x"94",x"90",x"DA",x"94",x"90",x"BE",x"BE",x"DA",x"90",x"90",x"94",x"BE",x"BE",x"DA",x"94",
        x"BE",x"DA",x"DA",x"90",x"94",x"90",x"94",x"DA",x"BE",x"94",x"94",x"94",x"94",x"DA",x"DA",x"94",
        x"DA",x"DA",x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"90",x"DA",x"DA",x"94",x"94",x"90",x"DA",    
        x"90",x"94",x"DA",x"94",x"DA",x"BE",x"BE",x"94",x"90",x"90",x"94",x"DA",x"94",x"DA",x"90",x"DA",
        x"DA",x"90",x"DA",x"90",x"90",x"94",x"FF",x"DA",x"90",x"94",x"94",x"BE",x"DA",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"94",x"FF",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"94",x"94",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"BE",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",

        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"09" GRASS
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",
        x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"BE",x"90",x"94",x"BE",x"DA",x"BE",x"94",
        x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"94",x"BE",x"90",x"90",x"BE",x"94",x"DA",x"DA",    
        x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"DA",x"94",x"DA",x"90",
        x"94",x"DA",x"94",x"94",x"94",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"94",x"DA",x"DA",x"94",x"DA",
        x"DA",x"90",x"90",x"DA",x"90",x"DA",x"90",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"94",x"DA",    
        x"BE",x"94",x"90",x"DA",x"94",x"90",x"BE",x"BE",x"DA",x"90",x"90",x"94",x"BE",x"BE",x"DA",x"94",
        x"BE",x"DA",x"DA",x"90",x"94",x"90",x"94",x"DA",x"BE",x"94",x"94",x"94",x"94",x"DA",x"DA",x"94",
        x"DA",x"DA",x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"90",x"DA",x"DA",x"94",x"94",x"90",x"DA",    
        x"90",x"94",x"DA",x"94",x"DA",x"BE",x"BE",x"94",x"90",x"90",x"94",x"DA",x"94",x"DA",x"90",x"DA",
        x"DA",x"90",x"DA",x"90",x"90",x"94",x"FF",x"DA",x"90",x"94",x"94",x"BE",x"DA",x"DA",x"94",x"94",
        x"DA",x"94",x"90",x"94",x"90",x"94",x"FF",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"DA",
        x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"94",x"94",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"BE",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90"
        );
  
begin
    showing_goal_msg_out <= '1';

    -- Clock divisor
    -- Divide system clock (100 MHz) by 4
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            ClkDiv <= (others => '0');
        else
            ClkDiv <= ClkDiv + 1;
        end if;
    end if;
    end process;

    -- 25 MHz clock (one system clock pulse width)
    Clk25 <= '1' when (ClkDiv = 3) else '0';



    --- testing animation thing
    --- slows the speed of time_cnt
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then -- or goal_reached = '0'
            time_cnt <= (others => '0');
        else --if (goal_reached = '1') then
            time_cnt <= time_cnt + 1;
        --else
        --    null;
        end if;
    end if;
    end process;
    
    
    
    --- testing animation thing
    --- 
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            x_cnt <= to_unsigned(192,10); -- Start x-cord
        elsif x_cnt = to_unsigned(448,10) then
            null;
        elsif time_cnt = "1111111111111111111" then -- Stop counter     
            x_cnt <= x_cnt + 1;
        else
            null;
        end if;
    end if;
    end process;

    

    -- 25 MHz clock (one system clock pulse width)
    Clk25 <= '1' when (ClkDiv = 3) else '0';


	
    -- Horizontal pixel counter

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Xpixel                         *
    -- *                                 *
    -- ***********************************
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Xpixel <= (others => '0');
        elsif Clk25 = '1' then
		    if Xpixel = 799 then	-- vi har nått slutet av pixelantalet
			    Xpixel <= (others => '0');
		    else
			    Xpixel <= Xpixel + 1;
		    end if;
	    end if;
    end if;
    end process;
	



    -- Horizontal sync

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Hsync                          *
    -- *                                 *
    -- ***********************************

    Hsync <=  '0' when ((Xpixel > 655) and (Xpixel <= 751)) else '1'; 

    -- Vertical pixel counter

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Ypixel                         *
    -- *                                 *
    -- ***********************************
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
	        Ypixel <= (others => '0');
        elsif Clk25 = '1' and Xpixel = 799 then
            if Ypixel = 520 then	-- vi har nått slutet av pixelantalet
	            Ypixel <= (others => '0');
            else 
	            Ypixel <= Ypixel + 1;
            end if;
        end if;
    end if;
    end process;


    -- Vertical sync

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Vsync                          *
    -- *                                 *
    -- ***********************************

    Vsync <= '0' when ((Ypixel > 489) and (Ypixel <= 491)) else '1';

    -- Video blanking signal

    -- ***********************************
    -- *                                 *
    -- *  VHDL for :                     *
    -- *  Blank                          *
    -- *                                 *
    -- ***********************************

    blank <= '1' when ((Xpixel > 639 and Xpixel <= 799) or (Ypixel > 479 and Ypixel <= 520)) else '0';

    isRbSprite <= '1' when ((Xpixel > 192 and Xpixel < x_cnt) and (Ypixel > 100 and Ypixel < 228) and not (spriteMemRb(to_integer(spriteAddrRb)) = x"FE")) else '0';  -- ÄNDRA EFTER SOTRLEK
    
    isCSprite <= '1' when ((Xpixel > 192 and Xpixel < 448 and x_cnt = to_unsigned(448,10)) and (Ypixel > 240 and Ypixel < 368) and not (spriteMemC(to_integer(spriteAddrC)) = x"FE")) else '0';  -- ÄNDRA EFTER SOTRLEK

    
    isGoalSprite <= '1' when ((Xpixel > sprite_xstart_g and Xpixel < sprite_xend_g) and (Ypixel > sprite_ystart_g and Ypixel < sprite_yend_g) and not (spriteMemGoal(to_integer(spriteAddrG)) = x"FE")) else '0';

    -- Tile memory
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            pixel <= (others => '0');
        elsif (isCSprite = '1') then
            pixel <= spriteMemC(to_integer(spriteAddrC));
        elsif (isRbSprite = '1' and goal_reached = '1') then
            pixel <= spriteMemRb(to_integer(spriteAddrRb));    
        elsif (isGoalSprite ='1' and disp_goal_pos = '1') then 
            pixel <= spriteMemGoal(to_integer(spriteAddrG));
        elsif (blank = '0') then
            pixel <= tileMem(to_integer(tileAddr));
        else
            pixel <= (others => '0');
        end if;
    end if;
    end process;



    -- Sets the offset of x and y pixel coords for sprite-drawing. 
    -- Sprite starts at 300 and 200 
    sprite_x_offset_rb <= Xpixel - to_unsigned(192,10);
    sprite_y_offset_rb <= Ypixel - to_unsigned(100,10);
    sprite_y_offset_c <= Ypixel - to_unsigned(240,10);

    -- chooses the tile index 
    x_s_limit <= score * to_unsigned(16,5);
    tileIndex <= x"05" when ((Xpixel > 0 and Xpixel < x_s_limit) and (Ypixel > 464 and Ypixel < 480)) else unsigned(data(4 downto 0));

    -- Calculates goal coordinates in pixels
    -- FIX NOT RIGHT!
    sprite_xstart_g <= to_unsigned(16 * to_integer(unsigned(goal_x)), 10); 
    sprite_xend_g <= to_unsigned(16 * (to_integer(unsigned(goal_x)) + 1), 10);
    sprite_ystart_g <= to_unsigned(16 * to_integer(unsigned(goal_y)), 10); 
    sprite_yend_g <= to_unsigned(16 * (to_integer(unsigned(goal_y)) + 1),10);


--goal_pos(14 downto 9));
--    alias goal_y : unsigned(4 downto 0) is unsigned(goal_pos(4 downto 0));
    

    -- Tile memory address composite
    tileAddr <= tileIndex & Ypixel(3 downto 0) & Xpixel(3 downto 0);
    spriteAddrRb <= sprite_y_offset_rb(6 downto 2) & sprite_x_offset_rb(7 downto 2); --Ändras när vi ändrar spriteMem
    --spritePixel <= spriteMem(to_integer(spriteAddr));
    

    spriteAddrC <= sprite_y_offset_c(6 downto 2) & sprite_x_offset_rb(7 downto 2); --Ändras när vi ändrar spriteMem

    spriteAddrG <= Ypixel(3 downto 0) & Xpixel(3 downto 0);


    -- Picture memory address composite
    --addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);
    addr <= to_unsigned(40, 6) * Ypixel(8 downto 4) + Xpixel(9 downto 4);


    -- VGA generation
    vgaRed(2) <= pixel(7);
    vgaRed(1) <= pixel(6);
    vgaRed(0) <= pixel(5);
    vgaGreen(2) <= pixel(4);
    vgaGreen(1) <= pixel(3);
    vgaGreen(0) <= pixel(2);
    vgaBlue(2) <= pixel(1);
    vgaBlue(1) <= pixel(0);


end Behavioral;




    
    --x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"00" GRASS (OK)
    --x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",    -- MINDRE VILD
    --x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"BE",x"90",x"94",x"BE",x"DA",x"BE",x"94",
    --x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"94",x"BE",x"90",x"90",x"BE",x"94",x"DA",x"DA",    
    --x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"DA",x"94",x"DA",x"90",
    --x"94",x"DA",x"94",x"94",x"94",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"94",x"DA",x"DA",x"94",x"DA",
    --x"DA",x"90",x"90",x"DA",x"90",x"DA",x"90",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"94",x"DA",    
    --x"BE",x"94",x"90",x"DA",x"94",x"90",x"BE",x"BE",x"DA",x"90",x"90",x"94",x"BE",x"BE",x"DA",x"94",
    --x"BE",x"DA",x"DA",x"90",x"94",x"90",x"94",x"DA",x"BE",x"94",x"94",x"94",x"94",x"DA",x"DA",x"94",
    --x"DA",x"DA",x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"90",x"DA",x"DA",x"94",x"94",x"90",x"DA",    
    --x"90",x"94",x"DA",x"94",x"DA",x"BE",x"BE",x"94",x"90",x"90",x"94",x"DA",x"94",x"DA",x"90",x"DA",
    --x"DA",x"90",x"DA",x"90",x"90",x"94",x"BE",x"DA",x"90",x"94",x"94",x"BE",x"DA",x"DA",x"94",x"94",
    --x"DA",x"94",x"90",x"94",x"90",x"94",x"BE",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"DA",
    --x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
    --x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"94",x"94",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
    --x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"BE",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",
    
    --x"BE",x"BE",x"94",x"94",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"00" GRASS (OK)
    --x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",    -- VILD
    --x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"BE",x"90",x"94",x"BE",x"DA",x"BE",x"94",
    --x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"94",x"BE",x"90",x"90",x"BE",x"94",x"DA",x"DA",    
    --x"DA",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"DA",x"94",x"DA",x"90",
    --x"94",x"DA",x"94",x"94",x"94",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"94",x"DA",x"DA",x"94",x"DA",
    --x"DA",x"90",x"90",x"DA",x"90",x"DA",x"90",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"BE",x"94",x"DA",    
    --x"BE",x"DA",x"90",x"DA",x"94",x"90",x"94",x"BE",x"DA",x"90",x"90",x"94",x"DA",x"BE",x"DA",x"DA",
    --x"BE",x"DA",x"DA",x"DA",x"94",x"90",x"94",x"DA",x"BE",x"94",x"DA",x"94",x"94",x"DA",x"DA",x"94",
    --x"DA",x"DA",x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"DA",x"DA",x"DA",x"DA",x"94",x"90",x"DA",    
    --x"90",x"DA",x"DA",x"DA",x"DA",x"BE",x"BE",x"94",x"90",x"94",x"DA",x"DA",x"94",x"DA",x"90",x"DA",
    --x"DA",x"90",x"DA",x"DA",x"90",x"DA",x"BE",x"DA",x"90",x"DA",x"94",x"BE",x"DA",x"DA",x"DA",x"94",
    --x"DA",x"DA",x"90",x"DA",x"90",x"DA",x"BE",x"DA",x"DA",x"DA",x"94",x"BE",x"DA",x"90",x"DA",x"94",
    --x"DA",x"90",x"90",x"DA",x"DA",x"90",x"DA",x"94",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
    --x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"DA",x"94",x"94",x"DA",x"DA",x"94",x"94",x"DA",x"DA",x"DA",
    --x"90",x"90",x"DA",x"BE",x"DA",x"DA",x"90",x"DA",x"BE",x"BE",x"DA",x"DA",x"DA",x"BE",x"BE",x"BE",
    
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",    -- x"01" BLUINICORN
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"FF",x"FF",x"FF",x"02",x"FF",    -- W/O GRASS
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"FF",x"02",x"02",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"02",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"FF",
    --x"FF",x"02",x"02",x"02",x"FF",x"FF",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"FF",
    --x"FF",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",
    --x"FF",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",
    --x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",    
    --x"02",x"02",x"FF",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"02",x"02",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"FF",x"FF",x"FF",x"FF",

    --x"FF",x"FF",x"FF",x"FF",x"FF",x"96",x"96",x"FF",x"FF",x"FF",x"96",x"FF",x"FF",x"FF",x"FF",x"FF",    -- x"02" TREE 1
    --x"FF",x"FF",x"FF",x"96",x"96",x"1A",x"1A",x"96",x"96",x"96",x"1A",x"12",x"12",x"FF",x"FF",x"FF",    -- W/O GRASS
    --x"FF",x"FF",x"FF",x"10",x"10",x"96",x"96",x"1A",x"10",x"1A",x"96",x"1A",x"18",x"12",x"FF",x"FF",
    --x"FF",x"FF",x"96",x"10",x"96",x"18",x"96",x"10",x"1A",x"96",x"10",x"18",x"1A",x"D6",x"12",x"FF",    
    --x"FF",x"96",x"10",x"1A",x"1A",x"96",x"10",x"18",x"96",x"D6",x"18",x"1A",x"18",x"12",x"FF",x"FF",
    --x"FF",x"10",x"10",x"96",x"96",x"D6",x"10",x"18",x"10",x"10",x"D6",x"18",x"1A",x"D6",x"12",x"FF",
    --x"FF",x"96",x"10",x"10",x"10",x"10",x"D6",x"10",x"18",x"18",x"10",x"1A",x"18",x"18",x"18",x"12",
    --x"FF",x"10",x"96",x"10",x"D6",x"10",x"10",x"1A",x"1A",x"10",x"1A",x"18",x"1A",x"1A",x"18",x"12",
    --x"10",x"96",x"1A",x"1A",x"10",x"10",x"1A",x"18",x"1A",x"18",x"18",x"1A",x"10",x"18",x"12",x"FF",	
    --x"FF",x"10",x"10",x"10",x"D0",x"D6",x"18",x"18",x"18",x"18",x"1A",x"10",x"18",x"18",x"1A",x"12",
	--x"FF",x"FF",x"10",x"10",x"FF",x"D0",x"D0",x"18",x"1A",x"D0",x"1A",x"18",x"18",x"12",x"12",x"FF",	
    --x"FF",x"FF",x"10",x"FF",x"FF",x"D0",x"D0",x"18",x"D0",x"12",x"18",x"12",x"12",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"FF",x"FF",x"12",x"FF",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"D0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"D0",x"D0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
    
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"96",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- x"03" TREE 2
    --x"FF",x"FF",x"FF",x"FF",x"96",x"96",x"12",x"96",x"1A",x"96",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- W/O GRASS
    --x"FF",x"FF",x"96",x"12",x"18",x"12",x"D6",x"12",x"96",x"12",x"1A",x"12",x"FF",x"1A",x"FF",x"FF",
    --x"FF",x"96",x"96",x"12",x"18",x"18",x"96",x"12",x"18",x"18",x"12",x"1A",x"12",x"1A",x"FF",x"FF",
    --x"FF",x"96",x"12",x"18",x"96",x"18",x"12",x"18",x"1A",x"12",x"18",x"D6",x"1A",x"18",x"FF",x"FF",
    --x"96",x"12",x"96",x"18",x"D6",x"12",x"1A",x"1A",x"12",x"18",x"D6",x"1A",x"19",x"FF",x"FF",x"FF",
    --x"12",x"18",x"18",x"D6",x"96",x"96",x"18",x"12",x"12",x"1A",x"12",x"18",x"18",x"1A",x"FF",x"FF",
    --x"96",x"96",x"12",x"96",x"18",x"18",x"1A",x"D6",x"1A",x"12",x"18",x"18",x"1A",x"12",x"1A",x"FF",
    --x"FF",x"96",x"12",x"12",x"1A",x"1A",x"18",x"1A",x"1A",x"18",x"1A",x"1A",x"12",x"1A",x"FF",x"FF",
    --x"FF",x"FF",x"96",x"12",x"18",x"18",x"18",x"1A",x"18",x"1A",x"18",x"1A",x"12",x"1A",x"FF",x"FF",
    --x"FF",x"FF",x"12",x"FF",x"1A",x"1A",x"1A",x"D0",x"1A",x"D0",x"D0",x"1A",x"18",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"1A",x"FF",x"D0",x"D0",x"D0",x"1A",x"18",x"1A",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"D0",x"FF",x"FF",x"1A",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"D0",x"D0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
    
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"92",x"B6",x"B6",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",  -- x"04" ROCK
    --x"FF",x"FF",x"FF",x"FF",x"FF",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"FF",x"FF",x"FF",x"FF",x"FF",  -- W/O GRASS
    --x"FF",x"FF",x"92",x"B6",x"FF",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"FF",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"FF",x"FF",x"FF",
    --x"FF",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"FF",x"FF",
    --x"FF",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"FF",
    --x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"FF",
    --x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"92",x"B6",
    --x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",
    --x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"92",x"B6",x"92",x"B6",x"B6",
    --x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
    --x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"FF",
    --x"FF",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"FF",
    --x"FF",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"FF",x"FF",
    --x"FF",x"FF",x"92",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"FF",x"FF",x"FF",
    --x"FF",x"FF",x"FF",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"FF",x"FF",x"FF",x"FF",
