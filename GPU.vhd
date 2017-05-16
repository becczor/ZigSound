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
        sel_track           : in unsigned(1 downto 0);
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
    signal unicorn	        : unsigned(7 downto 0);	-- unicorn tile index
    signal bg_tile	        : unsigned(7 downto 0);	-- background tile index
    signal tile		        : unsigned(7 downto 0);	-- tile index
    signal addr_change_calc : unsigned(10 downto 0);
    signal sound_icon       : unsigned(7 downto 0);	-- sound icon index
    signal curr_sound_icon  : unsigned(7 downto 0); -- curr pos sound icon

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
    nextpos_free <= '1' when (data_next = x"00" or data_next = x"01" or data_next = x"01") else '0'
    move <= '1' when move_req = '1' and nextpos_free = '1' else '0';
    
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
                        addr_change <= addr_change_calc; 
                        data_change <= tile;    -- Sets data to BG-tile.
                        move_resp <= '1';    -- We're done with curr_pos so CPU can set curr_pos to next_pos.
                        we_picmem <= '1';   -- PIC_MEM can now use address and data to clear curr_pos.
                        WRstate <= DRAW;    -- Set state to DRAW so we get addr and data from next_pos.
                    elsif (tog_sound_icon = '1') then  -- Toggle what sound icon is shown
                        addr_change <= to_unsigned(1199,11);  -- Select position (38,28) bottom-right
                        data_change <= sound_icon;  -- Set it to correct sound_icon
                        we_picmem <= '1';
                    else   
                        we_picmem <= '0';
                    end if;
                when DRAW =>
                    addr_change <= addr_change_calc; 
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
    -- Set correct bg tile depending on track theme
    with sel_track select
    bg_tile <=
    x"00" when "00", -- Track 1
    x"01" when "01", -- Track 2
    x"02" when "10", -- Track 3
    x"00" when others;
    -- Set correct curr pos sound icon depending on track theme
    with sel_track select
    unicorn <=
    x"04" when "00", -- Track 1
    x"05" when "01", -- Track 2
    x"06" when "10", -- Track 3
    x"00" when others;
    -- Set correct curr pos sound icon depending on track theme
    with sel_track select
    curr_sound_icon <=
    x"10" when "00", -- Track 1
    x"11" when "01", -- Track 2
    x"12" when "10", -- Track 3
    x"00" when others;
    
    addr_change_calc <= xpos + (to_unsigned(40, 6) * ypos); -- Translates x- and y-pos into PIC_MEM-address.
    
    addr_nextpos <= unsigned(NEXT_XPOS) + (to_unsigned(40, 6) * unsigned(NEXT_YPOS));
    -- Takes x- and y-pos from curr_pos if we're in IDLE, else from next_pos.
    xpos <= unsigned(CURR_XPOS) when (WRstate = IDLE) else unsigned(NEXT_XPOS);
    ypos <= unsigned(CURR_YPOS) when (WRstate = IDLE) else unsigned(NEXT_YPOS);
    tile <= bg_tile when (WRstate = IDLE) else unicorn;
    sound_icon <= curr_sound_icon when (sound_channel = '0') else x"13"; -- else x"13" means toggle icon for goal sound
    
  
    end behavioral;

