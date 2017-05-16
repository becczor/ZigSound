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
        -- FROM SOUND
        sound_channel       : in std_logic;      
        -- TO/FROM CPU
        move_req            : in std_logic;         -- move request
        tog_sound_icon      : in std_logic;
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
    signal addr_change_calc		: unsigned(10 downto 0);
    signal sound_icon       : unsigned(7 downto 0);	-- sound icon index

    type wr_type is (IDLE, DRAW);  -- declare state types for write cycle
    signal WRstate : wr_type;  -- write cycle state
    
    --********************
    --* Position aliases *
    --********************
    alias CURR_XPOS     : signed(5 downto 0) is curr_pos(14 downto 9);
    alias CURR_YPOS     : signed(4 downto 0) is curr_pos(4 downto 0);
    alias NEXT_XPOS     : signed(5 downto 0) is next_pos(14 downto 9);
    alias NEXT_YPOS     : signed(4 downto 0) is next_pos(4 downto 0);

begin
	
    --*************************************************************
    --* Check if we have a move request and if it can be approved *
    --*************************************************************
    --move <= '1' when move_req = '1' and data_nextpos = x"00" else '0';
    
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
                    if (move_req = '1' and data_nextpos = x"00") then  -- We should move.
                        addr_change <= addr_change_calc; -- Translates curr x- and y-pos into PIC_MEM-address.
                        data_change <= tile;    -- Sets data to BG-tile.
                        move_resp <= '1';    -- We're done with curr_pos so CPU can set curr_pos to next_pos.
                        we_picmem <= '1';   -- PIC_MEM can now use address and data to clear curr_pos.
                        WRstate <= DRAW;    -- Set state to DRAW so we get addr and data from next_pos.
                    elsif (tog_sound_icon = '1') then
                        addr_change <= to_unsigned(1199,11);
                        data_change <= sound_icon;
                        we_picmem <= '1';
                    else   
                        we_picmem <= '0';
                    end if;
                when DRAW =>
                    addr_change <= addr_change_calc; -- Translates x- and y-pos into PIC_MEM-address.
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
    
    addr_change_calc <= xpos + (to_unsigned(40, 6) * ypos);
    
    addr_nextpos <= unsigned(NEXT_XPOS) + (to_unsigned(40, 6) * unsigned(NEXT_YPOS));
    -- Takes x- and y-pos from curr_pos if we're in CLEAR, else from next_pos.
    xpos <= unsigned(CURR_XPOS) when (WRstate = IDLE) else unsigned(NEXT_XPOS);
    ypos <= unsigned(CURR_YPOS) when (WRstate = IDLE) else unsigned(NEXT_YPOS);
    tile <= x"00" when (WRstate = IDLE) else x"01";
    sound_icon <= x"05" when (sound_channel = '0') else x"06";
    
  
    end behavioral;

