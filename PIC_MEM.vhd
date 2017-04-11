--------------------------------------------------------------------------------
-- PIC MEM
-- ZigSound
-- 04-apr-2017
-- Version 0.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity PIC_MEM is
	port(
        clk		        	: in std_logic;
        rst		            : in std_logic;
        -- CPU
        sel_track       	: in unsigned(1 downto 0);
        -- GPU
        we		        	: in std_logic;
        data_nextpos    	: out unsigned(7 downto 0);
        addr_nextpos    	: in unsigned(10 downto 0);
        data_change	    	: in unsigned(7 downto 0);
        addr_change	    	: in unsigned(10 downto 0);
        -- VGA MOTOR
        data_vga        	: out unsigned(7 downto 0);
        addr_vga	    	: in unsigned(10 downto 0)
	);

end PIC_MEM;
	
-- Architecture
architecture Behavioral of PIC_MEM is

    -- Track memory type
    type ram_t is array (0 to 2047) of unsigned(7 downto 0);
    
    -- SÄTT VÅRA BANOR HÄR! JUST NU SÄTTS CURSOR PÅ INDEX 0, RESTEN SPACE

    -- TRACK 1 initialization
    signal track_1 : ram_t := (0 => x"1F", others => (others => '0')); 
    -- TRACK 2 initialization
    signal track_2 : ram_t := (0 => x"1F", others => (others => '0')); 
    -- TRACK 3 initialization
    signal track_3 : ram_t := (0 => x"1F", others => (others => '0')); 


begin

    -- Checks if write enable, in that case makes changes to memory using 
    -- addr_change and data_change.
    process(clk)
    begin
    if rising_edge(clk) then
        if (we = '1') then
            case sel_track is
                when "01" =>
                    track_1(to_integer(addr_change)) <= data_change;
                when "10" =>
                    track_2(to_integer(addr_change)) <= data_change;
                when "11" =>
                    track_3(to_integer(addr_change)) <= data_change;
                when others =>
                    null;
            end case;
        end if;  
    end if;
    end process;

    -- Sets data_nextpos to data at addr_nextpos and data_vga to data at addr_vga.
    with sel_track select
        data_nextpos <= 
        track_1(to_integer(addr_nextpos)) when "01",
        track_2(to_integer(addr_nextpos)) when "10",
        track_3(to_integer(addr_nextpos)) when "11",
        "00000000" when others;
    with sel_track select
        data_vga <= 
        track_1(to_integer(addr_vga)) when "01",
        track_2(to_integer(addr_vga)) when "10",
        track_3(to_integer(addr_vga)) when "11",
        "00000000" when others;

end Behavioral;

