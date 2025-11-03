library ieee;
use ieee.std_logic_1164.all;

-- MUX de Writeback (ALU vs. Shifter)
entity mux_WB is
    port (
        reg_write_src_sel : in  std_logic; -- 0=ALU, 1=Shifter (da CU)
        alu_result_in     : in  std_logic_vector(7 downto 0); -- da ULA
        shifter_result_in : in  std_logic_vector(7 downto 0); -- do BitShifter
        rf_write_data_out : out std_logic_vector(7 downto 0)  -- para regfile.data
    );
end entity mux_WB;

architecture behavioral of mux_WB is
begin

    -- Processo comportamental com lista de sensibilidade completa
    process (reg_write_src_sel, alu_result_in, shifter_result_in)
    begin
        if reg_write_src_sel = '1' then
            rf_write_data_out <= shifter_result_in; -- '1' = Shifter
        else
            rf_write_data_out <= alu_result_in;     -- '0' = ALU
        end if;
    end process;
    
end architecture;