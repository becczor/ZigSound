library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity zigsound is
	port(
	clk		                : in std_logic;
	rst		                : in std_logic;
    move_req                : in std_logic;                     -- move request
    move_resp			    : out std_logic;		            -- response to move request
    curr_pos                : in std_logic_vector(17 downto 0); -- current position
    next_pos                : in std_logic_vector(17 downto 0); -- next position
    sel_track       	    : in std_logic_vector(1 downto 0);   -- track select
    -- VGA OUT
    addr		    		: out unsigned(10 downto 0);
    vgaRed		        	: out std_logic_vector(2 downto 0);
    vgaGreen	        	: out std_logic_vector(2 downto 0);
    vgaBlue		        	: out std_logic_vector(2 downto 1);
    Hsync		        	: out std_logic;
    Vsync		        	: out std_logic
    );
end zigsound ;

architecture Behavioral of zigsound is

	-- Micro Memory component
	component uMem
		port(uAddr 	        : in unsigned(5 downto 0);
	 	uData 		        : out unsigned(15 downto 0));
	end component;

	-- Program Memory component
	component pMem
		port(pAddr 	        : in unsigned(15 downto 0);
	 	pData 		        : out unsigned(15 downto 0));
	end component;

	-- Graphics control component (GPU)
	component GPU
		port(
        clk                 : in std_logic;			-- system clock (100 MHz)
        rst	        		: in std_logic;			-- reset signal
        -- TO/FROM CPU
        move_req            : in std_logic;         -- move request
        curr_pos            : in std_logic_vector(17 downto 0); -- current position
        next_pos            : in std_logic_vector(17 downto 0); -- next position
        move_resp			: out std_logic;		-- response to move request
        -- TO/FROM PIC_MEM
        data_nextpos        : in std_logic_vector(7 downto 0);  -- tile data at nextpos
        addr_nextpos        : out std_logic_vector(10 downto 0); -- tile addr of nextpos
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
        addr_nextpos    	: in std_logic_vector(10 downto 0);
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



	-- Micro memory signals
	signal uM : unsigned(15 downto 0); -- micro Memory output
	signal uPC : unsigned(5 downto 0); -- micro Program Counter
	signal uPCsig : std_logic; -- (0:uPC++, 1:uPC=uAddr)
	signal uAddr : unsigned(5 downto 0); -- micro Address
	signal TB : unsigned(2 downto 0); -- To Bus field
	signal FB : unsigned(2 downto 0); -- From Bus field
	
	-- Program memory signals
	signal PM : unsigned(15 downto 0); -- Program Memory output
	signal PC : unsigned(15 downto 0); -- Program Counter
	signal Pcsig : std_logic; -- 0:PC=PC, 1:PC++
	signal ASR : unsigned(15 downto 0); -- Address Register
	signal IR : unsigned(15 downto 0); -- Instruction Register
	signal DATA_BUS : unsigned(15 downto 0); -- Data Bus
	
	-- GPU signals
    signal addr_nextpos_out     : std_logic_vector(10 downto 0);    -- tile addr of nextpos
    signal data_change_out      : std_logic_vector(7 downto 0);	    -- tile data for change
    signal addr_change_out      : unsigned(10 downto 0);            -- tile address for change
    signal we_picmem_out        : std_logic;		                -- write enable for PIC_MEM
	
	-- PIC_MEM signals
    signal data_nextpos_out     : std_logic_vector(7 downto 0); -- data PIC_MEM -> GPU
    signal data_vga_out         : std_logic_vector(7 downto 0); -- data PIC_MEM -> VGA
	
	-- VGA MOTOR signals 
    signal addr_vga_out         : unsigned(10 downto 0);
	
begin

	-- mPC : micro Program Counter
	process(clk)
	begin
	if rising_edge(clk) then
		if (rst = '1') then
			uPC <= (others => '0');
		elsif (uPCsig = '1') then
			uPC <= uAddr;
		else
			uPC <= uPC + 1;
		end if;
	end if;
	end process;
	
	-- PC : Program Counter
	process(clk)
	begin
	if rising_edge(clk) then
		if (rst = '1') then
			PC <= (others => '0');
		elsif (FB = "011") then
			PC <= DATA_BUS;
		elsif (PCsig = '1') then
			PC <= PC + 1;
		end if;
	end if;
	end process;
	
	-- IR : Instruction Register
	process(clk)
	begin
	if rising_edge(clk) then
		if (rst = '1') then
			IR <= (others => '0');
		elsif (FB = "001") then
			IR <= DATA_BUS;
		end if;
	end if;
	end process;

	-- ASR : Address Register
	process(clk)
	begin
	if rising_edge(clk) then
		if (rst = '1') then
			ASR <= (others => '0');
		elsif (FB = "100") then
			ASR <= DATA_BUS;
		end if;
	end if;
	end process;
	
	-- Micro memory component connection
	U0 : uMem port map(uAddr=>uPC, uData=>uM);

	-- Program memory component connection
	U1 : pMem port map(pAddr=>ASR, pData=>PM);
	
	-- GPU component connection
	U2 : GPU port map(
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
	U3 : PIC_MEM port map(
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
	U4 : VGA_MOTOR port map(
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
	
	-- micro memory signal assignments
	uAddr <= uM(5 downto 0);
	uPCsig <= uM(6);
	PCsig <= uM(7);
	FB <= uM(10 downto 8);
	TB <= uM(13 downto 11);

	-- data bus assignment
	DATA_BUS <= IR when (TB = "001") else
	PM when (TB = "010") else
	PC when (TB = "011") else
	ASR when (TB = "100") else
	(others => '0');

end Behavioral;
