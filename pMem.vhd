library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--******************
--* pMem Interface *
--******************
entity pMem is
  port(
    pAddr : in signed(7 downto 0);
    pData : out unsigned(17 downto 0));
end pMem;

architecture Behavioral of pMem is

--**************************
--* p_mem : Program Memory *
--**************************
type p_mem_t is array (0 to 1) of unsigned(17 downto 0);
constant p_mem_c : p_mem_t := (
    -- OP_GRx_M _ADDR
    -- 55555_333_22_88888888
	-- Paste assembled code here:
    b"00000_000_00_00000000",
    b"00000_000_00_00000000"
	);

  signal p_mem : p_mem_t := p_mem_c;

begin  

    --********************
    --* pData Assignment *
    --********************
    pData <= p_mem(to_integer(pAddr));

end Behavioral;
