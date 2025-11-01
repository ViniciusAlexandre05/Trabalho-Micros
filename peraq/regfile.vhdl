library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity regfile is
    port (
        clk  : in std_logic; -- entrada de clock
        rst  : in std_logic; -- reset síncrono
        we   : in std_logic; -- write enable
        addr : in unsigned(1 downto 0); -- seletor (2 bits = 4 registradores)
        data : in std_logic_vector(7 downto 0); -- entrada de dados
        q_0  : out std_logic_vector(7 downto 0);
        q_1  : out std_logic_vector(7 downto 0);
        q_2  : out std_logic_vector(7 downto 0);
        q_3  : out std_logic_vector(7 downto 0)
    );
end regfile;

architecture reg of regfile is
    type reg_array is array(0 to 3) of std_logic_vector(7 downto 0);
    signal regs : reg_array := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0')); -- zera todos os registradores 
            elsif we = '1' then
                regs(to_integer(addr)) <= data; -- grava o valor no registrador selecionado
            end if;
        end if;
    end process;

    -- conectando as saídas
    q_0 <= regs(0);
    q_1 <= regs(1);
    q_2 <= regs(2);
    q_3 <= regs(3);
end reg;
