library ieee;
use ieee.std_logic_1164.all;

-- MUX 4-para-1 para selecionar o registrador do Operando B
entity mux_b_reg is
    port (
        q_0, q_1, q_2, q_3 : in  std_logic_vector(7 downto 0); -- Saídas do regfile
        sel               : in  std_logic_vector(1 downto 0); -- Conecta ao IR.op2_out(1 downto 0)
        reg_b_data_out    : out std_logic_vector(7 downto 0)  -- Saída (vai para o mux_b_final)
    );
end entity;

architecture behavioral of mux_b_reg is
begin

    -- Processo comportamental com lista de sensibilidade completa
    process (sel, q_0, q_1, q_2, q_3)
    begin
        case sel is
            when "00" =>
                reg_b_data_out <= q_0;
            when "01" =>
                reg_b_data_out <= q_1;
            when "10" =>
                reg_b_data_out <= q_2;
            when "11" =>
                reg_b_data_out <= q_3;
            when others =>
                reg_b_data_out <= (others => '0'); -- Padrão de segurança
        end case;
    end process;

end architecture;