--------------------------------------------------------------------------------
-- KBD ENC
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity KBD_ENC is
  port (clk 					: in std_logic;			-- system clock (100 MHz)
	rst		        		: in std_logic;			-- reset signal
        PS2KeyboardCLK	                        : in std_logic; 		-- USB keyboard PS2 clock
        PS2KeyboardData			        : in std_logic;			-- USB keyboard PS2 data
        PS2cmd					: out std_logic_vector(17 downto 0);		-- tile data
  
end KBD_ENC;

-- architecture
architecture behavioral of KBD_ENC is
  signal PS2Clk					: std_logic;			-- Synchronized PS2 clock
  signal PS2Data				: std_logic;			-- Synchronized PS2 data
  signal PS2Clk_Q1, PS2Clk_Q2 	                : std_logic;			-- PS2 clock one pulse flip flop
  signal PS2Clk_op 				: std_logic;			-- PS2 clock one pulse 
	
  signal PS2Data_sr 			: std_logic_vector(10 downto 0);-- PS2 data shift register
	
  signal PS2BitCounter	                : unsigned(3 downto 0);		-- PS2 bit counter
  signal BC11                           : std_logic;


  type state_type is (IDLE, MAKE, BREAK);			-- declare state types for PS2
  signal PS2state : state_type;					-- PS2 state

  signal ScanCode			: std_logic_vector(7 downto 0);	-- scan code
  signal keyPressed			: std_logic_vector(17 downto 0);	--Which_key_that_has_been_pressed
                                                                   
                                                                    
begin

  -- Synchronize PS2-KBD signals
  process(clk)
  begin
    if rising_edge(clk) then
      PS2Clk <= PS2KeyboardCLK;
      PS2Data <= PS2KeyboardData;
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

    
 -- Scan Code -> KeyPressed mapping
 -- Translates the ScanCode to relevant key pressed codes.
 with ScanCode select
    keyPressed <= "000000000000000001" when x"1D",	-- W (UP)
    "000000000000000010" when x"1C",	-- A (LEFT)
    "000000000000000011" when x"1B",	-- S (DOWN)
    "000000000000000100" when x"23",	-- D (RIGHT)
    "000000000000000101" when x"29",	-- space
    "000000000000000000" when others;
						 
 
 -- Sets the out signal PS2cmd when
 -- the PSstate is make
 
 process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        PS2cmd <= "000000000000000000";
      else
        if (PS2state = MAKE) then
            PS2cmd <= keyPressed;
        else
            PS2cmd <= "000000000000000000";
        end if;
    end if;
 end process;


  
end behavioral;
