LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Este testbench testa a CPU (Fase 1) como uma "Caixa Preta"
ENTITY tb_cpu_top IS
END tb_cpu_top;

ARCHITECTURE Behavioral OF tb_cpu_top IS

    -- === 1. Componente ===
    -- Esta é a sua CPU inteira (Fase 1)
    COMPONENT cpu_top IS
        PORT (
            clk      : IN  STD_LOGIC;
            reset    : IN  STD_LOGIC;
            halt_out : OUT STD_LOGIC
        );
    END COMPONENT;

    -- === 2. Sinais ===
    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_reset : STD_LOGIC := '0';
    
    -- Este é o único sinal que monitoramos
    SIGNAL s_halt_out : STD_LOGIC;
    
    CONSTANT CLK_PERIOD : TIME := 10 ns;

BEGIN

    -- === 3. Instanciação ===
    -- Instancia a CPU "caixa preta"
    UUT_CPU : cpu_top
        PORT MAP (
            clk      => tb_clk,
            reset    => tb_reset,
            halt_out => s_halt_out
        );

    -- === 4. Gerador de Clock ===
    Clock_Process : PROCESS
    BEGIN
        -- Este clock vai parar SOZINHO quando o halt for detectado
        IF s_halt_out = '1' THEN
            WAIT;
        END IF;
    
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
        
    END PROCESS Clock_Process;

    -- === 5. Processo de Estímulo ===
    Stimulus_Process : PROCESS
    BEGIN
        REPORT "--- Testbench (cpu_top) iniciado ---";
        
        -- Aplica o reset assíncrono (que funciona para todos os seus módulos)
        tb_reset <= '1';
        REPORT "INFO: Reset ATIVADO.";
        WAIT FOR 12 ns; -- Tempo suficiente
        tb_reset <= '0';
        REPORT "INFO: Reset DESATIVADO. CPU está rodando o programa...";
        
        -- Agora nós não fazemos mais nada.
        -- Apenas esperamos o sinal 'halt_out' da CPU.
        
        WAIT UNTIL s_halt_out = '1';
        
        WAIT FOR 1 ns; -- Apenas para o log final ficar bonito
        
        REPORT "--- SUCESSO! HALT Detectado! Fim da Simulação ---";
        
        WAIT; -- Para este processo
        
    END PROCESS Stimulus_Process;

END Behavioral;