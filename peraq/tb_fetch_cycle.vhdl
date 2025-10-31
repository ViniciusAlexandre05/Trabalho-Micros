LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_fetch_cycle IS
END tb_fetch_cycle;

ARCHITECTURE Behavioral OF tb_fetch_cycle IS
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

    COMPONENT Instruction_Memory IS
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT Instruction_Register IS
        PORT (
            clk        : IN  STD_LOGIC;
            rst        : IN  STD_LOGIC;
            ir_load_en : IN  STD_LOGIC;
            data_in    : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
            opcode_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_reset : STD_LOGIC := '0'; 
    SIGNAL s_pc_addr_out : UNSIGNED(7 DOWNTO 0);
    SIGNAL s_mem_data_out : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL s_ir_opcode_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_pc_en      : STD_LOGIC;
    SIGNAL s_ir_load_en : STD_LOGIC;
    SIGNAL s_halt_out   : STD_LOGIC;
    SIGNAL s_dummy_vec8 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_dummy_vec7 : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL sim_stop : BOOLEAN := FALSE;
    
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    
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

    FUNCTION to_hex_24bit_unsigned (vec : IN UNSIGNED(23 DOWNTO 0)) RETURN STRING IS
    VARIABLE result_str : STRING(1 TO 6);
    
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
        result_str(1) := nybble_to_char(vec(23 DOWNTO 20));
        result_str(2) := nybble_to_char(vec(19 DOWNTO 16));
        
        result_str(3) := nybble_to_char(vec(15 DOWNTO 12));
        result_str(4) := nybble_to_char(vec(11 DOWNTO 8)); 
        
        result_str(5) := nybble_to_char(vec(7 DOWNTO 4));   
        result_str(6) := nybble_to_char(vec(3 DOWNTO 0));   
        
        RETURN result_str;
    END FUNCTION to_hex_24bit_unsigned;

    FUNCTION to_hex_24bit_slv (vec : IN STD_LOGIC_VECTOR(23 DOWNTO 0)) RETURN STRING IS
    BEGIN
        RETURN to_hex_24bit_unsigned(UNSIGNED(vec));
    END FUNCTION to_hex_24bit_slv;

BEGIN

    UUT_PC : Program_Counter
        PORT MAP (
            clk         => tb_clk, rst         => tb_reset,
            pc_en       => s_pc_en, pc_load_en  => '0',
            data_in     => (OTHERS => '0'),
            pc_out      => s_pc_addr_out
        );
        
    UUT_Mem : Instruction_Memory
        PORT MAP (
            Address  => s_pc_addr_out,
            Data_Out => s_mem_data_out
        );
        
    UUT_IR : Instruction_Register
        PORT MAP (
            clk        => tb_clk, rst        => tb_reset,
            ir_load_en => s_ir_load_en,
            data_in    => s_mem_data_out,
            opcode_out => s_ir_opcode_out
        );

    UUT_Control_Unit : control_unit
        PORT MAP (
            clk                 => tb_clk,
            reset               => tb_reset,
            opcode_in           => s_ir_opcode_out,
            A                   => s_dummy_vec8,
            flags_in            => s_dummy_vec7,
            pc_en               => s_pc_en,
            ir_load_en          => s_ir_load_en,
            halt_out            => s_halt_out,
            rf_write_en         => OPEN, alu_op              => OPEN,
            alu_src_b_sel       => OPEN, shifter_ctrl_out    => OPEN,
            reg_write_src_sel   => OPEN, ld_alu_flags_out    => OPEN,
            ld_shf_flags_out    => OPEN
        );

    Clock_Process : PROCESS
    BEGIN
        IF sim_stop THEN
            WAIT;
        END IF;
    
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
        
    END PROCESS Clock_Process;

    Stimulus_Process : PROCESS
        CONSTANT CYCLES_TO_RUN : INTEGER := 30; 
    BEGIN
        REPORT "--- Testbench (FIXED_CYCLES / Async Reset) iniciado ---";
        
        tb_reset <= '1';
        WAIT FOR 12 ns; 
        tb_reset <= '0';
        
        FOR i IN 1 TO CYCLES_TO_RUN LOOP
            WAIT UNTIL rising_edge(tb_clk);
            WAIT FOR 1 ns; 
            
            REPORT "Ciclo " & INTEGER'IMAGE(i) & ": " & 
                   "PC=" & to_hex_8bit_unsigned(s_pc_addr_out) &
                   ", MEM_Out=" & to_hex_24bit_slv(s_mem_data_out) & 
                   ", IR_Out=" & to_hex_8bit_slv(s_ir_opcode_out) &
                   ", pc_en=" & STD_LOGIC'IMAGE(s_pc_en) &
                   ", ir_load_en=" & STD_LOGIC'IMAGE(s_ir_load_en);
        END LOOP;
        
        REPORT "--- Fim da Simulação (limite de " & INTEGER'IMAGE(CYCLES_TO_RUN) & " ciclos atingido) ---";
        
        sim_stop <= TRUE;
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;