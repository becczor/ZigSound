library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--******************
--* pMem Interface *
--******************
entity pMem is
    port(
        pAddr       : in signed(7 downto 0);
        pData       : out signed(17 downto 0);
        clk         : in std_logic
        );
end pMem;

architecture Behavioral of pMem is

--**************************
--* p_mem : Program Memory *
--**************************
type p_mem_t is array (0 to 3) of signed(17 downto 0);
-- Maximum array length is 256, change when adding/deleting from pMem.
constant p_mem_c : p_mem_t := (
    -- OP_GRx_M _ADDR
    -- 55555_333_22_88888888
    b"01101_101_00_00000000",  -- 1. SETRND SEL_TRACK
    b"01101_100_00_00000000",  -- 2. SETRND GOAL_POS
    b"01100_000_01_11111110",  -- 3. BCT (BRA to 1 if G = 1) -2
    b"00110_000_01_11111011"   -- 4. BRA to 3 -5
	);

  signal p_mem : p_mem_t := p_mem_c;

begin  

    --********************
    --* pData Assignment *
    --********************
    --process(clk)
    --begin
    --    if rising_edge(clk) then
            pData <= p_mem(to_integer(pAddr));
    --    else
    --        null;
    --    end if;
    --end process;

end Behavioral;
