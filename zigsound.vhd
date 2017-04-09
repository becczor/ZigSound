library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--**********************
--* Computer Interface *
--**********************
entity zigsound is
    port(
        clk             : in std_logic;
        rst             : in std_logic);
end zigsound ;

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
		    pAddr           : out unsigned(7 downto 0);
		    pData           : in unsigned(17 downto 0);
		    PS2cmd          : in unsigned(17 downto 0);
            move_req        : out std_logic;
		    move_resp       : in std_logic;
		    curr_pos        : out unsigned(17 downto 0);
		    next_pos        : out unsigned(17 downto 0);
		    sel_track       : out unsigned(1 downto 0);
		    sel_sound       : out std_logic
		    );
  	end component;

    -- Micro Memory Component
    component uMem
        port(uAddr          : in unsigned(7 downto 0);
             uData          : out unsigned(24 downto 0));
    end component;

    -- Program Memory Component
	component pMem
		port(pAddr          : in unsigned(7 downto 0);
			 pData          : out unsigned(17 downto 0));
	end component;

    --**********************
    --* Connecting signals *
    --**********************  
    
    -- CPU
    signal pAddr_con        : unsigned(7 downto 0);
    signal uAddr_con        : unsigned(7 downto 0);
    signal move_req_con     : std_logic;
    signal curr_pos_con     : unsigned(17 downto 0);
	signal next_pos_con     : unsigned(17 downto 0);
	signal sel_track_con    : unsigned(1 downto 0);
	signal sel_sound_con    : std_logic;
    
    -- uMem
    signal uData_con        : unsigned(24 downto 0);
    
    -- pMem
    signal pData_con        : unsigned(17 downto 0);
	
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
                move_req => move_req_con,
                move_resp => move_resp_con,
                curr_pos => curr_pos_con,
                next_pos => next_pos_con,
                sel_track => sel_track_con,
                sel_sound => sel_sound_con
                );

    -- micro memory component connection
    U1 : uMem port map(
                uAddr=uAddr_con, 
                uData=>uData_con
                );

    -- program memory component connection
    U2 : pMem port map(
                pAddr=>pAddr_con, 
                pData=>pData_con
                );

end Behavioral;
