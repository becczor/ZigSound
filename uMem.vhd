library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- uMem interface
entity uMem is
  port (
    uAddr : in unsigned(7 downto 0);
    uData : out unsigned(15 downto 0));
end uMem;

architecture Behavioral of uMem is

-- micro Memory
type u_mem_t is array (0 to 255) of unsigned(15 downto 0);
constant u_mem_c : u_mem_t :=
	-- ALU_TB_FB_S_P_LC_SEQ_MICROADDR
	-- 4444_333_333_1_1_22_4444_7777777
	(	b"0000_011_100_0_0_00_0000_0000000", 	-- ASR:=PC
		b"0000_010_001_1_1_0000000", 			-- IR:=PM, PC:=PC+1
		b"0000_000_000_0_0_0000000",
		b"0000_000_000_0_0_0000000",
		b"0000_000_000_0_0_0000000",
		b"0000_000_000_0_0_0000000",
		b"0000_000_000_0_0_0000000",
	);

signal u_mem : u_mem_t := u_mem_c;

begin  -- Behavioral
  uData <= u_mem(to_integer(uAddr));

end Behavioral;
