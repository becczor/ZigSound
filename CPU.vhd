library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- CPU interface
entity CPU is
    port(
        clk : in std_logic;
        rst : in std_logic;
        uAddr : out unsigned(5 downto 0);
        uData : in unsigned(24 downto 0);
        pAddr : out unsigned(7 downto 0);
        pData : in unsigned(17 downto 0)
		move_req : out std_logic;
		move_resp : in std_logic;
		curr_pos : out unsigned(17 downto 0);
		next_pos : out unsigned(17 downto 0);
		sel_track : out std_logic_vector(1 downto 0)
        );
end CPU;


architecture Behavioral of CPU is
    
    --********
    -- Alias
    --********
    -- Post aliases
	alias uM : unsigned(24 downto 0) is uData(24 downto 0);
	alias PM : unsigned(17 downto 0) is pData(17 downto 0);
	alias ASR : unsigned(15 downto 0) is pAddr(15 downto 0);
    
    -- Micro instruction aliases
    alias ALU : std_logic_vector(3 downto 0) is uM(24 downto 21);       -- alu_op    
    alias TB : std_logic_vector(3 downto 0) is uM(20 downto 18);        -- to bus
    alias FB : std_logic_vector(3 downto 0) is uM(17 downto 15);        -- from bus
    alias S : std_logic is uM(14);                                      -- s bit
    alias P : std_logic is uM(13);                                      -- p bit
    alias LC : std_logic_vector(1 downto 0) is uM(12 downto 11);        -- lc
    alias SEQ : std_logic_vector(3 downto 0) is uM(10 downto 7);        -- seq
    alias MICROADDR : std_logic_vector(7 downto 0) is uM(6 downto 0);   -- micro address

	-- micro memory signals
	signal uPC : unsigned(5 downto 0); -- micro Program Counter
	signal uPCsig : std_logic; -- (0:uPC++, 1:uPC=uAddr)
	signal TB : unsigned(2 downto 0); -- To Bus field
	signal FB : unsigned(2 downto 0); -- From Bus field

	-- program memory signals
	signal PC : unsigned(15 downto 0); -- Program Counter
	signal Pcsig : std_logic; -- 0:PC=PC, 1:PC++
	signal IR : unsigned(15 downto 0); -- Instruction Register 
	signal DATA_BUS : unsigned(15 downto 0); -- Data Bus



begin 

	-- mPC : micro Program Counter
	process(clk)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				uPC <= (others => '0');
			elsif (uPCsig = '1') then
				uPC <= uAddr;
			else
				uPC <= uPC + 1;
			end if;
		end if;
	end process;
	
	-- PC : Program Counter
	process(clk)
	begin
		if rising_edge(clk) then
		  if (rst = '1') then
			PC <= (others => '0');
		  elsif (FB = "011") then
			PC <= DATA_BUS;
		  elsif (PCsig = '1') then
			PC <= PC + 1;
		  end if;
		end if;
	end process;
	
	-- IR : Instruction Register
	process(clk)
	begin
		if rising_edge(clk) then
		  if (rst = '1') then
			IR <= (others => '0');
		  elsif (FB = "001") then
			IR <= DATA_BUS;
		  end if;
		end if;
	end process;
	
  -- ASR : Address Register
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ASR <= (others => '0');
      elsif (FB = "100") then
        ASR <= DATA_BUS;
      end if;
    end if;
  end process;

    -- micro memory signal assignments
    uAddr <= uM(5 downto 0);
    uPCsig <= uM(6);
    PCsig <= uM(7);
    FB <= uM(10 downto 8);
    TB <= uM(13 downto 11);

  -- data bus assignment
  DATA_BUS <= IR when (TB = "001") else
    PM when (TB = "010") else
    PC when (TB = "011") else
    ASR when (TB = "100") else
   (others => '0');

end Behavioral;


