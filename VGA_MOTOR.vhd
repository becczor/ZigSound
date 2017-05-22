--------------------------------------------------------------------------------
-- VGA_MOTOR
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
    signal Xpixel2              : unsigned(9 downto 0);     -- Horizontal pixel counter, second in queue
    signal Ypixel2              : unsigned(9 downto 0);		-- Vertical pixel counter, second in queue
    signal Xpixel1              : unsigned(9 downto 0);     -- Horizontal pixel counter, first in queue
    signal Ypixel1              : unsigned(9 downto 0);		-- Vertical pixel counter, first in queue
    signal Xpixel	            : unsigned(9 downto 0);     -- Horizontal pixel counter
    signal Ypixel	            : unsigned(9 downto 0);		-- Vertical pixel counter
    signal ClkDiv	            : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
    signal Clk25			    : std_logic;			    -- One pulse width 25 MHz signal
    signal pixel_out            : std_logic_vector(7 downto 0);	 -- Pixel going out to display
    signal yayPixel             : std_logic_vector(7 downto 0);  -- Yay! Carrot ++ pixel
    signal rainbowPixel         : std_logic_vector(7 downto 0);
    signal debugGPixel          : std_logic_vector(7 downto 0);
    signal bgPixel              : std_logic_vector(7 downto 0);  -- Background tile pixel
    signal dataPixel            : std_logic_vector(7 downto 0);  -- Regular tile data pixel
    signal isTransparent        : std_logic := '0';         -- Signal for checking if current tile represents transparancy
    signal bgTile               : unsigned(4 downto 0);     -- Which bg tile we should take from when color is transparent
    signal bgTileAddr           : unsigned(12 downto 0);	
    signal tileAddr             : unsigned(12 downto 0);	-- Tile address, used to find specific pixel in tile
    signal blank                : std_logic;                -- blanking signal
    signal RainbowAddr          : unsigned(10 downto 0);    
    signal isRainbowSprite      : std_logic;                
    signal goal_msg_x_offset    : unsigned(9 downto 0);     -- Xpixel where goal message starts
    signal rainbow_y_offset     : unsigned(9 downto 0);     -- Ypixel where goal message starts
    signal debug_g_xstart       : unsigned(9 downto 0);     -- Xpixel where debug_g starts
    signal debug_g_xend         : unsigned(9 downto 0);     -- Xpixel where debug_g ends
    signal debug_g_ystart       : unsigned(9 downto 0);     -- Ypixel where debug_g starts
    signal debug_g_yend         : unsigned(9 downto 0);     -- Ypixel where debug_g ends
    signal debugGAddr           : unsigned(7 downto 0);     
    signal isDebugGSprite       : std_logic;
    signal yay_y_offset         : unsigned(9 downto 0);     -- Ypixel where "Yay" starts
    signal yayAddr              : unsigned(10 downto 0);    
    signal isYaySprite          : std_logic;                
    signal score_x_limit        : unsigned(9 downto 0);     -- X-position where we should stop displaying score and start displaying from track
    signal tileIndex            : unsigned(4 downto 0);     -- Carrot index if in range of score display, else tile from track

    -- Animation and goal message showing
    signal goal_msg_clk         : unsigned(18 downto 0);     -- Counter with purpose to slow down the animation of rainbow sprite
    signal goal_msg_cnt         : unsigned(9 downto 0);      -- Sets the end coord for RB-sprite and the delay after animation 
    signal goal_msg_x_limit     : unsigned(9 downto 0);      -- Xpixel up until where goal message is currently shown, counted up to max 448
    signal showing_goal_msg     : std_logic;                 -- '1' when goal message is being displayed
    
    -- Sprite memory type Rainbow
    type ram_s_rainbow is array (0 to 2047) of std_logic_vector(7 downto 0);
    -- Sprite memory Rainbow
    signal spriteMemRainbow : ram_s_rainbow := 
        (
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",
        x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",
        x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",
        x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",
        x"FC",x"FC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",
        x"54",x"54",x"FC",x"FC",x"FC",x"FC",x"FC",x"FC",x"EC",x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"E0",x"E0",x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"54",x"54",
        x"5A",x"5A",x"54",x"54",x"54",x"54",x"54",x"FC",x"FC",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",
        x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",
        x"E0",x"E0",x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"5A",
        x"5A",x"5A",x"5A",x"5A",x"5A",x"5A",x"54",x"54",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"EC",x"E0",
        x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",
        x"E0",x"EC",x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",
        x"2A",x"2A",x"2A",x"2A",x"2A",x"5A",x"5A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"FC",x"EC",x"EC",
        x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",
        x"EC",x"EC",x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"62",x"62",
        x"62",x"62",x"62",x"62",x"2A",x"2A",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"54",x"FC",x"FC",x"EC",
        x"EC",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"EC",x"EC",
        x"FC",x"FC",x"FC",x"54",x"54",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"A6",
        x"A6",x"A6",x"A6",x"62",x"62",x"62",x"62",x"62",x"2A",x"5A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",
        x"EC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"EC",x"FC",
        x"FC",x"54",x"54",x"5A",x"5A",x"5A",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"A6",
        x"EA",x"EA",x"A6",x"A6",x"A6",x"A6",x"A6",x"62",x"2A",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"FC",
        x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",
        x"54",x"54",x"5A",x"5A",x"2A",x"2A",x"2A",x"2A",x"62",x"62",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",
        x"EA",x"EA",x"EA",x"EA",x"EA",x"EA",x"A6",x"62",x"62",x"62",x"2A",x"2A",x"5A",x"5A",x"54",x"54",
        x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",
        x"54",x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"62",x"62",x"A6",x"A6",x"A6",x"EA",x"EA",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"EA",x"A6",x"A6",x"A6",x"62",x"62",x"2A",x"2A",x"5A",x"5A",x"5A",
        x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",
        x"5A",x"5A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"A6",x"A6",x"EA",x"EA",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",x"EA",x"A6",x"A6",x"62",x"62",x"2A",x"2A",x"2A",x"5A",
        x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"54",x"5A",
        x"5A",x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"EA",x"EA",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",x"A6",x"A6",x"62",x"62",x"62",x"62",x"2A",
        x"5A",x"5A",x"5A",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",
        x"2A",x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",x"A6",x"A6",x"A6",x"A6",x"62",x"2A",
        x"2A",x"2A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"EC",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"EC",x"FC",x"54",x"5A",x"5A",x"5A",x"2A",
        x"2A",x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",x"EA",x"EA",x"A6",x"62",x"62",
        x"62",x"2A",x"5A",x"5A",x"54",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"2A",x"2A",
        x"62",x"62",x"A6",x"A6",x"EA",x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"A6",x"A6",x"A6",
        x"62",x"2A",x"2A",x"5A",x"5A",x"54",x"54",x"FC",x"EC",x"EC",x"E0",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"62",
        x"62",x"A6",x"A6",x"EA",x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",x"EA",x"A6",
        x"62",x"62",x"2A",x"2A",x"2A",x"5A",x"54",x"FC",x"FC",x"FC",x"EC",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"54",x"5A",x"5A",x"2A",x"62",x"A6",
        x"A6",x"A6",x"EA",x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"A6",
        x"A6",x"62",x"62",x"62",x"2A",x"5A",x"54",x"54",x"54",x"FC",x"EC",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"EC",x"FC",x"54",x"5A",x"5A",x"5A",x"2A",x"2A",x"62",x"A6",
        x"EA",x"EA",x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",
        x"A6",x"A6",x"A6",x"62",x"2A",x"5A",x"5A",x"5A",x"54",x"FC",x"EC",x"EC",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"2A",x"2A",x"62",x"62",x"A6",
        x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"EA",
        x"EA",x"EA",x"A6",x"62",x"2A",x"2A",x"2A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",x"E0",x"01",
        x"01",x"01",x"01",x"E0",x"EC",x"EC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"62",x"62",x"A6",x"A6",
        x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"EA",x"A6",x"62",x"62",x"62",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"EC",x"E0",x"E0",x"01",
        x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"A6",x"A6",x"EA",
        x"EA",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"EA",x"A6",x"A6",x"A6",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",x"01",
        x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"62",x"A6",x"EA",x"EA",x"EA",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"EA",x"EA",x"EA",x"A6",x"62",x"2A",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"EC",x"E0",x"01",
        x"01",x"01",x"E0",x"E0",x"EC",x"FC",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"A6",x"EA",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"EA",x"A6",x"62",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",x"E0",
        x"01",x"01",x"E0",x"EC",x"EC",x"FC",x"54",x"5A",x"2A",x"2A",x"62",x"A6",x"EA",x"EA",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"EA",x"A6",x"A6",x"62",x"2A",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"E0",x"E0",
        x"01",x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"62",x"62",x"A6",x"EA",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"EA",x"EA",x"A6",x"62",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"EC",x"E0",x"E0",
        x"01",x"E0",x"E0",x"EC",x"FC",x"54",x"54",x"5A",x"2A",x"62",x"A6",x"A6",x"EA",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"EA",x"A6",x"A6",x"62",x"2A",x"2A",x"5A",x"54",x"FC",x"EC",x"EC",x"E0",
        x"01",x"E0",x"E0",x"EC",x"FC",x"54",x"5A",x"5A",x"2A",x"62",x"A6",x"EA",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"EA",x"EA",x"A6",x"62",x"62",x"2A",x"5A",x"54",x"FC",x"FC",x"EC",x"E0",
        x"E0",x"E0",x"EC",x"EC",x"FC",x"54",x"5A",x"2A",x"2A",x"62",x"A6",x"EA",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"EA",x"A6",x"A6",x"62",x"2A",x"5A",x"54",x"54",x"FC",x"EC",x"E0",
        x"E0",x"E0",x"EC",x"FC",x"FC",x"54",x"5A",x"2A",x"62",x"A6",x"EA",x"EA",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"EA",x"EA",x"A6",x"62",x"2A",x"5A",x"5A",x"54",x"FC",x"EC",x"E0"       
        );
    -- Sprite memory type Goal position 'G'      
    type ram_s_debug_g is array (0 to 255) of std_logic_vector(7 downto 0);        
    -- Sprite memory Goal position 'G'
    signal spriteMemDebugG : ram_s_debug_g := 
        (     
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"E0",x"E0",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",
        x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"E0",x"01",x"01",x"01",x"01"
        );
    -- Sprite memory type "Yay carrot++"  
    type ram_s_yay is array (0 to 2047) of std_logic_vector(7 downto 0);
    -- Sprite memory "Yay carrot++"
    signal spriteMemYay : ram_s_yay :=
        (
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"A6",
        x"A6",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"A6",
        x"A6",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",
        x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",
        x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",
        x"01",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"01",x"2C",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"2C",x"01",x"2C",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"01",x"2C",x"01",x"2C",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"2C",x"01",x"01",x"2C",x"2C",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"01",x"2C",x"2C",x"2C",x"01",x"2C",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"2C",x"2C",x"2C",x"01",x"01",x"01",x"2C",x"2C",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"2C",x"2C",x"2C",x"01",x"2C",x"2C",x"2C",x"2C",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"A6",x"A6",x"01",x"01",x"01",
        x"01",x"01",x"01",x"A6",x"A6",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"01",x"EC",x"2C",x"2C",x"2C",x"2C",x"2C",x"01",x"2C",x"01",x"2C",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"A6",x"A6",x"01",x"01",x"01",
        x"01",x"01",x"01",x"A6",x"A6",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"01",x"01",x"A6",x"A6",
        x"01",x"01",x"01",x"01",x"01",x"A8",x"EC",x"EC",x"2C",x"2C",x"2C",x"2C",x"2C",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",
        x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",
        x"01",x"01",x"01",x"01",x"EC",x"EC",x"A8",x"EC",x"EC",x"EC",x"2C",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",
        x"01",x"01",x"01",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",
        x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",x"A6",x"A6",x"01",x"01",
        x"01",x"01",x"01",x"A8",x"EC",x"EC",x"EC",x"EC",x"A8",x"EC",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"A6",x"A6",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",
        x"A6",x"A6",x"A6",x"A6",x"A6",x"A6",x"01",x"01",x"01",x"A6",x"A6",x"A6",x"A6",x"01",x"01",x"01",
        x"01",x"01",x"01",x"EC",x"A8",x"EC",x"EC",x"EC",x"A8",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"A8",x"EC",x"EC",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"EC",x"EC",x"EC",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"00",x"00",x"00",x"00",x"00",
        x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"EC",x"EC",x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"00",x"00",x"00",
        x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"A8",x"EC",x"EC",x"A8",x"EC",x"A8",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"EC",x"EC",x"EC",x"A8",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"EC",
        x"EC",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"EC",
        x"A8",x"EC",x"EC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"EC",x"EC",
        x"EC",x"A8",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",
        x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"00",x"00",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"EC",x"EC",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",x"A6",x"A6",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01"
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

        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",x"02",x"01",x"01",x"02",x"01", -- x"03" RUNNING BLUNICORN
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",x"02",x"02",x"02",x"02",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"02",x"02",x"9B",x"9B",x"9B",x"02",x"01",x"01",
        x"01",x"01",x"02",x"01",x"01",x"01",x"01",x"02",x"02",x"02",x"9B",x"02",x"9B",x"9B",x"9B",x"01",
        x"01",x"02",x"02",x"02",x"01",x"01",x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"02",x"01",
        x"01",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",
        x"01",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",
        x"02",x"02",x"02",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"02",x"02",x"01",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",
        x"01",x"01",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",
        x"01",x"9B",x"9B",x"9B",x"9B",x"01",x"01",x"01",x"01",x"01",x"9B",x"01",x"9B",x"9B",x"01",x"01",
        x"01",x"9B",x"01",x"01",x"9B",x"9B",x"01",x"01",x"01",x"01",x"9B",x"01",x"01",x"9B",x"01",x"01",
        x"01",x"9B",x"01",x"01",x"01",x"9B",x"01",x"01",x"01",x"01",x"9B",x"01",x"01",x"9B",x"01",x"01",
        x"01",x"00",x"01",x"01",x"01",x"00",x"01",x"01",x"01",x"01",x"00",x"01",x"01",x"00",x"01",x"01",
        
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
        
        x"01",x"01",x"01",x"01",x"01",x"01",x"DF",x"DF",x"DF",x"01",x"01",x"01",x"01",x"01",x"01",x"01",    -- x"05" ROCK WINTER
        x"01",x"01",x"01",x"01",x"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"DF",x"DF",x"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"01",x"01",x"01",x"01",
        x"01",x"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"01",x"01",x"01",
        x"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"01",x"01",
        x"01",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",x"01",
        x"B6",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",x"01",
        x"B6",x"B6",x"B6",x"B6",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",x"92",x"B6",
        x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"DF",x"DF",x"DF",x"DF",x"DF",x"DF",x"B6",x"B6",x"B6",x"B6",
        x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"DF",x"B6",x"DF",x"DF",x"92",x"B6",x"92",x"B6",x"B6",
        x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",
        x"92",x"92",x"B6",x"92",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"01",
        x"01",x"92",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"B6",x"B6",x"92",x"B6",x"92",x"92",x"B6",x"01",
        x"01",x"92",x"92",x"92",x"B6",x"B6",x"92",x"B6",x"B6",x"B6",x"B6",x"92",x"92",x"B6",x"01",x"01",
        x"01",x"01",x"92",x"92",x"92",x"B6",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"01",x"01",x"01",
        x"01",x"01",x"01",x"92",x"92",x"92",x"92",x"B6",x"B6",x"92",x"92",x"B6",x"01",x"01",x"01",x"01",

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
        
        x"01",x"01",x"01",x"01",x"01",x"D0",x"D0",x"01",x"01",x"01",x"D0",x"01",x"01",x"01",x"01",x"01",    -- x"08" TREE 1 AUTUMN
        x"01",x"01",x"01",x"D0",x"D0",x"80",x"80",x"D0",x"D0",x"D0",x"80",x"80",x"80",x"01",x"01",x"01",
        x"01",x"01",x"01",x"EC",x"EC",x"D0",x"D0",x"80",x"EC",x"80",x"D0",x"80",x"EC",x"80",x"01",x"01",
        x"01",x"01",x"D0",x"EC",x"D0",x"EC",x"D0",x"EC",x"80",x"D0",x"EC",x"EC",x"80",x"F0",x"80",x"01",
        x"01",x"D0",x"EC",x"80",x"80",x"D0",x"EC",x"EC",x"D0",x"F0",x"EC",x"80",x"EC",x"80",x"01",x"01",
        x"01",x"EC",x"EC",x"D0",x"D0",x"F0",x"EC",x"D0",x"EC",x"EC",x"F0",x"EC",x"80",x"F0",x"80",x"01",
        x"01",x"D0",x"EC",x"EC",x"EC",x"EC",x"F0",x"EC",x"EC",x"EC",x"EC",x"80",x"EC",x"EC",x"EC",x"80",
        x"01",x"EC",x"D0",x"EC",x"F0",x"EC",x"EC",x"80",x"80",x"EC",x"80",x"EC",x"80",x"80",x"EC",x"80",
        x"EC",x"D0",x"80",x"80",x"EC",x"EC",x"80",x"EC",x"80",x"EC",x"EC",x"80",x"EC",x"EC",x"80",x"01",
        x"01",x"EC",x"EC",x"EC",x"44",x"F0",x"EC",x"EC",x"EC",x"EC",x"80",x"EC",x"EC",x"EC",x"80",x"80",
        x"01",x"01",x"EC",x"EC",x"01",x"44",x"44",x"EC",x"80",x"44",x"80",x"EC",x"EC",x"80",x"80",x"01",
        x"01",x"01",x"EC",x"01",x"01",x"44",x"44",x"EC",x"44",x"80",x"EC",x"80",x"80",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"01",x"01",x"80",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",x"01",

        X"01",X"01",X"01",X"01",X"01",X"01",X"44",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",X"01",    -- x"09" TREE 2 AUTUMN
        X"01",X"01",X"01",X"01",X"44",X"44",X"EC",X"44",X"EC",X"44",X"01",X"01",X"01",X"01",X"01",X"01",
        X"01",X"01",X"44",X"EC",X"EC",X"F0",X"EC",X"EC",X"44",X"EC",X"80",X"EC",X"01",X"EC",X"01",X"01",
        X"01",X"44",X"44",X"F0",X"EC",X"EC",X"44",X"F0",X"F0",X"80",X"F0",X"EC",X"80",X"EC",X"01",X"01",
        X"01",X"44",X"F0",X"EC",X"44",X"EC",X"EC",X"F0",X"EC",X"EC",X"F0",X"EC",X"80",X"80",X"01",X"01",
        X"44",X"F0",X"44",X"F0",X"EC",X"EC",X"EC",X"EC",X"F0",X"80",X"EC",X"80",X"EC",X"01",X"01",X"01",
        X"EC",X"EC",X"EC",X"F0",X"44",X"44",X"EC",X"EC",X"EC",X"EC",X"80",X"EC",X"80",X"EC",X"01",X"01",
        X"44",X"44",X"EC",X"44",X"F0",X"EC",X"EC",X"80",X"F0",X"EC",X"F0",X"EC",X"EC",X"EC",X"EC",X"01",
        X"01",X"44",X"EC",X"EC",X"EC",X"F0",X"80",X"EC",X"EC",X"80",X"80",X"F0",X"EC",X"80",X"01",X"01",
        X"01",X"01",X"44",X"EC",X"F0",X"80",X"80",X"EC",X"80",X"EC",X"EC",X"80",X"EC",X"EC",X"01",X"01",
        X"01",X"01",X"EC",X"01",X"EC",X"EC",X"EC",x"44",X"EC",x"44",x"44",X"EC",X"80",X"01",X"01",X"01",
        X"01",X"01",X"01",X"01",X"01",X"EC",X"01",x"44",x"44",x"44",X"EC",X"80",X"EC",X"01",X"01",X"01",
        X"01",X"01",X"01",X"01",X"01",X"01",x"44",x"44",x"44",X"01",X"01",X"EC",X"01",X"01",X"01",X"01",
        X"01",X"01",X"01",X"01",X"01",X"01",X"01",x"44",x"44",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
        X"01",X"01",X"01",X"01",X"01",X"01",X"01",x"44",x"44",X"01",X"01",X"01",X"01",X"01",X"01",X"01",
        X"01",X"01",X"01",X"01",X"01",X"01",X"01",x"44",x"44",X"01",X"01",X"01",X"01",X"01",X"01",X"01",

        x"01",x"01",x"01",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",x"01",x"AC",x"AC",x"01",x"01",x"01",    -- x"0A" TREE 1 WINTER
        x"01",x"01",x"01",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",x"AC",x"AC",x"01",x"01",x"01",    
        x"AC",x"01",x"01",x"01",x"AC",x"AC",x"01",x"01",x"01",x"01",x"AC",x"AC",x"01",x"01",x"01",x"AC",
        x"AC",x"AC",x"01",x"FB",x"01",x"AC",x"AC",x"FB",x"01",x"01",x"AC",x"AC",x"01",x"AC",x"AC",x"AC",
        x"01",x"AC",x"AC",x"01",x"01",x"01",x"AC",x"AC",x"01",x"AC",x"AC",x"01",x"01",x"AC",x"01",x"01",
        x"01",x"01",x"AC",x"AC",x"01",x"FB",x"AC",x"AC",x"01",x"AC",x"01",x"01",x"AC",x"AC",x"AC",x"01",
        x"01",x"01",x"AC",x"AC",x"AC",x"01",x"AC",x"AC",x"01",x"AC",x"AC",x"AC",x"AC",x"FB",x"AC",x"01",
        x"01",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"AC",x"AC",
        x"AC",x"AC",x"01",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",x"01",x"AC",
        x"AC",x"01",x"01",x"01",x"AC",x"AC",x"AC",x"AC",x"AC",x"01",x"AC",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"FB",x"01",
        x"01",x"01",x"01",x"FB",x"FB",x"FB",x"AC",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"FB",x"FB",x"FB",x"01",x"01",x"01",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"AC",x"AC",x"AC",x"01",x"01",x"FB",x"FB",x"FB",x"FB",x"FB",
        x"01",x"01",x"01",x"01",x"FB",x"AC",x"AC",x"AC",x"AC",x"AC",x"AC",x"01",x"01",x"01",x"01",x"01",     

        x"01",x"01",x"01",x"01",x"01",x"44",x"01",x"01",x"01",x"01",x"01",x"44",x"01",x"01",x"01",x"01",    -- x"0B" TREE 2 WINTER
        x"01",x"01",x"44",x"01",x"44",x"01",x"44",x"44",x"01",x"01",x"44",x"01",x"01",x"01",x"44",x"01",
        x"01",x"44",x"01",x"44",x"01",x"01",x"01",x"44",x"01",x"01",x"01",x"44",x"01",x"44",x"01",x"44",
        x"01",x"01",x"01",x"44",x"44",x"44",x"01",x"44",x"44",x"01",x"44",x"01",x"44",x"01",x"44",x"01",
        x"01",x"01",x"44",x"01",x"01",x"44",x"01",x"01",x"44",x"01",x"44",x"44",x"01",x"44",x"01",x"01",
        x"01",x"44",x"01",x"01",x"01",x"44",x"44",x"01",x"44",x"44",x"44",x"01",x"44",x"01",x"01",x"01",
        x"44",x"01",x"44",x"01",x"44",x"01",x"44",x"44",x"44",x"01",x"44",x"44",x"01",x"01",x"44",x"01",
        x"01",x"01",x"44",x"44",x"44",x"44",x"44",x"01",x"44",x"44",x"44",x"01",x"44",x"44",x"01",x"01",
        x"01",x"01",x"01",x"01",x"44",x"01",x"44",x"44",x"01",x"44",x"01",x"44",x"44",x"01",x"44",x"01",
        x"01",x"01",x"01",x"01",x"44",x"44",x"01",x"44",x"44",x"44",x"44",x"44",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",x"01",x"01",
        x"01",x"01",x"01",x"01",x"01",x"44",x"44",x"44",x"44",x"44",x"44",x"01",x"01",x"01",x"01",x"01",

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

    --- Counter for slowing down goal_msg_cnt / the animation
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            goal_msg_clk <= (others => '0');     
        else
            goal_msg_clk <= goal_msg_clk + 1;
        end if;
    end if;
    end process;
    
    -- Counter for successively increasing how much of rainbow sprite is displayed
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1'  then
            goal_msg_cnt <= to_unsigned(192,10);       
        elsif goal_reached = '1' then
            showing_goal_msg <= '1';  -- Send signal to CPU that goal message is being shown. 
            goal_msg_cnt <= to_unsigned(192,10);  -- Start showing goal message from x = 192
        elsif goal_msg_cnt = to_unsigned(600, 10) then  -- Checks if end of rainbowanimation has been reached, Xpixel = 600
            showing_goal_msg <= '0';  -- Send signal to CPU that goal message is hidden. 
        elsif (goal_msg_clk = to_unsigned(131071,17) and showing_goal_msg = '1') then -- Everytime the goal_msg_clk reaches 131071 we increase the count, making the animation slow enough to see
            goal_msg_cnt <= goal_msg_cnt + 1;
        else
            null;
        end if;
    end if;
    end process;
    showing_goal_msg_out <= showing_goal_msg;
    goal_msg_x_limit <= goal_msg_cnt when (goal_msg_cnt < 449) else to_unsigned(448,10);  -- How far to display goal message while scrolling, max 448

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
            Xpixel2 <= (others => '0');
        elsif Clk25 = '1' then
		    if Xpixel2 = 799 then	-- vi har nått slutet av pixelantalet
			    Xpixel2 <= (others => '0');
		    else
			    Xpixel2 <= Xpixel2 + 1;
		    end if;
	    end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Xpixel1 <= (others => '0');
        elsif Clk25 = '1' then
		    Xpixel1 <= Xpixel2;
	    end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Xpixel <= (others => '0');
        elsif Clk25 = '1' then
		    Xpixel <= Xpixel1;
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
	        Ypixel2 <= (others => '0');
        elsif Clk25 = '1' and Xpixel2 = 799 then
            if Ypixel2 = 520 then	
	            Ypixel2 <= (others => '0');
            else 
	            Ypixel2 <= Ypixel2 + 1;
            end if;
        end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Ypixel1 <= (others => '0');
        elsif Clk25 = '1' then
		    Ypixel1 <= Ypixel2;
	    end if;
    end if;
    end process;
    
    process(clk)
    begin
    if rising_edge(clk) then
	    if rst = '1' then
            Ypixel <= (others => '0');
        elsif Clk25 = '1' then
		    Ypixel <= Ypixel1;
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

    -- Tile memory access   
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            yayPixel <= spriteMemYay(0);  -- Yay! Carrot ++
            rainbowPixel <= spriteMemRainbow(0);
            debugGPixel <= spriteMemDebugG(0);  
            bgPixel <= tileMem(0); -- Background tile
            dataPixel <= tileMem(0);  -- Regular tile data
        else
            yayPixel <= spriteMemYay(to_integer(yayAddr));  -- Yay! Carrot ++
            rainbowPixel <= spriteMemRainbow(to_integer(RainbowAddr));  
            debugGPixel <= spriteMemDebugG(to_integer(debugGAddr));  
            bgPixel <= tileMem(to_integer(bgTileAddr)); -- Background tile
            dataPixel <= tileMem(to_integer(tileAddr));  -- Regular tile data
        end if;
    end if;
    end process;
    
    -- Select what pixel to send out to display
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            pixel_out <= (others => '0');
        elsif (isYaySprite = '1' and showing_goal_msg = '1') then
            pixel_out <= yayPixel;
        elsif (isRainbowSprite = '1' and showing_goal_msg = '1') then   
            pixel_out <= rainbowPixel ;
        elsif (isDebugGSprite ='1' and disp_goal_pos = '1') then 
            pixel_out <= debugGPixel;
        elsif (blank = '0') then
            if (isTransparent = '1') then -- If current tile is transparent, we should display bg
                pixel_out <= bgPixel;
            else
                pixel_out <= dataPixel;
            end if;
        else
            pixel_out <= (others => '0');
        end if;
    end if;
    end process;
    
    -- Check if we're on the rainbow and that the pixel is not transparent
    isRainbowSprite <= '1' when ((Xpixel > 192 and Xpixel < goal_msg_x_limit) and (Ypixel > 100 and Ypixel < 228) and not (rainbowPixel = x"01")) else '0';
    -- Check if we're on "Yay, carrot ++" and that the pixel is not transparent
    isYaySprite <= '1' when ((Xpixel > 192 and Xpixel < 448 and goal_msg_x_limit = to_unsigned(448,10)) and (Ypixel > 240 and Ypixel < 368) and not (yayPixel = x"01")) else '0';
    -- Check if we're on the 'G' for goal pos and that the pixel is not transparent
    isDebugGSprite <= '1' when ((Xpixel > debug_g_xstart and Xpixel < debug_g_xend) and (Ypixel > debug_g_ystart and Ypixel < debug_g_yend) and not (debugGPixel = x"01")) else '0';
    -- Check if current tile represents transparancy
    isTransparent <= '1' when (dataPixel = x"01") else '0';
    
    -- Sets the offset in sprite mems of rainbow and "Yay".
    goal_msg_x_offset <= Xpixel1 - to_unsigned(192,10); -- Rainbow and "Yay" (goal msg) starts at Xpixel = 192
    rainbow_y_offset <= Ypixel1 - to_unsigned(100,10); -- Rainbow starts at Ypixel = 100
    yay_y_offset <= Ypixel1 - to_unsigned(240,10); -- "Yay" starts at Ypixel = 240

    -- Calculates coordinates of debug g in pixels
    debug_g_xstart <= to_unsigned(16 * to_integer(unsigned(goal_x)), 10); 
    debug_g_xend <= to_unsigned(16 * (to_integer(unsigned(goal_x)) + 1), 10);
    debug_g_ystart <= to_unsigned(16 * to_integer(unsigned(goal_y)), 10); 
    debug_g_yend <= to_unsigned(16 * (to_integer(unsigned(goal_y)) + 1),10);

    -- Tile memory address composite
    with sel_track select
    bgTile <= 
        "00000" when "00",  -- Track 1
        "00001" when "01",  -- Track 2
        "00010" when "10",  -- Track 3
        "00000" when "11",  -- Track 4
        (others =>'0') when others;
        
    -- Choose if we should set tileIndex to tile from TRACK or to carrot for displaying score. 
    score_x_limit <= to_unsigned(to_integer(score * 16), 10) when score < 40 else to_unsigned(624, 10);
    tileIndex <= "01110" when ((Xpixel1 > 0 and Xpixel1 < score_x_limit) and (Ypixel1 > 464 and Ypixel1 < 480)) else unsigned(data(4 downto 0)); -- Carrot tile or data tile
    
    -- Set addresses that choose tiles from TileMem    
    bgTileAddr <= bgTile & Ypixel1(3 downto 0) & Xpixel1(3 downto 0); -- Sel_track determines background tile (with select above).
    tileAddr <= tileIndex & Ypixel1(3 downto 0) & Xpixel1(3 downto 0); -- Set what tileAddr to give tileMem (carrot or from track).
    RainbowAddr <= rainbow_y_offset(6 downto 2) & goal_msg_x_offset(7 downto 2); --Ändras när vi ändrar spriteMem
    yayAddr <= yay_y_offset(6 downto 2) & goal_msg_x_offset(7 downto 2); --Ändras när vi ändrar spriteMem
    debugGAddr <= Ypixel1(3 downto 0) & Xpixel1(3 downto 0);

    -- Picture memory address composite
    addr <= to_unsigned(40, 6) * Ypixel2(8 downto 4) + Xpixel2(9 downto 4);

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

