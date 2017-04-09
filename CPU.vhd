library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--*****************
--* CPU interface *
--*****************
entity CPU is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        uAddr       : out unsigned(7 downto 0);
        uData       : in unsigned(24 downto 0);
        pAddr       : out unsigned(7 downto 0);
        pData       : in unsigned(17 downto 0)
		move_req    : out std_logic;
		move_resp   : in std_logic;
		curr_pos    : out unsigned(17 downto 0);
		next_pos    : out unsigned(17 downto 0);
		sel_track   : out unsigned(1 downto 0)
        );
end CPU;

architecture Behavioral of CPU is

    --****************
    --* Port aliases *
    --****************
    alias uM        : unsigned(24 downto 0) is uData(24 downto 0);
    alias PM        : unsigned(17 downto 0) is pData(17 downto 0);
    alias ASR       : unsigned(7 downto 0) is pAddr(7 downto 0);
    
    --*****************************
    --* Micro Instruction Aliases *
    --*****************************
    alias ALU       : unsigned(3 downto 0) is uM(24 downto 21);     -- ALU    
    alias TB        : unsigned(2 downto 0) is uM(20 downto 18);     -- To bus
    alias FB        : unsigned(2 downto 0) is uM(17 downto 15);     -- From bus
    alias S         : std_logic is uM(14);                          -- S-bit
    alias P         : std_logic is uM(13);                          -- P-bit
    alias LC        : unsigned(1 downto 0) is uM(12 downto 11);     -- LC
    alias SEQ       : unsigned(3 downto 0) is uM(10 downto 7);      -- SEQ
    alias MICROADDR : unsigned(7 downto 0) is uM(7 downto 0);       -- Micro address
    
    --**************************************
    --* Program Memory Instruction Aliases *
    --**************************************
    alias OP        : unsigned(4 downto 0) is PM(17 downto 13);     -- Operation    
    alias GRX       : unsigned(2 downto 0) is PM(12 downto 10);     -- Register    
    alias M         : unsigned(1 downto 0) is PM(9 downto 8);       -- Addressing mode    
    alias ADDR      : unsigned(7 downto 0) is PM(7 downto 0);       -- Address field    

    --************************
	--* Micro Memory Signals *
	--************************
	signal uPC      : unsigned(7 downto 0); -- Micro Program Counter
	
    --**************************
	--* Program Memory Signals *
	--**************************
	signal PC       : signed(7 downto 0); -- Program Counter
	signal IR       : signed(17 downto 0); -- Instruction Register 
	signal DATA_BUS : signed(17 downto 0); -- Data Bus
	
    --****************
    --* Flag Signals *
    --****************
	signal flag_Z   : std_logic := '0';
	signal flag_N   : std_logic := '0';
	signal flag_C   : std_logic := '0';  -- NOT ALWAYS BEING DETECTED ATM
	signal flag_O   : std_logic := '0';  -- NOT BEING DETECTED ATM
	signal flag_L   : std_logic := '0';  -- NOT BEING DETECTED ATM
	
    --********************
    --* Register Signals *
    --********************
    signal AR       : signed(17 downto 0) := (others => '0');
    signal GR0      : signed(17 downto 0) := "0000000000000011";    
    signal GR1      : signed(17 downto 0) := "0000000000000011";
    signal GR2      : signed(17 downto 0) := "0000000000000001";
    signal GR3      : signed(17 downto 0) := (others => '0');
    signal GOALPOS  : unsigned(17 downto 0) := (others => '0');
    signal NEXTPOS  : unsigned(17 downto 0) := (others => '0');
    signal CURPOS   : unsigned(17 downto 0) := (others => '0');
    signal PS2CMD   : unsigned(17 downto 0) := (others => '0');

    --****************************************************************************
	--* uAddr_instr : Array of uAddresses where each instruction begins in uMem. *
	--****************************************************************************
	type uAddr_instr_t is array (0 to 31) of std_logic_vector(7 downto 0);
	constant uAddr_instr_c : uAddr_instr_t := 
	-- LÄGG IN STARTADRESSER FÖR INSTRUKTIONER HÄR GUYS!!
        ("00000000",
         "00000000",
         "00000000", 
         "00000000", 
         "00000000", 
         "00000000", 
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000", 
         "00000000", 
         "00000000", 
         "00000000", 
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000", 
         "00000000", 
         "00000000", 
         "00000000", 
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000",
         "00000000");
    signal uAddr_instr : uAddr_instr_t := uAddr_instr_c;

begin 

	--*****************************
    --* IR : Instruction Register *
    --*****************************
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
	
	--*****************************
    --* AR : Accumulator Register *
    --*****************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                AR <= (others => '0');
            elsif (FB = "010") then
                AR <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --************************
    --* PC : Program Counter *
    --************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                PC <= (others => '0');
            elsif (FB = "011") then
                PC <= DATA_BUS(7 downto 0);
            elsif (P = '1') then
                PC <= PC + 1;
            end if;
        end if;
    end process;

	--*****************************************
    --* ASR : Program Memory Address Register *
    --*****************************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                ASR <= (others => '0');
            elsif (FB = "100") then
                ASR <= DATA_BUS(7 downto 0);
            end if;
        end if;
    end process;
    
    -- FB = "101" UNUSED
    
    --****************************
    --* GR0 : General Register 0 *
    --****************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                GR0 <= (others => '0');
            elsif (FB = "110" and GRX = "000") then
                GR0 <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --****************************
    --* GR1 : General Register 1 *
    --****************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                GR1 <= (others => '0');
            elsif (FB = "110" and GRX = "001") then
                GR1 <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --****************************
    --* GR2 : General Register 2 *
    --****************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                GR2 <= (others => '0');
            elsif (FB = "110" and GRX = "010") then
                GR2 <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --****************************
    --* GR3 : General Register 3 *
    --****************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                GR3 <= (others => '0');
            elsif (FB = "110" and GRX = "011") then
                GR3 <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --************************************
    --* GOALPOS : Goal Position Register *
    --************************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                GOALPOS <= (others => '0');
            elsif (FB = "110" and GRX = "100") then
                GOALPOS <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --************************************
    --* NEXTPOS : Next Position Register *
    --************************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                NEXTPOS <= (others => '0');
            elsif (FB = "110" and GRX = "101") then
                NEXTPOS <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --**************************************
    --* CURPOS : Current Position Register *
    --**************************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                CURPOS <= (others => '0');
            elsif (FB = "110" and GRX = "110") then
                CURPOS <= DATA_BUS;
            end if;
        end if;
    end process;
    
    --*********************************
    --* PS2CMD : PS2 Command Register *
    --*********************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                PS2CMD <= (others => '0');
            elsif (FB = "110" and GRX = "111") then
                PS2CMD <= DATA_BUS;
            end if;
        end if;
    end process;
    

    --*******************************
    --* uPC : Micro Program Counter *
    --*******************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                uPC <= (others => '0');
            else
                case SEQ is
                    when "0000" =>
                        uPC <= uPC + 1;
                    when "0001" => 
                        uPC <= uAddr_instr(to_integer(OP));
                    when "0010" =>
                        case M is
                            when "00" =>
                                uPC <= "00000011" -- "Direct adressering" uAddr
                            when "01" => 
                                uPC <= "00000100" -- "Immediate operand" uAddr
                            when "10" => 
                                uPC <= "00000101" -- "Indirect adressering" uAddr
                            when "11" => 
                                uPC <= "00000111" -- "Indexed adressering" uAddr
                            when others => 
                                uPC <= (others => '0');
                        end case;
                    when "0011" =>
                        uPC <= (others => '0');
                    when "0100" =>
                        if (flag_Z = '0') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if;        
                    when "0101" =>          -- "0110" and "0111" UNUSED (Subroutine-related)
                        uPC <= MICROADDR;
                    when "1000" =>
                        if (flag_Z = '1') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                       end if;
                    when "1001" =>
                        if (flag_N = '1') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if;
                    when "1010" =>
                        if (flag_C = '1') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if;
                    when "1011" =>
                        if (flag_O = '1') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if;
                    when "1100" =>
                        if (flag_L = '1') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if;  
                    when "1101" =>
                        if (flag_C = '0') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if; 
                    when "1110" =>
                        if (flag_O = '0') then
                            uPC <= MICROADDR;
                        else 
                            uPC <= uPC + 1;
                        end if;  
                    when "1111" =>
                        uPC = "000000"; -- SHOULD ALSO HALT EXECUTION   
                    when others =>
                        uPC = (others => '0');
                end case; 
            end if;
        end if;
    end process;
    
    
    --*******************************
    --* ALU : Arithmetic Logic Unit *
    --*******************************
    process(clk)
    begin
    if rising_edge(clk) then
        if rst = '1' then
            AR <= (others => '0');
            flag_Z <= '0';
            flag_N <= '0';
            flag_C <= '0';
            flag_O <= '0';
            flag_L <= '0';  
        else
            case ALU is
                when "0000" =>  -- NO FUNCTION (No flags) 
                    
                when "0001" => -- AR := DATA_BUS (No flags)
                    AR <= DATA_BUS;
                    
                when "0010" =>  -- ONES' COMPLEMENT, UNUSED (No flags)
                    AR <= (others => '0'); 
                    
                when "0011" =>  -- SET TO ZERO (Z/N)
                    AR <= (others => '0'); 
                    flag_N <= '0';
                    flag_Z <= '1';
                    
                when "0100" => -- AR := AR + DATA_BUS (Z/N/O/C)
                    AR <= AR + DATA_BUS;
                    if (resize(signed(AR + DATA_BUS),18)(17) = '1') then
                        flag_N <= '1';
                        flag_Z <= '0';
                    else
                        flag_N <= '0';
                        if (to_integer(AR + DATA_BUS) = 0) then
                            flag_Z <= '1';
                        end if; 
                    end if;
                    -- SHOULD SET OVERFLOW AND CARRY AS WELL
                    
                when "0101" => -- AR := AR - DATA_BUS (Z/N/O/C)
                    AR <= AR - DATA_BUS;
                    if (to_integer(AR - DATA_BUS) < 0) then
                        flag_N <= '1';
                        flag_Z <= '0';
                    else
                        flag_N <= '0';
                        if (to_integer(AR - DATA_BUS) = 0) then
                            flag_Z <= '1';
                        end if;
                    end if;
                    -- SHOULD SET OVERFLOW AND CARRY AS WELL
                    
                when "0110" => -- AR := AR and DATA_BUS (Z/N)
                    AR <= AR and DATA_BUS;
                    if (AR(17) = '1' and DATA_BUS(17) = '1') then
                        flag_N <= '1';
                        flag_Z <= '0';
                    else
                        flag_N <= '0';
                        if (to_integer(AR and DATA_BUS) = 0) then
                            flag_Z <= '1';
                        end if;    
                    end if;
                        
                 when "0111" => -- AR := AR or DATA_BUS (Z/N)
                    AR <= AR or DATA_BUS;
                    if (AR(17) = '1' or DATA_BUS(17) = '1') then
                        flag_N <= '1';
                    else
                        flag_N <= '0';
                    end if;
                    if (to_integer(AR or DATA_BUS) = 0) then
                        flag_Z <= '1';
                    else
                        flag_Z <= '0';
                    end if;
                    
                when "1000" => -- AR := AR + BUSS (No flags)
                    AR <= AR + DATA_BUS;
                    
                when "1001" => -- AR LSL, zero is shifted in, bit shifted out to C. (Z/N(C)
                    AR <= AR(16 downto 0) & '0';
                    flag_C <= AR(17);
                    flag_N <= AR(16);
                    if (to_integer(AR(16 downto 0) = 0) then
                        flag_Z = '1';
                    else
                        flag_Z = '0';
                    end if;
                    
                when "1010" => -- AR LSL, 32-bit, UNUSED
                    AR <= (others => '0'); 
                    
                when "1011" => -- AR ASR, sign bit is shifted in, bit shifted out to C. (Z/N/C)
                    AR <= AR(17) & AR(17 downto 1);
                    flag_C <= AR(0);
                    flag_N <= AR(17);
                    if (to_integer(AR(17) & AR(17 downto 1)) = 0) then
                        flag_Z = '1';
                    else
                        flag_Z = '0';
                    end if;
                
                when "1100" => -- ARHR ASR, UNUSED
                    AR <= (others => '0'); 
                
                when "1101" => -- AR LSR, zero is shifted in, bit shifted out to C. (Z/N/C)
                    AR <= '0' & AR(17 downto 1);
                    flag_C <= AR(0);
                    flag_N <= '0';
                    if (to_integer(AR(17 downto 1)) = 0) then
                        flag_Z = '1';
                    else
                        flag_Z = '0';
                    end if;
                
                when "1110" => -- Rotate AR to the left, UNUSED
                    AR <= (others => '0');
                
                when "1111" => -- Rotate ARHR to the left (32-bit), UNUSED
                    AR <= (others => '0'); 
                
                when others =>
                    AR <= (others => '0');
                
            end case;
    end if;
    end process;

    --***********************
    --* Data Bus Assignment *
    --***********************
    DATA_BUS <= 
    IR                      when (TB = "001") else
    PM                      when (TB = "010") else
    ("0000000000" & PC)     when (TB = "011") else
    AR                      when (TB = "100") else
    ("0000000000" & ASR)    when (TB = "101") else
    GR0                     when (TB = "110" and GRX = "000") else 
    GR1                     when (TB = "110" and GRX = "001") else 
    GR2                     when (TB = "110" and GRX = "010") else 
    GR3                     when (TB = "110" and GRX = "011") else 
    GOALPOS                 when (TB = "110" and GRX = "100") else 
    NEXTPOS                 when (TB = "110" and GRX = "101") else 
    CURRPOS                 when (TB = "110" and GRX = "110") else 
    PS2CMD                  when (TB = "110" and GRX = "111") else 
    (others => '0');

end Behavioral;


