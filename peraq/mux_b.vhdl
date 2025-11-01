library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_b is
    port (
        q_0, q_1, q_2, q_3 : in  std_logic_vector(7 downto 0);  -- saídas do regfile
        sel                 : in  std_logic_vector(7 downto 0);  -- op1 do IR
        reg_b_out           : out std_logic_vector(7 downto 0)   -- saída para ALU
    );
end entity;

architecture behavioral of mux_b is
begin
    -- Comportamento combinacional
    process(q_0, q_1, q_2, q_3, sel)
    begin
        case sel is
            when "0000000" => reg_b_out <= q_0;
            when "0000001" => reg_b_out <= q_1;
            when "0000010" => reg_b_out <= q_2;
            when "0000011" => reg_b_out <= q_3;
            when others => reg_b_out <= (others => '0');
        end case;
    end process;
end architecture;
