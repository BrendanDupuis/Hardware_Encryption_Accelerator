
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.AES_Library.all;

entity AES_CTR is
    port (
        clk         : in std_logic;
        start       : in std_logic;
        message_in  : in message_t;
        length      : in integer range 0 to 255;
        nonce       : in nonce_t;

        message_out : out message_t;
        done        : out std_logic
    );
end AES_CTR;

architecture Behavioral of AES_CTR is

    -- TODO: Define the states needed to control encryption.
    type state_t is (idle, processing, finished);
    signal state : state_t := idle;
    
    --save the inputs from idle phase
    signal saved_message : message_t;
    signal message_len : integer range 0 to 255;
    signal saved_nonce : nonce_t;
    
    --keep track of blocks during processing phase
    signal total_blocks : integer range 0 to 16 := 0;
    signal blocks_sent : integer range 0 to 16 := 0;
    signal blocks_received : integer range 0 to 16 := 0;
    
    --used to connect aes-ctr to keystream gen
    signal keystream : block_t;     --output keystream
    signal counter_block : block_t; --input nonce & ctr to ctr
    signal valid_in : std_logic := '0';   --block sent
    signal valid_out : std_logic; --block received
    
    --final result (ciphertext or plaintext
    signal fin : std_logic := '0';
    signal result : message_t := (others => (others => '0'));

begin
    AES_Keygen : entity work.AES_Keystream
        port map (
            clk           => clk,
            valid_in      => valid_in,
            counter_in    => counter_block,
            keystream_out => keystream,
            valid_out     => valid_out
        );
        
    process(clk)
        variable byte_index : integer;
    begin
        if rising_edge(clk) then
            --finite state machine passing input message through idle --> processing --> finished
            valid_in <= '0';
            fin <= '0';
            case state is
                when idle =>
                    --wait on input (when start = 1). Save inputs and calculate # of blocks needed
                    if start = '1' then
                        saved_message <= message_in;
                        message_len <= length;
                        saved_nonce <= nonce;
                        total_blocks <= (length + 15)/16; --take the ceiling of the length/16 (normal vhdl rounds down so add 15 to essentially round up)
                        
                        --reset these incase not initial message
                        blocks_sent <= 0;
                        blocks_received <= 0;
                        result <= (others => (others => '0'));
                        
                        --send to next state
                        if length = 0 then
                            state <= finished;
                        else
                            state <= processing;
                        end if;
                    end if;
                when processing =>
                    --generate keystream for nonce & ctr for # of blocks we need for our input message
                    --send in blocks once every clock cycle until we send all blocks needed
                    --once all send, wait until blocks_send == blocks received
                    --if valid_out == '1', then there is a block recieved & we can 
                    --xor message_in(proper bits) w/ keystream block
                    if blocks_sent < total_blocks then
                        --send another block
                        counter_block <= (nonce & std_logic_vector(to_unsigned(blocks_sent,32)));
                        valid_in <= '1';
                        blocks_sent <= blocks_sent+1;
                    end if;
                    if valid_out = '1' then
                        --we have a keystream block, so we can xor with input message byte
                        --Because message_t is an array of bytes, must loop through 0 to 15 
                        --to do each byte (loop can unravel and xor since independent)
                        for i in 0 to 15 loop
                            byte_index := blocks_received * 16 + i;
                            --When input should have a lot of leading 0's so we can ignore past here, dont need in final result
                            if byte_index < message_len then
                                result(byte_index) <= saved_message(byte_index) xor keystream(127-8*i downto 120-8*i);
                            end if;
                        end loop;
                        blocks_received <= blocks_received + 1;
                        if blocks_received+1 = total_blocks then
                            state <= finished;
                        end if;
                    end if;
                when finished =>
                    --send out signals
                    --send out full constructed messaqe and done signal
                    fin <= '1';
                    state <= idle;
            end case;
       end if;
    end process;
    
--send out message (only valid when done = '1')
done <= fin;
message_out <= result;
end Behavioral;
