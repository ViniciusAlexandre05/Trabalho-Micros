LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Este é um Teste de Unidade SIMPLES apenas para o Program_Counter
ENTITY tb_program_counter IS
END tb_program_counter;

ARCHITECTURE Behavioral OF tb_program_counter IS

    -- 1. Componente a ser testado
    COMPONENT Program_Counter IS
        PORT (
            clk         : IN  STD_LOGIC;
            rst         : IN  STD_LOGIC;
            pc_en       : IN  STD_LOGIC;
            pc_load_en  : IN  STD_LOGIC;
            data_in     : IN  UNSIGNED(7 DOWNTO 0);
            pc_out      : OUT UNSIGNED(7 DOWNTO 0)
        );
    END COMPONENT;

    -- Sinais para controlar o UUT
    SIGNAL tb_clk         : STD_LOGIC := '0';
    SIGNAL tb_rst         : STD_LOGIC := '0';
    SIGNAL tb_pc_en       : STD_LOGIC := '0';
    SIGNAL tb_pc_load_en  : STD_LOGIC := '0';
    SIGNAL tb_data_in     : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');

    -- Sinal para ler a saída
    SIGNAL s_pc_out : UNSIGNED(7 DOWNTO 0);

    CONSTANT CLK_PERIOD : TIME := 10 ns;
    
    -- Função de Conversão (para os REPORTs)
    FUNCTION to_hex_8bit_unsigned (vec : IN UNSIGNED(7 DOWNTO 0)) RETURN STRING IS
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
        nybble_hi := vec(7 DOWNTO 4);
        nybble_lo := vec(3 DOWNTO 0);
        result_str(1) := nybble_to_char(nybble_hi);
        result_str(2) := nybble_to_char(nybble_lo);
        RETURN result_str;
    END FUNCTION to_hex_8bit_unsigned;

BEGIN

    -- 1. Instanciar o PC
    UUT_PC : Program_Counter
        PORT MAP (
            clk         => tb_clk,
            rst         => tb_rst,
            pc_en       => tb_pc_en,
            pc_load_en  => tb_pc_load_en,
            data_in     => tb_data_in,
            pc_out      => s_pc_out
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
        REPORT "--- Testbench Program_Counter (Async Reset) iniciado ---";
        
        -- ==============================================
        -- Teste 1: Reset Assíncrono
        -- ==============================================
        tb_rst <= '1';
        WAIT FOR 1 ns; -- Espera o sinal propagar (não precisa de clock)
        
        ASSERT s_pc_out = x"00"
            REPORT "FALHA TESTE 1 (Reset): PC não foi para 00! Lido: x" & to_hex_8bit_unsigned(s_pc_out)
            SEVERITY ERROR;
        
        REPORT "SUCESSO TESTE 1: Reset Assíncrono OK. PC = x" & to_hex_8bit_unsigned(s_pc_out);
        
        tb_rst <= '0';
        WAIT FOR CLK_PERIOD; -- Espera um ciclo para estabilizar
        
        -- ==============================================
        -- Teste 2: Incremento (pc_en = '1')
        -- ==============================================
        REPORT "TESTE 2: Incrementando (pc_en='1')...";
        tb_pc_en <= '1';
        
        -- O PC usa falling_edge, então esperamos por ele
        WAIT UNTIL falling_edge(tb_clk); -- PC deve ir para 01
        WAIT FOR 1 ns; -- Espera a saída propagar
        ASSERT s_pc_out = x"01"
            REPORT "FALHA TESTE 2 (Inc 1): PC não foi para 01! Lido: x" & to_hex_8bit_unsigned(s_pc_out)
            SEVERITY ERROR;
            
        WAIT UNTIL falling_edge(tb_clk); -- PC deve ir para 02
        WAIT FOR 1 ns; 
        ASSERT s_pc_out = x"02"
            REPORT "FALHA TESTE 2 (Inc 2): PC não foi para 02! Lido: x" & to_hex_8bit_unsigned(s_pc_out)
            SEVERITY ERROR;
            
        REPORT "SUCESSO TESTE 2: Incremento OK. PC = x" & to_hex_8bit_unsigned(s_pc_out);

        -- ==============================================
        -- Teste 3: Hold (pc_en = '0')
        -- ==============================================
        REPORT "TESTE 3: Hold (pc_en='0')...";
        tb_pc_en <= '0';
        
        WAIT UNTIL falling_edge(tb_clk);
        WAIT FOR 1 ns;
        
        ASSERT s_pc_out = x"02" -- Valor DEVE ser mantido
            REPORT "FALHA TESTE 3 (Hold): PC mudou de valor! Lido: x" & to_hex_8bit_unsigned(s_pc_out)
            SEVERITY ERROR;
        REPORT "SUCESSO TESTE 3: Hold OK. PC = x" & to_hex_8bit_unsigned(s_pc_out);

        -- ==============================================
        -- Teste 4: Load (pc_load_en = '1')
        -- ==============================================
        REPORT "TESTE 4: Load x""AA"" (pc_load_en='1')...";
        tb_pc_load_en <= '1';
        tb_pc_en      <= '1'; -- Testa prioridade (Load deve vencer)
        tb_data_in    <= x"AA";
        
        WAIT UNTIL falling_edge(tb_clk);
        WAIT FOR 1 ns;
        
        ASSERT s_pc_out = x"AA"
            REPORT "FALHA TESTE 4 (Load): PC não foi para AA! Lido: x" & to_hex_8bit_unsigned(s_pc_out)
            SEVERITY ERROR;
        REPORT "SUCESSO TESTE 4: Load OK (e venceu 'pc_en'). PC = x" & to_hex_8bit_unsigned(s_pc_out);
        
        REPORT "--- Testbench Program_Counter finalizado ---";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;