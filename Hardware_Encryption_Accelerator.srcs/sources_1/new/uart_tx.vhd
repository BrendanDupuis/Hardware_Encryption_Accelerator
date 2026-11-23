----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2026 03:49:51 PM
-- Design Name: 
-- Module Name: uart_tx - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_tx is
 port(
    clk : in std_logic;
    din : in std_logic_vector(7 downto 0);
    dvalid : in std_logic;
    busy : out std_logic;
    dout : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is
    type uart_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : uart_state := IDLE;
    signal clk_count : unsigned(10 downto 0) := (others => '0'); 
    signal bit_index : integer range 0 to 7 := 0;
    

begin

    busy <= '0' when state = IDLE else '1'; --to mnake sure that the next byte aint given before the one being cycled through is done
    
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
            
                when IDLE =>
                    dout <= '1';
                    clk_count <= (others => '0');
                    bit_index <= 0;
                    if dvalid = '1' then state <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    dout <= '0';
                    if clk_count = 1084 then --125MHz/115200bps - 1 = 1084
                        clk_count <= (others => '0');
                        state     <= DATA_BITS;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when DATA_BITS =>
                    dout <= din(bit_index);  -- bit 0 (LSB) first
                    if clk_count = 1084 then
                        clk_count <= (others => '0');
                        if bit_index = 7 then
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when STOP_BIT =>
                    dout <= '1';
                    if clk_count = 1084 then
                        clk_count <= (others => '0');
                        state <= IDLE;
                    else
                        clk_count <= clk_count + 1;
                    end if; 
                    
            end case;
        end if;
    end process;
    
end Behavioral;
