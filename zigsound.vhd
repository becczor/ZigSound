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
        -- KBD_ENC out
        PS2KeyboardCLK          : in std_logic;  -- USB keyboard PS2 clock
        PS2KeyboardData         : in std_logic;  -- USB keyboard PS2 data

        -- Sound
        JB1                     : out std_logic;   -- the pmod is plugged in to the upper row of second slot
        
        --Test
        debug_PS2CLK            : out std_logic;
        debug_PS2Data           : out std_logic;
        test_diod   		    : out std_logic;
        test2_diod   		    : out std_logic;
        switch                  : in std_logic
        );
        
end zigsound;

architecture Behavioral of zigsound is
    
    --**************
    --* Components *
    --**************
    
    -- CPU component
	component CPU
    	port(
            clk             : in std_logic;
		    rst             : in std_logic;
		    --uAddr           : out unsigned(7 downto 0);
		    --uData           : in unsigned(24 downto 0);
		    --pAddr           : out signed(7 downto 0);
		    --pData           : in signed(17 downto 0);
		    PS2cmd          : in unsigned(17 downto 0);
            move_req_out    : out std_logic;
		    move_resp       : in std_logic;
		    curr_pos_out    : out signed(17 downto 0);
		    next_pos_out    : out signed(17 downto 0);
            goal_pos_out    : out signed(17 downto 0);
		    sel_track_out   : out unsigned(1 downto 0);
		    sel_sound_out   : out std_logic;
		    --test_diod   	: out std_logic;
		    switch          : in std_logic
		    );
  	end component;

    -- uMem : Micro Memory Component
    --component uMem
    --    port(uAddr          : in unsigned(7 downto 0);
    --         uData          : out unsigned(24 downto 0));
    --end component;

    -- pMem : Program Memory Component
	--component pMem
	--	port(pAddr          : in signed(7 downto 0);
	--		 pData          : out signed(17 downto 0));
	--end component;
	
    -- GPU : Graphics control component 
	component GPU
		port(
        clk                 : in std_logic;  -- system clock (100 MHz)
        rst	        		: in std_logic;  -- reset signal
        -- TO/FROM CPU
        move_req            : in std_logic;  -- move request
        curr_pos            : in signed(17 downto 0);  -- current position
        next_pos            : in signed(17 downto 0);  -- next position
        move_resp			: out std_logic;  -- response to move request
        -- TO/FROM PIC_MEM
        data_nextpos        : in unsigned(7 downto 0);  -- tile data at nextpos
        addr_nextpos        : out unsigned(10 downto 0);  -- tile addr of nextpos
        data_change			: out unsigned(7 downto 0);  -- tile data for change
        addr_change			: out unsigned(10 downto 0);  -- tile address for change
        we_picmem			: out std_logic  -- write enable for PIC_MEM
		);
	end component;

	-- PIC_MEM : Picture memory component
	component PIC_MEM
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
	end component;

	-- VGA_MOTOR : VGA motor component
	component VGA_MOTOR
		port(
		clk					: in std_logic;
		rst	        		: in std_logic;
		data	    		: in unsigned(7 downto 0);
		addr	    		: out unsigned(10 downto 0);
		vgaRed	       		: out std_logic_vector(2 downto 0);
		vgaGreen	    	: out std_logic_vector(2 downto 0);
		vgaBlue		    	: out std_logic_vector(2 downto 1);
		Hsync		    	: out std_logic;
		Vsync		    	: out std_logic
		);
	end component;
	
	-- KBD_ENC : Keyboard encoder
	component KBD_ENC
		port(
		clk					: in std_logic;
		rst	        		: in std_logic;
		PS2KeyboardCLK      : in std_logic;  -- USB keyboard PS2 clock
        PS2KeyboardData     : in std_logic;  -- USB keyboard PS2 data
        PS2cmd				: out unsigned(17 downto 0)
        --TEST
	    --test_diod		    : buffer std_logic  
		);
	end component;
	
    -- Sound component
    component SOUND
        port (
        clk                 : in std_logic;                      -- system clock (100 MHz)
        rst                 : in std_logic;                      -- reset signal
        goal_pos            : in signed(17 downto 0);  -- goal position
        curr_pos            : in signed(17 downto 0);  -- current position
        channel             : in std_logic;                      -- deciding which of the two sound that should be played, 0 = curr, 1 = goal.
        sound_data          : out std_logic;
        test_diod		    : buffer std_logic;
        test2_diod          : buffer std_logic
        );
    end component;

    --**********************
    --* Connecting signals *
    --**********************  
    
    -- CPU signals
    --signal pAddr_con        : signed(7 downto 0);
    --signal uAddr_con        : unsigned(7 downto 0);
    signal move_req_con     : std_logic;
    signal curr_pos_con     : signed(17 downto 0);
	signal next_pos_con     : signed(17 downto 0);
    signal goal_pos_con     : signed(17 downto 0);
	signal sel_track_con    : unsigned(1 downto 0);
	signal sel_sound_con    : std_logic;
    
    -- uMem signals
    --signal uData_con        : unsigned(24 downto 0);
    
    -- pMem signals
    --signal pData_con        : signed(17 downto 0);
    
    -- GPU signals
    signal move_resp_con        : std_logic;  -- Move request response
    signal addr_nextpos_con     : unsigned(10 downto 0);  -- tile addr of nextpos
    signal data_change_con      : unsigned(7 downto 0);  -- tile data for change
    signal addr_change_con      : unsigned(10 downto 0);  -- tile address for change
    signal we_picmem_con        : std_logic;  -- write enable for PIC_MEM
	
	-- PIC_MEM signals
    signal data_nextpos_con     : unsigned(7 downto 0); -- data PIC_MEM -> GPU
    signal data_vga_con         : unsigned(7 downto 0); -- data PIC_MEM -> VGA
	
	-- VGA MOTOR signals 
    signal addr_vga_con         : unsigned(10 downto 0);
    --TEST
    --signal vgaGreen_dummy   	: std_logic_vector(2 downto 0);
    
    -- KBD_ENC signals
    signal PS2cmd_con           : unsigned(17 downto 0);

    -- SOUND signals
    signal sound_data_con       : std_logic;
    

	
begin

    debug_PS2CLK <= PS2KeyboardCLK;
    debug_PS2Data <= PS2KeyboardData;

    JB1 <= sound_data_con;

    --****************
    --* Port Mapping *
    --****************
    
    -- CPU Component Connection
    U0 : CPU port map(
                clk => clk, 
                rst => rst, 
                --uAddr => uAddr_con, 
                --uData => uData_con, 
                --pAddr => pAddr_con, 
                --pData => pData_con,
                PS2cmd => PS2cmd_con,
                move_req_out => move_req_con,
                move_resp => move_resp_con,
                curr_pos_out => curr_pos_con,
                next_pos_out => next_pos_con,
                sel_track_out => sel_track_con,
                sel_sound_out => sel_sound_con,
                --test_diod => test_diod,
                switch => switch
                );

    -- uMem Component Connection
    --U1 : uMem port map(
    --            uAddr => uAddr_con, 
    --            uData => uData_con
    --            );

    -- pMem Component Connection
    --U2 : pMem port map(
    --            pAddr => pAddr_con, 
    --            pData => pData_con
    --            );
                
    -- GPU Component Connection
	U3 : GPU port map(
	            clk => clk, 
	            rst => rst, 
	            move_req => move_req_con,
	            move_resp => move_resp_con,
	            curr_pos => curr_pos_con,
	            next_pos => next_pos_con,
                data_nextpos => data_nextpos_con,
                addr_nextpos => addr_nextpos_con,
                data_change => data_change_con,
                addr_change => addr_change_con,
                we_picmem => we_picmem_con
	            );
	
	-- PIC_MEM Component Connection
	U4 : PIC_MEM port map(
	            clk => clk,
	            rst => rst,
	            we => we_picmem_con,
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
	            addr => addr_vga_con,
	            vgaRed => vgaRed,
	            vgaGreen => vgaGreen,
	            --vgaGreen => vgaGreen_dummy,
	            vgaBlue => vgaBlue,
	            Hsync => Hsync,
	            Vsync => Vsync
	            );
	            
	--vgaGreen <= "111" when PS2cmd_con(2) = '1' or vgaGreen = "111" else "000";
	            
	-- KBD_ENC Component Connection            
    U6 : KBD_ENC port map(
	            clk => clk,
	            rst => rst,
	            PS2KeyboardCLK => PS2KeyboardCLK,
	            PS2KeyboardData => PS2KeyboardData,
	            PS2cmd => PS2cmd_con
	            --test_diod => test_diod
	            );

    U7 : SOUND port map(
                clk => clk,
                rst => rst,
                goal_pos => goal_pos_con,
                curr_pos => curr_pos_con,
                channel => sel_sound_con,
                sound_data => sound_data_con,
                test_diod => test_diod,
                test2_diod => test2_diod
                );

  end Behavioral;
