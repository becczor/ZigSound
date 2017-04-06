--------------------------------------------------------------------------------
-- GRPX CTRL
-- ZigSound
-- 04-apr-2017
-- Version 0.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity GRPX_CTRL is
    port (
        clk                 : in std_logic;			-- system clock (100 MHz)
        rst	        		: in std_logic;			-- reset signal
        -- TO/FROM CPU
        move_req            : in std_logic;         -- move request
        curr_pos            : in std_logic_vector(17 downto 0); -- current position
        next_pos            : in std_logic_vector(17 downto 0); -- next position
        move_resp			: out std_logic;		-- response to move request
        -- TO/FROM PIC_MEM
        data_nextpos        : in std_logic_vector(4 downto 0);  -- tile data at nextpos
        addr_nextpos        : out std_logic_vector(10 downto 0); -- tile addr of nextpos
        data_change			: out std_logic_vector(4 downto 0);	-- tile data for change
        addr_change			: out unsigned(10 downto 0); -- tile address for change
        we_picmem			: out std_logic);		-- write enable for PIC_MEM
end GRPX_CTRL;

-- architecture
architecture behavioral of GRPX_CTRL is
    signal we               : std_logic;  -- write enable
    signal ypos             : std_logic_vector(4 downto 0);  -- curr y position
    signal xpos             : std_logic_vector(4 downto 0);  -- curr x position
    signal tile		: std_logic_vector(4 downto 0);	-- tile index
    type wr_type is (IDLE, DRAW);  -- declare state types for write cycle
    signal WRstate : wr_type;  -- write cycle state
    type ch_type is (WAITING, CHECK);  -- declare state types for write cycle
    signal CHstate : ch_type;  -- write cycle state
begin
	

    -- Checks for move requests and decides whether to approve or deny them with
    -- the help of data from PIC_MEM. If approved, sets write enable so we can 
    -- send data about the changes to PIC_MEM.
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            we <= '0';
        else
            case CHstate is
                when WAITING =>
                    if move_req = '1' then  -- CPU is telling us we have a move request.
                        -- Translates x- (14 downto 9) and y-pos (4 downto 0) in next_pos into PIC_MEM-address.
                        addr_nextpos <= next_pos(14 downto 9) + (to_unsigned(40, 11) * next_pos(4 downto 0));
                        CHstate <= CHECK;   -- Sets state to CHECK so that we check PIC_MEMs response next tick.
                    end if;
                when others =>
                    if data_nextpos = x"00" then -- If the tile is free (BG),
                        we <= '1';               -- it's ok to move here.
                    else
                        we <= '0';               -- otherwise not.
                    end if;
            end case;
        end if;
    end if;
    end process;
	
    -- Checks which state we're in and sets address, data and write enable for 
    -- PIC_MEM accordingly. Also tells CPU if it should set curr_pos to next_pos.
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            WRstate <= IDLE;
            move_resp <= '0';    
            we_picmem <= '0';
        else
            case WRstate is
                when IDLE =>
                    if (we = '1') then      -- Move request is approved, set data for PIC_MEM.
                        addr_change <= xpos + (to_unsigned(40, 11) * ypos); -- Translates x- and y-pos into PIC_MEM-address.
                        data_change <= tile;    -- Sets data to the correct tile (BG since we're in CLEAR).
                        move_resp <= '1';    -- We're done with curr_pos so CPU can set curr_pos to next_pos.
                        we_picmem <= '1';   -- PIC_MEM can now take address and data.
                        WRstate <= DRAW;    -- Set state to DRAW so we take data from next_pos.
                    else
                        move_resp <= '0';    
                        we_picmem <= '0';
                    end if;
                when others =>              -- We're in DRAW-state, set data for PIC_MEM.
                    addr_change <= xpos + (to_unsigned(40, 11) * ypos); -- Translates x- and y-pos into PIC_MEM-address.
                    data_change <= tile;    -- Sets data to the correct tile (CHAR since we're in DRAW).
                    WRstate <= IDLE;        -- Go back to IDLE-state.
            end case;
        end if;
    end if;
    end process;
	
    -- Sets variables. Takes x- and y-pos from curr_pos if we're in CLEAR,
    -- otherwise from next_pos.
    xpos <= curr_pos(14 downto 9) when (WRstate = CLEAR) else next_pos(14 downto 9);
    ypos <= curr_pos(4 downto 0) when (WRstate = CLEAR) else next_pos(4 downto 0);
    tile <= "00001" when (WRstate = DRAW) else "00000";
  
    end behavioral;

