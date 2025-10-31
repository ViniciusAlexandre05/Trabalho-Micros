LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;  
ENTITY tb_cu_ula IS
END tb_cu_ula;

ARCHITECTURE Behavioral OF tb_cu_ula IS

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

    COMPONENT ULA IS
        PORT (
            A         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            B         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            ALU_Sel   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
            Resultado : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            Flags     : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
        );
    END COMPONENT;
    
    CONSTANT OP_ADD     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"40";
    CONSTANT OP_SUB     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"41";
    CONSTANT OP_AND     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"42";
    CONSTANT OP_ADD_IMM : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"50";
    CONSTANT OP_SHL     : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"70";

    CONSTANT ALU_OP_ADD : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
    CONSTANT ALU_OP_SUB : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001";
    CONSTANT ALU_OP_AND : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00110";
    CONSTANT ALU_OP_NOP : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000"; 

    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_reset : STD_LOGIC := '0';
    SIGNAL tb_opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_A_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tb_B_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_halt    : STD_LOGIC;
    
    SIGNAL s_alu_op : STD_LOGIC_VECTOR(4 DOWNTO 0);
    
    SIGNAL s_alu_src_b_sel : STD_LOGIC;
    SIGNAL s_reg_write_src : STD_LOGIC_VECTOR(1 DOWNTO 0);
    
    SIGNAL s_ula_result : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_ula_flags  : STD_LOGIC_VECTOR(4 DOWNTO 0);
    
    CONSTANT CLK_PERIOD : TIME := 10 ns;

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


    UUT_Control_Unit : control_unit
        PORT MAP (
            clk                 => tb_clk,
            reset               => tb_reset,
            opcode_in           => tb_opcode,
            A                   => tb_A_data,
            alu_op              => s_alu_op, 
            alu_src_b_sel       => s_alu_src_b_sel,
            reg_write_src_sel   => s_reg_write_src,
            halt_out            => s_halt,

            pc_en               => OPEN, 
            ir_load_en          => OPEN,
            rf_write_en         => OPEN,
            shifter_ctrl_out    => OPEN
        );

    UUT_ULA : ULA
        PORT MAP (
            A         => tb_A_data, 
            B         => tb_B_data, 
            ALU_Sel   => s_alu_op,  
            Resultado => s_ula_result,
            Flags     => s_ula_flags
        );

    Clock_Process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
        IF s_halt = '1' THEN WAIT; END IF;
    END PROCESS;

    Stimulus_Process : PROCESS
        PROCEDURE run_test (
            CONSTANT test_name         : IN STRING;
            CONSTANT op_code_to_test   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT data_a_in         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT data_b_in         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT expected_result   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            CONSTANT expected_alu_op   : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            CONSTANT expected_b_sel    : IN STD_LOGIC;
            CONSTANT expected_reg_src  : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
        ) IS
            VARIABLE v_ula_result : STD_LOGIC_VECTOR(7 DOWNTO 0);
            VARIABLE v_alu_op     : STD_LOGIC_VECTOR(4 DOWNTO 0);
            VARIABLE v_b_sel      : STD_LOGIC;
            VARIABLE v_reg_src    : STD_LOGIC_VECTOR(1 DOWNTO 0);
        BEGIN
            tb_A_data <= data_a_in;
            tb_B_data <= data_b_in;
            tb_opcode <= op_code_to_test;

            WAIT UNTIL RISING_EDGE(tb_clk);
            WAIT UNTIL RISING_EDGE(tb_clk);
            
            WAIT UNTIL RISING_EDGE(tb_clk); 
            WAIT FOR 1 ns;
            
            ASSERT (s_alu_op = expected_alu_op)
                REPORT "FALHA [" & test_name & "]: Sinal 'alu_op' incorreto." SEVERITY ERROR;
            ASSERT (s_alu_src_b_sel = expected_b_sel)
                REPORT "FALHA [" & test_name & "]: Sinal 'alu_src_b_sel' incorreto." SEVERITY ERROR;
            ASSERT (s_ula_result = expected_result)
                REPORT "FALHA [" & test_name & "]: Resultado da ULA incorreto." SEVERITY ERROR;
            
            v_ula_result := s_ula_result;
            v_alu_op     := s_alu_op;
            v_b_sel      := s_alu_src_b_sel;
            
            WAIT UNTIL RISING_EDGE(tb_clk); 
            WAIT FOR 1 ns;
            
            ASSERT (s_reg_write_src = expected_reg_src)
                REPORT "FALHA [" & test_name & "]: Sinal 'reg_write_src_sel' incorreto." SEVERITY ERROR;

            v_reg_src := s_reg_write_src;

            REPORT "SUCESSO [" & test_name & "]: " & 
                   to_hex_8bit(data_a_in) & " op " & to_hex_8bit(data_b_in) & 
                   " -> " & to_hex_8bit(v_ula_result) & 
                   " (ALU_Op=" & to_hex_8bit("000" & v_alu_op) & 
                   ", B_Sel=" & STD_LOGIC'IMAGE(v_b_sel) & 
                   ", Reg_Src=" & to_hex_8bit("000000" & v_reg_src) & ")";
                   
        END PROCEDURE run_test;

    BEGIN
    
        REPORT "Testbench UDC + ULA iniciado.";
        
        tb_opcode <= x"00"; -- NOP
        tb_A_data <= (OTHERS => '0');
        tb_B_data <= (OTHERS => '0');
        
        -- Aplica o Reset
        tb_reset <= '1';
        WAIT FOR CLK_PERIOD;
        tb_reset <= '0';
        
        run_test("ADD",OP_ADD, x"10", x"20", x"30",ALU_OP_ADD,'0',"00");

        run_test("SUB", OP_SUB, x"35", x"15", x"20",ALU_OP_SUB,'0',"00");

        run_test("AND",OP_AND, x"F0", x"A5", x"A0",ALU_OP_AND,'0',"00");

        run_test("ADD_IMM",OP_ADD_IMM, x"11", x"22", x"33",ALU_OP_ADD,'1',"00");

        run_test("SHL",OP_SHL, x"AA", x"11", x"BB", ALU_OP_NOP, '0', "01");

        
        tb_opcode <= x"00";
        tb_A_data <= (OTHERS => '0');
        tb_B_data <= (OTHERS => '0');

        REPORT "Testbench finalizado.";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;