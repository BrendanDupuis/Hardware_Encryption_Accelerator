--this is gonna be used to combine everything p much
--I should have called it main.vhd or smthn, I dont feel like renaming it

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_bridge is
    port(
        sys_clk : in std_logic;
        uart_rxd : in std_logic; --keyboard to zybo
        uart_txd : out std_logic --zybo to putty
    );
end uart_bridge;

architecture Behavioral of uart_bridge is
    signal rx_data : std_logic_vector(7 downto 0);
    signal rx_valid : std_logic;
    signal tx_data : std_logic_vector(7 downto 0);
    signal tx_valid : std_logic;
    signal tx_busy : std_logic;
    signal keygen_in : std_logic_vector(127 downto 0);
    signal keygen_trigger : std_logic;
    signal keygen_finished : std_logic := '0';
    signal keygen_out : std_logic_vector(127 downto 0) := (others => '0');
begin

    rx : entity work.uart_rx
        port map (clk => sys_clk, din => uart_rxd, dout => rx_data, dvalid => rx_valid);
        
    flow : entity work.control_flow
        port map (clk => sys_clk, rx_data => rx_data, rx_valid => rx_valid, tx_data => tx_data, tx_valid => tx_valid, tx_busy => tx_busy, keygen_in => keygen_in, keygen_trigger => keygen_trigger, keygen_finished => keygen_finished, keygen_out => keygen_out);
    
    tx : entity work.uart_tx
        port map (clk => sys_clk, din => tx_data, dvalid => tx_valid, busy => tx_busy, dout => uart_txd); --open just means we aint using it here
end Behavioral;
