library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--*****************
--* CPU interface *
--*****************
entity CPU is
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
        goal_pos_out    : out signed(17 downto 0);
		sel_track_out   : out unsigned(1 downto 0);
		sel_sound_out   : out std_logic
		--TEST
        --test_diod       : out std_logic;
        --switch          : in std_logic
        );
end CPU;

architecture Behavioral of CPU is

    --****************
    --* Port aliases *
    --****************
    alias uM            : unsigned(24 downto 0) is uData(24 downto 0);
    alias PM            : signed(17 downto 0) is pData(17 downto 0);
    
    --*****************************
    --* Micro Instruction Aliases *
    --*****************************
    alias ALU           : unsigned(3 downto 0) is uM(24 downto 21);     -- ALU    
    alias TB            : unsigned(2 downto 0) is uM(20 downto 18);     -- To bus
    alias FB            : unsigned(2 downto 0) is uM(17 downto 15);     -- From bus
    alias S             : std_logic is uM(14);                          -- S-bit
    alias P             : std_logic is uM(13);                          -- P-bit
    alias LC            : unsigned(1 downto 0) is uM(12 downto 11);     -- LC
    alias SEQ           : unsigned(3 downto 0) is uM(10 downto 7);      -- SEQ
    alias MICROADDR     : unsigned(7 downto 0) is uM(7 downto 0);       -- Micro address
    
    --**************************************
    --* Program Memory Instruction Aliases *
    --**************************************
    alias OP            : signed(4 downto 0) is PM(17 downto 13);     -- Operation    
    alias GRX           : signed(2 downto 0) is PM(12 downto 10);     -- Register    
    alias M             : signed(1 downto 0) is PM(9 downto 8);       -- Addressing mode        
    alias ADDR          : signed(7 downto 0) is PM(7 downto 0);       -- Address field    

    --****************************
    --* Outgoing signals signals *
    --****************************
    -- To pMem
    signal ASR          : signed(7 downto 0);  -- (pAddr)
    -- To uMem
    signal uPC          : unsigned(7 downto 0); -- Micro Program Counter (uAddr)
    -- To GPU
    signal MOVE_REQ     : std_logic := '0';  -- Move request (move_req_out)
    signal CURR_POS     : signed(17 downto 0) := "000000001000000001"; -- Current Position (curr_pos_out)
    signal NEXT_POS     : signed(17 downto 0) := "000000001000000001";  -- Next Postition (next_pos_out)
    signal SEL_TRACK    : signed(1 downto 0) := "00";  -- Track select (sel_track_out)
    signal RND_SEL_TRACK : signed(1 downto 0) := "00"; -- Randomly generated track selector.
    -- Temp for saving next track before we can apply it to SEL_TRACK.
    signal next_track   : signed(1 downto 0) := "00"; 
    -- To SOUND
    signal SEL_SOUND    : std_logic := '0'; -- Sound select (sel_sound_out)
    
    --**************************
	--* Program Memory Signals *
	--**************************
	signal PC           : signed(7 downto 0); -- Program Counter
	signal IR           : signed(17 downto 0); -- Instruction Register 
	signal DATA_BUS     : signed(17 downto 0); -- Data Bus
	
    --****************
    --* Flag Signals *
    --****************
	signal flag_Z       : std_logic := '0';
	signal flag_N       : std_logic := '0';
	signal flag_C       : std_logic := '0';  -- NOT ALWAYS BEING DETECTED ATM
	signal flag_O       : std_logic := '0';  -- NOT BEING DETECTED ATM
	signal flag_L       : std_logic := '0';  -- NOT BEING DETECTED ATM
    signal flag_G       : std_logic := '0';  -- Goal reached
	
    --********************
    --* Register Signals *
    --********************
    signal AR           : signed(17 downto 0) := (others => '0');
    signal GR0          : signed(17 downto 0) := (others => '0');
    signal GR1          : signed(17 downto 0) := (others => '0');
    signal GR2          : signed(17 downto 0) := (others => '0');
    signal GR3          : signed(17 downto 0) := (others => '0');
    signal GOAL_POS     : signed(17 downto 0) := "000010100000001111";  -- Goal position (goal_pos_out)
    signal RND_GOAL_POS : signed(17 downto 0) := (others => '0');
    
    --********************
    --* Register aliases *
    --********************
    alias CURR_XPOS     : signed(5 downto 0) is CURR_POS(14 downto 9);
    alias CURR_YPOS     : signed(4 downto 0) is CURR_POS(4 downto 0);
    alias NEXT_XPOS     : signed(5 downto 0) is NEXT_POS(14 downto 9);
    alias NEXT_YPOS     : signed(4 downto 0) is NEXT_POS(4 downto 0);
    alias GOAL_XPOS     : signed(5 downto 0) is GOAL_POS(14 downto 9);
    alias GOAL_YPOS     : signed(4 downto 0) is GOAL_POS(4 downto 0);
    alias key_code      : unsigned(2 downto 0) is PS2cmd(2 downto 0);

    --************
    --* Counters *
    --************
    signal x_cnt        : signed(5 downto 0) := (others => '0');
    signal y_cnt        : signed(4 downto 0) := (others => '0');
    signal dly_cnt      : unsigned(1 downto 0) := (others => '0');

     --TEST                             
    --signal test_led_counter             : unsigned(25 downto 0);
    --signal test_signal                  : std_logic;
    --signal working                      : std_logic;

    --****************************************************************************
	--* uAddr_instr : Array of uAddresses where each instruction begins in uMem. *
	--****************************************************************************
	type uAddr_instr_t is array (0 to 31) of unsigned(7 downto 0);
	constant uAddr_instr_c : uAddr_instr_t := 
	-- OP consists of 5 bits, so the maximum amount of instructions is 32.
        (x"0A", -- LOAD     "00000" 0
         x"0B", -- STORE    "00001" 1
         x"0C", -- ADD      "00010" 2
         x"0F", -- SUB      "00011" 3
         x"12", -- AND      "00100" 4
         x"15", -- LSR      "00101" 5
         x"1B", -- BRA      "00110" 6
         x"1E", -- CMP      "00111" 7
         x"20", -- BNE      "01000" 8
         x"22", -- BGT      "01001" 9
         x"29", -- BGE      "01010" 10
         x"2E", -- HALT     "01011" 11
         x"2F", -- BCT      "01100" 12
         x"31", -- SETRND   "01101" 13
         x"00", -- NULL     "01110" 14
         x"00", -- NULL     "01111" 15
         x"00", -- NULL     "10000" 16
         x"00", -- NULL     "10001" 17
         x"00", -- NULL     "10010" 18
         x"00", -- NULL     "10011" 19
         x"00", -- NULL     "10100" 20
         x"00", -- NULL     "10101" 21
         x"00", -- NULL     "10110" 22
         x"00", -- NULL     "10111" 23
         x"00", -- NULL     "11000" 24
         x"00", -- NULL     "11001" 25
         x"00", -- NULL     "11010" 26
         x"00", -- NULL     "11011" 27
         x"00", -- NULL     "11100" 28
         x"00", -- NULL     "11101" 29
         x"00", -- NULL     "11110" 30
         x"00"  -- NULL     "11111" 31
        );
    signal uAddr_instr : uAddr_instr_t := uAddr_instr_c;
    
    --**************************
    --* p_mem : Program Memory *
    --**************************
    type free_pos_mem_t is array (0 to 3) of signed(17 downto 0);
    -- Maximum array length is 256, change when adding/deleting from pMem.
    constant free_pos_mem_c : free_pos_mem_t := (
        -- NNN_XXXXXX_NNNN_YYYYY
        "000" & to_signed(0) & "0000" & to_signed(1),
        "000" & to_signed(0) & "0000" & to_signed(0),
        "000" & to_signed(0) & "0000" & to_signed(0),
        "000" & to_signed(0) & "0000" & to_signed(0),
        "000" & to_signed(0) & "0000" & to_signed(0),
        "000" & to_signed(0) & "0000" & to_signed(0),
        "000" & to_signed(0) & "0000" & to_signed(0),
        "000" & to_signed(0) & "0000" & to_signed(0),
	);
    signal p_mem : p_mem_t := p_mem_c;

begin 
    
    --****************************
    --* Random number generation *
    --****************************  
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                x_cnt <= "010110";
                y_cnt <= "10011";
            else
                x_cnt <= x_cnt + 1;
                y_cnt <= y_cnt + 1;
            end if;
        end if;
    end process;

    RND_SEL_TRACK <= x_cnt(1 downto 0) when (not x_cnt(1 downto 0) = "11") else "00";
    RND_GOAL_POS <= ("000" & x_cnt & "0000" & y_cnt) when ((not (to_integer(x_cnt) = 1)) and (not (to_integer(y_cnt) = 1)));

    
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

    -- FB = "010" UNUSED (CAN'T WRITE TO PM)
    
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

    -- FB = "100" UNUSED (UNDEFINED)
    -- FB = "101" UNUSED (HR)
    
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
    --* GOAL_POS : Goal Position Register *
    --************************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                GOAL_POS <= (others => '0');
            elsif (FB = "110" and GRX = "100") then
                GOAL_POS <= DATA_BUS;
            end if;
        end if;
    end process;


    ----****************************************
    ----* SEL_TRACK : Track-selection Register *
    ----****************************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                SEL_TRACK <= "00";
                dly_cnt <= to_unsigned(0,2);
            -- In process of changing track, locking keyboard.
            elsif (dly_cnt = 0 and FB = "110" and GRX = "101") then
                next_track <= DATA_BUS(1 downto 0); 
                dly_cnt <= to_unsigned(1,2);
            elsif (dly_cnt = 1) then
                dly_cnt <= to_unsigned(2,2);
            -- Unlocking keyboard and changing track.
            elsif (dly_cnt = 2) then
                dly_cnt <= to_unsigned(0,2);
                SEL_TRACK <= next_track;
            else
                null;
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
            elsif (FB = "111") then 
                ASR <= DATA_BUS(7 downto 0);
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
                            uPC <= "00000011"; -- "Direct adressering" uAddr
                        when "01" => 
                            uPC <= "00000100"; -- "Immediate operand" uAddr
                        when "10" => 
                            uPC <= "00000101"; -- "Indirect adressering" uAddr
                        when "11" => 
                            uPC <= "00000111"; -- "Indexed adressering" uAddr
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
                when "0101" =>          
                    uPC <= MICROADDR;
                -- "0110" and "0111" UNUSED (Subroutine-related)
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
                --when "1010" =>
                --    if (flag_C = '1') then
                --        uPC <= MICROADDR;
                --    else 
                --        uPC <= uPC + 1;
                --    end if;
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
                when "1101" =>  -- Used in BCT (branch on continue).
                    if (flag_G = '1') then
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
                    uPC <= (others => '0'); -- SHOULD ALSO HALT EXECUTION   
                when others =>
                    null;
            end case; 
        end if;
    end if;
    end process;
    
    --******************************
    --* Goal position reached flag *
    --******************************
    flag_G <= '1' when (CURR_POS = GOAL_POS) else '0';  
    
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
                    null;
                    
                when "0001" => -- AR := DATA_BUS (No flags)
                    AR <= DATA_BUS;
                    
                --when "0010" =>  -- ONES' COMPLEMENT, (No flags) ***UNUSED***
                --when "0011" =>  -- SET TO ZERO (Z/N)            ***UNUSED***
                --    AR <= (others => '0'); 
                --    flag_N <= '0';
                --    flag_Z <= '1';
                    
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
                        
                 --when "0111" => -- AR := AR or DATA_BUS (Z/N)       ***UNUSED***
                 --   AR <= AR or DATA_BUS;
                 --   if (AR(17) = '1' or DATA_BUS(17) = '1') then
                 --       flag_N <= '1';
                 --   else
                 --       flag_N <= '0';
                 --   end if;
                 --   if (to_integer(AR or DATA_BUS) = 0) then
                 --       flag_Z <= '1';
                 --   else
                 --       flag_Z <= '0';
                 --   end if;
                    
                --when "1000" => -- AR := AR + BUSS (No flags)        ***UNUSED***
                --    AR <= AR + DATA_BUS;
                    
                --when "1001" => -- AR LSL, zero is shifted in, bit shifted out to C. (Z/N(C) ***UNUSED***
                --    AR <= AR(16 downto 0) & '0';
                --    flag_C <= AR(17);
                --    flag_N <= AR(16);
                --    if (to_integer(AR(16 downto 0)) = 0) then
                --        flag_Z <= '1';
                --    else
                --        flag_Z <= '0';
                --    end if;
                    
                --when "1010" => -- AR LSL, 32-bit,                   ***UNUSED***
                    
                --when "1011" => -- AR ASR, sign bit is shifted in, bit shifted out to C. (Z/N/C) ***UNUSED***
                --    AR <= AR(17) & AR(17 downto 1);
                --    flag_C <= AR(0);
                --    flag_N <= AR(17);
                --    if (to_integer(AR(17) & AR(17 downto 1)) = 0) then
                --        flag_Z <= '1';
                --    else
                --        flag_Z <= '0';
                --    end if;
                
                --when "1100" => -- ARHR ASR,                         ***UNUSED***
                
                when "1101" => -- AR LSR, zero is shifted in, bit shifted out to C. (Z/N/C)
                    AR <= '0' & AR(17 downto 1);
                    flag_C <= AR(0);
                    flag_N <= '0';
                    if (to_integer(AR(17 downto 1)) = 0) then
                        flag_Z <= '1';
                    else
                        flag_Z <= '0';
                    end if;
                
                --when "1110" => -- Rotate AR to the left,            ***UNUSED***
                --when "1111" => -- Rotate ARHR to the left (32-bit), ***UNUSED***
     
                when others =>
                    null;
     
            end case;
        end if;
    end if;
    end process;

    --***********************
    --* Data Bus Assignment *
    --***********************
    DATA_BUS <= 
    IR                              when (TB = "001") else
    PM                              when (TB = "010") else
    to_signed(0,10) & PC            when (TB = "011") else
    AR                              when (TB = "100") else
    --NULL                          when (TB = "101") else
    GR0                             when (TB = "110" and GRX = "000") else 
    GR1                             when (TB = "110" and GRX = "001") else 
    GR2                             when (TB = "110" and GRX = "010") else 
    GR3                             when (TB = "110" and GRX = "011") else
    RND_GOAL_POS                    when (TB = "110" and GRX = "100") else
    to_signed(0,16) & RND_SEL_TRACK when (TB = "110" and GRX = "101") else 
    GOAL_POS                        when (TB = "110" and GRX = "110") else 
    to_signed(0,16) & SEL_TRACK     when (TB = "110" and GRX = "111") else
    to_signed(0,10) & ASR           when (TB = "111") else
    DATA_BUS;
    
    --*************************
    --* PS2cmd Interpretation *
    --*************************
    process(clk)
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                CURR_POS <= "000000001000000001";
                NEXT_POS <= "000000001000000001";
                MOVE_REQ <= '0';
                SEL_SOUND <= '0';
            else
                if (move_resp = '1') then
                    CURR_POS <= NEXT_POS;
                end if;
                -- We're changing track, send move_req back to start.
                if (dly_cnt = 0 and FB = "110" and GRX = "101") then  
                    NEXT_POS <= "000000001000000001";
                    MOVE_REQ <= '1';
                -- Not in locked mode, check for key pressed.
                elsif (dly_cnt = 0) then
                    case key_code is
                        when "001" =>  -- UP (W)
                            NEXT_XPOS <= CURR_XPOS;
                            NEXT_YPOS <= CURR_YPOS - 1;
                            MOVE_REQ <= '1';
                        when "010" =>  -- LEFT (A)
                            NEXT_YPOS <= CURR_YPOS;
                            NEXT_XPOS <= CURR_XPOS - 1;
                            MOVE_REQ <= '1';
                        when "011" =>  -- DOWN (S)
                            NEXT_XPOS <= CURR_XPOS;
                            NEXT_YPOS <= CURR_YPOS + 1;
                            MOVE_REQ <= '1';
                        when "100" =>  -- RIGHT (D)
                            NEXT_YPOS <= CURR_YPOS;
                            NEXT_XPOS <= CURR_XPOS + 1;
                            MOVE_REQ <= '1';
                        when "101" => -- SOUND TOGGLE (SPACE)
                            SEL_SOUND <= not SEL_SOUND;
                            MOVE_REQ <= '0';
                        when others =>
                            MOVE_REQ <= '0';
                    end case;
                -- In locked mode, don't check for key pressed.
                else    
                    MOVE_REQ <= '0';
                end if;
            end if;
        end if;
    end process;
    
 
    --*******************************
    --* Outgoing signals assignment *
    --*******************************
    pAddr <= ASR;
    uAddr <= uPC; 
    curr_pos_out <= CURR_POS;
    next_pos_out <= NEXT_POS;
    goal_pos_out <= GOAL_POS;
    sel_track_out <= unsigned(SEL_TRACK);
    sel_sound_out <= SEL_SOUND;
    move_req_out <= MOVE_REQ;
    

    --*************
    --* TEST DIOD *
    --*************
    
    --test_diod <= PS2KeyboardData;
    
    --process(clk)
    --begin
    --if rising_edge(clk) then
    --    if (rst = '1') then
    --        test_led_counter <= (others => '0');
    --        test_diod <= '0';
    --        working <= '0';
    --    elsif (test_signal = '1' or working = '1') then
    --        working <= '1';
    --        test_diod <= '1';
    --        test_led_counter <= test_led_counter + 1;
    --        if (test_led_counter(20) = '1') then
    --            test_led_counter <= (others => '0');
    --            test_diod <= '0';
    --            working <= '0';
    --        end if;
    --    end if;
    --end if;
    --end process;
    
    --test_signal <= switch;

end Behavioral;


