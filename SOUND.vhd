--------------------------------------------------------------------------------
-- SOUND
-- Rebecca Lindblom
-- 31-mars-2017
-- Version 1.0


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type and various arithmetic operations
use IEEE.MATH_REAL.ALL;                 -- For floor, ceil, round etc.

-- entity
entity SOUND is
port (clk               : in std_logic;                      -- system clock (100 MHz)
    rst                 : in std_logic;                      -- reset signal
    goal_pos            : in std_logic_vector(17 downto 0);  -- goal position
    curr_pos            : in std_logic_vector(17 downto 0);  -- current position
    channel             : in std_logic;                      -- deciding which of the two sound that should be played, 0 = corr, 1 = goal.
    sound_data          : out std_logic;                     -- output to speaker
    --sound_enable        : in std_logic;                      -- possible for later to add on/off for sound
end SOUND;

-- architecture
architecture behavioral of SOUND is
    
    signal goal_x       : std_logic_vector(5 downto 0);
    signal curr_x       : std_logic_vector(5 downto 0);
   
    signal goal_y       : std_logic_vector(4 downto 0);
    signal curr_y       : std_logic_vector(4 downto 0);

    signal x            : std_logic_vector(5 downto 0);         -- x-signal for playing
    signal y            : std_logic_vector(4 downto 0);         -- y-signal for playing

    signal freq         : std_logic_vector(5 downto 0);         -- Divided value for desired frequency for freq at position,
                                                                -- 40 cols gives 40 possible frequencies
    signal beat         : std_logic_vector(4 downto 0);         -- Divided value for desired frequency for beat at position,
                                                                -- 30 cols gives 30 possible beats

    signal clk_div_beat : std_logic_vector;                     -- Dividing clock for beat
    signal clk_div_freq : std_logic_vector;                     -- Dividing clock for freq

    signal clk_beat : std_logic;                                -- Clock signal for beat
    signal clk_freq : std_logic;                                -- Clock signal for freq


begin

    -- Set signals for playing sound
    process(clk)
    begin
        if rising_edge(clk) then
            if channel = '1' then
                x <= goal_x;
                y <= goal_y;
            else
                x <= curr_x;
                y <= curr_y;
            end if;
        end if;
    end process;

    -- Transfer position data to internal signals
    process(clk)
    begin
        if rising_edge(clk) then
            goal_x <= goal_pos(14 downto 9);
            goal_y <= goal_pos(4 downto 0);
            curr_x <= curr_pos(14 downto 9);
            curr_y <= curr_pos(4 downto 0);
        end if;
    end process;

    
    -- Generate beat and freq
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
                beat <= 1;
                freq <= 1;
            else
                beat <= floor(100000000 / (0.555764 * exp(0.0980482 * y)));  -- 100 MHz/desired beat, gives value for when to toggle clk_beat.
                freq <= floor(100000000/ (300 + 25*x);                       -- 100 MHz/desired freq, gives value for when to toggle clk_freq.
            end if;
        end if;
    end process;
        
    -- Clock divisor
    -- Divide system clock (100 MHz) by beat and freq
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
                clk_div_beat <= (others => '0');
                clk_div_freq <= (others => '0');
            elsif clk_div_beat = beat then
                clk_div_beat <= 0;
            elsif clk_div_freq = beat then
                clk_div_freq <= 0;
            else
                clk_div_beat <= clk_div_beat + 1;
                clk_div_freq <= clk_div_freq + 1;
            end if;
        end if;
    end process;
	
  -- Set sound clocks (one system clock pulse width)
  clk_beat <= not clk_beat when (clk_beat_div <  floor(beat/2)) else clk_beat;
  clk_freq <= not clk_freq when (clk_freq_div <  floor(freq/2)) else clk_freq;

  
    

  -- Scan Code -> Tile Index mapping
  --with ScanCode select
  --  TileIndex <= x"00" when x"29",  -- space
  --  x"01" when x"1C",   -- A
  --  x"02" when x"32",   -- B
  --  x"03" when x"21",   -- C
  --  x"04" when x"23",   -- D
  --  x"05" when x"24",   -- E
  --  x"06" when x"2B",   -- F
  --  x"07" when x"34",   -- G
  --  x"08" when x"33",   -- H
  --  x"09" when x"43",   -- I
  --  x"0A" when x"3B",   -- J
  --  x"0B" when x"42",   -- K
  --  x"0C" when x"4B",   -- L
  --  x"0D" when x"3A",   -- M
  --  x"0E" when x"31",   -- N
  --  x"0F" when x"44",   -- O
  --  x"10" when x"4D",   -- P
  --  x"11" when x"15",   -- Q
  --  x"12" when x"2D",   -- R
  --  x"13" when x"1B",   -- S
  --  x"14" when x"2C",   -- T
  --  x"15" when x"3C",   -- U
  --  x"16" when x"2A",   -- V
  --  x"17" when x"1D",   -- W
  --  x"18" when x"22",   -- X
  --  x"19" when x"35",   -- Y
  --  x"1A" when x"1A",   -- Z
  --  x"1B" when x"54",  -- Å
  --  x"1C" when x"52",  -- Ä
  --  x"1D" when x"4C",  -- Ö
  --  x"00" when others;
    



  
end behavioral;
