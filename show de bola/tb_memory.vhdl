LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;         
USE IEEE.STD_LOGIC_TEXTIO.ALL; 

ENTITY tb_memory IS
END tb_memory;

ARCHITECTURE test OF tb_memory IS
    COMPONENT Instruction_Memory IS
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    CONSTANT C_CLK_PERIOD : TIME    := 10 ns;
    SIGNAL s_clk          : STD_LOGIC := '0';
    SIGNAL s_address      : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_data_out     : STD_LOGIC_VECTOR(23 DOWNTO 0); 

BEGIN
    UUT : COMPONENT Instruction_Memory
        PORT MAP (
            Address  => s_address,
            Data_Out => s_data_out
        );

    clk_process : PROCESS
    BEGIN
        s_clk <= '0';
        WAIT FOR C_CLK_PERIOD / 2;
        s_clk <= '1';
        WAIT FOR C_CLK_PERIOD / 2;
    END PROCESS;
    
    stim_process : PROCESS
    BEGIN
        REPORT "Iniciando teste da Instruction_Memory...";

        WAIT UNTIL rising_edge(s_clk);
        FOR i IN 0 TO 9 LOOP
            s_address <= to_unsigned(i, 8);
            WAIT UNTIL rising_edge(s_clk);
        END LOOP;
        
        REPORT "Teste concluído.";
        WAIT; 
    END PROCESS;

END test;