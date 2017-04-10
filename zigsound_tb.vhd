LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY zigsound_tb IS
END zigsound_tb;

ARCHITECTURE behavior OF zigsound_tb IS

    --Component Declaration for the Unit Under Test (UUT)
    COMPONENT zigsound
        PORT(
            clk                     : in std_logic;
            btnd                    : in std_logic;
            -- VGA_MOTOR out
            vgaRed		        	: out std_logic_vector(2 downto 0);
            vgaGreen	        	: out std_logic_vector(2 downto 0);
            vgaBlue		        	: out std_logic_vector(2 downto 1);
            Hsync		        	: out std_logic;
            Vsync		        	: out std_logic;
            -- KBD_ENC out
            PS2KeyboardCLK          : in std_logic;  -- USB keyboard PS2 clock
            PS2KeyboardData         : in std_logic  -- USB keyboard PS2 data
            );
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';
    signal btnd : std_logic := '0';
    signal PS2KeyboardCLK : std_logic := '0';  -- USB keyboard PS2 clock
    signal PS2KeyboardData : std_logic := '0'; -- USB keyboard PS2 data
    
    -- Sabina says : NEJ NEJ JAG ORKAR INTE VI KOPPLAR IN DET FUCK IT.


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

