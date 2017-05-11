library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--******************
--* uMem Interface *
--******************
entity uMem is
  port (
    clk   : in std_logic;
    uAddr : in unsigned(6 downto 0);
    uData : out unsigned(24 downto 0));

end uMem;

architecture Behavioral of uMem is

--************************
--* u_mem : Micro Memory *
--************************
type u_mem_t is array (0 to 60) of unsigned(24 downto 0);
-- Maximum array length is 127, change when adding/deleting from uMem.
constant u_mem_c : u_mem_t := (
        -- ALU_TB_FB_S_P_LC_SEQ_MICROADDR
        -- 4444_333_333_1_1_22_4444_7777777
		--Hämtfas
		b"0000_011_111_0_0_00_0000_0000000",	--00F8000	ASR := PC
		b"0000_010_001_0_1_00_0000_0000000",	--008A000	IR := PM, PC++
		--Hopp till korrekt beräkning av EA
		b"0000_000_000_0_0_00_0010_0000000",	--0000100	µPC := K2 (M-fältet)
		--Beräkningar av EA (Adresseringslägen)
		--Direkt
		b"0000_001_111_0_0_00_0001_0000000",	--0078080	ASR := IR, µPC := K1 (OP-fältet)
		--Omedelbar
		b"0000_011_111_0_1_00_0001_0000000",	--00FA080	ASR := PC, PC++, µPC := K1 (OP-fältet)
		--Indirekt
		b"0000_001_111_0_0_00_0000_0000000",	--0078000	ASR := IR
		b"0000_010_111_0_0_00_0001_0000000",	--00B8080	ASR := PM, µPC := K1 (OP-fältet)
		--Indexerad
		b"0001_001_000_0_0_00_0000_0000000",	--0240000	AR := IR via buss
		b"0100_110_000_1_0_00_0000_0000000",	--0984000	AR := GR3 + AR
		b"0000_100_111_0_0_00_0001_0000000",	--0138080	ASR := AR, µPC := K1 (OP-fältet)


		--LOAD 0A
		--GRx := PM(A)
		b"0000_010_110_0_0_00_0011_0000000",	--00B0180	GRx := PM(A), µPC = 0


		--STORE 0B
		--PM(A) := GRx	
        -- UNUSABLE WITH NO WAY TO WRITE TO PM FROM CPU.
		b"0000_110_010_0_0_00_0011_0000000",	--0190180	PM(A) := GRx, µPC = 0


		--ADD 0C
		--GRx := GRx + PM(A)
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0100_010_000_0_0_00_0000_0000000",	--0880000	AR := GRx + PM(A) via buss
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0
		--SUB 0F
		--GRx := GRx - PM(A)
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0101_010_000_0_0_00_0000_0000000",	--0A80000	AR := GRx - PM(A) via buss
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0
		--AND 12
		--GRx := GRx & PM(A)
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0110_010_000_0_0_00_0000_0000000",	--0C80000	AR := GRx & PM(A) via buss
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0
		--LSR 15
		--GRx skiftas logiskt höger Y steg	
		b"0000_001_000_0_0_10_0000_0000000",	--0041000	LC := IR via buss
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0000_000_000_0_0_00_1100_0011010",	--000061A	Hopp till (*) om L = 1 (LC = 0, d.v.s. klara) (#)
		b"1101_000_000_0_0_01_0000_0000000",	--1A00800	Skifta AR logiskt åt höger 1 steg, LC--
		b"0000_000_000_0_0_00_0101_0010111",	--0000297	Hopp till (#)
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0 (*)
		--BRA 1B
		--PC := PC + 1 + ADR
		b"0001_011_000_0_0_00_0000_0000000",	--02C0000	AR := PC via buss
		b"0100_001_000_0_0_00_0000_0000000",	--0840000	AR := PC + IR
		b"0000_100_011_0_0_00_0011_0000000",	--0118180	PC := AR
		--CMP 1E
		--Sätter flaggor genom
		--AR := GRx - PM(A)	
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0101_010_000_0_0_00_0011_0000000",	--0A80180	AR := GRx - PM(A) via buss
		--BNE 20
		--PC := PC + 1 + ADR 
		--om Z = 0, annars PC++
		b"0000_000_000_0_0_00_1000_0000000",	--0000400	µPC := 0 om Z = 1
		b"0000_000_000_0_0_00_0101_0011011",	--000029B	Hopp till BRA om Z = 0
		--BGT 22
		--PC := PC + 1 + ADR 
		--om >, annars PC++	
		b"0000_000_000_0_0_00_0100_0100100",	--0000224	Hopp till (*) om Z = 0
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		b"0000_000_000_0_0_00_1001_0100111",	--00004A7	Hopp till (#) om N = 1        (*)
		b"0000_000_000_0_0_00_1110_0011011",	--000071B	Hopp till BRA om O = 0
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		b"0000_000_000_0_0_00_1011_0011011",	--000059B	Hopp till BRA om O = 1        (#)
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		--BGE 29
		--PC := PC + 1 + ADR 
		--om ≥, annars PC++
		b"0000_000_000_0_0_00_1001_0101100",	--00004AC	Hopp till (#) om N = 1
		b"0000_000_000_0_0_00_1110_0011011",	--000071B	Hopp till BRA om O = 0
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		b"0000_000_000_0_0_00_1011_0011011",	--000059B	Hopp till BRA om O = 1        (#)
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		--HALT 2E
		--Avbryt exekvering
		b"0000_000_000_0_0_00_1111_0000000",    --0000780	Halt
        --BCT 2F
        --PC := PC + 1 + ADR
        --om G = 0, annars PC++
		b"0000_000_000_0_0_00_1101_0000000",	--0000680	µPC := 0 om G = 1
		b"0000_000_000_0_0_00_0101_0011011",	--000029B	Hopp till BRA
        --SETRND 31
        --GOAL_POS := RND_GOAL_POS if GRX = "100"    
        --SEL_TRACK := RND_SEL_TRACK if GRX = "101" 
        b"0000_110_110_0_0_00_0011_0000000", 	--01B0000	REG := RND_REG
        --SHOWGOALMSG 32
        --WON := '1'
        b"1000_000_000_0_0_00_0000_0000000",    --HEX       AR := '1'
        b"0000_100_100_0_0_00_0011_0000000",    --HEX       WON := '1' via buss (AR), µPC := 0
        --HIDEGOALMSG 34
        --WON := '0'
        b"0011_000_000_0_0_00_0000_0000000",    --HEX       AR := '0'
        b"0000_100_100_0_0_00_0011_0000000",    --HEX       WON := '0' via buss (AR), µPC := 0
		--WAIT 36
		--Wait for a while depending on PM(ASR)
		b"0000_010_000_0_0_10_0000_0000000",	--HEX	    LC_cnt := PM via buss
		b"0000_000_000_0_0_00_1100_0111001",	--HEX	    Hopp till (*) om L = 1 (LC_cnt = 0, d.v.s. klara) (#)
        b"0000_000_000_0_0_01_0101_0110111",	--HEX	    LC_cnt--, Hopp till (#)
        b"0000_000_000_0_0_00_0011_0000000",    --HEX       µPC := 0 (*)
        --INCRSCORE 3A
        -- SCORE <= SCORE + 1
        b"1000_000_000_0_0_00_0000_0000000",    --HEX       AR := '1'
        b"0100_101_000_0_0_00_0000_0000000",    --HEX       AR := AR + SCORE via buss
        b"0000_100_101_0_0_00_0011_0000000"     --HEX       SCORE := AR, µPC := 0
        );

signal u_mem : u_mem_t := u_mem_c;

begin

    --********************
    --* uData Assignment *
    --********************
    --process(clk)
    --begin
    --    if rising_edge(clk) then
            uData <= u_mem(to_integer(uAddr));
    --    else
    --        null;
    --    end if;
    --end process;
    
end Behavioral;


