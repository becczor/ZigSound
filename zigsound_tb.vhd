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
            rst                     : in std_logic;
            -- VGA_MOTOR out
            vgaRed		        	: out std_logic_vector(2 downto 0);
            vgaGreen	        	: out std_logic_vector(2 downto 0);
            vgaBlue		        	: out std_logic_vector(2 downto 1);
            Hsync		        	: out std_logic;
            Vsync		        	: out std_logic;
            -- KBD_ENC out
            PS2KeyboardCLK          : in std_logic;  -- USB keyboard PS2 clock
            PS2KeyboardData         : in std_logic;  -- USB keyboard PS2 data
            -- Test
            test_diod               : buffer std_logic;  -- Test diod
            test2_diod              : buffer std_logic;
            -- Sound
            sound                   : out std_logic
            );
            
    END COMPONENT;

    --Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal PS2KeyboardCLK : std_logic := '1';  -- USB keyboard PS2 clock
    signal PS2KeyboardData : std_logic := '1'; -- USB keyboard PS2 data
    signal tb_running : boolean := true;
   
    

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: zigsound PORT MAP (
        clk => clk,
        rst => rst,
        PS2KeyboardCLK => PS2KeyboardCLK,
        PS2KeyboardData => PS2KeyboardData
    );
    
    rst <= '1', '0' after 1.7 us;
		
    -- Clock process definitions
    clk_gen : process
    begin
        while tb_running loop
            clk <= '0';
            wait for 20 ns;
            clk <= '1';
            wait for 20 ns;
        end loop;
        wait;
    end process;

    
    ps2_code_gen : process
    begin
        wait for 2000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '1';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '1';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '1';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '0';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardData <= '1';
        PS2KeyboardCLK <= '1';
        wait for 1000 ns;
        PS2KeyboardCLK <= '0';
        wait for 1000 ns;
        
        PS2KeyboardCLK <= '1';
        wait for 3000 ns;
        
        wait;
        
    end process;
    
       
END;
