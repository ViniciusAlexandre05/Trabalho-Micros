LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;  -- Necessário para UNSIGNED

-- Este testbench usa uma PROCEDURE para testar a UDC + Shifter
ENTITY tb_cu_shifter IS
END tb_cu_shifter;

ARCHITECTURE Behavioral OF tb_cu_shifter IS

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

    COMPONENT BitShifter IS
        PORT (
            Data_In    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            Shift_Ctrl : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            Data_Out   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            Carry_Out  : OUT STD_LOGIC
        );
    END COMPONENT;
    
    -- === 2. Opcodes ===
    CONSTANT OP_SHL : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"70";
    CONSTANT OP_SHR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"71";
    CONSTANT OP_ADD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40"; -- Teste de não-op

    -- === 3. Sinais ===
    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_reset : STD_LOGIC := '0';
    SIGNAL tb_opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_A_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_shifter_ctrl    : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL s_reg_write_src   : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL s_halt            : STD_LOGIC;
    SIGNAL s_shifter_result : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_shifter_carry  : STD_LOGIC;
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- === 4. Função de Conversão (VHDL-93) ===
    FUNCTION to_hex_8bit (vec : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) RETURN STRING IS
        VARIABLE result_str : STRING(1 TO 2);
        VARIABLE nybble_hi  : UNSIGNED(3 DOWNTO 0);
        VARIABLE nybble_lo  : UNSIGNED(3 DOWNTO 0);
        
        FUNCTION nybble_to_char (nyb : IN UNSIGNED(3 DOWNTO 0)) RETURN CHARACTER IS
        BEGIN
            CASE nyb IS
                WHEN x"0" => RETURN '0'; WHEN x"1" => RETURN '1';
                WHEN x"2" => RETURN '2'; WHEN x"3" => RETURN '3';
                WHEN x"4" => RETURN '4'; WHEN x"5" => RETURN '5';
                WHEN x"6" => RETURN '6'; WHEN x"7" => RETURN '7';
                WHEN x"8" => RETURN '8'; WHEN x"9" => RETURN '9';
                WHEN x"A" => RETURN 'A'; WHEN x"B" => RETURN 'B';
                WHEN x"C" => RETURN 'C'; WHEN x"D" => RETURN 'D';
                WHEN x"E" => RETURN 'E'; WHEN x"F" => RETURN 'F';
                WHEN OTHERS => RETURN 'X';
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
            A                   => tb_A_data,
            shifter_ctrl_out    => s_shifter_ctrl,
            reg_write_src_sel   => s_reg_write_src,
            pc_en               => OPEN, ir_load_en          => OPEN,
            rf_write_en         => OPEN, alu_op              => OPEN,
            alu_src_b_sel       => OPEN, halt_out            => s_halt
        );

    UUT_BitShifter : BitShifter
        PORT MAP (
            Data_In    => tb_A_data,
            Shift_Ctrl => s_shifter_ctrl,
            Data_Out   => s_shifter_result,
            Carry_Out  => s_shifter_carry
        );

    -- === 6. Gerador de Clock ===
    Clock_Process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
        IF s_halt = '1' THEN WAIT; END IF;
    END PROCESS;

    -- === 7. Processo de Estímulo (com PROCEDURE) ===
    Stimulus_Process : PROCESS
    
        -- ==========================================================
        -- ==          DEFINIÇÃO DA PROCEDURE DE TESTE             ==
        -- ==========================================================
        PROCEDURE run_test (
            CONSTANT test_name       : IN STRING;
            CONSTANT op_code_to_test : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT data_a_in       : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT expected_result : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT expected_shf_ctrl : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            CONSTANT expected_reg_src  : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
        ) IS
            -- === CORREÇÃO: Variáveis para "tirar foto" dos sinais ===
            VARIABLE v_shf_result : STD_LOGIC_VECTOR(7 DOWNTO 0);
            VARIABLE v_shf_ctrl   : STD_LOGIC_VECTOR(1 DOWNTO 0);
            VARIABLE v_reg_src    : STD_LOGIC_VECTOR(1 DOWNTO 0);
        BEGIN
            -- 1. Define os sinais de entrada ANTES do ciclo de clock
            tb_A_data <= data_a_in;
            tb_opcode <= op_code_to_test;

            -- 2. Simula os 4 ciclos de clock da instrução
            
            -- S_FETCH
            WAIT UNTIL RISING_EDGE(tb_clk); 
            
            -- S_DECODE
            WAIT UNTIL RISING_EDGE(tb_clk); 
            
            -- S_EXECUTE (Verifica o controle e o resultado)
            WAIT UNTIL RISING_EDGE(tb_clk); 
            WAIT FOR 1 ns; -- Espera a lógica combinacional
            
            ASSERT (s_shifter_ctrl = expected_shf_ctrl)
                REPORT "FALHA [" & test_name & "]: Sinal 'shifter_ctrl' incorreto." SEVERITY ERROR;
                
            ASSERT (s_shifter_result = expected_result)
                REPORT "FALHA [" & test_name & "]: Resultado do Shifter incorreto." SEVERITY ERROR;
            
            -- === CORREÇÃO: "Tira a foto" dos sinais do S_EXECUTE ===
            v_shf_result := s_shifter_result;
            v_shf_ctrl   := s_shifter_ctrl;
            
            -- S_WRITEBACK (Verifica a fonte do registrador)
            WAIT UNTIL RISING_EDGE(tb_clk); 
            WAIT FOR 1 ns; -- Espera a lógica combinacional
            
            ASSERT (s_reg_write_src = expected_reg_src)
                REPORT "FALHA [" & test_name & "]: Sinal 'reg_write_src_sel' incorreto." SEVERITY ERROR;

            -- === CORREÇÃO: "Tira a foto" do sinal do S_WRITEBACK ===
            v_reg_src := s_reg_write_src;

            -- 3. Imprime o sucesso usando as VARIÁVEIS (que não mudam)
            REPORT "SUCESSO [" & test_name & "]: " & 
                   to_hex_8bit(data_a_in) & " -> " & to_hex_8bit(v_shf_result) & 
                   " (Ctrl=" & to_hex_8bit("000000" & v_shf_ctrl) & 
                   ", Src=" & to_hex_8bit("000000" & v_reg_src) & ")";
                   
        END PROCEDURE run_test;
        -- ==========================================================

    BEGIN -- <-- INÍCIO DOS COMANDOS SEQUENCIAIS
    
        REPORT "Testbench com Procedure iniciado.";
        
        -- Valores padrão (inativos)
        tb_opcode <= x"00"; -- NOP
        tb_A_data <= (OTHERS => '0');
        
        -- Aplica o Reset
        tb_reset <= '1';
        WAIT FOR CLK_PERIOD;
        tb_reset <= '0';
        
        -- ==========================================================
        -- ==          CHAMADAS DE TESTE (DEPOIS do BEGIN)         ==
        -- ==========================================================
        
        -- Teste 1: Shift Left
        run_test("SHL",    OP_SHL,   x"A5",     x"4A",             "01",             "01");

        -- Teste 2: Shift Right
        run_test("SHR",    OP_SHR,   x"B3",     x"59",             "10",             "01");
        
        -- Teste 3: Não-Shift (Operação da ULA)
        run_test("ADD",    OP_ADD,   x"C3",     x"C3",             "00",             "00");
        
        -- Limpa os sinais no final
        tb_opcode <= x"00"; -- NOP
        tb_A_data <= (OTHERS => '0');

        REPORT "Testbench finalizado.";
        WAIT; -- Fim da simulação
        
    END PROCESS Stimulus_Process;

END Behavioral;