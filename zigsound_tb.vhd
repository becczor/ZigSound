LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY zigsound_tb IS
END zigsound_tb;

ARCHITECTURE behavior OF zigsound_tb IS

    --Component Declaration for the Unit Under Test (UUT)
    COMPONENT zigsound
        PORT(
            clk                         : in std_logic;
            rst                         : in std_logic;
            -- VGA_MOTOR out
            vgaRed		        	: out std_logic_vector(2 downto 0);
            vgaGreen	        	        : out std_logic_vector(2 downto 0);
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
    signal rst : std_logic := '0';
    signal PS2KeyboardCLK : std_logic := '1';  -- USB keyboard PS2 clock
    signal PS2KeyboardData : std_logic := '1'; -- USB keyboard PS2 data
    signal tb_running : boolean := true;
    
  


    --Clock period definitions
    

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    uut: zigsound PORT MAP (
        clk => clk,
        rst => rst,
        --vgaRed => vgaRed,
        --vgaGreen => vgaGreen,
        --vgaBlue => vgaBlue,
        --Hsync => Hsync,
        --VSync => VSync,
        PS2KeyboardCLK => PS2KeyboardCLK,
        PS2KeyboardData => PS2KeyboardData
    );
		
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


    ps2_clk_gen : process
    begin
        while tb_running loop
            PS2KeyboardCLK <= '1';
            wait for 1000 ns;
            PS2KeyboardCLK <= '0';
            wait for 1000 ns;
        end loop;
        wait;
    end process;
    
    
    ps2_code_gen : process
    begin -- Send in two space presses
        wait for 40000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';  
        
        wait for 40000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '0';
        wait for 2000 ns;
        PS2KeyboardData <= '1';  
        wait;
        
        
    end process;
    
       
END;


