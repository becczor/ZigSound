library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity zigsound is
  port(clk: in std_logic;
		rst: in std_logic);
end zigsound ;

architecture Behavioral of zigsound is


    -- CPU component
	component CPU
    	port(
		    clk : in std_logic;
		    rst : out std_logic
		    uAddr : out unsigned(5 downto 0);
		    uData : in unsigned(15 downto 0)
		    pAddr : out unsigned(15 downto 0);
		    pData : in unsigned(15 downto 0);
            move_req : out std_logic;
		    move_resp : in std_logic;
		    curr_pos : out unsigned(17 downto 0);
		    next_pos : out unsigned(17 downto 0);
		    sel_track : out std_logic_vector(1 downto 0)
		    );
  	end component;

    -- micro Memory component
    component uMem
        port(uAddr : in unsigned(5 downto 0);
             uData : out unsigned(15 downto 0));
    end component;

    -- program Memory component
	component pMem
		port(pAddr : in unsigned(15 downto 0);
			 pData : out unsigned(15 downto 0));
	end component;

    --********************
    -- Connecting signals
    --********************  
    signal uAddr_con : unsigned(5 downto 0);
    signal uData_con : unsigned(15 downto 0);
    signal pAddr_con : unsigned(15 downto 0);
    signal pData_con : unsigned(15 downto 0);
	

begin

    -- CPU component connection
    U0 : CPU port map(uAddr=>uAddr_con, uData=>uData_con, pAddr=>pAddr_con, pData=>pData_con);

    -- micro memory component connection
    U0 : uMem port map(uAddr=uAddr_con, uData=>uData_con);

    -- program memory component connection
    U1 : pMem port map(pAddr=>pAddr_con, pData=>pData_con);
	

	


end Behavioral;
