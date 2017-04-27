--------------------------------------------------------------------------------
-- SOUND
-- Rebecca Lindblom
-- 31-mars-2017
-- Version 1.0


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
    sound_data          : out std_logic);                    -- output to speaker
    --sound_enable        : in std_logic;                      -- possible for later to add on/off for sound
end SOUND;

-- architecture
architecture behavioral of SOUND is
    
    signal goal_x       : signed(5 downto 0);
    signal curr_x       : signed(5 downto 0);
   
    signal goal_y       : signed(4 downto 0);
    signal curr_y       : signed(4 downto 0);

    signal x            : signed(5 downto 0);         -- x-position for playing
    signal y            : signed(4 downto 0);         -- y-position for playing

    signal beat         : signed(19 downto 0);        -- Divided value for desired frequency for beat at position
    signal freq         : signed(10 downto 0);        -- Divided value for desired frequency for freq at position

    signal clk_div_beat : signed(19 downto 0);        -- Dividing clock for beat
    signal clk_div_freq : signed(10 downto 0);        -- Dividing clock for freq

    signal clk_beat     : std_logic;                            -- Clock signal for beat
    signal clk_freq     : std_logic;                            -- Clock signal for freq

    -- Flip flops
    signal q_beat       : std_logic := '0';                       -- Beat flip flop
    signal q_beat_plus  : std_logic := '0';    
    
    signal q_freq       : std_logic := '0';                       -- Freq flip flop
    signal q_freq_plus  : std_logic := '0';     

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
      "11110100001001000000" when "11101",--1000000 when 29,
      "11000000101111100010"  when "11100",--789474  when 28,
      "10011111001110001110"  when "11011",--652174  when 27,
      "10000111101000100100"  when "11010",--555556  when 26,
      "01110110001000011111" when "11001",--483871  when 25,
      "01101000101000011011"  when "11000",--428571  when 24,
      "01011101111001100111"  when "10111",--384615  when 23,
      "01010101001010100101"  when "10110",--348837  when 22,
      "01001101111010101101"  when "10101",--319149  when 21,
      "01000111110011100110"  when "10100",--294118  when 20,
      "01000010100101010111"  when "10011",--272727  when 19,
      "00111101000010010000"  when "10010",--250000  when 18,
      "00111000010101110001"  when "10001",--230769  when 17,
      "00110100010100001110"  when "10000",--214286  when 16,
      "00110000001011111000"  when "01111",--197368  when 15,
      "00101100000111110011"  when "01110",--180723  when 14,
      "00101000101100001011" when "01101",--166667  when 13,
      "00100101100011110110"  when "01100",--153846  when 12,
      "00100010101101100100"  when "01011",--142180  when 11,
      "00011111110110000011"  when "01010",--130435  when 10,
      "00011101000100001000"  when "01001",--119048  when 9,
      "00011010101000100011"  when "01000",--109091  when 8,
      "00011000011010100000"  when "00111",--100000  when 7,
      "00010110001100011101"   when "00110",--90909   when 6,
      "00010011110010111001"   when "00101",--81081   when 5,
      "00010001110111010011"   when "00100",--73171   when 4,
      "00001111111011000001"   when "00011",--65217   when 3,
      "00001110000101011100"   when "00010",--57692   when 2,
      "00001100011010011111"   when "00001",--50847   when 1,
      "00001011000110001111"   when "00000",--45455   when 0,
      "00000000000000000001"   when others;--1       when others;

    -- x-position -> freq value for toggle clk_freq
    -- Follows freq <= round(100000000/ (300 + 25*x)
    -- See list of Hz-values in frequencies.txt
    -- Position is 0 at left of screen
    with x select
      freq <=
      "11000000010" when "000000",--1538 when 0,
      "10110010101" when "000001",--1429 when 1,
      "10100110101" when "000010",--1333 when 2,
      "10011100010" when "000011",--1250 when 3,
      "10010011000" when "000100",--1176 when 4,
      "10001010111" when "000101",--1111 when 5,
      "10000011101" when "000110",--1053 when 6,
      "01111101000" when "000111",--1000 when 7,
      "01110111000"  when "001000",--952  when 8,
      "01110001101"  when "001001",--909  when 9,
      "01101100110"  when "001010",--870  when 10,
      "01101000001"  when "001011",--833  when 11,
      "01100100000"  when "001100",--800  when 12,
      "01100000001" when "001101",--769  when 13,
      "01011100101"  when "001110",--741  when 14,
      "01011001010"  when "001111",--714  when 15,
      "01010110010"  when "010000",--690  when 16,
      "01010011011"  when "010001",--667  when 17,
      "01010000101"  when "010010",--645  when 18,
      "01001110001" when "010011",--625  when 19,
      "01001011110"  when "010100",--606  when 20,
      "01001001100"  when "010101",--588  when 21,
      "01000111011"  when "010110",--571  when 22,
      "01000101100" when "010111",--556  when 23,
      "01000011101"  when "011000",--541  when 24,
      "01000001110"  when "011001",--526  when 25,
      "01000000001"  when "011010",--513  when 26,
      "00111110100"  when "011011",--500  when 27,
      "00111101000"  when "011100",--488  when 28
      "00111011100"  when "011101",--476  when 29,
      "00111010001"  when "011110",--465  when 30,
      "00111000111" when "011111",--455  when 31,
      "00110111100" when "100000",--444  when 32,
      "00110110011"  when "100001",--435  when 33,
      "00110101010"  when "100010",--426  when 34,
      "00110100001"  when "100011",--417  when 35,
      "00110011000"  when "100100",--408  when 36,
      "00110010000"  when "100101",--400  when 37,
      "00110001000"  when "100110",--392  when 38,
      "00110000001"  when "100111",--385  when 39,
      "00000000001"    when others;--1    when others;

        
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

    -- Toggle sound clocks to get 50% duty cycle
    clk_beat <= not clk_beat when (clk_beat_div < beat) else clk_beat;
    clk_freq <= not clk_freq when (clk_freq_div < freq) else clk_freq;


    -- Beat flip flop
    process(clk_beat) begin
        if rising_edge(clk_beat) then
            if rst='1' then
                q_beat <= 0;
            else
                q_beat <= q_beat_plus;
            end if;
        end if;
    end process;

    -- Freq flip flop
    process(clk_freq) begin
        if rising_edge(clk_beat) then
            if rst='1' then
                q_freq <= 0;
            else
                q_freq <= q_freq_plus;
            end if;
        end if;
    end process;
        
    --q_beat_plus <= sound_enable and not q_beat;
    q_beat_plus <= not q_beat;
    q_freq_plus <= q_beat and not q_freq;
  
end behavioral;
