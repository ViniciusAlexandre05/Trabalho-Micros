library ieee;
use ieee.std_logic_1164.all;

-- MUX 2-para-1 para selecionar Registrador vs. Imediato
entity mux_b_final is
    port (
        reg_in  : in  std_logic_vector(7 downto 0); -- Conecta à saída do mux_b_reg
        imm_in  : in  std_logic_vector(7 downto 0); -- Conecta ao IR.op2_out(7 downto 0)
        sel     : in  std_logic;                    -- Conecta ao CU.alu_src_b_sel
        operand_b_out : out std_logic_vector(7 downto 0) -- Saída final (vai para a ALU)
    );
end entity;

architecture behavioral of mux_b_final is
begin

    -- Processo comportamental com lista de sensibilidade completa
    process (sel, reg_in, imm_in)
    begin
        if sel = '1' then
            operand_b_out <= imm_in; -- '1' = seleciona imediato
        else
            operand_b_out <= reg_in;  -- '0' (ou 'X', 'U') = seleciona registrador
        end if;
    end process;

end architecture;