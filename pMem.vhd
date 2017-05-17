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
type p_mem_t is array (0 to 15) of signed(17 downto 0);
-- Maximum array length is 256, change when adding/deleting from pMem.
constant p_mem_c : p_mem_t := (
    -- OP_GRx_M _ADDR
    -- 55555_333_22_88888888
    b"01101_101_00_00000000",  -- 0.  SETNEXT : SEL_TRACK <= NEXT_SEL_TRACK
    b"10000_000_01_00000000",  -- 1.  WAIT : Wait a while depending on µLOOPCNT (2.)
    b"011111111111111111",     -- 2.  Value µLOOPCNT : LC_cnt <= µLOOPCNT
    b"01101_100_00_00000000",  -- 3.  SETNEXT : GOAL_POS <= RND_GOAL_POS
    b"01100_000_00_11111111",  -- 4.  BCT : BRA back here while G = 0 (ADDR = -1)
    b"10010_000_00_00000000",  -- 5.  SENDWONSIG : WON <= '1', WON <= '0'
    b"00000_000_01_00000000",  -- 6.  LOAD : GR0 <= LOOPCNT (5.)
    b"011111111111111111",     -- 7.  Value LOOPCNT : Num of WAIT before INCRSCORE (11.)
    b"10000_000_01_00000000",  -- 8.  WAIT : Wait a while depending on µLOOPCNT (7.)
    b"011111111111111111",     -- 9.  Value µLOOPCNT : LC_cnt <= µLOOPCNT
    b"00011_000_01_00000000",  -- 10.  SUB : GR0 (LOOPCNT) <= GR0 - 1
    b"000000000000000001",     -- 11.  Value 1 : Arg for SUB (8. and 16.)
    b"01000_000_00_11111011",  -- 12. BNE : BRA back to WAIT (6.) if GR0 (LOOPCNT) != 0 (Z=0) (ADDR = -5)
    b"10011_000_00_11111111",  -- 13. BSW : BRA back here while S = 1 (ADDR = -1)
    b"10001_000_00_00000000",  -- 14. INCRSCORE : SCORE <= SCORE + 1
    b"00110_000_00_11110000"   -- 15. BRA : Go back to (0.) (ADDR = -16) 
	);

  signal p_mem : p_mem_t := p_mem_c;

begin  

    pData <= p_mem(to_integer(pAddr));

end Behavioral;
