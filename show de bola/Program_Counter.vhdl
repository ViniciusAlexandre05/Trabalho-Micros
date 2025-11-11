LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Program_Counter IS
    PORT (
        clk        : IN  STD_LOGIC;
        rst        : IN  STD_LOGIC;
        pc_en      : IN  STD_LOGIC;
        pc_load_en : IN  STD_LOGIC; --não usado
        data_in    : IN  UNSIGNED(7 DOWNTO 0); -- não usado
        pc_out     : OUT UNSIGNED(7 DOWNTO 0)
    );
END Program_Counter;

ARCHITECTURE rtl OF Program_Counter IS
    SIGNAL s_pc : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    
    process(clk)
    begin
        if falling_edge(clk) then 
            if rst = '1' then
                s_pc <= (OTHERS => '0');
            elsif pc_load_en = '1' then
                s_pc <= data_in;
            elsif pc_en = '1' then
                s_pc <= s_pc + 1;
            end if;
        end if;
    end process;

    pc_out <= s_pc;

END rtl;