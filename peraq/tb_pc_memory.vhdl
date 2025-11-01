LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Este testbench testa a integração do PC com a Memória de Instruções
ENTITY tb_pc_memory IS
END tb_pc_memory;

ARCHITECTURE Behavioral OF tb_pc_memory IS

    -- === 1. Componentes ===
    
    -- (Copiado do seu Program_Counter.vhdl corrigido)
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

    -- (Copiado do seu Instruction_Memory.vhdl)
    COMPONENT Instruction_Memory IS
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;
    
    -- === 2. Sinais de Conexão ===
    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_reset : STD_LOGIC := '0'; 
    
    -- Sinais controlados pelo Testbench
    SIGNAL tb_pc_en : STD_LOGIC := '0';
    
    -- Sinais de "fio" (conexão PC -> Mem)
    SIGNAL s_pc_addr_out : UNSIGNED(7 DOWNTO 0);
    
    -- Sinais de monitoramento (saída da Mem)
    SIGNAL s_mem_data_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- === 3. Funções de Conversão ===
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

    FUNCTION to_hex_8bit_slv (vec : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) RETURN STRING IS
    BEGIN
        RETURN to_hex_8bit_unsigned(UNSIGNED(vec));
    END FUNCTION to_hex_8bit_slv;

BEGIN

    -- === 4. Instanciações ===
    
    UUT_PC : Program_Counter
        PORT MAP (
            clk         => tb_clk,
            rst         => tb_reset,
            pc_en       => tb_pc_en,     -- Controlado por NÓS
            pc_load_en  => '0',          -- Amarrado em '0'
            data_in     => (OTHERS => '0'),
            pc_out      => s_pc_addr_out -- Conectado à Memória
        );
        
    UUT_Mem : Instruction_Memory
        PORT MAP (
            Address  => s_pc_addr_out, -- Conectado ao PC
            Data_Out => s_mem_data_out -- Monitorado por NÓS
        );

    -- === 5. Gerador de Clock ===
    Clock_Process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
    END PROCESS;

    -- === 6. Processo de Estímulo ===
    Stimulus_Process : PROCESS
    BEGIN
        REPORT "--- Testbench (PC + Memória) iniciado ---";
        
        -- ================== Teste 1: Reset Assíncrono ==================
        REPORT "TESTE 1: Reset...";
        tb_reset <= '1';
        WAIT FOR 1 ns; -- Reset é assíncrono
        
        -- Verifica o PC
        ASSERT s_pc_addr_out = x"00"
            REPORT "FALHA (Reset): PC não foi para 00! Lido: x" & to_hex_8bit_unsigned(s_pc_addr_out)
            SEVERITY ERROR;
        
        -- Verifica a Memória (que é combinacional e reage ao PC=00)
        -- (O programa na sua memória tem x"11" no endereço 0)
        ASSERT s_mem_data_out = x"11"
            REPORT "FALHA (Reset): Memória não mostrou x""11""! Lido: x" & to_hex_8bit_slv(s_mem_data_out)
            SEVERITY ERROR;
            
        REPORT "SUCESSO (Reset): PC=x" & to_hex_8bit_unsigned(s_pc_addr_out) & 
               ", Mem=x" & to_hex_8bit_slv(s_mem_data_out);
        
        tb_reset <= '0';
        WAIT FOR CLK_PERIOD; -- Espera um ciclo para estabilizar
        
        -- ================== Teste 2: Hold (pc_en='0') ==================
        REPORT "TESTE 2: Hold (pc_en='0')...";
        tb_pc_en <= '0';
        
        WAIT UNTIL falling_edge(tb_clk); -- O PC *não* deve incrementar
        WAIT FOR 1 ns; -- Espera propagação
        
        ASSERT s_pc_addr_out = x"00"
            REPORT "FALHA (Hold): PC incrementou indevidamente! Lido: x" & to_hex_8bit_unsigned(s_pc_addr_out)
            SEVERITY ERROR;
        REPORT "SUCESSO (Hold): PC mantido em x" & to_hex_8bit_unsigned(s_pc_addr_out);

        -- ================== Teste 3: Incremento (pc_en='1') ==================
        REPORT "TESTE 3: Incremento (pc_en='1')...";
        tb_pc_en <= '1';
        
        -- 1º Incremento (PC -> 01)
        WAIT UNTIL falling_edge(tb_clk); -- PC deve ir para 01
        WAIT FOR 1 ns; -- Espera PC atualizar
        ASSERT s_pc_addr_out = x"01"
            REPORT "FALHA (Inc 1): PC não foi para 01! Lido: x" & to_hex_8bit_unsigned(s_pc_addr_out)
            SEVERITY ERROR;
            
        WAIT FOR 1 ns; -- Espera Memória (combinacional) reagir ao novo PC
        -- (O programa na sua memória tem x"AA" no endereço 1)
        ASSERT s_mem_data_out = x"AA"
            REPORT "FALHA (Inc 1): Memória não mostrou x""AA""! Lido: x" & to_hex_8bit_slv(s_mem_data_out)
            SEVERITY ERROR;

        REPORT "SUCESSO (Inc 1): PC=x" & to_hex_8bit_unsigned(s_pc_addr_out) & 
               ", Mem=x" & to_hex_8bit_slv(s_mem_data_out);

        -- 2º Incremento (PC -> 02)
        WAIT UNTIL falling_edge(tb_clk); -- PC deve ir para 02
        WAIT FOR 1 ns; 
        ASSERT s_pc_addr_out = x"02"
            REPORT "FALHA (Inc 2): PC não foi para 02! Lido: x" & to_hex_8bit_unsigned(s_pc_addr_out)
            SEVERITY ERROR;
            
        WAIT FOR 1 ns; 
        -- (O programa na sua memória tem x"11" no endereço 2)
        ASSERT s_mem_data_out = x"11"
            REPORT "FALHA (Inc 2): Memória não mostrou x""11""! Lido: x" & to_hex_8bit_slv(s_mem_data_out)
            SEVERITY ERROR;
            
        REPORT "SUCESSO (Inc 2): PC=x" & to_hex_8bit_unsigned(s_pc_addr_out) & 
               ", Mem=x" & to_hex_8bit_slv(s_mem_data_out);
        
        REPORT "--- Testbench (PC + Memória) finalizado ---";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;