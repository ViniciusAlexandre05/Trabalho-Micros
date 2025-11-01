library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity regfile is
    port (
        clk  : in std_logic;  
        rst  : in std_logic;  
        we   : in std_logic;  
        addr : in unsigned(1 downto 0);  
        data_in : in std_logic_vector(7 downto 0);  
        data_out: out std_logic_vector(7 downto 0)
    );
end regfile;

architecture reg of regfile is
    type reg_array is array(0 to 3) of std_logic_vector(7 downto 0);
    signal regs : reg_array := (others => (others => '0'));
begin
    -- Leitura assíncrona
    data_out <= regs(to_integer(addr));

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));
            elsif we = '1' then
                regs(to_integer(addr)) <= data_in;
            end if;
        end if;
    end process;
end architecture;
