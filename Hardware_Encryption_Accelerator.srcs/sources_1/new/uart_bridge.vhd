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
    signal data : std_logic_vector(7 downto 0);
    signal valid : std_logic;

begin

    rx : entity work.uart_rx
        port map (clk => sys_clk, din => uart_rxd, dout => data, dvalid => valid);
    
    tx : entity work.uart_tx
        port map (clk => sys_clk, din => data, dvalid => valid, busy => open, dout => uart_txd); --open just means we aint using it here
end Behavioral;
