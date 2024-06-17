----------------------------------------------------------------------------------
-- Author; "IvanLum"
-- 
-- Create Date: 05/28/2024 06:26:38 PM
-- Design Name: 
-- Module Name: ToF_tb - Structural
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


entity ToF_tb is
    Port (
        CLK     : in  STD_LOGIC;
        RST     : in std_logic;
        
        SDA     : inout std_logic;
        SCL     : inout std_logic;
        IRQ     : inout std_logic;
        SS      : out std_logic;
        
        disp_out: out STD_LOGIC_VECTOR(6 downto 0);
		disp_sel: out STD_LOGIC_VECTOR(3 downto 0)
    );
end ToF_tb;

architecture Structural of ToF_tb is


    
       --####################################################################--
      --######################################################################--
     --##############################             #############################--
    --##############################   COMPONENTS  #############################--
     --##############################             #############################--
      --######################################################################--
       --####################################################################--
       
    ----------------------------------------------------------------------------------
    ------------------------------ Display comp --------------------------------------
    ----------------------------------------------------------------------------------
    component DISPLAY is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        D   : in std_logic_vector(3 downto 0);
        C   : in std_logic_vector(3 downto 0);
        B   : in std_logic_vector(3 downto 0);
        A   : in std_logic_vector(3 downto 0);
        disp_sel : out STD_LOGIC_VECTOR (3 downto 0);
        disp_out : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component;
    
    ----------------------------------------------------------------------------------
    ------------------------------ I2C (pmodToF) comp --------------------------------
    ----------------------------------------------------------------------------------
    component pmodToF_i2c is
        Port (
            CLK     : in  STD_LOGIC;
            sda     : inout  STD_LOGIC;
            scl     : inout  STD_LOGIC;
            data    : out std_logic_vector(15 downto 0);
            IRQ     : inout std_logic;
            SS      : out std_logic;
            rx_event : out std_logic
        );
    end component;
    
    
       --####################################################################--
      --######################################################################--
     --##############################             #############################--
    --##############################    SIGNALS    #############################--
     --##############################             #############################--
      --######################################################################--
       --####################################################################--
    
    
    ----------------------------------------------------------------------------------
    ----------------------------- Display test signals -------------------------------
    ----------------------------------------------------------------------------------
    signal counter : std_logic_vector(15 downto 0) := (others => '0');
    signal decimal_v : std_logic_vector(15 downto 0) := (others => '0');
	signal natur : std_logic_vector(15 downto 0) := (others => '0');
	signal out_v : std_logic_vector(15 downto 0) := (others => '0');

    
    ----------------------------------------------------------------------------------
    --------------------------------- I2C test signals -------------------------------
    ----------------------------------------------------------------------------------
    
    signal rx_event_i2c : std_logic := '0';  

    
begin
    
       --####################################################################--
      --######################################################################--
     --##############################             #############################--
    --##############################  CONNECTIONS  #############################--
     --##############################             #############################--
      --######################################################################--
       --####################################################################--
    
    ----------------------------------------------------------------------------------
    ---------------------------------- DISPLAY conn ----------------------------------
    ----------------------------------------------------------------------------------
    DISPLAY_conn: DISPLAY PORT MAP (
	       clk => clk,
	       rst => rst,
	       D => out_v(15 downto 12),
	       C => out_v(11 downto 8),
	       B => out_v(7 downto 4),
	       A => out_v(3 downto 0),
	       disp_sel => disp_sel,
	       disp_out => disp_out
	);
    
    
    ----------------------------------------------------------------------------------
    ------------------------------- I2C (pmodToF) conn -------------------------------
    ----------------------------------------------------------------------------------
    pmodToF_i2c_conn:
    pmodToF_i2c port map (
        CLK => CLK,
        sda => sda,
        scl => scl,
        data => counter,
        IRQ  => IRQ,
        SS   => SS,
        rx_event   => rx_event_i2c
    );

	
	decimal_v <= std_logic_vector( to_unsigned( (conv_integer(counter) * 33310) / 65536, 16));
	natur(3 downto 0) <= std_logic_vector( to_unsigned(conv_integer(decimal_v) mod 10, 4) );
	natur(7 downto 4) <= std_logic_vector( to_unsigned((conv_integer(decimal_v) / 10) mod 10, 4) );
	natur(11 downto 8) <= std_logic_vector( to_unsigned((conv_integer(decimal_v) / 100) mod 10, 4) );
	natur(15 downto 12) <= std_logic_vector( to_unsigned((conv_integer(decimal_v) / 1000) mod 10, 4) );
 
	out_v <= natur;
    
end Structural;