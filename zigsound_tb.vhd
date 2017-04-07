LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY zigsound_tb IS
END zigsound_tb;

ARCHITECTURE behavior OF zigsound_tb IS

  --Component Declaration for the Unit Under Test (UUT)
  COMPONENT zigsound
  PORT( clk                 : IN std_logic;
        rst                 : IN std_logic;
        goal_pos            : in std_logic_vector(17 downto 0);  -- goal position
        curr_pos            : in std_logic_vector(17 downto 0);  -- current position
        channel             : in std_logic;                      -- deciding which of the two sound that should be played, 0 = curr, 1 = goal.
        sound_data          : out std_logic);                    -- output to speaker);
  END COMPONENT;

  --Inputs
  signal clk : std_logic:= '0';
  signal rst : std_logic:= '0';

  --Clock period definitions
  constant clk_period : time:= 1 us;

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  uut: zigsound PORT MAP (
    clk => clk,
    rst => rst
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
END;

