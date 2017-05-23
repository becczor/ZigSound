--------------------------------------------------------------------------------
-- pMem
-- ZigSound
-- 04-apr-2017
-- Version 0.1

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
-- IF YOU CHANGE ARRAY SIZE, REMEMBER TO CHANGE LIMITS OF ASR ASSIGNMENT AT THE BOTTOM OF CPU!
type p_mem_t is array (0 to 13) of signed(17 downto 0); 
-- Maximum array length is 256, change when adding/deleting from pMem.
constant p_mem_c : p_mem_t := (
    -- OP_GRx_M _ADDR
    -- 55555_333_22_88888888
    b"10100_101_00_00000000",  -- 0.  INCRTRACK : NEXT_TRACK <= NEXT_TRACK + 1
    b"01101_100_00_00000000",  -- 1.  SETRNDGOALPOS : GOAL_POS <= RND_GOAL_POS
    b"01100_000_00_11111111",  -- 2.  BCT : BRA back here while G = 0 (ADDR = -1)
    b"10010_000_00_00000000",  -- 3.  SENDWONSIG : GOAL_REACHED <= '1', GOAL_REACHED <= '0'
    b"00000_000_01_00000000",  -- 4.  LOAD : GR0 <= LOOPCNT (5.)
    b"011111111111111111",     -- 5.  Value LOOPCNT : Num of WAIT before INCRSCORE (11.)
    b"10000_000_01_00000000",  -- 6.  WAIT : Wait a while depending on µLOOPCNT (7.)
    b"011111111111111111",     -- 7.  Value µLOOPCNT : LC_cnt <= µLOOPCNT
    b"00011_000_01_00000000",  -- 8.  SUB : GR0 (LOOPCNT) <= GR0 - 1
    b"000000000000000001",     -- 9.  Value 1 : Arg for SUB (8. and 16.)
    b"01000_000_00_11111011",  -- 10. BNE : BRA back to WAIT (6.) if GR0 (LOOPCNT) != 0 (Z=0) (ADDR = -5)
    b"10011_000_00_11111111",  -- 11. BSW : BRA back here while S = 1 (ADDR = -1)
    b"10001_000_00_00000000",  -- 12. INCRSCORE : SCORE <= SCORE + 1
    b"00110_000_00_11110010"   -- 13. BRA : Go back to (0.) (ADDR = -14) 
	);

  signal p_mem : p_mem_t := p_mem_c;

begin  

    pData <= p_mem(to_integer(pAddr));

end Behavioral;
