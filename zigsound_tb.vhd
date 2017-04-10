LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY zigsound_tb IS
END zigsound_tb;

ARCHITECTURE behavior OF zigsound_tb IS

    --Component Declaration for the Unit Under Test (UUT)
    COMPONENT zigsound
        PORT(
        clk                     : IN std_logic;
        rst                     : IN std_logic;
        move_req                : IN std_logic;         -- move request
        --move_resp			    : OUT std_logic;		-- response to move request
        curr_pos                : IN unsigned(17 downto 0); -- current position
        next_pos                : IN unsigned(17 downto 0); -- next position
        sel_track       	    : in std_logic_vector(1 downto 0)   -- track select
        -- VGA OUT
        --addr		    		: out unsigned(10 downto 0);
        --vgaRed		        	: out std_logic_vector(2 downto 0);
        --vgaGreen	        	: out std_logic_vector(2 downto 0);
        --vgaBlue		        	: out std_logic_vector(2 downto 1);
        --Hsync		        	: out std_logic;
        --Vsync		        	: out std_logic
        );
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal move_req : std_logic := '0';         -- move request
    signal curr_pos : unsigned(17 downto 0) := "000000000000000000"; -- current position
    signal next_pos : unsigned(17 downto 0) := "000000001000000001"; -- next position
    signal sel_track : std_logic_vector(1 downto 0) := "00";   -- track select

    --Clock period definitions
    constant clk_period : time:= 1 us;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: zigsound PORT MAP (
        clk => clk,
        rst => rst,
        move_req => move_req,
        curr_pos => curr_pos,
        next_pos => next_pos,
        sel_track => sel_track
    );
		
    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    rst <= '1', '0' after 1.7 us;
    move_req <= '1' after 2.0 us, '0' after 2.1 us;
END;

