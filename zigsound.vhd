library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--**********************
--* Computer Interface *
--**********************
entity zigsound is

    port(
        clk             : in std_logic;
        rst             : in std_logic
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
		    uAddr           : out unsigned(7 downto 0);
		    uData           : in unsigned(24 downto 0);
		    pAddr           : out signed(7 downto 0);
		    pData           : in signed(17 downto 0);
		    PS2cmd          : in unsigned(17 downto 0);
            move_req_out    : out std_logic;
		    move_resp       : in std_logic;
		    curr_pos_out    : out signed(17 downto 0);
		    next_pos_out    : out signed(17 downto 0);
		    sel_track_out   : out unsigned(1 downto 0);
		    sel_sound_out   : out std_logic
		    );
  	end component;

    -- Micro Memory Component
    component uMem
        port(uAddr          : in unsigned(7 downto 0);
             uData          : out unsigned(24 downto 0));
    end component;

    -- Program Memory Component
	component pMem
		port(pAddr          : in signed(7 downto 0);
			 pData          : out signed(17 downto 0));
	end component;
	
    -- Graphics control component (GPU)
	component GPU
		port(
        clk                 : in std_logic;			-- system clock (100 MHz)
        rst	        		: in std_logic;			-- reset signal
        -- TO/FROM CPU
        move_req            : in std_logic;         -- move request
        curr_pos            : in unsigned(17 downto 0); -- current position
        next_pos            : in unsigned(17 downto 0); -- next position
        move_resp			: out std_logic;		-- response to move request
        -- TO/FROM PIC_MEM
        data_nextpos        : in std_logic_vector(7 downto 0);  -- tile data at nextpos
        addr_nextpos        : out unsigned(10 downto 0); -- tile addr of nextpos
        data_change			: out std_logic_vector(7 downto 0);	-- tile data for change
        addr_change			: out unsigned(10 downto 0); -- tile address for change
        we_picmem			: out std_logic		-- write enable for PIC_MEM
		);
	end component;

	-- Picture memory component (PIC_MEM)
	component PIC_MEM
		port(
        clk		        	: in std_logic;
        rst		            : in std_logic;
        -- CPU
        sel_track       	: in std_logic_vector(1 downto 0);
        -- GPU
        we		        	: in std_logic;
        data_nextpos    	: out std_logic_vector(7 downto 0);
        addr_nextpos    	: in unsigned(10 downto 0);
        data_change	    	: in std_logic_vector(7 downto 0);
        addr_change	    	: in unsigned(10 downto 0);
        -- VGA MOTOR
        data_vga        	: out std_logic_vector(7 downto 0);
        addr_vga	    	: in unsigned(10 downto 0)
		);
	end component;

	-- VGA motor component (VGA_MOTOR)
	component VGA_MOTOR
		port(
		clk					: in std_logic;
		rst	        		: in std_logic;
		data	    		: in std_logic_vector(7 downto 0);
		addr	    		: out unsigned(10 downto 0);
		vgaRed	       		: out std_logic_vector(2 downto 0);
		vgaGreen	    	: out std_logic_vector(2 downto 0);
		vgaBlue		    	: out std_logic_vector(2 downto 1);
		Hsync		    	: out std_logic;
		Vsync		    	: out std_logic
		);
	end component;

    --**********************
    --* Connecting signals *
    --**********************  
    
    -- CPU
    signal pAddr_con        : signed(7 downto 0);
    signal uAddr_con        : unsigned(7 downto 0);
    signal PS2cmd_con       : unsigned(17 downto 0);
    signal move_req_con     : std_logic;
    signal move_resp_con    : std_logic;
    signal curr_pos_con     : signed(17 downto 0);
	signal next_pos_con     : signed(17 downto 0);
	signal sel_track_con    : unsigned(1 downto 0);
	signal sel_sound_con    : std_logic;
    
    -- uMem
    signal uData_con        : unsigned(24 downto 0);
    
    -- pMem
    signal pData_con        : signed(17 downto 0);
    
    -- GPU signals
    signal move_resp_con        : std_logic;  -- Move request response
    signal addr_nextpos_con     : unsigned(10 downto 0);    -- tile addr of nextpos
    signal data_change_con      : std_logic_vector(7 downto 0);	    -- tile data for change
    signal addr_change_con      : unsigned(10 downto 0);            -- tile address for change
    signal we_picmem_con        : std_logic;		                -- write enable for PIC_MEM
	
	-- PIC_MEM signals
    signal data_nextpos_con     : std_logic_vector(7 downto 0); -- data PIC_MEM -> GPU
    signal data_vga_con         : std_logic_vector(7 downto 0); -- data PIC_MEM -> VGA
	
	-- VGA MOTOR signals 
    signal addr_vga_con         : unsigned(10 downto 0);
	
begin

    --****************
    --* Port Mapping *
    --****************
    
    -- CPU component connection
    U0 : CPU port map(
                clk => clk, 
                rst => rst, 
                uAddr => uAddr_con, 
                uData => uData_con, 
                pAddr => pAddr_con, 
                pData => pData_con,
                PS2cmd => PS2cmd_con,
                move_req_out => move_req_con,
                move_resp => move_resp_con,
                curr_pos_out => curr_pos_con,
                next_pos_out => next_pos_con,
                sel_track_out => sel_track_con,
                sel_sound_out => sel_sound_con
                );

    -- micro memory component connection
    U1 : uMem port map(
                uAddr => uAddr_con, 
                uData => uData_con
                );

    -- program memory component connection
    U2 : pMem port map(
                pAddr => pAddr_con, 
                pData => pData_con
                );
                
                - GPU component connection
	U3 : GPU port map(
	            clk => clk, 
	            rst => rst, 
	            move_req => move_req,
	            move_resp => move_resp,
	            curr_pos => curr_pos,
	            next_pos => next_pos,
                data_nextpos => data_nextpos_out,
                addr_nextpos => addr_nextpos_out,
                data_change => data_change_out,
                addr_change => addr_change_out,
                we_picmem => we_picmem_out
	            );
	
	-- PIC_MEM component connection
	U4 : PIC_MEM port map(
	            clk => clk,
	            rst => rst,
	            we => we_picmem_out,
	            data_nextpos => data_nextpos_out,
	            addr_nextpos => addr_nextpos_out,
	            data_change => data_change_out,
	            addr_change => addr_change_out,
	            data_vga => data_vga_out,
	            addr_vga => addr_vga_out,
	            sel_track => sel_track
	            );
	
	-- VGA_MOTOR component connection
	U5 : VGA_MOTOR port map(
	            clk => clk,
	            rst => rst,
	            data => data_vga_out,
	            addr => addr_vga_out,
	            vgaRed => vgaRed,
	            vgaGreen => vgaGreen,
	            vgaBlue => vgaBlue,
	            Hsync => Hsync,
	            Vsync => Vsync
	            );

end Behavioral;
