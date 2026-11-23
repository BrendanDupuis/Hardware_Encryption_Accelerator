
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.AES_Library.all;

entity PRNG is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        enable     : in  std_logic;
        seed_in    : in  block_t;

        random_out : out block_t;
        valid      : out std_logic
    );
end PRNG;


architecture Behavioral of PRNG is

begin


end Behavioral;
