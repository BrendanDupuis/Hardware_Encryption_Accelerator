
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.AES_Library.all;
use work.AES_Functions.all;

entity AES_Keystream is
    port (
        clk           : in  std_logic;
        valid_in      : in  std_logic;
        counter_in    : in  block_t; -- 96-bit nonce + 32-bit counter
        keystream_out : out block_t;
        valid_out     : out std_logic
    );
end AES_Keystream;

architecture Behavioral of AES_Keystream is

    --Generate round keys (constant aes_key so constant round keys across keystreams)
    constant roundKeys : round_keys_t := GenerateRoundKeys(AES_KEY);

    --10 aes rounds
    signal r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10 : block_t;

    --This valid signal is used to track valid output keystream blocks. So AES-ctr is going to be
    --passing in blocks one at a time (nonce+1, nonce+2, nonce+3,....nonce+i), and this keystream
    --function runs through 10 stages so the full keystream wont be ready for a few cycles. 
    --To help this, we have the valid vector, which follows the keystream through rounds, so aes-ctr
    --can know when each block is done and it can continue working rather than waiting on every block
    --to be finished
    signal valid : std_logic_vector(10 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then

            --AES rounds
            r0 <= counter_in xor roundKeys(0);
            r1 <= AESRound(r0, roundKeys(1), false);
            r2 <= AESRound(r1, roundKeys(2), false);
            r3 <= AESRound(r2, roundKeys(3), false);
            r4 <= AESRound(r3, roundKeys(4), false);
            r5 <= AESRound(r4, roundKeys(5), false);
            r6 <= AESRound(r5, roundKeys(6), false);
            r7 <= AESRound(r6, roundKeys(7), false);
            r8 <= AESRound(r7, roundKeys(8), false);
            r9 <= AESRound(r8, roundKeys(9), false);
            r10 <= AESRound(r9, roundKeys(10), true); --true --> skips mixColumns function (aes standard)
            
            --Update valid to track when valid output block is here..
            valid(0) <= valid_in;
            valid(10 downto 1) <= valid(9 downto 0);

        end if;
    end process;

    --Completed keystream generation (if valid(10) = '1')
    keystream_out <= r10;
    --High only when keystream_out contains a valid result --> signal to aes-ctr valid block.
    valid_out <= valid(10);

end Behavioral;
