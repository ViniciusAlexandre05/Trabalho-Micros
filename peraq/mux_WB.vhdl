library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Necessário para usar UNSIGNED na saída

entity mux_WB is
    port (
        -- Entrada de Controle
        reg_write_src_sel : in  std_logic_vector(1 downto 0); -- Seleciona a fonte (00=ALU, 01=Shifter)
        reg_write_addr_in : in  std_logic_vector(1 downto 0); -- Seleciona endereço
        
        -- Entradas de Dados (Saídas da ALU e do Shifter)
        alu_result_in     : in  std_logic_vector(7 downto 0);
        shifter_result_in : in  std_logic_vector(7 downto 0);
        
        -- Saídas para o Register File (RF)
        rf_write_addr_out : out unsigned(1 downto 0);          -- Endereço para o RF (UNSIGNED)
        rf_write_data_out : out std_logic_vector(7 downto 0)   -- Dados para o RF
    );
end entity mux_WB;

architecture behavior of mux_WB is
begin

    process (reg_write_src_sel, alu_result_in, shifter_result_in, reg_write_addr_in)
    begin
        -- 1. Definição dos Dados de Saída (rf_write_data_out)
        case reg_write_src_sel is
            when "00" =>
                rf_write_data_out <= alu_result_in;     -- Saída da ALU
            
            when "01" =>
                rf_write_data_out <= shifter_result_in; -- Saída do Shifter
            
            when others =>
                -- Comportamento padrão para valor inválido
                rf_write_data_out <= (others => '0');
                REPORT "MUX_WB: reg_write_src_sel inválido (" & to_string(reg_write_src_sel) & ")" 
                    SEVERITY ERROR;
        end case;

        -- 2. Definição do Endereço de Saída
        rf_write_addr_out <= unsigned(reg_write_addr_in);
        
    end process;

end architecture behavior;