LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;         
USE IEEE.STD_LOGIC_TEXTIO.ALL; 

-- Este é um testbench APENAS para a Instruction_Memory
ENTITY tb_memory IS
END tb_memory;

ARCHITECTURE test OF tb_memory IS

    -- 1. Declaração do Componente que vamos testar
    COMPONENT Instruction_Memory IS
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    -- 2. Sinais de Teste
    CONSTANT C_CLK_PERIOD : TIME    := 10 ns;
    SIGNAL s_clk          : STD_LOGIC := '0';
    SIGNAL s_address      : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_data_out     : STD_LOGIC_VECTOR(23 DOWNTO 0); -- O fio que vamos "espiar"

BEGIN

    -- 3. Instanciação do Componente (UUT = Unit Under Test)
    UUT : COMPONENT Instruction_Memory
        PORT MAP (
            Address  => s_address,
            Data_Out => s_data_out
        );

    -- 4. Geração de Clock (necessário para sequenciar os endereços)
    clk_process : PROCESS
    BEGIN
        s_clk <= '0';
        WAIT FOR C_CLK_PERIOD / 2;
        s_clk <= '1';
        WAIT FOR C_CLK_PERIOD / 2;
    END PROCESS;
    
    -- 5. Processo de Estímulo (Simula o PC contando)
    stim_process : PROCESS
    BEGIN
        REPORT "Iniciando teste da Instruction_Memory...";
        
        -- Espera o primeiro ciclo de clock
        WAIT UNTIL rising_edge(s_clk);
        
        -- Loop para ler os 10 primeiros endereços de memória
        FOR i IN 0 TO 9 LOOP
            
            -- Envia o endereço para a memória
            s_address <= to_unsigned(i, 8);
            
            -- Espera um ciclo de clock completo antes de pedir o próximo endereço
            WAIT UNTIL rising_edge(s_clk);
        END LOOP;
        
        REPORT "Teste concluído. Verifique as 10 primeiras instruções no GTKWave.";
        
        -- Para a simulação
        WAIT; 
    END PROCESS;

END test;