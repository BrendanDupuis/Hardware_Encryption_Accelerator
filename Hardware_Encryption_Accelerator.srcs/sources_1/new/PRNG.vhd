
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.AES_Library.all;

entity PRNG is
    port (
        clk       : in std_logic;
        start  : in std_logic;
        nonce_out : out nonce_t;
        valid_out : out std_logic
    );
end PRNG;

architecture Behavioral of PRNG is

    --Define the three ring oscillators, a 3, 5, and 7 stage ring oscillator. 
    --In this module we are going to sample each of these ring oscillators at random times to
    --compile our pseudo random seed
    signal ring3 : std_logic_vector(2 downto 0);
    signal ring5 : std_logic_vector(4 downto 0);
    signal ring7 : std_logic_vector(6 downto 0);

    --sampling signals
    signal sample3 : std_logic_vector(1 downto 0) := (others => '0');
    signal sample5 : std_logic_vector(1 downto 0) := (others => '0');
    signal sample7 : std_logic_vector(1 downto 0) := (others => '0');

    --output + counter
    signal nonce : nonce_t := (others => '0');
    signal bit_count   : integer range 0 to 96 := 0;

    signal collecting : std_logic := '0';
    signal valid  : std_logic := '0';

    --Apparently vhdl synthesizer will see the ring oscillators as pointless and remove them 
    --from synthesized design, so need these directives to ensure they are contained in our
    --synthesized design
    attribute KEEP : string;
    attribute DONT_TOUCH : string;

    attribute KEEP of ring3 : signal is "TRUE";
    attribute KEEP of ring5 : signal is "TRUE";
    attribute KEEP of ring7 : signal is "TRUE";

    attribute DONT_TOUCH of ring3 : signal is "TRUE";
    attribute DONT_TOUCH of ring5 : signal is "TRUE";
    attribute DONT_TOUCH of ring7 : signal is "TRUE";

begin
    --implement all of our ring oscilators (simply tie together 3, 5, and 7 not gates respectively)
    --3 stage ring oscillator implementation 
    ring3(0) <= not ring3(2);
    ring3(1) <= not ring3(0);
    ring3(2) <= not ring3(1);

    --5 stage ring oscillator implementation
    ring5(0) <= not ring5(4);
    ring5(1) <= not ring5(0);
    ring5(2) <= not ring5(1);
    ring5(3) <= not ring5(2);
    ring5(4) <= not ring5(3);

    --7 stage ring oscillator implementation
    ring7(0) <= not ring7(6);
    ring7(1) <= not ring7(0);
    ring7(2) <= not ring7(1);
    ring7(3) <= not ring7(2);
    ring7(4) <= not ring7(3);
    ring7(5) <= not ring7(4);
    ring7(6) <= not ring7(5);

    --sample them oscillators 
    process(clk)
    begin
        if rising_edge(clk) then
            --take previous sample left shift and concatenate sample from 3, 5, & 7 oscillators respectively
            sample3 <= sample3(0) & ring3(2);
            sample5 <= sample5(0) & ring5(4);
            sample7 <= sample7(0) & ring7(6);
        end if;
    end process;

    --process to sample until we get 96 bit nonce
    process(clk)
    begin
        if rising_edge(clk) then
            --0 until nonce is finished
            valid <= '0';
            if collecting = '0' then
                --begin collecting bits
                if start = '1' then
                    collecting <= '1';
                    bit_count <= 0;
                    nonce <= (others => '0');
                end if;
            else
                --shift in the new sampled bits into lsb
                nonce <= nonce(94 downto 0) & (sample3(1) xor sample5(1) xor sample7(1));
                if bit_count = 95 then
                    --finished collecting
                    collecting <= '0';
                    valid <= '1';
                else
                    bit_count <= bit_count + 1;
                end if;

            end if;

        end if;
    end process;

    nonce_out <= nonce;
    valid_out <= valid;

end Behavioral;
