LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_cu_regfile IS
END tb_cu_regfile;

ARCHITECTURE Behavioral OF tb_cu_regfile IS

    -- === 1. Componentes ===
    
    COMPONENT control_unit IS
        PORT (
            clk                 : IN  STD_LOGIC;
            reset               : IN  STD_LOGIC;
            opcode_in           : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            A                   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            pc_en               : OUT STD_LOGIC;
            ir_load_en          : OUT STD_LOGIC;
            rf_write_en         : OUT STD_LOGIC;
            alu_op              : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            alu_src_b_sel       : OUT STD_LOGIC;
            shifter_ctrl_out    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            reg_write_src_sel   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            halt_out            : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Componente RegFile (A VERSÃO CORRETA, COM CLK)
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
    
    -- === 2. Opcodes ===
    CONSTANT OP_ADD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40";
    CONSTANT OP_NOP : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";

    -- === 3. Sinais ===
    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_reset : STD_LOGIC := '0';
    SIGNAL tb_opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_dummy_A : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL s_rf_write_en : STD_LOGIC;
    SIGNAL s_reg_addr_w : UNSIGNED(1 DOWNTO 0);
    SIGNAL s_reg_data_w : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    SIGNAL s_reg_q0, s_reg_q1, s_reg_q2, s_reg_q3 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- === 4. Função de Conversão ===
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

    -- === 5. Instanciações ===
    
    UUT_Control_Unit : control_unit
        PORT MAP (
            clk                 => tb_clk,
            reset               => tb_reset,
            opcode_in           => tb_opcode,
            A                   => tb_dummy_A,
            rf_write_en         => s_rf_write_en,
            pc_en               => OPEN, ir_load_en          => OPEN,
            alu_op              => OPEN, alu_src_b_sel       => OPEN,
            shifter_ctrl_out    => OPEN, reg_write_src_sel   => OPEN,
            halt_out            => OPEN
        );

    UUT_RegFile : regfile
        PORT MAP (
            clk  => tb_clk,
            rst  => tb_reset,
            we   => s_rf_write_en,
            addr => s_reg_addr_w,
            data => s_reg_data_w,
            q_0  => s_reg_q0,
            q_1  => s_reg_q1,
            q_2  => s_reg_q2,
            q_3  => s_reg_q3
        );

    -- === 6. Gerador de Clock ===
    Clock_Process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
    END PROCESS;

    -- === 7. Processo de Estímulo (CORRIGIDO) ===
    Stimulus_Process : PROCESS
    BEGIN
        REPORT "Testbench UDC + RegFile (Corrigido v2) iniciado.";
        
        tb_opcode <= OP_NOP;
        s_reg_addr_w <= "00";
        s_reg_data_w <= x"00";
        
        tb_reset <= '1';
        WAIT FOR CLK_PERIOD;
        tb_reset <= '0';
        
        -- Teste 1: Escrever x"AA" no Registrador R1
        REPORT "Teste 1: Escrevendo x""AA"" em R1...";
        
        tb_opcode <= OP_ADD;
        s_reg_addr_w <= "01";
        s_reg_data_w <= x"AA";
        
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_FETCH (T=15ns)
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_DECODE (T=25ns)
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_EXECUTE (T=35ns)
        
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_WRITEBACK (T=45ns)
        WAIT FOR 1 ns; -- (T=46ns)
        ASSERT (s_rf_write_en = '1')
            REPORT "FALHA: Write Enable (we) INATIVO no S_WRITEBACK!" SEVERITY ERROR;
        
        REPORT "INFO: 'we' ativado. Sinais (AA, 01) estao estaveis.";
        
        -- ================== CORREÇÃO DE TIMING ==================
        -- Espera a borda de descida (T=50ns), que é quando o regfile
        -- (corretamente) vai ler os dados.
        WAIT UNTIL falling_edge(tb_clk); -- (T=50ns)
        REPORT "INFO: Borda de descida. RegFile deve ter escrito AGORA.";
        
        -- AGORA (depois de T=50ns) nós podemos mudar os sinais
        -- para o próximo ciclo (S_FETCH).
        tb_opcode <= OP_NOP; 
        s_reg_data_w <= x"00";
        
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_FETCH (T=55ns)
        WAIT FOR 1 ns; -- (T=56ns)
        
        -- Verificação do Teste 1
        ASSERT (s_reg_q1 = x"AA")
            REPORT "FALHA TESTE 1: R1 não contém o valor esperado! Esperado: x""AA"", Lido: x""" & 
                   to_hex_8bit(s_reg_q1) & """"
            SEVERITY ERROR;
            
        ASSERT (s_reg_q0 = x"00" AND s_reg_q2 = x"00" AND s_reg_q3 = x"00")
            REPORT "FALHA TESTE 1: Outro registrador foi escrito indevidamente!" SEVERITY WARNING;

        REPORT "SUCESSO TESTE 1: R1 = x""" & to_hex_8bit(s_reg_q1) & """";
        REPORT "Testbench finalizado.";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;