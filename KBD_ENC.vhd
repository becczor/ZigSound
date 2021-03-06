--------------------------------------------------------------------------------
-- KBD ENC
-- ZigSound 
-- 04-apr-2017
-- Version 0.1

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

entity KBD_ENC is
    port (
        clk 					        : in std_logic;  -- system clock (100 MHz)
        rst		        		        : in std_logic;  -- reset signal
        PS2KeyboardCLK                  : in std_logic;  -- USB keyboard PS2 clock
        PS2KeyboardData			        : in std_logic;  -- USB keyboard PS2 data
        PS2cmd					        : out unsigned(2 downto 0)
        );		
end KBD_ENC;

architecture behavioral of KBD_ENC is
    signal PS2Clk					    : std_logic;  -- Synchronized PS2 clock
    signal PS2Data				        : std_logic;  -- Synchronized PS2 data
    signal PS2Clk_Q1, PS2Clk_Q2 	    : std_logic;  -- PS2 clock one pulse flip flop
    signal PS2Clk_op 				    : std_logic;  -- PS2 clock one pulse 
    signal PS2Data_sr 			        : unsigned(10 downto 0);  -- PS2 data shift register
    signal PS2BitCounter	            : unsigned(3 downto 0);  -- PS2 bit counter
    signal ScanCode			            : unsigned(7 downto 0);  -- scan code
    signal key_code			            : unsigned(2 downto 0);  --Which_key_that_has_been_pressed     
    
    type state_type is (IDLE, MAKE, BREAK);  -- declare state types for PS2
    signal PS2state : state_type;  -- PS2 state                                                                  
begin
    
    --*******************************
    --* PS2 signals synchronization *
    --*******************************
    process(clk)
    begin
    if rising_edge(clk) then
        if (rst = '1') then
            PS2Clk <= '1';
            PS2Data <= '1';
        else
            PS2Clk <= PS2KeyboardCLK;
            PS2Data <= PS2KeyboardData;
        end if;
    end if;
    end process;

	--**********************************************************************
    --* PS2Clk_op : Generate one cycle pulse from PS2 clock, negative edge *
    --**********************************************************************
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            PS2Clk_Q1 <= '1';
            PS2Clk_Q2 <= '0';
        else
            PS2Clk_Q1 <= PS2Clk;
            PS2Clk_Q2 <= not PS2Clk_Q1;
        end if;
    end if;
    end process;
	
    PS2Clk_op <= (not PS2Clk_Q1) and (not PS2Clk_Q2);

    -- *****************************************************
    -- * PS2Data_sr : Shift Register for taking in PS2Data *
    -- *****************************************************
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            PS2Data_sr <= (others => '0');
        elsif PS2Clk_op = '1' then
            PS2Data_sr <= PS2Data & PS2Data_sr(10 downto 1);
        end if;
    end if;
    end process;

    ScanCode <= PS2Data_sr(8 downto 1);

    -- **************************************
    -- * PS2BitCounter : Counter for states *
    -- **************************************
	process(clk)
	begin
	if rising_edge(clk) then
	    if rst = '1' then 
		    PS2BitCounter <= (others => '0');
		elsif PS2BitCounter = 11 then
			PS2BitCounter <= (others => '0');
		elsif PS2Clk_op = '1' then
			PS2BitCounter <= PS2BitCounter + 1;
		end if;
	end if;
	end process;

    --*************************************************
    --* State handler : Changes state and sets PS2cmd *
    --*************************************************
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            PS2state <= IDLE;
            PS2cmd <= (others => '0');
        else
            case PS2state is
                when MAKE => 
                    PS2cmd <= (others => '0');
	                PS2state <= IDLE;
                when BREAK => 
	                if PS2BitCounter = 11 then
		                PS2state <= IDLE;
	                else
		                PS2state <= BREAK;
	                end if;
                when others =>
	                if PS2BitCounter = 11 then
		                if (ScanCode = x"F0") then
			                PS2state <= BREAK;
		                else
                            PS2cmd <= key_code;
			                PS2state <= MAKE;
		                end if;
	                else
		                PS2state <= IDLE;
	                end if;
            end case;
        end if;
    end if;
    end process;
    
    --****************************************************************************
    --* key_code : Translates ScanCode into signal to be sent to INPUT_DATA_MNGR *
    --****************************************************************************
    with ScanCode select
        key_code <= 
            "001" when x"1D",	-- W (UP)
            "010" when x"1C",	-- A (LEFT)
            "011" when x"1B",	-- S (DOWN)
            "100" when x"23",	-- D (RIGHT)
            "101" when x"34",	-- G (TOGGLE DISPLAY GOAL POS)
            "110" when x"29",	-- space
            (others =>'0') when others;
						  
end behavioral;
