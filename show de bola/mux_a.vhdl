library ieee;
use ieee.std_logic_1164.all;

entity mux_a is
    port (
        q_0, q_1, q_2, q_3 : in  std_logic_vector(7 downto 0); -- saídas do regfile
        sel               : in  std_logic_vector(1 downto 0); -- op1 IR
        reg_a_out         : out std_logic_vector(7 downto 0)  -- saída
    );
end entity;

architecture behavioral of mux_a is
begin

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
                reg_a_out <= (others => '0');
        end case;
    end process;

end architecture;