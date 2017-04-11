--------------------------------------------------------------------------------
-- GPU
-- ZigSound
-- 04-apr-2017
-- Version 0.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity GPU is
    port (
        clk                 : in std_logic;			-- system clock (100 MHz)
        rst	        		: in std_logic;			-- reset signal
        
        -- TO/FROM CPU
        move_req            : in std_logic;         -- move request
        move_resp			: out std_logic := '0';		-- response to move request
        curr_pos            : in signed(17 downto 0); -- current position
        next_pos            : in signed(17 downto 0); -- next position
   
        -- TO/FROM PIC_MEM
        data_nextpos        : in unsigned(7 downto 0);  -- tile data at nextpos
        addr_nextpos        : out unsigned(10 downto 0) := (others => '0'); -- tile addr of nextpos
        data_change			: out unsigned(7 downto 0) := (others => '0');	-- tile data for change
        addr_change			: out unsigned(10 downto 0) := (others => '0'); -- tile address for change
        we_picmem			: out std_logic := '0'		-- write enable for PIC_MEM
        );
end GPU;

-- architecture
architecture behavioral of GPU is

    signal move             : std_logic := '0';
    signal ypos             : unsigned(4 downto 0);  -- curr y position
    signal xpos             : unsigned(5 downto 0);  -- curr x position
    signal tile		        : unsigned(7 downto 0);	-- tile index

    type wr_type is (IDLE, DRAW);  -- declare state types for write cycle
    signal WRstate : wr_type;  -- write cycle state

begin
	
    --*************************************************************
    --* Check if we have a move request and if it can be approved *
    --*************************************************************
    move <= '1' when move_req = '1' and data_nextpos = x"00" else '0';
    
    --*******************************************************************
    --* Move handler : Sets address, data and enable-signal for PIC_MEM *
    --*******************************************************************
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            WRstate <= IDLE;
            addr_change <= (others => '0');
            data_change <= (others => '0');
            move_resp <= '0';    
            we_picmem <= '0';
        else
            case WRstate is
                when IDLE =>
                    if (move = '1') then  -- We should move.
                        addr_change <= xpos + (to_unsigned(40, 6) * ypos); -- Translates curr x- and y-pos into PIC_MEM-address.
                        data_change <= tile;    -- Sets data to BG-tile.
                        move_resp <= '1';    -- We're done with curr_pos so CPU can set curr_pos to next_pos.
                        we_picmem <= '1';   -- PIC_MEM can now use address and data to clear curr_pos.
                        WRstate <= DRAW;    -- Set state to DRAW so we get addr and data from next_pos.
                    else   
                        we_picmem <= '0';
                    end if;
                when DRAW =>
                    addr_change <= xpos + (to_unsigned(40, 6) * ypos); -- Translates x- and y-pos into PIC_MEM-address.
                    data_change <= tile;  -- Sets data to character tile.
                    move_resp <= '0'; 
                    WRstate <= IDLE;
                when others =>
                    null;
            end case;
        end if;
    end if;
    end process;
    
    --*********************
    --* Signal assignment *
    --*********************
	addr_nextpos <= unsigned(next_pos(14 downto 9)) + (to_unsigned(40, 6) * unsigned(next_pos(4 downto 0)));
    -- Takes x- and y-pos from curr_pos if we're in CLEAR, else from next_pos.
    xpos <= unsigned(curr_pos(14 downto 9)) when (WRstate = IDLE) else unsigned(next_pos(14 downto 9));
    ypos <= unsigned(curr_pos(4 downto 0)) when (WRstate = IDLE) else unsigned(next_pos(4 downto 0));
    tile <= x"00" when (WRstate = IDLE) else x"1F";
  
    end behavioral;

