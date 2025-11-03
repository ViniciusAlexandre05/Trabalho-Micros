library ieee;
use ieee.std_logic_1164.all;

-- MUX para o Operando A (Seleciona entre os 4 registradores)
entity mux_a is
    port (
        q_0, q_1, q_2, q_3 : in  std_logic_vector(7 downto 0); -- saídas do regfile
        sel               : in  std_logic_vector(1 downto 0); -- op1(1 downto 0) do IR
        reg_a_out         : out std_logic_vector(7 downto 0)  -- saída para ALU/Shifter
    );
end entity;

architecture behavioral of mux_a is
begin

    -- CORREÇÃO: Convertido para um processo comportamental
    -- 1. A lista de sensibilidade DEVE incluir TODAS as entradas (sel, q_0, ... q_3).
    -- 2. Deve haver uma atribuição padrão (como 'when others') para evitar latches.
    process (sel, q_0, q_1, q_2, q_3)
    begin
        case sel is
            when "00" =>
                reg_a_out <= q_0;
            when "01" =>
                reg_a_out <= q_1;
            when "10" =>
                reg_a_out <= q_2;
            when "11" =>
                reg_a_out <= q_3;
            when others =>
                reg_a_out <= (others => '0'); -- Padrão de segurança
        end case;
    end process;

end architecture;