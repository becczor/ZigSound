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
    b"01100_000_00_11111111",  -- 3. BCT : Stay here while G = 0 (-1)
    -- 4. WON : Stay here while LC (ADR) > 0, also set won := '1' while here
    b"01110_000_00_01111111",  -- 4. See above
    b"00110_000_00_11111100"   -- 6. BRA back to 1 (-4)
	);
    -- Testade ändra M från 01 till 00 och ändra -2/-5 till -1/-4 på BCT/BRA

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
