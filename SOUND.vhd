--------------------------------------------------------------------------------
-- SOUND
-- Rebecca Lindblom
-- 31-mars-2017
-- Version 1.0


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity SOUND is
port (clk               : in std_logic;                      -- system clock (100 MHz)
    rst                 : in std_logic;                      -- reset signal
    goal_pos            : in std_logic_vector(17 downto 0);  -- goal position
    curr_pos            : in std_logic_vector(17 downto 0);  -- current position
    channel             : in std_logic;                      -- deciding which of the two sound that should be played
    sound_enable        : in std_logic;                      -- possible for later to add on/off for sound
    sound_data          : out std_logic;                     -- output to speaker
end SOUND;

-- architecture
architecture behavioral of SOUND is
    signal freq_clk     : std_logic_vector(5 downto 0);         -- 40 cols gives 40 possible frequencies
    signal goal_x       : std_logic_vector(5 downto 0);
    signal curr_x       : std_logic_vector(5 downto 0);

    signal beat_clk     : std_logic_vector(4 downto 0);         -- 30 rows gives 30 possible beats
    signal goal_y       : std_logic_vector(4 downto 0);
    signal curr_y       : std_logic_vector(4 downto 0);
begin

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

    
  -- Generate one cycle pulse from PS2 clock, negative edge

    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                PS2Clk_Q1 <= '1';
                PS2Clk_Q2 <= '0';
            else
                PS2Clk_Q1 <= PS2Clk;
                PS2Clk_Q2 <= not PS2Clk_Q1;
            end if;
        end if;
    end process;
    
  PS2Clk_op <= (not PS2Clk_Q1) and (not PS2Clk_Q2);
    

  
  -- PS2 data shift register

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_data_shift_reg             *
  -- *                                 *
  -- ***********************************
process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        PS2Data_sr <= "00000000000";
      elsif PS2Clk_op = '1' then
        PS2Data_sr <= PS2Data & PS2Data_sr(10 downto 1);
      end if;
    end if;
  end process;

  ScanCode <= PS2Data_sr(8 downto 1);
    
  -- PS2 bit counter
  -- The purpose of the PS2 bit counter is to tell the PS2 state machine when to change state

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_bit_Counter                *
  -- *                                 *
  -- ***********************************

process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        PS2BitCounter <= "0000";
      elsif BC11 = '1' then
        PS2BitCounter <= "0000";
      elsif PS2Clk_op = '1' then
        PS2BitCounter <= PS2BitCounter + 1;
      end if;
    end if;
  end process;

  BC11  <= '1' when (PS2BitCounter = "1011") else '0';

  -- PS2 state
  -- Either MAKE or BREAK state is identified from the scancode
  -- Only single character scan codes are identified
  -- The behavior of multiple character scan codes is undefined

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_State                      *
  -- *                                 *
  -- ***********************************

  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        PS2state <= IDLE;
      else
        case PS2state is
          when IDLE =>
            if ((BC11 = '1') and (not (ScanCode = x"F0"))) then
              PS2state <= MAKE;
            elsif ((BC11 = '1') and (ScanCode = x"F0")) then
              PS2state <= BREAK;
            else
              PS2state <= IDLE;
            end if;
          when MAKE =>
            PS2state <= IDLE;
          when BREAK =>
            if BC11 = '1' then
              PS2state <= IDLE;
            else
              PS2state <= BREAK;
            end if;
          when others =>
            PS2state <= IDLE;
        end case;
      end if;
    end if;
  end process;

    
    

  -- Scan Code -> Tile Index mapping
  with ScanCode select
    TileIndex <= x"00" when x"29",  -- space
    x"01" when x"1C",   -- A
    x"02" when x"32",   -- B
    x"03" when x"21",   -- C
    x"04" when x"23",   -- D
    x"05" when x"24",   -- E
    x"06" when x"2B",   -- F
    x"07" when x"34",   -- G
    x"08" when x"33",   -- H
    x"09" when x"43",   -- I
    x"0A" when x"3B",   -- J
    x"0B" when x"42",   -- K
    x"0C" when x"4B",   -- L
    x"0D" when x"3A",   -- M
    x"0E" when x"31",   -- N
    x"0F" when x"44",   -- O
    x"10" when x"4D",   -- P
    x"11" when x"15",   -- Q
    x"12" when x"2D",   -- R
    x"13" when x"1B",   -- S
    x"14" when x"2C",   -- T
    x"15" when x"3C",   -- U
    x"16" when x"2A",   -- V
    x"17" when x"1D",   -- W
    x"18" when x"22",   -- X
    x"19" when x"35",   -- Y
    x"1A" when x"1A",   -- Z
    x"1B" when x"54",  -- Å
    x"1C" when x"52",  -- Ä
    x"1D" when x"4C",  -- Ö
    x"00" when others;
                         
                         
  -- set cursor movement based on scan code
  with ScanCode select
    curMovement <= NEWLINE when x"5A",          -- enter scancode (5A), so move cursor to next line
                   BACKWARD when x"66",         -- backspace scancode (66), so move cursor backward
                   FORWARD when others;         -- for all other scancodes, move cursor forward


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------ GENERERA GRAFUPPDATERING -------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  
  -- curposX
  -- update cursor X position based on current cursor position (curposX and curposY) and cursor
  -- movement (curMovement)
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        curposX <= (others => '0');
      elsif (WRstate = WRCHAR) then
        if (curMovement = FORWARD) then
          if (curposX = 19) then
            curposX <= (others => '0');
          else
            curposX <= curposX + 1;
          end if;
        elsif (curMovement = BACKWARD) then
          if ((curposX = 0) and (curposY >= 0)) then
            curposX <= to_unsigned(19, curposX'length);
          else
            curposX <= curposX - 1;
          end if;
        elsif (curMovement = NEWLINE) then
          curposX <= (others => '0');
        end if;
      end if;
    end if;
  end process;
    

  -- curposY
  -- update cursor Y position based on current cursor position (curposX and curposY) and cursor
  -- movement (curMovement)
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        curposY <= (others => '0');
      elsif (WRstate = WRCHAR) then
        if (curMovement = FORWARD) then
          if (curposX = 19) then
            if (curposY = 14) then
              curposY <= (others => '0');
            else
              curposY <= curposY + 1;
            end if;
          end if;
        elsif (curMovement = BACKWARD) then
          if (curposX = 0) then
            if (curposY = 0) then
              curposY <= to_unsigned(14, curposY'length);
            else
              curposY <= curposY - 1;
            end if;
          end if;
        elsif (curMovement = NEWLINE) then
          if (curposY = 14) then
            curposY <= (others => '0');
          else
            curposY <= curposY + 1;
          end if;
        end if;
      end if;
    end if;
  end process;


  -- write state
  -- every write cycle begins with writing the character tile index at the current
  -- cursor position, then moving to the next cursor position and there write the
  -- cursor tile index
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        WRstate <= STANDBY;
      else
        case WRstate is
          when STANDBY =>
            if (PS2state = MAKE) then
              WRstate <= WRCHAR;
            else
              WRstate <= STANDBY;
            end if;
          when WRCHAR =>
            WRstate <= WRCUR;
          when WRCUR =>
            WRstate <= STANDBY;
          when others =>
            WRstate <= STANDBY;
        end case;
      end if;
    end if;
  end process;
    

  -- we will be enabled ('1') for two consecutive clock cycles during WRCHAR and WRCUR states
  -- and disabled ('0') otherwise at STANDBY state
  we <= '0' when (WRstate = STANDBY) else '1';


  -- memory address is a composite of curposY and curposX
  -- the "to_unsigned(20, 6)" is needed to generate a correct size of the resulting unsigned vector
  addr <= to_unsigned(20, 6)*curposY + curposX;

  
  -- data output is set to be x"1F" (cursor tile index) during WRCUR state, otherwise set as scan code tile index
  data <= x"1F" when (WRstate =  WRCUR) else TileIndex;

  
end behavioral;
