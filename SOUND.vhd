--------------------------------------------------------------------------------
-- SOUND
-- Rebecca Lindblom
-- 31-mars-2017


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type and various arithmetic operations

-- entity
entity SOUND is
port (
    clk                 : in std_logic;                      -- system clock (100 MHz)
    rst                 : in std_logic;                      -- reset signal
    goal_pos            : in signed(17 downto 0);  -- goal position
    curr_pos            : in signed(17 downto 0);  -- current position
    channel             : in std_logic;                      -- deciding which of the two sound that should be played, 0 = curr, 1 = goal.
    sound_data          : out std_logic;
    test_diod           : out std_logic;
    test2_diod          : out std_logic
    );                    -- output to speaker
    --sound_enable        : in std_logic;                      -- possible for later to add on/off for sound
    
end SOUND;

-- architecture
architecture behavioral of SOUND is
    
    alias goal_x : signed(5 downto 0) is goal_pos(14 downto 9);
    alias goal_y : signed(4 downto 0) is goal_pos(4 downto 0);
    
    alias curr_x : signed(5 downto 0) is curr_pos(14 downto 9);
    alias curr_y : signed(4 downto 0) is curr_pos(4 downto 0);

    signal x            : signed(5 downto 0);         -- x-position for playing
    signal y            : signed(4 downto 0);         -- y-position for playing

    signal beat         : signed(26 downto 0);        -- Divided value for desired frequency for beat at position
    signal freq         : signed(16 downto 0);        -- Divided value for desired frequency for freq at position

    signal clk_div_beat : unsigned(26 downto 0);        -- Dividing clock for beat
    signal clk_div_freq : unsigned(16 downto 0);        -- Dividing clock for freq

    signal clk_beat     : std_logic := '0';                            -- Clock signal for beat
    signal clk_freq     : std_logic := '0';                            -- Clock signal for freq

    -- Flip flops
    signal q_beat       : std_logic := '0';                       -- Beat flip flop
    signal q_beat_plus  : std_logic := '0';    
    
    signal q_freq       : std_logic := '0';                       -- Freq flip flop
    signal q_freq_plus  : std_logic := '0';

    -- ******* TESTING *******
    --signal test         : signed(16 downto 0) := to_signed(113636, 17);
    --signal clk_test     : std_logic := '0';
    --signal clk_div_test : unsigned(16 downto 0);
    --signal q_test       : std_logic := '0';
    --signal q_test_plus  : std_logic := '0';
begin

    -- Set signals for playing sound
    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                x <= "000000";
                y <= "00000";
            elsif channel = '1' then
                x <= goal_x;
                y <= goal_y;
            else
                x <= curr_x;
                y <= curr_y;
            end if;
        end if;
    end process;


    -- y position -> beat value for toggle clk_beat
    -- follows beat = round(100000000 / (0.555764 * exp(0.0980482 * y)))
    -- See list of Hz-values in frequencies.txt
    -- Position is 0 at top of screen
    with y select
        beat <=
        to_signed(100000000, 27) when to_signed(0, 5),
        to_signed(78947368, 27) when to_signed(1, 5),
        to_signed(65217391, 27) when to_signed(2, 5),
        to_signed(55555556, 27) when to_signed(3, 5),
        to_signed(48387097, 27) when to_signed(4, 5),
        to_signed(42857143, 27) when to_signed(5, 5),
        to_signed(38461538, 27) when to_signed(6, 5),
        to_signed(34883721, 27) when to_signed(7, 5),
        to_signed(31914894, 27) when to_signed(8, 5),
        to_signed(29411765, 27) when to_signed(9, 5),
        to_signed(27272727, 27) when to_signed(10, 5),
        to_signed(25000000, 27) when to_signed(11, 5),
        to_signed(23076923, 27) when to_signed(12, 5),
        to_signed(21428571, 27) when to_signed(13, 5),
        to_signed(19736842, 27) when to_signed(14, 5),
        to_signed(18072289, 27) when to_signed(15, 5),
        to_signed(16666667, 27) when to_signed(16, 5),
        to_signed(15384615, 27) when to_signed(17, 5),
        to_signed(14218009, 27) when to_signed(18, 5),
        to_signed(13043478, 27) when to_signed(19, 5),
        to_signed(11904762, 27) when to_signed(20, 5),
        to_signed(10909091, 27) when to_signed(21, 5),
        to_signed(10000000, 27) when to_signed(22, 5),
        to_signed(9090909, 27) when to_signed(23, 5),
        to_signed(8108108, 27) when to_signed(24, 5),
        to_signed(7317073, 27) when to_signed(25, 5),
        to_signed(6521739, 27) when to_signed(26, 5),
        to_signed(5769231, 27) when to_signed(27, 5),
        to_signed(5084746, 27) when to_signed(28, 5),
        to_signed(4545455, 27) when to_signed(29, 5),
        to_signed(1, 27) when others;

    -- x-position -> freq value for toggle clk_freq
    -- Follows freq <= round(100_000_000/ (440 + 25*x)
    -- See list of Hz-values in frequencies.txt
    -- Position is 0 at left of screen
    with x select
        freq <=
        to_signed(107527, 17) when to_signed(0, 6),
        to_signed(102041, 17) when to_signed(1, 6),
        to_signed(97087, 17) when to_signed(2, 6),
        to_signed(92593, 17) when to_signed(3, 6),
        to_signed(88496, 17) when to_signed(4, 6),
        to_signed(84746, 17) when to_signed(5, 6),
        to_signed(81301, 17) when to_signed(6, 6),
        to_signed(78125, 17) when to_signed(7, 6),
        to_signed(75188, 17) when to_signed(8, 6),
        to_signed(72464, 17) when to_signed(9, 6),
        to_signed(69930, 17) when to_signed(10, 6),
        to_signed(67568, 17) when to_signed(11, 6),
        to_signed(65359, 17) when to_signed(12, 6),
        to_signed(63291, 17) when to_signed(13, 6),
        to_signed(61350, 17) when to_signed(14, 6),
        to_signed(59524, 17) when to_signed(15, 6),
        to_signed(57803, 17) when to_signed(16, 6),
        to_signed(56180, 17) when to_signed(17, 6),
        to_signed(54645, 17) when to_signed(18, 6),
        to_signed(53191, 17) when to_signed(19, 6),
        to_signed(51813, 17) when to_signed(20, 6),
        to_signed(50505, 17) when to_signed(21, 6),
        to_signed(49261, 17) when to_signed(22, 6),
        to_signed(48077, 17) when to_signed(23, 6),
        to_signed(46948, 17) when to_signed(24, 6),
        to_signed(45872, 17) when to_signed(25, 6),
        to_signed(44843, 17) when to_signed(26, 6),
        to_signed(43860, 17) when to_signed(27, 6),
        to_signed(42918, 17) when to_signed(28, 6),
        to_signed(42017, 17) when to_signed(29, 6),
        to_signed(41152, 17) when to_signed(30, 6),
        to_signed(40323, 17) when to_signed(31, 6),
        to_signed(39526, 17) when to_signed(32, 6),
        to_signed(38760, 17) when to_signed(33, 6),
        to_signed(38023, 17) when to_signed(34, 6),
        to_signed(37313, 17) when to_signed(35, 6),
        to_signed(36630, 17) when to_signed(36, 6),
        to_signed(35971, 17) when to_signed(37, 6),
        to_signed(35336, 17) when to_signed(38, 6),
        to_signed(34722, 17) when to_signed(39, 6),
        to_signed(1, 11) when others;
      
        
    -- Clock divisor
    -- Divide system clock (100 MHz) by beat and freq
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
                clk_div_beat <= (others => '0');
                clk_div_freq <= (others => '0');
            elsif clk_div_beat = unsigned(beat) then
                clk_div_beat <= (others => '0');
                clk_div_freq <= clk_div_freq + 1;
            elsif clk_div_freq = unsigned(beat) then
                clk_div_freq <= (others => '0');
                clk_div_beat <= clk_div_beat + 1;
            else
                clk_div_beat <= clk_div_beat + 1;
                clk_div_freq <= clk_div_freq + 1;
            end if;
        end if;
    end process;

    -- Toggle sound clocks to get 50% duty cycle
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_beat <= '0';
            elsif clk_div_beat = unsigned(beat) then
                clk_beat <= not clk_beat;
            end if;
        end if;
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_freq <= '0';
            elsif clk_div_freq = unsigned(freq) then
                clk_freq <= not clk_freq;
            end if;
        end if;
    end process;


    ---- Beat flip flop
    process(clk_beat) begin
        if rising_edge(clk_beat) then
            if rst = '1' then
                q_beat <= '0';
            else
                q_beat <= q_beat_plus;
            end if;
        end if;
    end process;

    ---- Freq flip flop
    process(clk_freq) begin
        if rising_edge(clk_freq) then
            if rst='1' then
                q_freq <= '0';
            else
                q_freq <= q_freq_plus;
            end if;
        end if;
    end process;
        
    q_beat_plus <= not q_beat;
    q_freq_plus <= q_beat and (not q_freq);
    
    test_diod <= q_beat;
    test2_diod <= clk_beat;
    
    sound_data <= q_freq;

    -- ********** TESTING **************
    
    -- Clock divisor
    -- Divide system clock (100 MHz) by test
    --process(clk) begin
    --    if rising_edge(clk) then
    --        if rst='1' then
    --            clk_div_test <= (others => '0');
    --        elsif clk_div_test = unsigned(test) then
    --            clk_div_test <= (others => '0');
    --        else
    --            clk_div_test <= clk_div_test + 1;
    --        end if;
    --    end if;
    --end process;

    -- Toggle sound clocks to get 50% duty cycle
    --process(clk) begin
    --    if rising_edge(clk) then
    --        if rst = '1' then
    --            clk_test <= '0';
    --        elsif clk_div_test = unsigned(test) then
    --            clk_test <= not clk_test;
    --        end if;
    --    end if;
    --end process;
    
    -- flip flop
    --process(clk_test) begin
    --    if rising_edge(clk_test) then
    --        if rst='1' then
    --            q_test <= '0';
    --        else
    --            q_test <= q_test_plus;
    --        end if;
    --    end if;
    --end process;

    --q_test_plus <= not q_test;
    
    --sound_data <= q_test;
    --test_diod <= q_test;
    --test2_diod <= clk_test;
  
end behavioral;
