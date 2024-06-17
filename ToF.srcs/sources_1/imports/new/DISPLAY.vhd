----------------------------------------------------------------------------------
-- Author; "IvanLum"
-- 
-- Create Date: 03/12/2024 11:48:10 AM
-- Design Name: 
-- Module Name: DISPLAY - RTL
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
use IEEE.std_logic_unsigned.all;

entity DISPLAY is
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
end DISPLAY;

architecture RTL of DISPLAY is
    signal bcd: STD_LOGIC_VECTOR (3 downto 0);
    signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
    signal disp_select: std_logic_vector(1 downto 0);
begin
    disp_select <= refresh_counter(19 downto 18); -- freq: (clk / 2^19) hz 

    deco: process(bcd)
    begin
        case bcd is
        when "0000" => disp_out <= "0000001"; -- "0"     
        when "0001" => disp_out <= "1001111"; -- "1" 
        when "0010" => disp_out <= "0010010"; -- "2" 
        when "0011" => disp_out <= "0000110"; -- "3" 
        when "0100" => disp_out <= "1001100"; -- "4" 
        when "0101" => disp_out <= "0100100"; -- "5" 
        when "0110" => disp_out <= "0100000"; -- "6" 
        when "0111" => disp_out <= "0001111"; -- "7" 
        when "1000" => disp_out <= "0000000"; -- "8"     
        when "1001" => disp_out <= "0000100"; -- "9" 
        when "1010" => disp_out <= "0000010"; -- a
        when "1011" => disp_out <= "1100000"; -- b
        when "1100" => disp_out <= "0110001"; -- C
        when "1101" => disp_out <= "1000010"; -- d
        when "1110" => disp_out <= "0110000"; -- E
        when "1111" => disp_out <= "0111000"; -- F
        end case;
    end process;
    
    process(clk,rst)
    begin 
        if(rst='1') then
            refresh_counter <= (others => '0');
        elsif(rising_edge(clk)) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
     
    process(disp_select, D, C, B, A)
    begin
        case disp_select is
        when "11" =>
            disp_sel <= "0111"; 
            bcd <= D;
        when "10" =>
            disp_sel <= "1011"; 
            bcd <= C;
        when "01" =>
            disp_sel <= "1101"; 
            bcd <= B;
        when "00" =>
            disp_sel <= "1110"; 
            bcd <= A;
        end case;
    end process;

end RTL;