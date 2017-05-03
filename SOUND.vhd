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

    signal beat         : signed(19 downto 0);        -- Divided value for desired frequency for beat at position
    signal freq         : signed(10 downto 0);        -- Divided value for desired frequency for freq at position

    signal clk_div_beat : unsigned(19 downto 0);        -- Dividing clock for beat
    signal clk_div_freq : unsigned(10 downto 0);        -- Dividing clock for freq

    signal clk_beat     : std_logic := '0';                            -- Clock signal for beat
    signal clk_freq     : std_logic := '0';                            -- Clock signal for freq

    -- Flip flops
    signal q_beat       : std_logic := '0';                       -- Beat flip flop
    signal q_beat_plus  : std_logic := '0';    
    
    signal q_freq       : std_logic := '0';                       -- Freq flip flop
    signal q_freq_plus  : std_logic := '0';

    signal test         : signed(10 downto 0) := to_signed(350);
    signal clk_test     : std_logic := '0';
    signal clk_div_test : unsigned(10 downto 0);
    signal q_test       : std_logic := '0';
    signal q_test_plus  : std_logic := '0';
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
      --"11110100001001000000" when "11101",--1000000 when 29,
      --to_signed(789474, 20) when
      --"11000000101111100010"  when "11100",--789474  when 28,
      --"10011111001110001110"  when "11011",--652174  when 27,
      --"10000111101000100100"  when "11010",--555556  when 26,
      --"01110110001000011111" when "11001",--483871  when 25,
      --"01101000101000011011"  when "11000",--428571  when 24,
      --"01011101111001100111"  when "10111",--384615  when 23,
      --"01010101001010100101"  when "10110",--348837  when 22,
      --"01001101111010101101"  when "10101",--319149  when 21,
      --"01000111110011100110"  when "10100",--294118  when 20,
      --"01000010100101010111"  when "10011",--272727  when 19,
      --"00111101000010010000"  when "10010",--250000  when 18,
      --"00111000010101110001"  when "10001",--230769  when 17,
      --"00110100010100001110"  when "10000",--214286  when 16,
      --"00110000001011111000"  when "01111",--197368  when 15,
      --"00101100000111110011"  when "01110",--180723  when 14,
      --"00101000101100001011" when "01101",--166667  when 13,
      --"00100101100011110110"  when "01100",--153846  when 12,
      --"00100010101101100100"  when "01011",--142180  when 11,
      --"00011111110110000011"  when "01010",--130435  when 10,
      --"00011101000100001000"  when "01001",--119048  when 9,
      --"00011010101000100011"  when "01000",--109091  when 8,
      --"00011000011010100000"  when "00111",--100000  when 7,
      --"00010110001100011101"   when "00110",--90909   when 6,
      --"00010011110010111001"   when "00101",--81081   when 5,
      --"00010001110111010011"   when "00100",--73171   when 4,
      --"00001111111011000001"   when "00011",--65217   when 3,
      --"00001110000101011100"   when "00010",--57692   when 2,
      --"00001100011010011111"   when "00001",--50847   when 1,
      ----"00001011000110001111"   when "00000",--45455   when 0,
      to_signed(1000000, 20)   when others;--Maximum      when others;

    -- x-position -> freq value for toggle clk_freq
    -- Follows freq <= round(100000000/ (300 + 25*x)
    -- See list of Hz-values in frequencies.txt
    -- Position is 0 at left of screen
    with x select
        freq <=
        to_signed(1075, 11) when to_signed(0, 6),
        to_signed(1020, 11) when to_signed(1, 6),
        to_signed(971, 11) when to_signed(2, 6),
        to_signed(926, 11) when to_signed(3, 6),
        to_signed(885, 11) when to_signed(4, 6),
        to_signed(847, 11) when to_signed(5, 6),
        to_signed(813, 11) when to_signed(6, 6),
        to_signed(781, 11) when to_signed(7, 6),
        to_signed(752, 11) when to_signed(8, 6),
        to_signed(725, 11) when to_signed(9, 6),
        to_signed(699, 11) when to_signed(10, 6),
        to_signed(676, 11) when to_signed(11, 6),
        to_signed(654, 11) when to_signed(12, 6),
        to_signed(633, 11) when to_signed(13, 6),
        to_signed(613, 11) when to_signed(14, 6),
        to_signed(595, 11) when to_signed(15, 6),
        to_signed(578, 11) when to_signed(16, 6),
        to_signed(562, 11) when to_signed(17, 6),
        to_signed(546, 11) when to_signed(18, 6),
        to_signed(532, 11) when to_signed(19, 6),
        to_signed(518, 11) when to_signed(20, 6),
        to_signed(505, 11) when to_signed(21, 6),
        to_signed(493, 11) when to_signed(22, 6),
        to_signed(481, 11) when to_signed(23, 6),
        to_signed(469, 11) when to_signed(24, 6),
        to_signed(459, 11) when to_signed(25, 6),
        to_signed(448, 11) when to_signed(26, 6),
        to_signed(439, 11) when to_signed(27, 6),
        to_signed(429, 11) when to_signed(28, 6),
        to_signed(420, 11) when to_signed(29, 6),
        to_signed(412, 11) when to_signed(30, 6),
        to_signed(403, 11) when to_signed(31, 6),
        to_signed(395, 11) when to_signed(32, 6),
        to_signed(388, 11) when to_signed(33, 6),
        to_signed(380, 11) when to_signed(34, 6),
        to_signed(373, 11) when to_signed(35, 6),
        to_signed(366, 11) when to_signed(36, 6),
        to_signed(360, 11) when to_signed(37, 6),
        to_signed(353, 11) when to_signed(38, 6),
        to_signed(347, 11) when to_signed(39, 6),
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


    -- Beat flip flop
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                q_beat <= '0';
            elsif clk_beat = '1' then
                q_beat <= q_beat_plus;
            end if;
        end if;
    end process;
                


    -- Freq flip flop
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
                q_freq <= '0';
            elsif clk_freq = '1' then
                q_freq <= q_freq_plus;
            end if;
        end if;
    end process;
        
    --q_beat_plus <= sound_enable and not q_beat;
    q_beat_plus <= not q_beat;
    q_freq_plus <= q_beat and (not q_freq);
    --q_freq_plus <= not q_freq;
    
    test_diod <= q_beat;
    test2_diod <= clk_beat;
    
    --sound_data <= q_freq;

    -- ********** TESTING **************
    -- flip flop
    process(clk) begin
        if rising_edge(clk) then
            if rst='1' then
                q_test <= '0';
            elsif clk_test = '1' then
                q_test <= q_test_plus;
            end if;
        end if;
    end process;
  
end behavioral;
