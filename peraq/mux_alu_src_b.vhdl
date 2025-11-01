library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mux_alu_src_b is
    Port (
        -- Entradas de dados
        data_reg_in  : in STD_LOGIC_VECTOR(7 downto 0);  -- Valor do registrador
        data_op2_in  : in STD_LOGIC_VECTOR(7 downto 0);  -- Valor imediato (op2)
        
        -- Sinal de controle da UC
        alu_src_b_sel : in STD_LOGIC;  -- 0=registrador, 1=immediate
        
        -- Saída
        data_out     : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity mux_alu_src_b;

architecture Behavioral of mux_alu_src_b is
begin
    process(alu_src_b_sel, data_reg_in, data_op2_in)
    begin
        case alu_src_b_sel is
            when '0' =>    -- Seleciona registrador
                data_out <= data_reg_in;
            when '1' =>    -- Seleciona valor imediato (op2)
                data_out <= data_op2_in;
            when others => -- Para simulation safety
                data_out <= (others => '0');
        end case;
    end process;
end architecture Behavioral;