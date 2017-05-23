--------------------------------------------------------------------------------
-- ZigSound
-- 04-apr-2017
-- Version 0.1

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--**********************
--* Computer Interface *
--**********************
entity zigsound is
    port(
        clk                     : in std_logic;
        rst                     : in std_logic;
        -- VGA_MOTOR out
        vgaRed		        	: out std_logic_vector(2 downto 0);
        vgaGreen	        	: out std_logic_vector(2 downto 0);
        vgaBlue		        	: out std_logic_vector(2 downto 1);
        Hsync		        	: out std_logic;
        Vsync		        	: out std_logic;
        -- KBD_ENC
        PS2KeyboardCLK          : in std_logic;  -- USB keyboard PS2 clock
        PS2KeyboardData         : in std_logic;  -- USB keyboard PS2 data
        -- Sound
        JB1                     : out std_logic   -- the pmod is plugged in to the upper row of second slot
        );     
end zigsound;

architecture Behavioral of zigsound is
    
    --**************
    --* Components *
    --**************
    
    -- CPU component
	component CPU
    	port(
        clk                     : in std_logic;
        rst                     : in std_logic;
        uAddr                   : out unsigned(6 downto 0);
        uData                   : in unsigned(24 downto 0);
        pAddr                   : out signed(7 downto 0);
        pData                   : in signed(17 downto 0);
        PS2cmd                  : in unsigned(17 downto 0);
        move_req_out            : out std_logic;
        upd_sound_icon_out      : out std_logic;  -- signal for chaning the sound icon
	    move_resp               : in std_logic;
	    curr_pos_out            : out signed(17 downto 0);
	    next_pos_out            : out signed(17 downto 0);
        goal_pos_out            : out signed(17 downto 0);
	    sel_track_out           : out unsigned(1 downto 0);
	    sel_sound_out           : out std_logic;
	    goal_reached_out        : out std_logic;
	    showing_goal_msg        : in std_logic;
	    disp_goal_pos_out       : out std_logic;
        score_out               : out unsigned(5 downto 0)
		);
  	end component;

    --uMem : Micro Memory Component
    component uMem
        port(
        clk                     : in std_logic;   
        uAddr                   : in unsigned(6 downto 0);
        uData                   : out unsigned(24 downto 0)
         );
    end component;

    --pMem : Program Memory Component
	component pMem
        port(
        pAddr                   : in signed(7 downto 0);
        pData                   : out signed(17 downto 0);
        clk                     : in std_logic
        );
	end component;
	
    -- GPU : Graphics control component 
	component GPU
		port(
        clk                     : in std_logic;  -- system clock (100 MHz)
        rst	           		    : in std_logic;  -- reset signal
        -- From SOUND
        sound_channel           : in std_logic;
        -- TO/FROM CPU
        sel_track               : in unsigned(1 downto 0);
        move_req                : in std_logic;  -- move request
        upd_sound_icon          : in std_logic;   -- signal for changing the sound icon
        curr_pos                : in signed(17 downto 0);  -- current position
        next_pos                : in signed(17 downto 0);  -- next position
        move_resp			    : out std_logic;  -- response to move request
        -- TO/FROM TRACK_MEM
        data_nextpos            : in unsigned(7 downto 0);  -- tile data at nextpos
        addr_nextpos            : out unsigned(10 downto 0);  -- tile addr of nextpos
        data_change			    : out unsigned(7 downto 0);  -- tile data for change
        addr_change			    : out unsigned(10 downto 0);  -- tile address for change
        we_trackmem			    : out std_logic  -- write enable for TRACK_MEM
		);
	end component;

	-- TRACK_MEM : Track memory component
	component TRACK_MEM
		port(
        clk    	                : in std_logic;
        rst	                    : in std_logic;
        -- CPU
        sel_track       	    : in unsigned(1 downto 0);
        -- GPU
        we		                : in std_logic;
        data_nextpos    	    : out unsigned(7 downto 0);
        addr_nextpos    	    : in unsigned(10 downto 0);
        data_change	    	    : in unsigned(7 downto 0);
        addr_change	    	    : in unsigned(10 downto 0);
        -- VGA MOTOR
        data_vga        	    : out unsigned(7 downto 0);
        addr_vga	    	    : in unsigned(10 downto 0)
		);
	end component;

	-- VGA_MOTOR : VGA motor component
	component VGA_MOTOR
		port(
		clk			            : in std_logic;
		rst	        	        : in std_logic; 
		data	    		    : in unsigned(7 downto 0);
        sel_track               : in unsigned(1 downto 0);
		goal_pos                : in signed(17 downto 0);
        goal_reached            : in std_logic;
        showing_goal_msg_out    : out std_logic;
        disp_goal_pos           : in std_logic;
        score                   : in unsigned(5 downto 0);
		addr	    		    : out unsigned(10 downto 0);
		vgaRed	       		    : out std_logic_vector(2 downto 0);
		vgaGreen	    	    : out std_logic_vector(2 downto 0);
		vgaBlue		    	    : out std_logic_vector(2 downto 1);
		Hsync		    	    : out std_logic;
		Vsync		    	    : out std_logic
		);
	end component;
	
	-- KBD_ENC : Keyboard encoder
	component KBD_ENC
		port(
		clk					    : in std_logic;
		rst	        		    : in std_logic;
		PS2KeyboardCLK          : in std_logic;  -- USB keyboard PS2 clock
        PS2KeyboardData         : in std_logic;  -- USB keyboard PS2 data
        PS2cmd				    : out unsigned(17 downto 0)
		);
	end component;
	
    -- Sound component
    component SOUND
        port (
        clk                     : in std_logic;            -- system clock (100 MHz)
        rst                     : in std_logic;            -- reset signal
        goal_pos                : in signed(17 downto 0);  -- goal position
        curr_pos                : in signed(17 downto 0);  -- current position
        channel                 : in std_logic;            -- deciding which of the two sounds that should be played, 0 = curr, 1 = goal.
        sound_data              : out std_logic            --
        );
    end component;

    --**********************
    --* Connecting signals *
    --**********************  
    
    -- CPU signals
    signal pAddr_con            : signed(7 downto 0);
    signal uAddr_con            : unsigned(6 downto 0);
    signal move_req_con         : std_logic;
    signal upd_sound_icon_con   : std_logic;
    signal curr_pos_con         : signed(17 downto 0);
	signal next_pos_con         : signed(17 downto 0);
    signal goal_pos_con         : signed(17 downto 0);
	signal sel_track_con        : unsigned(1 downto 0);
	signal sel_sound_con        : std_logic;
	signal disp_goal_pos_con    : std_logic;
    signal goal_reached_con     : std_logic;
    signal score_con            : unsigned(5 downto 0);
    
    -- uMem signals
    signal uData_con            : unsigned(24 downto 0);
    
    -- pMem signals
    signal pData_con            : signed(17 downto 0);
    
    -- GPU signals
    signal move_resp_con        : std_logic;  -- Move request response
    signal addr_nextpos_con     : unsigned(10 downto 0);  -- tile addr of nextpos
    signal data_change_con      : unsigned(7 downto 0);  -- tile data for change
    signal addr_change_con      : unsigned(10 downto 0);  -- tile address for change
    signal we_trackmem_con        : std_logic;  -- write enable for TRACK_MEM
	
	-- TRACK_MEM signals
    signal data_nextpos_con     : unsigned(7 downto 0); -- data TRACK_MEM -> GPU
    signal data_vga_con         : unsigned(7 downto 0); -- data TRACK_MEM -> VGA
	
	-- VGA MOTOR signals 
    signal addr_vga_con         : unsigned(10 downto 0);
    signal showing_goal_msg_con : std_logic;
    
    -- KBD_ENC signals
    signal PS2cmd_con           : unsigned(17 downto 0);

    -- SOUND signals
    signal sound_data_con       : std_logic;
	
begin
    
    JB1 <= sound_data_con;

    --****************
    --* Port Mapping *
    --****************
    
    -- CPU Component Connection
    U0 : CPU port map(
                clk => clk, 
                rst => rst, 
                uAddr => uAddr_con,
                uData => uData_con,
                pAddr => pAddr_con,
                pData => pData_con,
                PS2cmd => PS2cmd_con,
                move_req_out => move_req_con,
                upd_sound_icon_out => upd_sound_icon_con,
                move_resp => move_resp_con,
                curr_pos_out => curr_pos_con,
                next_pos_out => next_pos_con,
                goal_pos_out => goal_pos_con,
                sel_track_out => sel_track_con,
                sel_sound_out => sel_sound_con,
                goal_reached_out => goal_reached_con,
                showing_goal_msg => showing_goal_msg_con,
                disp_goal_pos_out => disp_goal_pos_con,
                score_out => score_con
                );

    -- uMem Component Connection
    U1 : uMem port map(
                clk => clk,
                uAddr => uAddr_con,
                uData => uData_con
                );

    -- pMem Component Connection
    U2 : pMem port map(
                
                pAddr => pAddr_con,
                pData => pData_con,
                clk => clk
                );
                
    -- GPU Component Connection
	U3 : GPU port map(
	            clk => clk, 
	            rst => rst,
	            sound_channel => sel_sound_con, 
	            sel_track => sel_track_con,
	            move_req => move_req_con,
	            upd_sound_icon => upd_sound_icon_con,
	            move_resp => move_resp_con,
	            curr_pos => curr_pos_con,
	            next_pos => next_pos_con,
                data_nextpos => data_nextpos_con,
                addr_nextpos => addr_nextpos_con,
                data_change => data_change_con,
                addr_change => addr_change_con,
                we_trackmem => we_trackmem_con
	            );
	
	-- TRACK_MEM Component Connection
	U4 : TRACK_MEM port map(
	            clk => clk,
	            rst => rst,
	            we => we_trackmem_con,
	            data_nextpos => data_nextpos_con,
	            addr_nextpos => addr_nextpos_con,
	            data_change => data_change_con,
	            addr_change => addr_change_con,
	            data_vga => data_vga_con,
	            addr_vga => addr_vga_con,
	            sel_track => sel_track_con
	            );
	
	-- VGA_MOTOR Component Connection
	U5 : VGA_MOTOR port map(
	            clk => clk,
	            rst => rst,
	            data => data_vga_con,
                sel_track => sel_track_con,
	            goal_pos => goal_pos_con,
	            goal_reached => goal_reached_con,
	            showing_goal_msg_out => showing_goal_msg_con,
	            disp_goal_pos => disp_goal_pos_con, 
	            score => score_con,
	            addr => addr_vga_con,
	            vgaRed => vgaRed,
	            vgaGreen => vgaGreen,
	            vgaBlue => vgaBlue,
	            Hsync => Hsync,
	            Vsync => Vsync
	            );
	            
	-- KBD_ENC Component Connection            
    U6 : KBD_ENC port map(
	            clk => clk,
	            rst => rst,
	            PS2KeyboardCLK => PS2KeyboardCLK,
	            PS2KeyboardData => PS2KeyboardData,
	            PS2cmd => PS2cmd_con
	            );

    U7 : SOUND port map(
                clk => clk,
                rst => rst,
                goal_pos => goal_pos_con,
                curr_pos => curr_pos_con,
                channel => sel_sound_con,
                sound_data => sound_data_con
                );

  end Behavioral;
