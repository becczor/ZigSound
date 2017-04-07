library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- CPU interface
entity CPU is
    port(
        clk : in std_logic;
        rst : in std_logic;
        uAddr : out unsigned(5 downto 0);
        uData : in unsigned(15 downto 0);
        pAddr : out unsigned(15 downto 0);
        pData : in unsigned(15 downto 0)
        );
end CPU;


architecture Behavioral of CPU is
    
-- Alias
--  alias TO_BUS : std_logic_vector(3 downto 0) is micro_instr(23 downto 20);     -- to bus
--  alias FROM_BUS : std_logic_vector(3 downto 0) is micro_instr(19 downto 16);   -- from bus
--  alias P_BIT : std_logic is micro_instr(15);                                   -- p bit
--  alias ALU_OP : std_logic_vector(2 downto 0) is micro_instr(14 downto 12);     -- alu_op
--  alias SEQ : std_logic_vector(3 downto 0) is micro_instr(11 downto 8);         -- seq
--  alias MICRO_ADR : std_logic_vector(7 downto 0) is micro_instr(7 downto 0);    -- micro address

    -- micro memory signals
  -- signal uM : unsigned(15 downto 0); -- micro Memory output uData
  signal uPC : unsigned(5 downto 0); -- micro Program Counter
  signal uPCsig : std_logic; -- (0:uPC++, 1:uPC=uAddr)
  -- signal uAddr : unsigned(5 downto 0); -- micro Address uAddr
  signal TB : unsigned(2 downto 0); -- To Bus field
  signal FB : unsigned(2 downto 0); -- From Bus field
	
  -- program memory signals
  -- signal PM : unsigned(15 downto 0); -- Program Memory output  pData
  signal PC : unsigned(15 downto 0); -- Program Counter
  signal Pcsig : std_logic; -- 0:PC=PC, 1:PC++
  -- signal ASR : unsigned(15 downto 0); -- Address Register  pAddr
  signal IR : unsigned(15 downto 0); -- Instruction Register 
  signal DATA_BUS : unsigned(15 downto 0); -- Data Bus

    alias uM : unsigned(15 downto 0) is uData(15 downto 0);
    alias PM : unsigned(15 downto 0) is pData(15 downto 0);
    alias ASR : unsigned(15 downto 0) is pAddr(15 downto 0);

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
