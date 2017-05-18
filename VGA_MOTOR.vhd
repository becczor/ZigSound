--VGA MOTOR
-- ZigSound

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
    sel_track                   : in unsigned(1 downto 0);
    goal_pos                    : in signed(17 downto 0);
    goal_reached                : in std_logic;
    showing_goal_msg_out        : out std_logic;
    disp_goal_pos               : in std_logic;
    score                       : in unsigned(5 downto 0);
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

    --*************************
    --* Goal position aliases *
    --*************************
    alias goal_x : signed(5 downto 0) is goal_pos(14 downto 9);
    alias goal_y : signed(4 downto 0) is goal_pos(4 downto 0);
    
    --***********
    --* Signals *
    --***********
    signal Xpixel_next          : unsigned(9 downto 0);     -- Next horizontal pixel counter
    signal Ypixel_next          : unsigned(9 downto 0);		-- Next vertical pixel counter
    signal Xpixel	            : unsigned(9 downto 0);     -- Horizontal pixel counter
    signal Ypixel	            : unsigned(9 downto 0);		-- Vertical pixel counter
    signal ClkDiv	            : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
    signal Clk25			    : std_logic;			    -- One pulse width 25 MHz signal
    signal pixel_out            : std_logic_vector(7 downto 0);	 -- Tile pixel data
    signal goalCarrotPixel      : std_logic_vector(7 downto 0);  -- Yay! Carrot ++
    signal goalRbPixel          : std_logic_vector(7 downto 0);  -- Rainbow
    signal dispGoalPosPixel     : std_logic_vector(7 downto 0);  -- Display goal pos
    signal bgPixel              : std_logic_vector(7 downto 0);  -- Background tile
    signal dataPixel            : std_logic_vector(7 downto 0);  -- Regular tile data
    signal isTransparent        : std_logic := '0';         -- Signal for checking if current tile represents transparancy
    signal bgTileAddr           : unsigned(12 downto 0);	-- Background tile address
    signal tileAddr             : unsigned(12 downto 0);	-- Tile address
    signal blank                : std_logic;                -- blanking signal
    signal spriteAddrRb         : unsigned(10 downto 0);     -- The sprite addr
    signal isRbSprite           : std_logic;                -- '1' if VGA should show sprite '0' if tile
    signal sprite_x_offset_rb   : unsigned(9 downto 0);     -- xPixel - start of sprite x-position
    signal sprite_y_offset_rb   : unsigned(9 downto 0);     -- yPixel - start of y-position 
    signal sprite_xstart_g      : unsigned(9 downto 0);
    signal sprite_xend_g        : unsigned(9 downto 0);
    signal sprite_ystart_g      : unsigned(9 downto 0);
    signal sprite_yend_g        : unsigned(9 downto 0);
    signal spriteAddrG          : unsigned(7 downto 0);
    signal isGoalSprite         : std_logic;
    signal sprite_y_offset_c    : unsigned(9 downto 0);     -- yPixel - start of y-position
    signal spriteAddrc          : unsigned(10 downto 0);     -- The sprite addr
    signal isCSprite            : std_logic;                -- '1' if VGA should show sprite '0' if tile
    -- Signals for score
    signal x_s_limit    : unsigned(9 downto 0);     -- The limit of shown score in x-pos
    signal tileIndex    : unsigned(4 downto 0);

    -- Animation and goal message showing
    signal time_cnt             : unsigned(18 downto 0);
    signal x_cnt                : unsigned(9 downto 0);
    signal showing_Xpixel_cnt    : unsigned(9 downto 0);
    signal showing_goal_msg      : std_logic;              
    
    -- Sprite memory type
    type ram_s_r is array (0 to 2047) of std_logic_vector(7 downto 0);
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
          
    type ram_s_goal is array (0 to 255) of std_logic_vector(7 downto 0);         
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

    type ram_s_c is array (0 to 2047) of std_logic_vector(7 downto 0);
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
    type ram_t is array (0 to 3839) of std_logic_vector(7 downto 0);
    -- Tile memory : There is room for 32 different tiles.
    signal tileMem : ram_t := 
        (
        x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"00" GRASS SUMMER 
        x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",    -- (BG TRACK 1)
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
        
        x"F5",x"F5",x"F9",x"F5",x"F9",x"D1",x"ED",x"F5",x"F5",x"D1",x"ED",x"D1",x"D1",x"D1",x"ED",x"ED",    -- x"01" GRASS AUTUMN
        x"ED",x"D1",x"D1",x"F9",x"ED",x"D1",x"ED",x"D1",x"D1",x"F5",x"D1",x"D1",x"F5",x"F5",x"D1",x"F9",    -- (BG TRACK 2)
        x"F9",x"F5",x"F5",x"D1",x"F5",x"F9",x"F9",x"D1",x"ED",x"F5",x"ED",x"F9",x"F5",x"D1",x"F5",x"F9",
        x"F9",x"F9",x"F5",x"ED",x"F5",x"F5",x"ED",x"D1",x"F9",x"F5",x"ED",x"ED",x"F5",x"F9",x"D1",x"D1",    
        x"D1",x"D1",x"F9",x"ED",x"D1",x"D1",x"F5",x"D1",x"F5",x"F9",x"F9",x"D1",x"D1",x"F9",x"D1",x"ED",
        x"F9",x"D1",x"F9",x"F9",x"F9",x"D1",x"ED",x"D1",x"F9",x"D1",x"D1",x"F9",x"D1",x"D1",x"F9",x"D1",
        x"D1",x"ED",x"ED",x"D1",x"ED",x"D1",x"ED",x"F5",x"D1",x"F9",x"ED",x"D1",x"D1",x"F5",x"F9",x"D1",    
        x"F5",x"F9",x"ED",x"D1",x"F9",x"ED",x"F5",x"F5",x"D1",x"ED",x"ED",x"F9",x"F5",x"F5",x"D1",x"F9",
        x"F5",x"D1",x"D1",x"ED",x"F9",x"ED",x"F9",x"D1",x"F5",x"F9",x"F9",x"F9",x"F9",x"D1",x"D1",x"F9",
        x"D1",x"D1",x"ED",x"ED",x"D1",x"F5",x"D1",x"F9",x"ED",x"ED",x"D1",x"D1",x"F9",x"F9",x"ED",x"D1",    
        x"ED",x"F9",x"D1",x"F9",x"D1",x"F5",x"F5",x"F9",x"ED",x"ED",x"F9",x"D1",x"F9",x"D1",x"ED",x"D1",
        x"D1",x"ED",x"D1",x"ED",x"ED",x"F9",x"F5",x"D1",x"ED",x"F9",x"F9",x"F5",x"D1",x"D1",x"F9",x"F9",
        x"D1",x"F9",x"ED",x"F9",x"ED",x"F9",x"F5",x"D1",x"D1",x"D1",x"F9",x"F5",x"D1",x"ED",x"D1",x"D1",
        x"D1",x"ED",x"ED",x"F9",x"F9",x"ED",x"D1",x"F9",x"D1",x"D1",x"F5",x"ED",x"ED",x"F9",x"D1",x"F9",
        x"ED",x"D1",x"D1",x"F5",x"D1",x"F9",x"D1",x"F9",x"F9",x"D1",x"ED",x"F9",x"ED",x"D1",x"D1",x"D1",
        x"ED",x"ED",x"D1",x"F5",x"D1",x"F9",x"ED",x"D1",x"F5",x"F5",x"ED",x"D1",x"D1",x"F5",x"F5",x"ED",

        x"DF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",    -- x"02" GRASS WINTER
        x"FF",x"FF",x"FF",x"FF",x"DF",x"FB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",    -- (BG TRACK 3)
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"DF",x"FB",x"FF",x"FF",x"FF",x"DF",x"FB",
        x"FF",x"FF",x"DF",x"FB",x"FF",x"FF",x"DF",x"FB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"DF",x"DF",x"DF",x"FB",x"FF",x"FF",
        x"FF",x"DF",x"FB",x"FF",x"FF",x"FB",x"FF",x"FF",x"FF",x"FF",x"DF",x"DF",x"DF",x"FB",x"FF",x"FF",
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"DF",x"FB",x"DF",x"DF",x"DF",x"FB",x"DF",x"FF",
        x"FF",x"DF",x"DF",x"DF",x"FB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        x"FF",x"DF",x"DF",x"DF",x"FB",x"FF",x"FF",x"FF",x"FF",x"DF",x"DF",x"DF",x"FF",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"FF",x"DF",x"DF",x"DF",x"DF",x"FF",x"FF",x"DF",x"DF",x"DF",x"FF",x"FF",x"FF",x"FF",
        x"FF",x"FF",x"FF",x"DF",x"DF",x"DF",x"DF",x"FF",x"DF",x"FF",x"FF",x"FF",x"FF",x"DF",x"FB",x"FF",
        x"FF",x"FF",x"FF",x"FB",x"FB",x"FB",x"FB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        x"DF",x"DF",x"DF",x"FF",x"DF",x"FF",x"FF",x"DF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        x"FB",x"FB",x"FB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"DF",x"DF",x"DF",x"DF",x"DF",
        x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FB",x"FB",x"FB",x"FB",x"FB",
        x"DF",x"DF",x"DF",x"DF",x"FB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",    -- x"03" BLUINICORN
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",x"01",x"01",x"01",x"02",x"01",    
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",x"02",x"01",x"02",x"02",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",x"02",x"9B",x"9B",x"9B",x"01",x"01",x"01",
        x"01",x"01",x"02",x"01",x"01",x"01",x"01",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"01",
        x"01",x"02",x"02",x"02",x"01",x"01",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"01",
        x"01",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",
        x"01",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",
        x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",    
        x"02",x"02",x"01",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"02",x"02",x"01",x"01",x"01",x"01",x"01",x"02",x"02",x"01",x"01",x"01",x"01",
        
        x"01",x"01",x"01",x"01",x"01",x"01",x"92",x"B6",x"B6",x"01",x"01",x"01",x"01",x"01",x"01",x"01",    -- x"04" ROCK SUMMER/AUTUMN
        x"01",x"01",x"01",x"01",x"01",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"92",x"B6",x"01",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"01",x"01",x"01",
        x"01",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"01",x"01",
        x"01",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"01",
        x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"01",
        x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"92",x"B6",
        x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",
        x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"92",x"B6",x"92",x"B6",x"B6",
        x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"01",
        x"01",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"01",
        x"01",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"01",x"01",
        x"01",x"01",x"92",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"01",x"01",x"01",
        x"01",x"01",x"01",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"01",x"01",x"01",x"01",
        
        X"01",X"01",X"01",X"01",X"01",X"01",x"DF",x"DF",x"DF",X"01",X"01",X"01",X"01",X"01",X"01",X"01",    -- x"05" ROCK WINTER
        X"01",X"01",X"01",X"01",X"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",X"01",X"01",X"01",X"01",X"01",
        X"01",X"01",x"DF",x"DF",X"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",X"01",X"01",X"01",X"01",
        X"01",X"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",X"01",X"01",X"01",
        X"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",X"01",X"01",
        X"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",X"01",
        x"B6",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",X"01",
        x"B6",x"B6",x"B6",x"B6",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",x"92",x"B6",
        x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",x"B6",x"B6",x"B6",
        x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"DF",x"B6",x"DF",x"DF",x"92",x"B6",x"92",x"B6",x"B6",
        x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",X"01",
        X"01",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",X"01",
        X"01",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",X"01",X"01",
        X"01",X"01",x"92",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",X"01",X"01",X"01",
        X"01",X"01",X"01",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",X"01",X"01",X"01",X"01",

        x"01",x"01",x"01",x"01",x"01",x"96",x"96",x"01",x"01",x"01",x"96",x"01",x"01",x"01",x"01",x"01",    -- x"06" TREE 1 SUMMER
        x"01",x"01",x"01",x"96",x"96",x"1A",x"1A",x"96",x"96",x"96",x"1A",x"12",x"12",x"01",x"01",x"01",    
        x"01",x"01",x"01",x"10",x"10",x"96",x"96",x"1A",x"10",x"1A",x"96",x"1A",x"18",x"12",x"01",x"01",
        x"01",x"01",x"96",x"10",x"96",x"18",x"96",x"10",x"1A",x"96",x"10",x"18",x"1A",x"D6",x"12",x"01",    
        x"01",x"96",x"10",x"1A",x"1A",x"96",x"10",x"18",x"96",x"D6",x"18",x"1A",x"18",x"12",x"01",x"01",
        x"01",x"10",x"10",x"96",x"96",x"D6",x"10",x"18",x"10",x"10",x"D6",x"18",x"1A",x"D6",x"12",x"01",
        x"01",x"96",x"10",x"10",x"10",x"10",x"D6",x"10",x"18",x"18",x"10",x"1A",x"18",x"18",x"18",x"12",
        x"01",x"10",x"96",x"10",x"D6",x"10",x"10",x"1A",x"1A",x"10",x"1A",x"18",x"1A",x"1A",x"18",x"12",
        x"10",x"96",x"1A",x"1A",x"10",x"10",x"1A",x"18",x"1A",x"18",x"18",x"1A",x"10",x"18",x"12",x"01",
        x"01",x"10",x"10",x"10",x"D0",x"D6",x"18",x"18",x"18",x"18",x"1A",x"10",x"18",x"18",x"1A",x"12",
        x"01",x"01",x"10",x"10",x"01",x"D0",x"D0",x"18",x"1A",x"D0",x"1A",x"18",x"18",x"12",x"12",x"01",
        x"01",x"01",x"10",x"01",x"01",x"D0",x"D0",x"18",x"D0",x"12",x"18",x"12",x"12",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"12",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",

        x"01",x"01",x"01",x"01",x"01",x"01",x"96",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",  -- x"07" TREE 2 SUMMER
        x"01",x"01",x"01",x"01",x"96",x"96",x"12",x"96",x"1A",x"96",x"01",x"01",x"01",x"01",x"01",x"01",  
        x"01",x"01",x"96",x"12",x"18",x"12",x"D6",x"12",x"96",x"12",x"1A",x"12",x"01",x"1A",x"01",x"01",
        x"01",x"96",x"96",x"12",x"18",x"18",x"96",x"12",x"18",x"18",x"12",x"1A",x"12",x"1A",x"01",x"01",
        x"01",x"96",x"12",x"18",x"96",x"18",x"12",x"18",x"1A",x"12",x"18",x"D6",x"1A",x"18",x"01",x"01",
        x"96",x"12",x"96",x"18",x"D6",x"12",x"1A",x"1A",x"12",x"18",x"D6",x"1A",x"19",x"01",x"01",x"01",
        x"12",x"18",x"18",x"D6",x"96",x"96",x"18",x"12",x"12",x"1A",x"12",x"18",x"18",x"1A",x"01",x"01",
        x"96",x"96",x"12",x"96",x"18",x"18",x"1A",x"D6",x"1A",x"12",x"18",x"18",x"1A",x"12",x"1A",x"01",
        x"01",x"96",x"12",x"12",x"1A",x"1A",x"18",x"1A",x"1A",x"18",x"1A",x"1A",x"12",x"1A",x"01",x"01",
        x"01",x"01",x"96",x"12",x"18",x"18",x"18",x"1A",x"18",x"1A",x"18",x"1A",x"12",x"1A",x"01",x"01",
        x"01",x"01",x"12",x"01",x"1A",x"1A",x"1A",x"D0",x"1A",x"D0",x"D0",x"1A",x"18",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"1A",x"01",x"D0",x"D0",x"D0",x"1A",x"18",x"1A",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"D0",x"01",x"01",x"1A",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",

        x"01",x"01",x"01",x"01",x"01",x"96",x"96",x"01",x"01",x"01",x"96",x"01",x"01",x"01",x"01",x"01",    -- x"08" TREE 1 AUTUMN (FIX COLORS!!)
        x"01",x"01",x"01",x"96",x"96",x"1A",x"1A",x"96",x"96",x"96",x"1A",x"12",x"12",x"01",x"01",x"01",    
        x"01",x"01",x"01",x"10",x"10",x"96",x"96",x"1A",x"10",x"1A",x"96",x"1A",x"18",x"12",x"01",x"01",
        x"01",x"01",x"96",x"10",x"96",x"18",x"96",x"10",x"1A",x"96",x"10",x"18",x"1A",x"D6",x"12",x"01",    
        x"01",x"96",x"10",x"1A",x"1A",x"96",x"10",x"18",x"96",x"D6",x"18",x"1A",x"18",x"12",x"01",x"01",
        x"01",x"10",x"10",x"96",x"96",x"D6",x"10",x"18",x"10",x"10",x"D6",x"18",x"1A",x"D6",x"12",x"01",
        x"01",x"96",x"10",x"10",x"10",x"10",x"D6",x"10",x"18",x"18",x"10",x"1A",x"18",x"18",x"18",x"12",
        x"01",x"10",x"96",x"10",x"D6",x"10",x"10",x"1A",x"1A",x"10",x"1A",x"18",x"1A",x"1A",x"18",x"12",
        x"10",x"96",x"1A",x"1A",x"10",x"10",x"1A",x"18",x"1A",x"18",x"18",x"1A",x"10",x"18",x"12",x"01",
        x"01",x"10",x"10",x"10",x"D0",x"D6",x"18",x"18",x"18",x"18",x"1A",x"10",x"18",x"18",x"1A",x"12",
        x"01",x"01",x"10",x"10",x"01",x"D0",x"D0",x"18",x"1A",x"D0",x"1A",x"18",x"18",x"12",x"12",x"01",
        x"01",x"01",x"10",x"01",x"01",x"D0",x"D0",x"18",x"D0",x"12",x"18",x"12",x"12",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"12",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",

        x"01",x"01",x"01",x"01",x"01",x"01",x"96",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",  -- x"09" TREE 2 AUTUMN (FIX COLORS!!)
        x"01",x"01",x"01",x"01",x"96",x"96",x"12",x"96",x"1A",x"96",x"01",x"01",x"01",x"01",x"01",x"01",  
        x"01",x"01",x"96",x"12",x"18",x"12",x"D6",x"12",x"96",x"12",x"1A",x"12",x"01",x"1A",x"01",x"01",
        x"01",x"96",x"96",x"12",x"18",x"18",x"96",x"12",x"18",x"18",x"12",x"1A",x"12",x"1A",x"01",x"01",
        x"01",x"96",x"12",x"18",x"96",x"18",x"12",x"18",x"1A",x"12",x"18",x"D6",x"1A",x"18",x"01",x"01",
        x"96",x"12",x"96",x"18",x"D6",x"12",x"1A",x"1A",x"12",x"18",x"D6",x"1A",x"19",x"01",x"01",x"01",
        x"12",x"18",x"18",x"D6",x"96",x"96",x"18",x"12",x"12",x"1A",x"12",x"18",x"18",x"1A",x"01",x"01",
        x"96",x"96",x"12",x"96",x"18",x"18",x"1A",x"D6",x"1A",x"12",x"18",x"18",x"1A",x"12",x"1A",x"01",
        x"01",x"96",x"12",x"12",x"1A",x"1A",x"18",x"1A",x"1A",x"18",x"1A",x"1A",x"12",x"1A",x"01",x"01",
        x"01",x"01",x"96",x"12",x"18",x"18",x"18",x"1A",x"18",x"1A",x"18",x"1A",x"12",x"1A",x"01",x"01",
        x"01",x"01",x"12",x"01",x"1A",x"1A",x"1A",x"D0",x"1A",x"D0",x"D0",x"1A",x"18",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"1A",x"01",x"D0",x"D0",x"D0",x"1A",x"18",x"1A",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"D0",x"01",x"01",x"1A",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",

        x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",    -- x"0A" TREE 1 WINTER
        x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",    
        x"AB",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",x"AB",
        x"AB",x"AB",x"01",x"FB",x"01",x"AB",x"AB",x"FB",x"01",x"01",x"AB",x"AB",x"01",x"AB",x"AB",x"AB",
        x"01",x"AB",x"AB",x"01",x"01",x"01",x"AB",x"AB",x"01",x"AB",x"AB",x"01",x"01",x"AB",x"01",x"01",
        x"01",x"01",x"AB",x"AB",x"01",x"FB",x"AB",x"AB",x"01",x"AB",x"01",x"01",x"AB",x"AB",x"AB",x"01",
        x"01",x"01",x"AB",x"AB",x"AB",x"01",x"AB",x"AB",x"01",x"AB",x"AB",x"AB",x"AB",x"FB",x"AB",x"AB",
        x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"AB",x"AB",
        x"AB",x"AB",x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",
        x"AB",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"AB",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"FB",x"01",
        x"01",x"01",x"01",x"FB",x"FB",x"FB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"FB",x"FB",x"FB",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"FB",x"FB",x"FB",x"FB",x"FB",
        x"01",x"01",x"01",x"01",x"FB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",

        x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",    -- x"0B" TREE 2 WINTER (CURRENTLY SAME AS TREE 1)  
        x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",    
        x"AB",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",x"01",x"AB",x"AB",x"01",x"01",x"01",x"AB",
        x"AB",x"AB",x"01",x"FB",x"01",x"AB",x"AB",x"FB",x"01",x"01",x"AB",x"AB",x"01",x"AB",x"AB",x"AB",
        x"01",x"AB",x"AB",x"01",x"01",x"01",x"AB",x"AB",x"01",x"AB",x"AB",x"01",x"01",x"AB",x"01",x"01",
        x"01",x"01",x"AB",x"AB",x"01",x"FB",x"AB",x"AB",x"01",x"AB",x"01",x"01",x"AB",x"AB",x"AB",x"01",
        x"01",x"01",x"AB",x"AB",x"AB",x"01",x"AB",x"AB",x"01",x"AB",x"AB",x"AB",x"AB",x"FB",x"AB",x"AB",
        x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"AB",x"AB",
        x"AB",x"AB",x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",
        x"AB",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"AB",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"FB",x"01",
        x"01",x"01",x"01",x"FB",x"FB",x"FB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"FB",x"FB",x"FB",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"AB",x"AB",x"AB",x"01",x"01",x"FB",x"FB",x"FB",x"FB",x"FB",
        x"01",x"01",x"01",x"01",x"FB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"01",x"01",x"01",x"01",x"01",

        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",    -- x"0C" SOUND ICON CURR
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",    
        x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"01",
        x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",
        x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",

        x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",    -- x"0D" SOUND ICON GOAL 
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
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
        
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"01",x"2C",x"01",x"2C",x"2C",x"01",x"2C",    -- x"0E" CARROT 
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"2C",x"01",x"2C",x"2C",x"01",x"01",x"2C",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"01",x"2C",x"01",x"01",x"2C",x"2C",x"2C",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EC",x"2C",x"2C",x"2C",x"2C",x"01",x"2C",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"A8",x"EC",x"2C",x"2C",x"01",x"2C",x"01",x"01",x"2C",
        x"01",x"01",x"01",x"01",x"01",x"01",x"EC",x"EC",x"EC",x"A8",x"2C",x"2C",x"2C",x"2C",x"2C",x"2C",
        x"01",x"01",x"01",x"01",x"01",x"A8",x"EC",x"EC",x"EC",x"EC",x"EC",x"2C",x"2C",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"EC",x"EC",x"EC",x"A8",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A8",x"EC",x"EC",x"EC",x"EC",x"A8",x"EC",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"EC",x"EC",x"A8",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"A8",x"EC",x"EC",x"EC",x"EC",x"EC",x"A8",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"EC",x"A8",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"EC",x"EC",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"EC",x"A8",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"EC",x"EC",x"EC",x"A8",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01"       
        );
  
begin


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
        if rst = '1'  then
            x_cnt <= to_unsigned(192,10); -- Start x-cord
        elsif goal_reached = '1' then
            showing_goal_msg <= '1';
            x_cnt <= to_unsigned(192,10);
        elsif x_cnt = "1001011000" then 
            showing_goal_msg <= '0';
        elsif (time_cnt = "11111111111111111" and showing_goal_msg = '1') then -- Stop counter     
            x_cnt <= x_cnt + 1;
        else
            null;
        end if;
    end if;
    end process;

    showing_goal_msg_out <= showing_goal_msg;
    showing_Xpixel_cnt <= x_cnt when (x_cnt < 449) else to_unsigned(448,10);  

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
            Xpixel_next <= (others => '0');
        elsif Clk25 = '1' then
		    if Xpixel_next = 799 then	-- vi har nått slutet av pixelantalet
			    Xpixel_next <= (others => '0');
		    else
			    Xpixel_next <= Xpixel_next + 1;
		    end if;
	    end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Xpixel <= (others => '0');
        elsif Clk25 = '1' then
		    Xpixel <= Xpixel_next;
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
	        Ypixel_next <= (others => '0');
        elsif Clk25 = '1' and Xpixel_next = 799 then
            if Ypixel_next = 520 then	-- vi har nått slutet av pixelantalet
	            Ypixel_next <= (others => '0');
            else 
	            Ypixel_next <= Ypixel_next + 1;
            end if;
        end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Ypixel <= (others => '0');
        elsif Clk25 = '1' then
		    Ypixel <= Ypixel_next;
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

    blank <= '1' when ((Xpixel_next > 639 and Xpixel_next <= 799) or (Ypixel_next > 479 and Ypixel_next <= 520)) else '0';

    isRbSprite <= '1' when ((Xpixel_next > 192 and Xpixel_next < showing_Xpixel_cnt) and (Ypixel_next > 100 and Ypixel_next < 228) and not (spriteMemRb(to_integer(spriteAddrRb)) = x"FE")) else '0';  -- ÄNDRA EFTER SOTRLEK
    
    isCSprite <= '1' when ((Xpixel_next > 192 and Xpixel_next < 448 and showing_Xpixel_cnt = to_unsigned(448,10)) and (Ypixel_next > 240 and Ypixel_next < 368) and not (spriteMemC(to_integer(spriteAddrC)) = x"FE")) else '0';  -- ÄNDRA EFTER SOTRLEK

    isGoalSprite <= '1' when ((Xpixel_next > sprite_xstart_g and Xpixel_next < sprite_xend_g) and (Ypixel_next > sprite_ystart_g and Ypixel_next < sprite_yend_g) and not (spriteMemGoal(to_integer(spriteAddrG)) = x"FE")) else '0';

    -- Tile memory access   
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            goalCarrotPixel <= spriteMemC(0);  -- Yay! Carrot ++
            goalRbPixel <= spriteMemRb(0);  -- Rainbow
            dispGoalPosPixel <= spriteMemGoal(0);  -- Display goal pos
            bgPixel <= tileMem(0); -- Background tile
            dataPixel <= tileMem(0);  -- Regular tile data
        else
            goalCarrotPixel <= spriteMemC(to_integer(spriteAddrC));  -- Yay! Carrot ++
            goalRbPixel <= spriteMemRb(to_integer(spriteAddrRb));  -- Rainbow
            dispGoalPosPixel <= spriteMemGoal(to_integer(spriteAddrG));  -- Display goal pos
            bgPixel <= tileMem(to_integer(bgTileAddr)); -- Background tile
            dataPixel <= tileMem(to_integer(tileAddr));  -- Regular tile data
        end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            pixel_out <= (others => '0');
        elsif (isCSprite = '1' and showing_goal_msg = '1') then
            --pixel <= spriteMemC(to_integer(spriteAddrC));
            pixel_out <= goalCarrotPixel;
        elsif (isRbSprite = '1' and showing_goal_msg = '1') then
            --pixel <= spriteMemRb(to_integer(spriteAddrRb));   
            pixel_out <= goalRbPixel ;
        elsif (isGoalSprite ='1' and disp_goal_pos = '1') then 
            --pixel <= spriteMemGoal(to_integer(spriteAddrG));
            pixel_out <= dispGoalPosPixel;
        elsif (blank = '0') then
            if (isTransparent = '1') then -- If current tile is transparent, we should display bg
                --pixel <= tileMem(to_integer(bgTileAddr));
                pixel_out <= bgPixel;
            else
                --pixel <= tileMem(to_integer(tileAddr));
                pixel_out <= dataPixel;
            end if;
        else
            pixel_out <= (others => '0');
        end if;
    end if;
    end process;

    -- Check if current tile represents transparancy
    --isTransparent <= '1' when (tileMem(to_integer(tileAddr)) = x"01") else '0';
    isTransparent <= '1' when (dataPixel = x"01") else '0';
    
    -- Sets the offset of x and y pixel coords for sprite-drawing. 
    -- Sprite starts at 300 and 200 
    sprite_x_offset_rb <= Xpixel_next - to_unsigned(192,10);
    sprite_y_offset_rb <= Ypixel_next - to_unsigned(100,10);
    sprite_y_offset_c <= Ypixel_next - to_unsigned(240,10);

    -- chooses the tile index 
    x_s_limit <= to_unsigned(to_integer(score * 16), 10) when score < 40 else to_unsigned(624, 10);
    tileIndex <= "01110" when ((Xpixel_next > 0 and Xpixel_next < x_s_limit) and (Ypixel_next > 464 and Ypixel_next < 480)) else unsigned(data(4 downto 0)); -- Carrot tile or data tile

    -- Calculates goal coordinates in pixels
    sprite_xstart_g <= to_unsigned(16 * to_integer(unsigned(goal_x)), 10); 
    sprite_xend_g <= to_unsigned(16 * (to_integer(unsigned(goal_x)) + 1), 10);
    sprite_ystart_g <= to_unsigned(16 * to_integer(unsigned(goal_y)), 10); 
    sprite_yend_g <= to_unsigned(16 * (to_integer(unsigned(goal_y)) + 1),10);

    -- Tile memory address composite
    bgTileAddr <= "000" & sel_track & Ypixel_next(3 downto 0) & Xpixel_next(3 downto 0); -- Sel_track determines background tile.
    tileAddr <= tileIndex & Ypixel_next(3 downto 0) & Xpixel_next(3 downto 0);
    spriteAddrRb <= sprite_y_offset_rb(6 downto 2) & sprite_x_offset_rb(7 downto 2); --Ändras när vi ändrar spriteMem
    spriteAddrC <= sprite_y_offset_c(6 downto 2) & sprite_x_offset_rb(7 downto 2); --Ändras när vi ändrar spriteMem
    spriteAddrG <= Ypixel_next(3 downto 0) & Xpixel_next(3 downto 0);

    -- Picture memory address composite
    addr <= to_unsigned(40, 6) * Ypixel_next(8 downto 4) + Xpixel_next(9 downto 4);

    -- VGA generation
    vgaRed(2) <= pixel_out(7);
    vgaRed(1) <= pixel_out(6);
    vgaRed(0) <= pixel_out(5);
    vgaGreen(2) <= pixel_out(4);
    vgaGreen(1) <= pixel_out(3);
    vgaGreen(0) <= pixel_out(2);
    vgaBlue(2) <= pixel_out(1);
    vgaBlue(1) <= pixel_out(0);


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
    
     --BACKUP OM TRANSPARENT INTE FUNKAR
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

        --x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"90",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"02",    -- x"03" BLUINICORN SUMMER
        --x"90",x"DA",x"DA",x"94",x"90",x"DA",x"90",x"DA",x"DA",x"BE",x"02",x"DA",x"BE",x"BE",x"02",x"94",    -- WITH GRASS SUMMER
        --x"94",x"BE",x"BE",x"DA",x"BE",x"94",x"94",x"DA",x"90",x"02",x"02",x"94",x"02",x"02",x"BE",x"94",
        --x"94",x"94",x"BE",x"90",x"BE",x"BE",x"90",x"DA",x"02",x"02",x"9B",x"9B",x"9B",x"94",x"DA",x"DA",
        --x"DA",x"DA",x"02",x"90",x"DA",x"DA",x"BE",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"90",
        --x"94",x"02",x"02",x"02",x"94",x"DA",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"DA",
        --x"DA",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"DA",
        --x"BE",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"BE",x"DA",x"94",
        --x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"DA",x"DA",x"94",
        --x"02",x"02",x"90",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"94",x"90",x"DA",        
        --x"90",x"94",x"DA",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"94",x"DA",x"90",x"DA",
        --x"DA",x"90",x"DA",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"DA",x"DA",x"94",x"94",
        --x"DA",x"94",x"90",x"9B",x"9B",x"94",x"BE",x"DA",x"DA",x"DA",x"9B",x"9B",x"DA",x"90",x"DA",x"DA",
        --x"DA",x"90",x"90",x"9B",x"9B",x"90",x"DA",x"94",x"DA",x"DA",x"9B",x"9B",x"90",x"94",x"DA",x"94",
        --x"90",x"DA",x"DA",x"9B",x"9B",x"94",x"DA",x"94",x"94",x"DA",x"9B",x"9B",x"90",x"DA",x"DA",x"DA",
        --x"90",x"90",x"DA",x"02",x"02",x"94",x"90",x"DA",x"BE",x"BE",x"02",x"02",x"DA",x"BE",x"BE",x"90",

        --x"F5",x"F5",x"F9",x"F5",x"F9",x"D1",x"ED",x"F5",x"F5",x"D1",x"ED",x"D1",x"D1",x"D1",x"ED",x"02",    -- x"04" BLUINICORN AUTUMN
        --x"ED",x"D1",x"D1",x"F9",x"ED",x"D1",x"ED",x"D1",x"D1",x"F5",x"02",x"D1",x"F5",x"F5",x"02",x"F9",    -- WITH GRASS AUTUMN
        --x"F9",x"F5",x"F5",x"D1",x"F5",x"F9",x"F9",x"D1",x"ED",x"02",x"02",x"F9",x"02",x"02",x"F5",x"F9",
        --x"F9",x"F9",x"F5",x"ED",x"F5",x"F5",x"ED",x"D1",x"02",x"02",x"9B",x"9B",x"9B",x"F9",x"D1",x"D1",
        --x"D1",x"D1",x"02",x"ED",x"D1",x"D1",x"F5",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"ED",
        --x"F9",x"02",x"02",x"02",x"F9",x"D1",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"D1",
        --x"D1",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"F9",x"D1",
        --x"F5",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"F5",x"D1",x"F9",
        --x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"F9",x"D1",x"D1",x"F9",
        --x"02",x"02",x"ED",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"F9",x"F9",x"ED",x"D1",        
        --x"ED",x"F9",x"D1",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"F9",x"D1",x"ED",x"D1",
        --x"D1",x"ED",x"D1",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"D1",x"D1",x"F9",x"F9",
        --x"D1",x"F9",x"ED",x"9B",x"9B",x"F9",x"F5",x"D1",x"D1",x"D1",x"9B",x"9B",x"D1",x"ED",x"D1",x"D1",
        --x"D1",x"ED",x"ED",x"9B",x"9B",x"ED",x"D1",x"F9",x"D1",x"D1",x"9B",x"9B",x"ED",x"F9",x"D1",x"F9",
        --x"ED",x"D1",x"D1",x"9B",x"9B",x"F9",x"D1",x"F9",x"F9",x"D1",x"9B",x"9B",x"ED",x"D1",x"D1",x"D1",
        --x"ED",x"ED",x"D1",x"02",x"02",x"F9",x"ED",x"D1",x"F5",x"F5",x"02",x"02",x"D1",x"F5",x"F5",x"ED",

        --x"DF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",    -- x"05" BLUINICORN WINTER
        --x"FF",x"FF",x"FF",x"FF",x"DF",x"FB",x"FF",x"FF",x"FF",x"FF",x"02",x"FF",x"FF",x"FF",x"02",x"FF",    -- WITH GRASS WINTER
        --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"FF",x"02",x"02",x"DF",x"FB",
        --x"FF",x"FF",x"DF",x"FB",x"FF",x"FF",x"DF",x"FB",x"02",x"02",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",
        --x"FF",x"FF",x"02",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"FF",
        --x"FF",x"02",x"02",x"02",x"FF",x"FB",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"FF",
        --x"FF",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"DF",x"FF",
        --x"FF",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",
        --x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",    
        --x"02",x"02",x"FF",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
        --x"FF",x"FF",x"FF",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"DF",x"FB",x"FF",
        --x"FF",x"FF",x"FF",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
        --x"DF",x"DF",x"DF",x"9B",x"9B",x"FF",x"FF",x"DF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",
        --x"FB",x"FB",x"FB",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",x"FF",x"9B",x"9B",x"DF",x"DF",x"DF",x"DF",
        --x"FF",x"FF",x"FF",x"9B",x"9B",x"FF",x"FF",x"FF",x"FF",x"FF",x"9B",x"9B",x"FB",x"FB",x"FB",x"FB",
        --x"DF",x"DF",x"DF",x"02",x"02",x"FF",x"FF",x"FF",x"FF",x"FF",x"02",x"02",x"FF",x"FF",x"FF",x"FF",
        
        --x"BE",x"BE",x"94",x"BE",x"94",x"96",x"96",x"BE",x"BE",x"DA",x"96",x"DA",x"DA",x"DA",x"90",x"90",    -- x"06" TREE 1 SUMMER
        --x"90",x"DA",x"DA",x"96",x"96",x"1A",x"1A",x"96",x"96",x"96",x"1A",x"12",x"12",x"BE",x"DA",x"94",    -- WITH GRASS SUMMER
        --x"94",x"BE",x"BE",x"10",x"10",x"96",x"96",x"1A",x"10",x"1A",x"96",x"1A",x"18",x"12",x"BE",x"94",
        --x"94",x"94",x"96",x"10",x"96",x"18",x"96",x"10",x"1A",x"96",x"10",x"18",x"1A",x"D6",x"12",x"DA",            
        --x"DA",x"96",x"10",x"1A",x"1A",x"96",x"10",x"18",x"96",x"D6",x"18",x"1A",x"18",x"12",x"DA",x"90",
        --x"94",x"10",x"10",x"96",x"96",x"D6",x"10",x"18",x"10",x"10",x"D6",x"18",x"1A",x"D6",x"12",x"DA",
        --x"DA",x"96",x"10",x"10",x"10",x"10",x"D6",x"10",x"18",x"18",x"10",x"1A",x"18",x"18",x"18",x"12",
        --x"BE",x"10",x"96",x"10",x"D6",x"10",x"10",x"1A",x"1A",x"10",x"1A",x"18",x"1A",x"1A",x"18",x"12",
        --x"10",x"96",x"1A",x"1A",x"10",x"10",x"1A",x"18",x"1A",x"18",x"18",x"1A",x"10",x"18",x"12",x"94",
        --x"DA",x"10",x"10",x"10",x"D0",x"D6",x"18",x"18",x"18",x"18",x"1A",x"10",x"18",x"18",x"1A",x"12",
        --x"90",x"94",x"10",x"10",x"DA",x"D0",x"D0",x"18",x"1A",x"D0",x"1A",x"18",x"18",x"12",x"12",x"DA",
        --x"DA",x"90",x"10",x"90",x"90",x"D0",x"D0",x"18",x"D0",x"12",x"18",x"12",x"12",x"DA",x"94",x"94",
        --x"DA",x"94",x"90",x"94",x"90",x"94",x"D0",x"D0",x"DA",x"DA",x"12",x"BE",x"DA",x"90",x"DA",x"DA",
        --x"DA",x"90",x"90",x"94",x"94",x"90",x"D0",x"D0",x"DA",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        --x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"D0",x"D0",x"D0",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        --x"90",x"90",x"DA",x"BE",x"DA",x"D0",x"D0",x"D0",x"D0",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",
        
        --x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"96",x"BE",x"BE",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"07" TREE 2 SUMMER
        --x"90",x"DA",x"DA",x"94",x"96",x"96",x"12",x"96",x"1A",x"96",x"DA",x"DA",x"BE",x"BE",x"DA",x"94",    -- WITH GRASS SUMMER
        --x"94",x"BE",x"96",x"12",x"18",x"12",x"D6",x"12",x"96",x"12",x"1A",x"12",x"BE",x"1A",x"BE",x"94",
        --x"94",x"96",x"96",x"12",x"18",x"18",x"96",x"12",x"18",x"18",x"12",x"1A",x"12",x"1A",x"DA",x"DA",
        --x"DA",x"96",x"12",x"18",x"96",x"18",x"12",x"18",x"1A",x"12",x"18",x"D6",x"1A",x"18",x"DA",x"90",
        --x"96",x"12",x"96",x"18",x"D6",x"12",x"1A",x"1A",x"12",x"18",x"D6",x"1A",x"19",x"DA",x"94",x"DA",
        --x"12",x"18",x"18",x"D6",x"96",x"96",x"18",x"12",x"12",x"1A",x"12",x"18",x"18",x"1A",x"94",x"DA",
        --x"96",x"96",x"12",x"96",x"18",x"18",x"1A",x"D6",x"1A",x"12",x"18",x"18",x"1A",x"12",x"1A",x"94",
        --x"BE",x"96",x"12",x"12",x"1A",x"1A",x"18",x"1A",x"1A",x"18",x"1A",x"1A",x"12",x"1A",x"DA",x"94",
        --x"DA",x"DA",x"96",x"12",x"18",x"18",x"18",x"1A",x"18",x"1A",x"18",x"1A",x"12",x"1A",x"90",x"DA",
        --x"90",x"94",x"12",x"94",x"1A",x"1A",x"1A",x"D0",x"1A",x"D0",x"D0",x"1A",x"18",x"DA",x"90",x"DA",
        --x"DA",x"90",x"DA",x"90",x"90",x"1A",x"BE",x"D0",x"D0",x"D0",x"1A",x"18",x"1A",x"DA",x"94",x"94",
        --x"DA",x"94",x"90",x"94",x"90",x"94",x"D0",x"D0",x"D0",x"DA",x"94",x"1A",x"DA",x"90",x"DA",x"DA",
        --x"DA",x"90",x"90",x"94",x"94",x"90",x"DA",x"D0",x"D0",x"DA",x"BE",x"90",x"90",x"94",x"DA",x"94",
        --x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"DA",x"D0",x"D0",x"DA",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        --x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"D0",x"D0",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",

        --x"F5",x"F5",x"F9",x"F5",x"F9",x"D0",x"D0",x"F5",x"F5",x"D1",x"D0",x"D1",x"D1",x"D1",x"ED",x"ED",    -- x"08" TREE 1 AUTUMN
        --x"ED",x"D1",x"D1",x"D0",x"D0",x"E0",x"E0",x"D0",x"D0",x"D0",x"E0",x"FC",x"FC",x"F5",x"D1",x"F9",    -- WITH GRASS AUTUMN
        --x"F9",x"F5",x"F5",x"B4",x"B4",x"D0",x"D0",x"E0",x"B4",x"E0",x"D0",x"E0",x"C8",x"FC",x"F5",x"F9",
        --x"F9",x"F9",x"D0",x"B4",x"D0",x"C8",x"D0",x"B4",x"E0",x"D0",x"B4",x"C8",x"E0",x"F5",x"FC",x"D1",            
        --x"D1",x"D0",x"B4",x"E0",x"E0",x"D0",x"B4",x"C8",x"D0",x"F5",x"C8",x"E0",x"C8",x"FC",x"D1",x"ED",
        --x"F9",x"B4",x"B4",x"D0",x"D0",x"F5",x"B4",x"C8",x"B4",x"B4",x"F5",x"C8",x"E0",x"F5",x"FC",x"D1",
        --x"D1",x"D0",x"B4",x"B4",x"B4",x"B4",x"F5",x"B4",x"C8",x"C8",x"B4",x"E0",x"C8",x"C8",x"C8",x"FC",
        --x"F5",x"B4",x"D0",x"B4",x"F5",x"B4",x"B4",x"E0",x"E0",x"B4",x"E0",x"C8",x"E0",x"E0",x"C8",x"FC",
        --x"B4",x"D0",x"E0",x"E0",x"B4",x"B4",x"E0",x"C8",x"E0",x"C8",x"C8",x"E0",x"B4",x"C8",x"FC",x"F9",
        --x"D1",x"B4",x"B4",x"B4",x"AC",x"F5",x"C8",x"C8",x"C8",x"C8",x"E0",x"B4",x"C8",x"C8",x"E0",x"FC",
        --x"ED",x"F9",x"B4",x"B4",x"D1",x"AC",x"AC",x"C8",x"E0",x"AC",x"E0",x"C8",x"C8",x"FC",x"FC",x"D1",
        --x"D1",x"ED",x"B4",x"ED",x"ED",x"AC",x"AC",x"C8",x"AC",x"FC",x"C8",x"FC",x"FC",x"D1",x"F9",x"F9",
        --x"D1",x"F9",x"ED",x"F9",x"ED",x"F9",x"AC",x"AC",x"D1",x"D1",x"FC",x"F5",x"D1",x"ED",x"D1",x"D1",
        --x"D1",x"ED",x"ED",x"F9",x"F9",x"ED",x"AC",x"AC",x"D1",x"D1",x"F5",x"ED",x"ED",x"F9",x"D1",x"F9",
        --x"ED",x"D1",x"D1",x"F5",x"D1",x"F9",x"AC",x"AC",x"AC",x"D1",x"ED",x"F9",x"ED",x"D1",x"D1",x"D1",
        --x"ED",x"ED",x"D1",x"F5",x"D1",x"AC",x"AC",x"AC",x"AC",x"F5",x"ED",x"D1",x"D1",x"F5",x"F5",x"ED",
        
        --x"F5",x"F5",x"F9",x"F5",x"F9",x"D1",x"D0",x"F5",x"F5",x"D1",x"ED",x"D1",x"D1",x"D1",x"ED",x"ED",    -- x"09" TREE 2 AUTUMN
        --x"ED",x"D1",x"D1",x"F9",x"D0",x"D0",x"FC",x"D0",x"E0",x"D0",x"D1",x"D1",x"F5",x"F5",x"D1",x"F9",    -- WITH GRASS AUTUMN
        --x"F9",x"F5",x"D0",x"FC",x"C8",x"FC",x"F5",x"FC",x"D0",x"FC",x"E0",x"FC",x"F5",x"E0",x"F5",x"F9",
        --x"F9",x"D0",x"D0",x"FC",x"C8",x"C8",x"D0",x"FC",x"C8",x"C8",x"FC",x"E0",x"FC",x"E0",x"D1",x"D1",
        --x"D1",x"D0",x"FC",x"C8",x"D0",x"C8",x"FC",x"C8",x"E0",x"FC",x"C8",x"F5",x"E0",x"C8",x"D1",x"ED",
        --x"D0",x"FC",x"D0",x"C8",x"F5",x"FC",x"E0",x"E0",x"FC",x"C8",x"F5",x"E0",x"19",x"D1",x"F9",x"D1",
        --x"FC",x"C8",x"C8",x"F5",x"D0",x"D0",x"C8",x"FC",x"FC",x"E0",x"FC",x"C8",x"C8",x"E0",x"F9",x"D1",
        --x"D0",x"D0",x"FC",x"D0",x"C8",x"C8",x"E0",x"F5",x"E0",x"FC",x"C8",x"C8",x"E0",x"FC",x"E0",x"F9",
        --x"F5",x"D0",x"FC",x"FC",x"E0",x"E0",x"C8",x"E0",x"E0",x"C8",x"E0",x"E0",x"FC",x"E0",x"D1",x"F9",
        --x"D1",x"D1",x"D0",x"FC",x"C8",x"C8",x"C8",x"E0",x"C8",x"E0",x"C8",x"E0",x"FC",x"E0",x"ED",x"D1",
        --x"ED",x"F9",x"FC",x"F9",x"E0",x"E0",x"E0",x"AC",x"E0",x"AC",x"AC",x"E0",x"C8",x"D1",x"ED",x"D1",
        --x"D1",x"ED",x"D1",x"ED",x"ED",x"E0",x"F5",x"AC",x"AC",x"AC",x"E0",x"C8",x"E0",x"D1",x"F9",x"F9",
        --x"D1",x"F9",x"ED",x"F9",x"ED",x"F9",x"AC",x"AC",x"AC",x"D1",x"F9",x"E0",x"D1",x"ED",x"D1",x"D1",
        --x"D1",x"ED",x"ED",x"F9",x"F9",x"ED",x"D1",x"AC",x"AC",x"D1",x"F5",x"ED",x"ED",x"F9",x"D1",x"F9",
        --x"ED",x"D1",x"D1",x"F5",x"D1",x"F9",x"D1",x"AC",x"AC",x"D1",x"ED",x"F9",x"ED",x"D1",x"D1",x"D1",
        --x"ED",x"ED",x"D1",x"F5",x"D1",x"F9",x"ED",x"AC",x"AC",x"F5",x"ED",x"D1",x"D1",x"F5",x"F5",x"ED",

        --x"DF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",    -- x"0A" TREE 1 WINTER
        --x"FF",x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",    -- WITH GRASS WINTER
        --x"AB",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",x"DF",x"AB",x"AB",x"FF",x"FF",x"DF",x"AB",
        --x"AB",x"AB",x"DF",x"FB",x"FF",x"AB",x"AB",x"FB",x"FF",x"FF",x"AB",x"AB",x"FF",x"AB",x"AB",x"AB",
        --x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"AB",x"AB",x"DF",x"DF",x"AB",x"FF",x"FF",
        --x"FF",x"DF",x"AB",x"AB",x"FF",x"FB",x"AB",x"AB",x"FF",x"AB",x"DF",x"DF",x"AB",x"AB",x"AB",x"FF",
        --x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"AB",x"AB",x"DF",x"AB",x"AB",x"AB",x"AB",x"FB",x"AB",x"AB",
        --x"FF",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",
        --x"AB",x"AB",x"DF",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"DF",x"DF",x"DF",x"FF",x"FF",x"AB",x"AB",
        --x"AB",x"FF",x"FF",x"DF",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"AB",x"DF",x"FF",x"FF",x"FF",x"FF",
        --x"FF",x"FF",x"FF",x"DF",x"DF",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"DF",x"FB",x"FF",
        --x"FF",x"FF",x"FF",x"FB",x"FB",x"FB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        --x"DF",x"DF",x"DF",x"FF",x"DF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        --x"FB",x"FB",x"FB",x"FF",x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"DF",x"DF",x"DF",x"DF",x"DF",
        --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"FB",x"FB",x"FB",x"FB",x"FB",
        --x"DF",x"DF",x"DF",x"DF",x"FB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",

        --lpöox"DF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",    -- x"0B" TREE 2 WINTER (CURRENTLY SAME AS TREE 1)
        --x"FF",x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",    -- WITH GRASS WINTER
        --x"AB",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",x"DF",x"AB",x"AB",x"FF",x"FF",x"DF",x"AB",
        --x"AB",x"AB",x"DF",x"FB",x"FF",x"AB",x"AB",x"FB",x"FF",x"FF",x"AB",x"AB",x"FF",x"AB",x"AB",x"AB",
        --x"FF",x"AB",x"AB",x"FF",x"FF",x"FF",x"AB",x"AB",x"FF",x"AB",x"AB",x"DF",x"DF",x"AB",x"FF",x"FF",
        --x"FF",x"DF",x"AB",x"AB",x"FF",x"FB",x"AB",x"AB",x"FF",x"AB",x"DF",x"DF",x"AB",x"AB",x"AB",x"FF",
        --x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"AB",x"AB",x"DF",x"AB",x"AB",x"AB",x"AB",x"FB",x"AB",x"AB",
        --x"FF",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",
        --x"AB",x"AB",x"DF",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"DF",x"DF",x"DF",x"FF",x"FF",x"AB",x"AB",
        --x"AB",x"FF",x"FF",x"DF",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"AB",x"DF",x"FF",x"FF",x"FF",x"FF",
        --x"FF",x"FF",x"FF",x"DF",x"DF",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"DF",x"FB",x"FF",
        --x"FF",x"FF",x"FF",x"FB",x"FB",x"FB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        --x"DF",x"DF",x"DF",x"FF",x"DF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        --x"FB",x"FB",x"FB",x"FF",x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"DF",x"DF",x"DF",x"DF",x"DF",
        --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"AB",x"AB",x"AB",x"FF",x"FF",x"FB",x"FB",x"FB",x"FB",x"FB",
        --x"DF",x"DF",x"DF",x"DF",x"FB",x"AB",x"AB",x"AB",x"AB",x"AB",x"AB",x"FF",x"FF",x"FF",x"FF",x"FF",

        --x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"92",x"B6",x"B6",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"0C" ROCK SUMMER
        --x"90",x"DA",x"DA",x"94",x"90",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"DA",x"BE",x"BE",x"DA",x"94",    -- WITH GRASS SUMMER
        --x"94",x"BE",x"92",x"B6",x"BE",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"BE",x"DA",x"BE",x"94",
        --x"94",x"94",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"94",x"DA",x"DA",
        --x"DA",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"DA",x"90",
        --x"94",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"DA",
        --x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"DA",
        --x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"92",x"B6",
        --x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",
        --x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"92",x"B6",x"92",x"B6",x"B6",
        --x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        --x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"94",
        --x"DA",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"DA",
        --x"DA",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"94",
        --x"90",x"DA",x"DA",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"DA",x"DA",
        --x"90",x"90",x"DA",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"BE",x"BE",x"90",   

        --x"F5",x"F5",x"F9",x"F5",x"F9",x"D1",x"92",x"B6",x"B6",x"D1",x"ED",x"D1",x"D1",x"D1",x"ED",x"ED",    -- x"0D" ROCK AUTUMN
        --x"ED",x"D1",x"D1",x"F9",x"ED",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"D1",x"F5",x"F5",x"D1",x"F9",    -- WITH GRASS AUTUMN
        --x"F9",x"F5",x"92",x"B6",x"FF",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"F5",x"D1",x"F5",x"F9",
        --x"F9",x"F9",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"F9",x"D1",x"D1",
        --x"D1",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"D1",x"ED",
        --x"F9",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"D1",
        --x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"D1",
        --x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"92",x"B6",
        --x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",
        --x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"92",x"B6",x"92",x"B6",x"B6",
        --x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        --x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"F9",
        --x"D1",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"D1",
        --x"D1",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"D1",x"F9",
        --x"ED",x"D1",x"92",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"D1",x"D1",x"D1",
        --x"ED",x"ED",x"D1",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"D1",x"F5",x"F5",x"ED",

        --x"BE",x"BE",x"94",x"BE",x"94",x"DA",x"92",x"B6",x"B6",x"DA",x"90",x"DA",x"DA",x"DA",x"90",x"90",    -- x"0F" ROCK WINTER (FIXA)
        --x"90",x"DA",x"DA",x"94",x"90",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"DA",x"BE",x"BE",x"DA",x"94",    -- WITH GRASS WINTER
        --x"94",x"BE",x"92",x"B6",x"BE",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"BE",x"DA",x"BE",x"94",
        --x"94",x"94",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"94",x"DA",x"DA",
        --x"DA",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"DA",x"90",
        --x"94",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"DA",
        --x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"DA",
        --x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"92",x"B6",
        --x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",
        --x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"92",x"B6",x"92",x"B6",x"B6",
        --x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        --x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"94",
        --x"DA",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"DA",
        --x"DA",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"94",
        --x"90",x"DA",x"DA",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"DA",x"DA",
        --x"90",x"90",x"DA",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"DA",x"BE",x"BE",x"90",
        
        --x"BE",x"BE",x"94",x"BE",x"94",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"DA",x"DA",x"90",x"90",    -- x"10" TOGGLE CURRPOS SUMMER
        --x"90",x"DA",x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"DA",x"94",    -- WITH GRASS SUMMER
        --x"94",x"BE",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"94",
        --x"94",x"94",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"DA",x"DA",
        --x"DA",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"90",    
        --x"94",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",
        --x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",
        --x"BE",x"94",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"94",
        --x"BE",x"DA",x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"DA",x"94",
        --x"DA",x"DA",x"90",x"90",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"94",x"94",x"90",x"DA",
        --x"90",x"94",x"DA",x"94",x"DA",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"DA",x"94",x"DA",x"90",x"DA",    
        --x"DA",x"90",x"DA",x"90",x"90",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"DA",x"DA",x"94",x"94",
        --x"DA",x"94",x"90",x"94",x"90",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"BE",x"DA",x"90",x"DA",x"DA",
        --x"DA",x"90",x"90",x"94",x"94",x"90",x"E0",x"E0",x"E0",x"E0",x"BE",x"90",x"90",x"94",x"DA",x"94",
        --x"90",x"DA",x"DA",x"BE",x"DA",x"94",x"E0",x"E0",x"E0",x"E0",x"90",x"94",x"90",x"DA",x"DA",x"DA",
        --x"90",x"90",x"DA",x"BE",x"DA",x"94",x"90",x"E0",x"E0",x"BE",x"90",x"DA",x"DA",x"BE",x"BE",x"90",       

        --x"F5",x"F5",x"F9",x"F5",x"F9",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"D1",x"D1",x"D1",x"ED",x"ED",    -- x"11" TOGGLE CURRPOS AUTUMN
        --x"ED",x"D1",x"D1",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"F5",x"D1",x"F9",    -- WITH GRASS AUTUMN
        --x"F9",x"F5",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"F5",x"F9",
        --x"F9",x"F9",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"D1",x"D1",
        --x"D1",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"ED",    
        --x"F9",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"D1",
        --x"D1",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"D1",
        --x"F5",x"F9",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"D1",x"F9",
        --x"F5",x"D1",x"D1",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"D1",x"D1",x"F9",
        --x"D1",x"D1",x"ED",x"ED",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"F9",x"F9",x"ED",x"D1",
        --x"ED",x"F9",x"D1",x"F9",x"D1",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"D1",x"F9",x"D1",x"ED",x"D1",    
        --x"D1",x"ED",x"D1",x"ED",x"ED",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"F5",x"D1",x"D1",x"F9",x"F9",
        --x"D1",x"F9",x"ED",x"F9",x"ED",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"F5",x"D1",x"ED",x"D1",x"D1",
        --x"D1",x"ED",x"ED",x"F9",x"F9",x"ED",x"E0",x"E0",x"E0",x"E0",x"F5",x"ED",x"ED",x"F9",x"D1",x"F9",
        --x"ED",x"D1",x"D1",x"F5",x"D1",x"F9",x"E0",x"E0",x"E0",x"E0",x"ED",x"F9",x"ED",x"D1",x"D1",x"D1",
        --x"ED",x"ED",x"D1",x"F5",x"D1",x"F9",x"ED",x"E0",x"E0",x"F5",x"ED",x"D1",x"D1",x"F5",x"F5",x"ED",
        
        --x"DF",x"FF",x"FF",x"FF",x"FF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",x"FF",x"FF",    -- x"12" TOGGLE CURRPOS WINTER
        --x"FF",x"FF",x"FF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",    -- WITH GRASS WINTER
        --x"FF",x"FF",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"DF",x"FB",
        --x"FF",x"FF",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",
        --x"FF",x"E0",x"E0",x"E0",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"FF",
        --x"FF",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",
        --x"FF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"00",x"00",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",
        --x"FF",x"DF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",
        --x"FF",x"DF",x"DF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",
        --x"FF",x"FF",x"FF",x"DF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",x"FF",
        --x"FF",x"FF",x"FF",x"DF",x"DF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"DF",x"FB",x"FF",
        --x"FF",x"FF",x"FF",x"FB",x"FB",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",x"FF",x"FF",
        --x"DF",x"DF",x"DF",x"FF",x"DF",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"FF",x"FF",x"FF",x"FF",x"FF",
        --x"FB",x"FB",x"FB",x"FF",x"FF",x"FF",x"E0",x"E0",x"E0",x"E0",x"FF",x"DF",x"DF",x"DF",x"DF",x"DF",
        --x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"E0",x"E0",x"E0",x"E0",x"FF",x"FB",x"FB",x"FB",x"FB",x"FB",
        --x"DF",x"DF",x"DF",x"DF",x"FB",x"FF",x"FF",x"E0",x"E0",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
        
        --x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",    -- x"13" TOGGLE GOALPOS 
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00", 
        --x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        --x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        --x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        --x"00",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",x"00",x"FF",x"FF",x"00",
        --x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"

