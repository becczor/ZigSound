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

    signal x            : std_logic_vector(5 downto 0);         -- x-position for playing
    signal y            : std_logic_vector(4 downto 0);         -- y-position for playing

    signal freq         : std_logic_vector(10 downto 0);        -- Divided value for desired frequency for freq at position
    signal beat         : std_logic_vector(19 downto 0);        -- Divided value for desired frequency for beat at position

    signal clk_div_beat : std_logic_vector;                     -- Dividing clock for beat
    signal clk_div_freq : std_logic_vector;                     -- Dividing clock for freq

    signal clk_beat : std_logic;                                -- Clock signal for beat
    signal clk_freq : std_logic;                                -- Clock signal for freq


begin

    -- Set signals for playing sound
    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                x <= 0;
                y <= 0;
            elsif channel = '1' then
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
            -- Should look at registers all the time, even at reset
            goal_x <= goal_pos(14 downto 9);
            goal_y <= goal_pos(4 downto 0);
            curr_x <= curr_pos(14 downto 9);
            curr_y <= curr_pos(4 downto 0);
        end if;
    end process;


    -- y position -> beat value for toggle clk_beat
    -- follows beat = round(100000000 / (0.555764 * exp(0.0980482 * y)))
    -- See list of Hz-values in frequencies.txt
    -- Position is 0 at top of screen
    with y select
      beat <=
      1000000 when 29,
      789474  when 28,
      652174  when 27,
      555556  when 26,
      483871  when 25,
      428571  when 24,
      384615  when 23,
      348837  when 22,
      319149  when 21,
      294118  when 20,
      272727  when 19,
      250000  when 18,
      230769  when 17,
      214286  when 16,
      197368  when 15,
      180723  when 14,
      166667  when 13,
      153846  when 12,
      142180  when 11,
      130435  when 10,
      119048  when 9,
      109091  when 8,
      100000  when 7,
      90909   when 6,
      81081   when 5,
      73171   when 4,
      65217   when 3,
      57692   when 2,
      50847   when 1,
      45455   when 0,
      1       when others;

    -- x-position -> freq value for toggle clk_freq
    -- Follows freq <= round(100000000/ (300 + 25*x)
    -- See list of Hz-values in frequencies.txt
    -- Position is 0 at left of screen
    with x select
      freq <=
      1538 when 0,
      1429 when 1,
      1333 when 2,
      1250 when 3,
      1176 when 4,
      1111 when 5,
      1053 when 6,
      1000 when 7,
      952  when 8,
      909  when 9,
      870  when 10,
      833  when 11,
      800  when 12,
      769  when 13,
      741  when 14,
      714  when 15,
      690  when 16,
      667  when 17,
      645  when 18,
      625  when 19,
      606  when 20,
      588  when 21,
      571  when 22,
      556  when 23,
      541  when 24,
      526  when 25,
      513  when 26,
      500  when 27,
      488  when 28
      476  when 29,
      465  when 30,
      455  when 31,
      444  when 32,
      435  when 33,
      426  when 34,
      417  when 35,
      408  when 36,
      400  when 37,
      392  when 38,
      385  when 39,
      1    when others;

        
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
  clk_beat <= not clk_beat when (clk_beat_div < beat) else clk_beat;
  clk_freq <= not clk_freq when (clk_freq_div < freq) else clk_freq;

  
end behavioral;
