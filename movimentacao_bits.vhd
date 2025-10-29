library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity movimentacao_bits is
    Port (    -- sinais de controle
              clk : in STD_LOGIC;
              reset : in STD_LOGIC;
              -- barramento de dados de 8 bits
              entrada : in STD_LOGIC_VECTOR (7 downto 0);
              saida : out STD_LOGIC_VECTOR (7 downto 0);

                -- SINAIS DE CONTROLE DO DECODER
            decoder_mov     : in STD_LOGIC;  -- Ativa movimentação
            decoder_shift_l : in STD_LOGIC;  -- Ativa shift left  
            decoder_shift_r : in STD_LOGIC;  -- Ativa shift right
            decoder_set_bit : in STD_LOGIC;  -- Ativa set bit
            decoder_bit_pos : in STD_LOGIC_VECTOR(2 downto 0); -- Qual bit manipular
        )

           
end entity;

architecture Behavioral of movimentacao_bits is

   signal reg_out : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
begin

    process(clk, reset)
        variable temp : STD_LOGIC_VECTOR(7 downto 0);
    begin
        if rising_edge(clk) then
        
            if reset = '1' then
                reg_out <= (others => '0');

            else
                temp := entrada;  -- valor base de referência

                -- Prioridade das operações:
                if decoder_set_bit = '1' then
                    -- seta o bit escolhido para '1'
                    temp(to_integer(unsigned(decoder_bit_pos))) := '1';

                elsif decoder_shift_l = '1' then
                    temp := entrada(6 downto 0) & '0';

                elsif decoder_shift_r = '1' then
                    temp := '0' & entrada(7 downto 1);

                elsif decoder_mov = '1' then
                    temp := entrada;

                end if;

                reg_out <= temp;
            end if;

        end if;
    end process;

    -- saída
    saida <= reg_out;

end Behavioral;
