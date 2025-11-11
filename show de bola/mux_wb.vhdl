library ieee;
use ieee.std_logic_1164.all;

entity mux_WB is
    port (
        reg_write_src_sel : in  std_logic; -- 0=ALU, 1=Shifter
        alu_result_in     : in  std_logic_vector(7 downto 0); -- ALU
        shifter_result_in : in  std_logic_vector(7 downto 0); -- Shifter
        rf_write_data_out : out std_logic_vector(7 downto 0)
    );
end entity mux_WB;

architecture behavioral of mux_WB is
begin

    process (reg_write_src_sel, alu_result_in, shifter_result_in)
    begin
        if reg_write_src_sel = '1' then
            rf_write_data_out <= shifter_result_in;
        else
            rf_write_data_out <= alu_result_in;    
        end if;
    end process;
    
end architecture;