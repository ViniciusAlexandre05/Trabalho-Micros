library ieee;
use ieee.std_logic_1164.all;

entity mux_b_final is
    port (
        reg_in  : in  std_logic_vector(7 downto 0); -- Registrador
        imm_in  : in  std_logic_vector(7 downto 0); -- Imediato
        sel     : in  std_logic;                    -- Seleciona
        operand_b_out : out std_logic_vector(7 downto 0) -- Saída
    );
end entity;

architecture behavioral of mux_b_final is
begin

    process (sel, reg_in, imm_in)
    begin
        if sel = '1' then
            operand_b_out <= imm_in;
        else
            operand_b_out <= reg_in;
        end if;
    end process;

end architecture;