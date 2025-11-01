library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_a is
    port (
        q_0, q_1, q_2, q_3 : in  std_logic_vector(7 downto 0);  -- saídas do regfile
        sel                 : in  std_logic_vector(7 downto 0);  -- op1 do IR
        reg_a_out           : out std_logic_vector(7 downto 0)   -- saída para ALU
    );
end entity;

architecture behavioral of mux_a is
begin
    -- Comportamento combinacional
    process(q_0, q_1, q_2, q_3, sel)
    begin
        case sel is
            when "00000000" => reg_a_out <= q_0;
            when "00000001" => reg_a_out <= q_1;
            when "00000010" => reg_a_out <= q_2;
            when "00000011" => reg_a_out <= q_3;
            when others => reg_a_out <= (others => '0');
        end case;
    end process;
end architecture;
