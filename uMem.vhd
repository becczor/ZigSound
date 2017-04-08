library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- uMem interface
entity uMem is
  port (
    uAddr : in unsigned(7 downto 0);
    uData : out unsigned(24 downto 0));
end uMem;

architecture Behavioral of uMem is

-- micro Memory
type u_mem_t is array (0 to 255) of unsigned(24 downto 0);
constant u_mem_c : u_mem_t :=
       -- ALU_TB_FB_S_P_LC_SEQ_MICROADDR
	   -- 4444_333_333_1_1_22_4444_7777777
	(	
		--Hämtfas
		b"0000_011_111_0_0_00_0000_0000000",	--00F8000	ASR := PC
		b"0000_010_001_0_1_00_0000_0000000",	--008A000	IR:= PM, PC++
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

		--LOAD
		--GRx := PM(A)	0A	
		b"0000_010_110_0_0_00_0011_0000000",	--00B0180	GRx := PM(A), µPC = 0
		--STORE
		--PM(A) := GRx	0B	
		b"0000_110_010_0_0_00_0011_0000000",	--0190180	PM(A) := GRx, µPC = 0
		--ADD
		--GRx := GRx + PM(A)	0C	
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0100_010_000_0_0_00_0000_0000000",	--0880000	AR := GRx + PM(A) via buss
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0
		--SUB
		--GRx := GRx - PM(A)	0F	
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0101_010_000_0_0_00_0000_0000000",	--0A80000	AR := GRx - PM(A) via buss
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0
		--AND
		--GRx := GRx & PM(A)	12	
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0110_010_000_0_0_00_0000_0000000",	--0C80000	AR := GRx & PM(A) via buss
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0
		--LSR
		--GRx skiftas logiskt höger Y steg 	15	
		b"0000_001_000_0_0_10_0000_0000000",	--0041000	LC := IR via buss
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0000_000_000_0_0_00_1100_0011010",	--000061A	Hopp till (*) om L = 1 (LC = 0, d.v.s. klara) (#)
		b"1101_000_000_0_0_01_0000_0000000",	--1A00800	Skifta AR logiskt åt höger 1 steg, LC--
		b"0000_000_000_0_0_00_0101_0010111",	--0000297	Hopp till (#)
		b"0000_100_110_0_0_00_0011_0000000",	--0130180	GRx := AR, µPC = 0 (*)
		--BRA
		--PC := PC + 1 + ADR	1B	
		b"0001_011_000_0_0_00_0000_0000000",	--02C0000	AR := PC via buss
		b"0100_001_000_0_0_00_0000_0000000",	--0840000	AR := PC + IR
		b"0000_100_011_0_0_00_0011_0000000",	--0118180	PC := AR
		--CMP
		--Sätter flaggor genom
		--AR := GRx - PM(A)	1E	
		b"0001_110_000_0_0_00_0000_0000000",	--0380000	AR := GRx via buss
		b"0101_010_000_0_0_00_0011_0000000",	--0A80180	AR := GRx - PM(A) via buss
		--BNE
		--PC := PC + 1 + ADR 
		--om z = 1, annars PC++	20	
		b"0000_000_000_0_0_00_1000_0000000",	--0000400	 µPC := 0 om Z = 1
		b"0000_000_000_0_0_00_0101_0011011",	--000029B	Hopp till BRA
		--BGT
		--PC := PC + 1 + ADR 
		--om >, annars PC++	22	
		b"0000_000_000_0_0_00_0100_0100100",	--0000224	Hopp till (*) om Z = 0
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		b"0000_000_000_0_0_00_1001_0100111",	--00004A7	Hopp till (#) om N = 1        (*)
		b"0000_000_000_0_0_00_1110_0011011",	--000071B	Hopp till BRA om O = 0
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		b"0000_000_000_0_0_00_1011_0011011",	--000059B	Hopp till BRA om O = 1        (#)
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		--BGE
		--PC := PC + 1 + ADR 
		--om ≥, annars PC++	29	
		b"0000_000_000_0_0_00_1001_0101100",	--00004AC	Hopp till (#) om N = 1
		b"0000_000_000_0_0_00_1110_0011011",	--000071B	Hopp till BRA om O = 0
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		b"0000_000_000_0_0_00_1011_0011011",	--000059B	Hopp till BRA om O = 1        (#)
		b"0000_000_000_0_0_00_0011_0000000",	--0000180	µPC := 0
		--HALT
		--Avbryt exekvering	2E	
		b"0000_000_000_0_0_00_1111_0000000",	--0000780	Halt
	);

signal u_mem : u_mem_t := u_mem_c;

begin  -- Behavioral
  uData <= u_mem(to_integer(uAddr));

end Behavioral;


