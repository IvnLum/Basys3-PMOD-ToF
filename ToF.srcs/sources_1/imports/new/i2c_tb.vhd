----------------------------------------------------------------------------------
-- Author; "IvanLum"
-- 
-- Create Date: 05/28/2024 09:01:25 PM
-- Design Name: 
-- Module Name: i2c_tb - Structural
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity pmodToF_i2c is
    Port (
        CLK     : in  STD_LOGIC;
        sda     : inout  STD_LOGIC;
        scl     : inout  STD_LOGIC;
        data    : out std_logic_vector(15 downto 0);
        IRQ     : inout std_logic;
        SS      : out std_logic;
        rx_event : out std_logic
    );
end pmodToF_i2c;

architecture Structural of pmodToF_i2c is
    
    component i2c_master is
      GENERIC(
        input_clk : integer := 100_000_000; --input clock speed from user logic in Hz
        bus_clk   : integer := 400_000);   --speed the i2c bus (scl) will run at in Hz
      PORT(
        clk       : IN     STD_LOGIC;                    --system clock
        reset_n   : IN     STD_LOGIC;                    --active low reset
        ena       : IN     STD_LOGIC;                    --latch in command
        addr      : IN     STD_LOGIC_VECtoR(6 DOWNto 0); --address of target slave
        rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
        data_wr   : IN     STD_LOGIC_VECtoR(7 DOWNto 0); --data to write to slave
        busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
        data_rd   : OUT    STD_LOGIC_VECtoR(7 DOWNto 0); --data read from slave
        ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
        sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
        scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
    end COMPONENT;
    
    constant pmodToF_i2c_enable_register_address : std_logic_vector(7 downto 0) := x"01"; 
    constant pmodToF_i2c_enable_payload_value : std_logic_vector(7 downto 0) := x"00";
    
    constant pmodToF_i2c_clear_register_address : std_logic_vector(7 downto 0) := x"B0"; 
    constant pmodToF_i2c_clear_payload_value : std_logic_vector(7 downto 0) := x"D1";
    
    constant pmodToF_i2c_request_i_register_address : std_logic_vector(7 downto 0) := x"13"; 
    constant pmodToF_i2c_request_i_payload_value : std_logic_vector(7 downto 0) := x"7D";
    
    constant pmodToF_i2c_request_ii_register_address : std_logic_vector(7 downto 0) := x"60"; 
    constant pmodToF_i2c_request_ii_payload_value : std_logic_vector(7 downto 0) := x"01";
    
    constant pmodToF_i2c_data_register_address_i : std_logic_vector(7 downto 0) := x"D1"; 
    constant pmodToF_i2c_data_register_address_ii : std_logic_vector(7 downto 0) := x"D2";
    
    constant pmodToF_i2c_data_ii_register_address_i : std_logic_vector(7 downto 0) := x"D3"; 
    constant pmodToF_i2c_data_ii_register_address_ii : std_logic_vector(7 downto 0) := x"D4"; 
    
    constant pmodToF_i2c_address : std_logic_vector(6 downto 0) := "1010111"; -- x"57"
    constant pmodToF_i2c_ctrl_addresses_length : integer := 8;
    constant pmodToF_i2c_calib_addresses_length : integer := 13;
    
    type ctrl_addresses is array (0 to 7) of std_logic_vector(7 downto 0);
    type reg_addresses is array (0 to 12) of std_logic_vector(7 downto 0);
    
    constant pmodToF_i2c_ctrl_addresses  : ctrl_addresses := 
        (
            x"10", x"11", x"13", x"60", x"18", x"19", x"90", x"91"
        );
    constant pmodToF_i2c_ctrl_values  : ctrl_addresses := 
        (
            x"04", x"6E", x"71", x"01", x"22", x"22", x"0F", x"FF"
        );
   constant pmodToF_i2c_registers_addresses  : reg_addresses :=
       (
            x"24", x"25", x"26", x"27", x"28", x"29", x"2A", x"2B", x"2C", x"2D", x"2E", x"2F", x"30"
       );
   constant pmodToF_i2c_registers_values  : reg_addresses :=
       (
            x"46", x"52", x"A8", x"47", x"5A", x"73", x"FE", x"00", x"07", x"BD", x"63", x"0F", x"B5"
       );
   signal IRQ_i2c_consume_address : std_logic_vector(7 downto 0) := x"69";
   signal IRQ_i2c_consume_tmp : std_logic_vector(7 downto 0) := (others => '0');
   
   signal current_est : std_logic_vector (4 downto 0) := "00000"; 

   
   type FSM is
    (   IDLE,
        INIT_REG0, INIT_REG1,
        LOAD_CTRL_REGS, LOAD_CALIB_REGS,
        MEASURE_SEQ0, MEASURE_SEQ1, MEASURE_SEQ2,
        MEASUREMENT_SAMPLE,
        SLEEP_SS,
        AWAIT_IRQ_RESPONSE,
        MSB_pre_ACQ, 
        LSB_pre_ACQ,
        MSB_LSB_pre_MERGE,
        PRECISSION_CHECK,
        MSB_ACQ, 
        LSB_ACQ,
        MSB_LSB_MERGE,
        SAMPLES_RESET
    );
   signal fsm_state : FSM := IDLE;
   signal data_buff : std_logic_vector(7 downto 0) := "UUUUUUUU";
   signal init_tof : std_logic := '1';   
   
   signal mode_rw : std_logic := '0';
   signal busy : std_logic := 'U';
   
   signal test_val : std_logic_vector(7 downto 0) := x"AB";
   signal read_i2c : std_logic_vector(7 downto 0) := "UUUUUUUU";
   
   signal ack_error : std_logic := '0';
      SIGNAL i2c_busy    : STD_LOGIC := '0';
   SIGNAL i2c_ack_error    : STD_LOGIC;  
   signal ena : std_logic := '1';

   
   SIGNAL i2c_ena     : STD_LOGIC := '0';    
   SIGNAL i2c_addr    : STD_LOGIC_VECtoR(6 DOWNto 0);
   SIGNAL i2c_rw      : STD_LOGIC;            
   SIGNAL i2c_data_wr : STD_LOGIC_VECtoR(7 DOWNto 0);
   SIGNAL i2c_data_rd : STD_LOGIC_VECtoR(7 DOWNto 0);
   SIGNAL i2c_rst_n    : STD_LOGIC := '1'; 
   
   signal pmodToFMSB : std_logic_vector(7 downto 0);
   signal pmodToFLSB : std_logic_vector(7 downto 0);
   signal MSB_merge_LSB_pre : std_logic_vector(15 downto 0) := (others => 'U');
   signal MSB_merge_LSB : std_logic_vector(15 downto 0) := (others => 'U');
   
   signal iclk : std_logic := '0';
   
   signal busy_prev : std_logic := '0';
   
   signal rx_evt : std_logic := '0';

begin
    data <= MSB_merge_LSB;
    rx_event <= rx_evt;
    a:
    i2c_master port map (
        clk => clk,
        reset_n => i2c_rst_n,
        ena => i2c_ena,
        addr => i2c_addr,
        rw => i2c_rw,
        data_wr => i2c_data_wr,
        busy => i2c_busy,
        data_rd => i2c_data_rd,
        ack_error => i2c_ack_error,
        sda => sda,
        scl => scl
    );

    pmodToF_process : process(clk, i2c_rst_n, ena)
    variable busy_cnt  : integer range 0 to 9 := 0;           
    variable counter   : integer range 0 to 500_000_000 := 0;
    variable current_byte   : integer range 0 to 13 := 0;
    variable samples : integer := 0;
    constant samples_t : integer := 2;
    variable avg : integer := 0;
    begin
        rx_evt <= '0';
        if ena = '0' then
            fsm_state <= IDLE;
            counter := 0;
            busy_cnt := 0;
            current_byte := 0;
        elsif rising_edge(clk) then
            case fsm_state is
            when IDLE =>
                if counter < 10_000_000 then
                    counter := counter + 1;
                else
                    counter := 0;
                    if ena = '1' then 
                        fsm_state <= INIT_REG0;
                    end if;
                end if;
            when INIT_REG0 =>
                busy_prev <= i2c_busy;                        
                if(busy_prev = '0' and i2c_busy = '1') then   
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 => 
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                              
                    i2c_rw <= '0';                                                                                                                     
                    i2c_data_wr <= pmodToF_i2c_enable_register_address;                                                                                              
                when 1 =>                                                                                      
                    i2c_data_wr <= pmodToF_i2c_enable_payload_value;                                                                                      
                when 2 => 
                    i2c_ena <= '0'; 
                    if(i2c_busy = '0') then
                        busy_cnt := 0; 
                        fsm_state <= INIT_REG1;
                    end if;
                when others => NULL;
                end case;
            when INIT_REG1 =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                             
                    i2c_rw <= '0';                                                                                                                        
                    i2c_data_wr <= pmodToF_i2c_clear_register_address;                                                                                               
                when 1 =>                                                                                     
                    i2c_data_wr <= pmodToF_i2c_clear_payload_value;                                                                                      
                when 2 => 
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= LOAD_CTRL_REGS;
                        current_byte := 0;
                    end if;
                when others => NULL;
                end case;
            when LOAD_CTRL_REGS =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is 
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                            
                    i2c_rw <= '0';                                                                                                                       
                    i2c_data_wr <= pmodToF_i2c_ctrl_addresses(current_byte);                                                                                             
                when 1 =>                                                                                     
                    i2c_data_wr <= pmodToF_i2c_ctrl_values(current_byte);                                                                                    
                when 2 => 
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        if current_byte < (pmodToF_i2c_ctrl_addresses_length-1) then
                            current_byte := current_byte + 1;
                            fsm_state <= LOAD_CTRL_REGS;
                        else
                            current_byte := 0;
                            fsm_state <= LOAD_CALIB_REGS;
                        end if;
                    end if;
                when others => NULL;
                end case;
            when LOAD_CALIB_REGS =>
                busy_prev <= i2c_busy; 
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                              
                    i2c_rw <= '0';                                                                                                                  
                    i2c_data_wr <= pmodToF_i2c_registers_addresses(current_byte);                                                                                             
                when 1 =>                                                                                        
                    i2c_data_wr <= pmodToF_i2c_registers_values(current_byte);                                                                                     
                when 2 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        if current_byte < (pmodToF_i2c_calib_addresses_length-1) then
                            current_byte := current_byte + 1;
                            fsm_state <= LOAD_CALIB_REGS;
                        else
                            current_byte := 0;
                            fsm_state <= MEASURE_SEQ0;
                        end if;
                    end if;    
                when others => NULL;
                end case;
            when MEASURE_SEQ0 =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                             
                    i2c_rw <= '0';                                                                                                                  
                    i2c_data_wr <= pmodToF_i2c_request_i_register_address;                                                                                             
                when 1 =>                                                                                     
                    i2c_data_wr <= pmodToF_i2c_request_i_payload_value;                                                                                       
                when 2 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= MEASURE_SEQ1;
                    end if;
                when others => NULL;
                end case;
            when MEASURE_SEQ1 =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                             
                    i2c_rw <= '0';                                                                                                                     
                    i2c_data_wr <= pmodToF_i2c_request_ii_register_address;                                                                                         
                when 1 =>                                                                                     
                    i2c_data_wr <= pmodToF_i2c_request_ii_payload_value;                                                                                      
                when 2 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= MEASURE_SEQ2;
                    end if;
                when others => NULL;
                end case;
            when MEASURE_SEQ2 =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then 
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is 
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                             
                    i2c_rw <= '0';                                                                                                                        
                    i2c_data_wr <= IRQ_i2c_consume_address;                                                                                              
                when 1 =>
                    i2c_rw <= '1';                                                                                 
                when 2 =>
                    if(i2c_busy = '0') then                                                                                      
                        IRQ_i2c_consume_tmp <= i2c_data_rd;
                    end if;                                                                                        
                when 3 => 
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= MEASUREMENT_SAMPLE;
                        i2c_rw <= '0'; 
                        counter := 0;
                    end if;
                when others => NULL;
                end case;
            when MEASUREMENT_SAMPLE =>
                SS <= '0';
                if  counter < 28_000 then
                    counter := counter + 1;
                else
                    fsm_state <= SLEEP_SS;
                    counter := 0;
                end if;
            when SLEEP_SS =>
                SS <= '1';
                if  counter < 72_000 then
                    counter := counter + 1;
                else
                    fsm_state <= AWAIT_IRQ_RESPONSE;
                    counter := 0;
                end if;         
            when AWAIT_IRQ_RESPONSE =>
                if IRQ = '0' then
                    IRQ <= 'Z';
                    fsm_state <= MSB_pre_ACQ;
                end if;
             when MSB_pre_ACQ =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                              
                    i2c_rw <= '0';                                                                                                                       
                    i2c_data_wr <= pmodToF_i2c_data_ii_register_address_i;                                                                                             
                when 1 =>
                    i2c_rw <= '1';                                                                                 
                when 2 =>
                    if(i2c_busy = '0') then                                                                                      
                        pmodToFMSB <= i2c_data_rd;
                    end if;                                                                                        
                when 3 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= LSB_pre_ACQ;
                        i2c_rw <= '0';
                    end if;
                when others => NULL;
                end case;
            when LSB_pre_ACQ =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                              
                    i2c_rw <= '0';                                                                                                                        
                    i2c_data_wr <= pmodToF_i2c_data_ii_register_address_ii;                                                                                             
                when 1 =>
                    i2c_rw <= '1';                                                                                 
                when 2 =>
                    if(i2c_busy = '0') then                                                                                      
                        pmodToFLSB <= i2c_data_rd;
                    end if;                                                                                        
                when 3 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= MSB_LSB_pre_MERGE;
                        i2c_rw <= '0';
                    end if;
                when others => NULL;
                end case;
            when MSB_LSB_pre_MERGE =>
                MSB_merge_LSB_pre <= pmodToFMSB & pmodToFLSB;
                fsm_state <= PRECISSION_CHECK;
            when PRECISSION_CHECK =>
                if ((conv_integer(MSB_merge_LSB_pre) * 33310) / 65536) > 500 then
                    MSB_merge_LSB <= (others => '0');
                    fsm_state <= MEASUREMENT_SAMPLE;
                else
                    fsm_state <= MSB_ACQ;                    
                end if; 
            when MSB_ACQ =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                              
                    i2c_rw <= '0';                                                                                                                       
                    i2c_data_wr <= pmodToF_i2c_data_register_address_i;                                                                                             
                when 1 =>
                    i2c_rw <= '1';                                                                                 
                when 2 =>
                    if(i2c_busy = '0') then                                                                                      
                        pmodToFMSB <= i2c_data_rd;
                    end if;                                                                                        
                when 3 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= LSB_ACQ;
                        i2c_rw <= '0';
                    end if;
                when others => NULL;
                end case;
            when LSB_ACQ =>
                busy_prev <= i2c_busy;
                if(busy_prev = '0' and i2c_busy = '1') then
                    busy_cnt := busy_cnt + 1;
                end if;    
                case busy_cnt is
                when 0 =>
                    i2c_ena <= '1';
                    i2c_addr <= pmodToF_i2c_address;                                                                                                              
                    i2c_rw <= '0';                                                                                                                        
                    i2c_data_wr <= pmodToF_i2c_data_register_address_ii;                                                                                             
                when 1 =>
                    i2c_rw <= '1';                                                                                 
                when 2 =>
                    if(i2c_busy = '0') then                                                                                      
                        pmodToFLSB <= i2c_data_rd;
                    end if;                                                                                        
                when 3 =>
                    i2c_ena <= '0';
                    if(i2c_busy = '0') then
                        busy_cnt := 0;
                        fsm_state <= MSB_LSB_MERGE;
                        i2c_rw <= '0';
                    end if;
                when others => NULL;
                end case;
            when MSB_LSB_MERGE =>
                if samples < samples_t then
                    avg := avg + conv_integer(pmodToFMSB & pmodToFLSB);
                    samples := samples + 1;
                    fsm_state <= MEASUREMENT_SAMPLE;
                else
                    MSB_merge_LSB <= std_logic_vector( to_unsigned(avg / samples_t, 16));
                    rx_evt <= '1';
                    fsm_state <= SAMPLES_RESET;
               end if;
            when SAMPLES_RESET =>
                avg := 0;
                samples := 0;
                fsm_state <= MEASUREMENT_SAMPLE;
            end case;
        end if;
    end process;
end Structural;