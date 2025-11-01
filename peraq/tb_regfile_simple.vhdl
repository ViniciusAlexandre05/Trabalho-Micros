LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Este é um Teste de Unidade SIMPLES apenas para o regfile
ENTITY tb_regfile_simple IS
END tb_regfile_simple;

ARCHITECTURE Behavioral OF tb_regfile_simple IS

    -- Componente RegFile (A VERSÃO CORRIGIDA, COM CLK e falling_edge)
    COMPONENT regfile IS
        PORT (
            clk  : IN  STD_LOGIC;
            rst  : IN  STD_LOGIC;
            we   : IN  STD_LOGIC;
            addr : IN  UNSIGNED(1 DOWNTO 0);
            data : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_0  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_1  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_2  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_3  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    -- Sinais para controlar o RegFile
    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_rst   : STD_LOGIC := '0';
    SIGNAL tb_we    : STD_LOGIC := '0';
    SIGNAL tb_addr  : UNSIGNED(1 DOWNTO 0) := "00";
    SIGNAL tb_data  : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";

    -- Sinais para ler as saídas
    SIGNAL s_q0, s_q1, s_q2, s_q3 : STD_LOGIC_VECTOR(7 DOWNTO 0);

    CONSTANT CLK_PERIOD : TIME := 10 ns;
    
    -- Função de Conversão (para os REPORTs)
    FUNCTION to_hex_8bit (vec : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) RETURN STRING IS
        VARIABLE result_str : STRING(1 TO 2);
        VARIABLE nybble_hi  : UNSIGNED(3 DOWNTO 0);
        VARIABLE nybble_lo  : UNSIGNED(3 DOWNTO 0);
        FUNCTION nybble_to_char (nyb : IN UNSIGNED(3 DOWNTO 0)) RETURN CHARACTER IS
        BEGIN
            CASE nyb IS
                WHEN x"0"=>RETURN '0'; WHEN x"1"=>RETURN '1'; WHEN x"2"=>RETURN '2';
                WHEN x"3"=>RETURN '3'; WHEN x"4"=>RETURN '4'; WHEN x"5"=>RETURN '5';
                WHEN x"6"=>RETURN '6'; WHEN x"7"=>RETURN '7'; WHEN x"8"=>RETURN '8';
                WHEN x"9"=>RETURN '9'; WHEN x"A"=>RETURN 'A'; WHEN x"B"=>RETURN 'B';
                WHEN x"C"=>RETURN 'C'; WHEN x"D"=>RETURN 'D'; WHEN x"E"=>RETURN 'E';
                WHEN x"F"=>RETURN 'F'; WHEN OTHERS=>RETURN 'X';
            END CASE;
        END FUNCTION nybble_to_char;
    BEGIN
        nybble_hi := UNSIGNED(vec(7 DOWNTO 4));
        nybble_lo := UNSIGNED(vec(3 DOWNTO 0));
        result_str(1) := nybble_to_char(nybble_hi);
        result_str(2) := nybble_to_char(nybble_lo);
        RETURN result_str;
    END FUNCTION to_hex_8bit;

BEGIN

    -- 1. Instanciar o RegFile
    UUT_RegFile : regfile
        PORT MAP (
            clk  => tb_clk,
            rst  => tb_rst,
            we   => tb_we,
            addr => tb_addr,
            data => tb_data,
            q_0  => s_q0,
            q_1  => s_q1,
            q_2  => s_q2,
            q_3  => s_q3
        );

    -- 2. Gerador de Clock
    Clock_Process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
    END PROCESS;

    -- 3. Processo de Estímulo
    Stimulus_Process : PROCESS
    BEGIN
        REPORT "--- Testbench SIMPLES do RegFile iniciado ---";
        
        -- Aplicar Reset
        tb_rst <= '1';
        WAIT FOR CLK_PERIOD;
        tb_rst <= '0';
        WAIT FOR CLK_PERIOD / 4;
        
        -- ==============================================
        -- Teste 1: Escrever x"AA" em R1 (addr "01")
        -- ==============================================
        REPORT "TESTE 1: Configurando escrita de x""AA"" em R1...";
        
        -- Configura os sinais de escrita (antes da borda de descida)
        tb_we   <= '1';
        tb_addr <= "01";
        tb_data <= x"AA";

        -- Espera a borda de descida (é aqui que a escrita deve acontecer)
        WAIT UNTIL falling_edge(tb_clk); -- (T=15ns)
        REPORT "INFO: Borda de descida. 'we' esta em '1'. Escrita deve ocorrer AGORA.";
        
        -- Espera a borda de subida (para o próximo ciclo)
        WAIT UNTIL rising_edge(tb_clk); -- (T=20ns)
        
        -- Desliga os sinais de escrita
        tb_we   <= '0';
        tb_data <= x"00";
        tb_addr <= "00";
        
        -- Espera um pouco para a leitura estabilizar
        WAIT FOR CLK_PERIOD / 4; -- (T=22.5ns)
        
        -- ==============================================
        -- Verificação
        -- ==============================================
        
        -- A leitura (q_1) é combinacional, então o valor JÁ DEVE estar lá
        ASSERT (s_q1 = x"AA")
            REPORT "FALHA TESTE 1: R1 não contém o valor esperado! Esperado: x""AA"", Lido: x""" & 
                   to_hex_8bit(s_q1) & """"
            SEVERITY ERROR;
            
        ASSERT (s_q0 = x"00" AND s_q2 = x"00" AND s_q3 = x"00")
            REPORT "FALHA TESTE 1: Outro registrador foi escrito indevidamente!" SEVERITY WARNING;

        REPORT "SUCESSO TESTE 1: R1 = x""" & to_hex_8bit(s_q1) & """";
        
        REPORT "--- Testbench SIMPLES finalizado ---";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;