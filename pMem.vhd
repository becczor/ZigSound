library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- pMem interface
entity pMem is
  port(
    pAddr : in unsigned(7 downto 0);
    pData : out unsigned(17 downto 0));
end pMem;

architecture Behavioral of pMem is

-- program Memory, 256 rows
type p_mem_t is array (0 to 255) of unsigned(17 downto 0);

-- OP   _GRx_M _A
-- 55555_333_22_88888888
constant p_mem_c : p_mem_t :=
	(
	-- Paste assembled code here:
		x"0042",
		x"00A0",
		x"70FF",
		x"1337",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000",
		x"0000"
	);

  signal p_mem : p_mem_t := p_mem_c;


begin  -- pMem
  pData <= p_mem(to_integer(pAddr));

end Behavioral;
