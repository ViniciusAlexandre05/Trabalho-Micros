LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Este é um NOVO testbench com uma estratégia de timing diferente (Mid-Cycle Sample)
ENTITY tb_cu_flag_register IS
END tb_cu_flag_register;

ARCHITECTURE Behavioral OF tb_cu_flag_register IS

    -- === 1. Componentes ===
    
    COMPONENT control_unit IS
        PORT (
            clk                 : IN  STD_LOGIC;
            reset               : IN  STD_LOGIC;
            opcode_in           : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            A                   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            flags_in            : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
            pc_en               : OUT STD_LOGIC;
            ir_load_en          : OUT STD_LOGIC;
            rf_write_en         : OUT STD_LOGIC;
            alu_op              : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            alu_src_b_sel       : OUT STD_LOGIC;
            shifter_ctrl_out    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            reg_write_src_sel   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            ld_alu_flags_out    : OUT STD_LOGIC;
            ld_shf_flags_out    : OUT STD_LOGIC;
            halt_out            : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Flag_Register IS
        PORT (
            clk     : IN  STD_LOGIC;
            rst     : IN  STD_LOGIC;
            LD_ZF   : IN  STD_LOGIC;
            LD_CF   : IN  STD_LOGIC;
            LD_SF   : IN  STD_LOGIC;
            LD_PF   : IN  STD_LOGIC;
            LD_IF   : IN  STD_LOGIC;
            LD_DF   : IN  STD_LOGIC;
            LD_OF   : IN  STD_LOGIC;
            set_ZF  : IN  STD_LOGIC;
            set_CF  : IN  STD_LOGIC;
            set_SF  : IN  STD_LOGIC;
            set_PF  : IN  STD_LOGIC;
            set_IF  : IN  STD_LOGIC;
            set_DF  : IN  STD_LOGIC;
            set_OF  : IN  STD_LOGIC;
            R_FLAGS : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;
    
    -- === 2. Opcodes ===
    CONSTANT OP_ADD     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40";
    CONSTANT OP_MOV_REG : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"10";

    -- === 3. Sinais ===
    SIGNAL tb_clk     : STD_LOGIC := '0';
    SIGNAL tb_reset   : STD_LOGIC := '0'; 
    SIGNAL tb_opcode  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_dummy_A : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL s_flags_reg_out : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_ld_alu_flags : STD_LOGIC;
    SIGNAL s_ld_shf_flags : STD_LOGIC;
    SIGNAL s_set_zf, s_set_cf, s_set_sf, s_set_pf, s_set_of : STD_LOGIC;
    SIGNAL s_ld_zf, s_ld_cf, s_ld_sf, s_ld_pf, s_ld_of : STD_LOGIC;
    
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT HALF_CLK : TIME := CLK_PERIOD / 2;

    -- === 4. Função de Conversão (VHDL-93) ===
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
            flags_in            => s_flags_reg_out,
            ld_alu_flags_out    => s_ld_alu_flags,
            ld_shf_flags_out    => s_ld_shf_flags,
            pc_en               => OPEN, ir_load_en          => OPEN,
            rf_write_en         => OPEN, alu_op              => OPEN,
            alu_src_b_sel       => OPEN, shifter_ctrl_out    => OPEN,
            reg_write_src_sel   => OPEN, halt_out            => OPEN
        );

    UUT_Flag_Reg : Flag_Register
        PORT MAP (
            clk     => tb_clk,
            rst     => tb_reset,
            LD_ZF   => s_ld_zf, LD_CF   => s_ld_cf, LD_SF   => s_ld_sf,
            LD_PF   => s_ld_pf, LD_IF   => '0',     LD_DF   => '0',
            LD_OF   => s_ld_of,
            set_ZF  => s_set_zf, set_CF  => s_set_cf, set_SF  => s_set_sf,
            set_PF  => s_set_pf, set_IF  => '0',     set_DF  => '0',
            set_OF  => s_set_of,
            R_FLAGS => s_flags_reg_out
        );

    -- === 6. "Glue Logic" ===
    s_ld_zf <= s_ld_alu_flags OR s_ld_shf_flags;
    s_ld_cf <= s_ld_alu_flags OR s_ld_shf_flags;
    s_ld_sf <= s_ld_alu_flags OR s_ld_shf_flags;
    s_ld_pf <= s_ld_alu_flags OR s_ld_shf_flags;
    s_ld_of <= s_ld_alu_flags; 

    -- === 7. Gerador de Clock ===
    Clock_Process : PROCESS
    BEGIN
        WAIT FOR HALF_CLK;
        tb_clk <= NOT tb_clk;
    END PROCESS;

    -- === 8. Processo de Estímulo (ESTRATÉGIA DE TIMING DIFERENTE) ===
    Stimulus_Process : PROCESS
    BEGIN
        REPORT "--- Testbench (Mid-Cycle Sample) iniciado ---";
        
        tb_opcode <= (OTHERS => '0');
        tb_reset <= '1';
        WAIT UNTIL falling_edge(tb_clk); 
        tb_reset <= '0';
        WAIT FOR CLK_PERIOD;
        
        -- ==============================================
        -- Teste 1: OP_ADD (Flags da ULA)
        -- ==============================================
        REPORT "TESTE 1: Rodando OP_ADD...";
        
        s_set_zf <= '1'; s_set_cf <= '0'; s_set_sf <= '1';
        s_set_pf <= '0'; s_set_of <= '1';
        tb_opcode <= OP_ADD;
        
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_FETCH
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_DECODE
        
        -- S_EXECUTE começa AQUI (ex: T=35ns)
        WAIT UNTIL RISING_EDGE(tb_clk); 
        
        -- === NOVA ESTRATÉGIA DE TESTE ===
        -- Espera até o *meio* do ciclo S_EXECUTE, onde os sinais
        -- combinacionais (ld_alu_flags) estão estáveis.
        WAIT FOR HALF_CLK - 1 ns; -- (ex: T=39ns)
        
        REPORT "INFO (ADD): Verificando sinais no *meio* do S_EXECUTE...";
        ASSERT s_ld_alu_flags = '1' REPORT "FALHA (ADD): ld_alu_flags_out deveria ser '1'" SEVERITY ERROR;
        ASSERT s_ld_shf_flags = '0' REPORT "FALHA (ADD): ld_shf_flags_out deveria ser '0'" SEVERITY ERROR;
        
        -- O Flag_Register (falling_edge) vai escrever na *próxima* borda de descida (T=40ns)
        
        -- Espera o próximo ciclo (S_WRITEBACK) para ler o resultado
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_WRITEBACK (ex: T=45ns)
        WAIT FOR 1 ns; -- (ex: T=46ns)
        
        -- Verifica o resultado no Flag_Register
        ASSERT s_flags_reg_out = "1010001"
            REPORT "FALHA (ADD): Flags incorretos! Esperado: 1010001, Lido: x" & to_hex_8bit('0' & s_flags_reg_out)
            SEVERITY ERROR;
        REPORT "SUCESSO (ADD): Flags = x" & to_hex_8bit('0' & s_flags_reg_out);

        -- ==============================================
        -- Teste 2: OP_MOV_REG (Teste de "Hold")
        -- ==============================================
        REPORT "TESTE 2: Rodando OP_MOV_REG...";
        
        s_set_zf <= '0'; s_set_cf <= '1'; s_set_sf <= '0';
        s_set_pf <= '1'; s_set_of <= '0';
        tb_opcode <= OP_MOV_REG;
        
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_FETCH
        WAIT UNTIL RISING_EDGE(tb_clk); -- S_DECODE
        
        -- S_EXECUTE começa AQUI
        WAIT UNTIL RISING_EDGE(tb_clk);
        
        -- === NOVA ESTRATÉGIA DE TESTE ===
        WAIT FOR HALF_CLK - 1 ns; 
        
        REPORT "INFO (MOV): Verificando sinais no *meio* do S_EXECUTE...";
        ASSERT s_ld_alu_flags = '0' REPORT "FALHA (MOV): ld_alu_flags_out deveria ser '0'" SEVERITY ERROR;
        ASSERT s_ld_shf_flags = '0' REPORT "FALHA (MOV): ld_shf_flags_out deveria ser '0'" SEVERITY ERROR;
        
        -- Próximo ciclo (S_WRITEBACK)
        WAIT UNTIL RISING_EDGE(tb_clk);
        WAIT FOR 1 ns;
        
        -- O valor NÃO PODE ter mudado
        ASSERT s_flags_reg_out = "1010001"
            REPORT "FALHA (MOV): Hold falhou! Valor mudou para: x" & to_hex_8bit('0' & s_flags_reg_out)
            SEVERITY ERROR;
        REPORT "SUCESSO (MOV): Hold OK. Valor mantido: x" & to_hex_8bit('0' & s_flags_reg_out);
        
        REPORT "--- Testbench (Mid-Cycle Sample) finalizado ---";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;