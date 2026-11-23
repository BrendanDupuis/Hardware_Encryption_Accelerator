library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.AES_Library.all;

package AES_Functions is
    --helper function for aes round (used in keystream generation)
    function AESRound(
        state       : block_t;
        round_key   : block_t;
        final_round : boolean
    ) return block_t;
    
    --Function to create the keys for each encryption round (splits up our AES key 
    function generateRoundKeys(
        aes_key : block_t
    ) return round_keys_t;

end package AES_Functions;


package body AES_Functions is

    -- Private helper functions

    function subBytes(state : block_t)return block_t is
    variable next_state : block_t;
    variable byte_to_int : integer;
    begin
        --each byte will be assigned a random byte using the sbox lut
        for i in 0 to 15 loop
            --get byte from input
            byte_to_int := to_integer(unsigned(state(127 - 8*i downto 120 - 8*i)));
            --Set the bits in output state from the SBOX lut
            next_state(127-8*i downto 120-8*i) := SBOX(byte_to_int);
        end loop;
        return next_state;
    end function;

    function shiftRows(state : block_t) return block_t is
    --input views as 4byte x 4byte matrix
    --row 0 shifted 0 spots [0:31]
    --row 1 shifted 1 spots [32:63]
    --row 2 shifted 2 spots [64:95]
    --row 3 shifted 3 spots [96:127]
    --Shift == left shift with loop around
    variable next_state : block_t;
    begin
    next_state(127 downto 96) := state(127 downto 120) & state(87 downto 80) & state(47 downto 40) & state(7 downto 0);
    next_state(95 downto 64) := state(95 downto 88) & state(55 downto 48) & state(15 downto 8) & state(103 downto 96);
    next_state(63 downto 32) := state(63 downto 56) & state(23 downto 16) & state(111 downto 104) & state(71 downto 64); 
    next_state(31 downto 0) := state(31 downto 24) & state(119 downto 112) & state(79 downto 72) & state(39 downto 32);
    return next_state;
    end function;
    
    function xtime2(b : std_logic_vector(7 downto 0)) return std_logic_vector(7 downto 0) is
    variable result : std_logic_vector(7 downto 0);
    begin
        result := b(6 downto 0) & '0';
        if(b(7) = '1') then
            result := result XOR x"1B";
        end if;
        return result;
    end function;
    
    function xtime3(b : std_logic_vector(7 downto 0)) return std_logic_vector(7 downto 0) is
    begin  
        return xtime2(b) XOR b;
    end function;
    
    function addRoundKey(state, key : block_t) return block_t is
    begin
        return state xor key;
    end function;
    
    
    function MixColumns(state : block_t) return block_t is
    --Input is viewed as a 4x4 grid, denote each column as (s0,s1,s2,s3)
    --after MixColumns, (s0,s1,s2,s3) = (r0,r1,r2,r3) where:
    --r0= xtime2(s0) ^ xtime3(s1) ^ s2 ^ s3
    --r1 = s0 ^ xtime2(s1) ^ xtime3(s2) ^ s3
    --r2 = s0 ^ s1 ^ xtime2(s2) ^ xtime3(s3)
    --r3 = xtime3(s0) ^ s1 ^ s2 ^ xtime2(s3)
    variable next_state : block_t;
    variable s0,s1,s2,s3 : byte_t;
    begin
      for i in 0 to 3 loop
        s0 := state(127-32*i downto 120-32*i);
        s1 := state(119-32*i downto 112-32*i);
        s2 := state(111-32*i downto 104-32*i);
        s3 := state(103-32*i downto 96-32*i);

        -- Calculate the four new bytes for this column
        next_state(127-32*i downto 120-32*i) := xtime2(s0) xor xtime3(s1) xor s2 xor s3;
        next_state(119-32*i downto 112-32*i) := s0 xor xtime2(s1) xor xtime3(s2) xor s3;
        next_state(111-32*i downto 104-32*i) := s0 xor s1 xor xtime2(s2) xor xtime3(s3);
        next_state(103-32*i downto 96-32*i) := xtime3(s0) xor s1 xor s2 xor xtime2(s3);
      end loop;
      return next_state;
    end function;

    function generateRoundKeys(aes_key : block_t) return round_keys_t is
        --initializes round_keys_t for our using
        --round_keys_t[0] = AES_Key
        --round keys 1-10 loop with next keys being determined based off previous key
        variable w0,w1,w2,w3, sub_w3,w0_next,w1_next,w2_next,w3_next,rotated_w3 , temp: std_logic_vector(31 downto 0);
        variable keyState : block_t;
        variable roundKeys : round_keys_t;
    begin
        roundKeys(0) := aes_key;
        for i in 1 to 10 loop
            --Split the previous 128-bit round key into four 32-bit words
            --W0 = RK[round - 1][127:96]   // Bytes 0..3
            --W1 = RK[round - 1][95:64]    // Bytes 4..7
            --W2 = RK[round - 1][63:32]    // Bytes 8..11
            --W3 = RK[round - 1][31:0]     // Bytes 12..15
            w0 := roundKeys(i-1)(127 downto 96);
            w1 := roundKeys(i-1)(95 downto 64);
            w2 := roundKeys(i-1)(63 downto 32);
            w3 := roundKeys(i-1)(31 downto 0);
            --Step 2a: RotWord - Rotate W3 left by 1 byte (8 bits)
            rotated_w3 := w3(23 downto 0) & w3(31 downto 24);
            --Step 2b: SubWord - Pass each of the 4 bytes through the S-Box  in parallel
            --sub_W3[31:24] = SBOX[ rotated_W3[31:24] ]
            --sub_W3[23:16] = SBOX[ rotated_W3[23:16] ]
            --sub_W3[15:8]  = SBOX[ rotated_W3[15:8]  ]
            --sub_W3[7:0]   = SBOX[ rotated_W3[7:0]   ]
            sub_w3 := SBOX(to_integer(unsigned(rotated_w3(31 downto 24)))) 
                & SBOX(to_integer(unsigned(rotated_w3(23 downto 16)))) 
                & SBOX(to_integer(unsigned(rotated_w3(15 downto 8))))
                & SBOX(to_integer(unsigned(rotated_w3(7 downto 0))));
            --Step 2c: Rcon XOR - XOR the top byte with the round constant
            --RCON is a constant AES defined 10 element array
            --temp = sub_W3 XOR concatenate(RCON[round], 0x000000)
            temp := sub_w3 XOR (RCON(i) & x"000000");
            --Step 2d: Cascade XORs to form the 4 words of the new round key
            --W0_next = W0 XOR temp
            --W1_next = W1 XOR W0_next
            --W2_next = W2 XOR W1_next
            --W3_next = W3 XOR W2_next
            w0_next := w0 XOR temp;
            w1_next := w1 xor w0_next;
            w2_next := w2 xor w1_next;
            w3_next := w3 xor w2_next;
            --Step 2e: Recombine the four 32-bit words into the new 128-bit round key
            --RK[round] = concatenate(W0_next, W1_next, W2_next, W3_next)
            roundKeys(i) := w0_next & w1_next & w2_next & w3_next;

        end loop;
        return roundKeys;
    end function;
    
    function AESRound(
        state       : block_t;
        round_key   : block_t;
        final_round : boolean
    ) return block_t is
    variable next_state : block_t;
    begin
        --perform one round with input key
        next_state := subBytes(state);
        next_state := shiftRows(next_state);
        if not final_round then
            next_state := mixColumns(next_state);
        end if;  
        next_state := addRoundKey(next_state, round_key);
        return next_state;
        
    end function;
    
end package body AES_Functions;