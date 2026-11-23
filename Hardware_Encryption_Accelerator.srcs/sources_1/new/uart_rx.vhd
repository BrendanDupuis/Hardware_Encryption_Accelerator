----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2026 05:08:52 PM
-- Design Name: 
-- Module Name: uart_rx - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_rx is
    port (
        clk : in std_logic;
        din : in  std_logic;
        dout : out std_logic_vector(7 downto 0);
        dvalid : out std_logic := '0'
        );
end uart_rx;

architecture Behavioral of uart_rx is
    type uart_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT, DONE);
    signal state : uart_state := IDLE;
    signal dff1 : std_logic := '1';           -- see pg 7 on the notes, this is the DFF synchronization stuff 
    signal dff2 : std_logic := '1';
    signal tick_count : unsigned(6 downto 0) := (others => '0');
    signal tick : std_logic := '0';
    signal baud : unsigned(4 downto 0) := (others => '0');
    signal bit_index : unsigned(3 downto 0) := (others => '0');
begin

    tick_calc : process(clk)
    begin
        if rising_edge(clk) then
            dff2 <= dff1;
            dff1 <= din;
            
            if tick_count = 67 then --125MHz/(16*115200) - 1 = ~67, lmao
                tick_count <= (others => '0');
                tick <= '1';
            else
                tick_count <= tick_count + 1;
                tick <= '0';
            end if;
        end if;
    end process tick_calc;
    
    
    FSM : process(clk)
    begin
        if rising_edge(clk) then
            dvalid <= '0';
            if tick = '1' then
                case state is
                    when IDLE =>
                        if dff2 = '0' then
                            baud <= (others => '0');
                            state <= START_BIT;
                        end if;
                        
                    when START_BIT =>
                        if baud = 7 then
                            baud <= (others => '0');
                            if dff2 = '0' then
                                bit_index <= (others => '0');
                                state <= DATA_BITS;
                            else
                                state <= IDLE;
                            end if;
                        else
                            baud <= baud + 1;
                        end if;
                        
                    when DATA_BITS =>
                        if baud = 15 then
                            baud <= (others => '0');
                            dout(to_integer(bit_index)) <= dff2;
                            if bit_index = 7 then state <= STOP_BIT; else bit_index <= bit_index + 1;
                            end if;
                        else
                            baud <= baud + 1;
                        end if;
                        
                    when STOP_BIT =>
                        if baud = 15 then
                            baud <= (others => '0');
                            state <= DONE;
                        else
                            baud <= baud + 1;
                        end if;
                        
                    when DONE =>
                        --see below
                end case;
            elsif state = DONE then --has to sit outside because not triggered by tick
                dvalid <= '1';
                state <= IDLE;
            end if;
        end if;
    end process FSM;
    
end Behavioral;
