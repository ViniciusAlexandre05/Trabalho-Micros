LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY processor_tb IS
END processor_tb;

ARCHITECTURE structure OF processor_tb IS

    CONSTANT C_CLK_PERIOD : TIME := 10 ns;

    --Declaracao
    COMPONENT control_unit IS
        PORT (
            clk         : IN  STD_LOGIC;
            reset       : IN  STD_LOGIC;
            opcode_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            flags_in    : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
            A           : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
            pc_en       : OUT STD_LOGIC;
            ir_load_en  : OUT STD_LOGIC;
            rf_write_en : OUT STD_LOGIC;
            reg_write_addr : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); 
            alu_op      : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            alu_src_b_sel : OUT STD_LOGIC;
            shifter_ctrl_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            reg_write_src_sel : OUT STD_LOGIC;
            ld_alu_flags_out  : OUT STD_LOGIC;
            ld_shf_flags_out  : OUT STD_LOGIC;
            halt_out    : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Instruction_Memory IS
        PORT ( 
            Address  : IN  UNSIGNED(7 DOWNTO 0); 
            Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0) );
    END COMPONENT;

    COMPONENT Instruction_Register IS
        PORT ( 
            clk : IN STD_LOGIC; 
            rst : IN STD_LOGIC; 
            ir_load_en : IN STD_LOGIC; 
            data_in : IN STD_LOGIC_VECTOR(23 DOWNTO 0); 
            opcode_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            op1_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            op2_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT Program_Counter IS
        PORT ( 
            clk : IN STD_LOGIC; 
            rst : IN STD_LOGIC; 
            pc_en : IN STD_LOGIC; 
            pc_load_en : IN STD_LOGIC; 
            data_in : IN UNSIGNED(7 DOWNTO 0); 
            pc_out : OUT UNSIGNED(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT regfile IS
        PORT ( 
            clk  : IN STD_LOGIC; 
            rst  : IN STD_LOGIC; 
            we   : IN STD_LOGIC; 
            addr : IN UNSIGNED(1 DOWNTO 0); 
            data : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
            q_0  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            q_1  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            q_2  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            q_3  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT mux_a IS
        PORT ( 
            q_0, q_1, q_2, q_3 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
            sel : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); 
            reg_a_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT mux_b_reg IS
        PORT ( q_0, q_1, q_2, q_3 : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); 
        sel : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); 
        reg_b_data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT mux_b_final IS
        PORT ( 
        reg_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        imm_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        sel : IN STD_LOGIC; 
        operand_b_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT mux_WB IS
        PORT ( 
            reg_write_src_sel : IN STD_LOGIC; 
            alu_result_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
            shifter_result_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
            rf_write_data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) );
    END COMPONENT;

    COMPONENT ULA IS
        PORT ( 
            A : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
            B : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
            ALU_Sel : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
            Resultado : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            Flags : OUT STD_LOGIC_VECTOR(4 DOWNTO 0) );
    END COMPONENT;
    COMPONENT BitShifter IS
        PORT ( 
            Data_In : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
            Shift_Ctrl : IN STD_LOGIC_VECTOR(1 DOWNTO 0); 
            Data_Out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
            shf_flags_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) );
    END COMPONENT;

    COMPONENT Flag_Register IS
        PORT ( 
            clk : IN STD_LOGIC; 
            rst : IN STD_LOGIC; 
            ld_alu_flags : IN STD_LOGIC; 
            ld_shf_flags : IN STD_LOGIC; 
            alu_flags_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
            shf_flags_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
            R_FLAGS : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) );
    END COMPONENT;

    SIGNAL tb_clk  : STD_LOGIC := '0';
    SIGNAL tb_rst  : STD_LOGIC := '0';
    SIGNAL tb_halt : STD_LOGIC;

    SIGNAL s_pc_en       : STD_LOGIC;
    SIGNAL s_ir_load_en  : STD_LOGIC;
    SIGNAL s_rf_write_en : STD_LOGIC;
    SIGNAL s_rf_write_addr : STD_LOGIC_VECTOR(1 DOWNTO 0); 
    SIGNAL s_alu_op      : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL s_alu_src_b_sel : STD_LOGIC;
    SIGNAL s_shifter_ctrl_out : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL s_reg_write_src_sel : STD_LOGIC;
    SIGNAL s_ld_alu_flags : STD_LOGIC;
    SIGNAL s_ld_shf_flags : STD_LOGIC;
    
    SIGNAL s_pc_out          : UNSIGNED(7 DOWNTO 0);
    SIGNAL s_im_data_out     : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL s_ir_opcode       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_ir_op1          : STD_LOGIC_VECTOR(7 DOWNTO 0); 
    SIGNAL s_ir_op2          : STD_LOGIC_VECTOR(7 DOWNTO 0); 
    SIGNAL s_rf_q0           : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_rf_q1           : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_rf_q2           : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_rf_q3           : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_mux_a_out       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_mux_b_reg_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_mux_b_final_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_alu_result      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_alu_flags       : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL s_shf_result      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_shf_flags       : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_mux_wb_out      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_flags_out       : STD_LOGIC_VECTOR(6 DOWNTO 0);


BEGIN
    -- Instanciação
    CU_inst : COMPONENT control_unit
        PORT MAP (
            clk         => tb_clk,
            reset       => tb_rst,
            opcode_in   => s_ir_opcode,
            flags_in    => s_flags_out,
            A           => s_ir_op1,
            pc_en       => s_pc_en,
            ir_load_en  => s_ir_load_en,
            rf_write_en => s_rf_write_en,
            reg_write_addr => s_rf_write_addr, 
            alu_op      => s_alu_op,
            alu_src_b_sel => s_alu_src_b_sel,
            shifter_ctrl_out => s_shifter_ctrl_out,
            reg_write_src_sel => s_reg_write_src_sel,
            ld_alu_flags_out  => s_ld_alu_flags,
            ld_shf_flags_out  => s_ld_shf_flags,
            halt_out    => tb_halt
        );

    PC_inst : COMPONENT Program_Counter
        PORT MAP (
            clk        => tb_clk,
            rst        => tb_rst,
            pc_en      => s_pc_en,
            pc_load_en => '0', 
            data_in    => (OTHERS => '0'),
            pc_out     => s_pc_out
        );

    IM_inst : COMPONENT Instruction_Memory
        PORT MAP (
            Address  => s_pc_out,
            Data_Out => s_im_data_out
        );

    IR_inst : COMPONENT Instruction_Register
        PORT MAP (
            clk        => tb_clk,
            rst        => tb_rst,
            ir_load_en => s_ir_load_en,
            data_in    => s_im_data_out,
            opcode_out => s_ir_opcode,
            op1_out    => s_ir_op1,
            op2_out    => s_ir_op2
        );

    RF_inst : COMPONENT regfile
        PORT MAP (
            clk  => tb_clk,
            rst  => tb_rst,
            we   => s_rf_write_en,
            addr => UNSIGNED(s_rf_write_addr), 
            data => s_mux_wb_out,
            q_0  => s_rf_q0,
            q_1  => s_rf_q1,
            q_2  => s_rf_q2,
            q_3  => s_rf_q3
        );

    MUX_A_inst : COMPONENT mux_a
        PORT MAP (
            q_0       => s_rf_q0,
            q_1       => s_rf_q1,
            q_2       => s_rf_q2,
            q_3       => s_rf_q3,
            sel       => s_ir_op1(1 DOWNTO 0), 
            reg_a_out => s_mux_a_out
        );
        
    MUX_B_REG_inst : COMPONENT mux_b_reg
        PORT MAP ( 
            q_0 => s_rf_q0, 
            q_1 => s_rf_q1, 
            q_2 => s_rf_q2, 
            q_3 => s_rf_q3, 
            sel => s_ir_op2(1 DOWNTO 0), 
            reg_b_data_out => s_mux_b_reg_out 
        );

    MUX_B_FINAL_inst : COMPONENT mux_b_final
        PORT MAP ( 
            reg_in => s_mux_b_reg_out,
            imm_in => s_ir_op2, sel => s_alu_src_b_sel, 
            operand_b_out => s_mux_b_final_out 
        );

    ULA_inst : COMPONENT ULA
        PORT MAP ( 
            A => s_mux_a_out, 
            B => s_mux_b_final_out, 
            ALU_Sel => s_alu_op, 
            Resultado => s_alu_result, 
            Flags => s_alu_flags 
        );

    SHF_inst : COMPONENT BitShifter
        PORT MAP ( 
            Data_In => s_mux_a_out, 
            Shift_Ctrl => s_shifter_ctrl_out, 
            Data_Out => s_shf_result, 
            shf_flags_out => s_shf_flags 
        );

    MUX_WB_inst : COMPONENT mux_WB
        PORT MAP ( 
            reg_write_src_sel => s_reg_write_src_sel, 
            alu_result_in => s_alu_result, 
            shifter_result_in => s_shf_result, 
            rf_write_data_out => s_mux_wb_out 
        );

    FR_inst : COMPONENT Flag_Register
        PORT MAP ( 
            clk => tb_clk, 
            rst => tb_rst, 
            ld_alu_flags => s_ld_alu_flags, 
            ld_shf_flags => s_ld_shf_flags, 
            alu_flags_in => s_alu_flags, 
            shf_flags_in => s_shf_flags, 
            R_FLAGS => s_flags_out 
        );

    clk_process : PROCESS
    BEGIN
        tb_clk <= '0'; WAIT FOR C_CLK_PERIOD / 2;
        tb_clk <= '1'; WAIT FOR C_CLK_PERIOD / 2;
        IF tb_halt = '1' THEN WAIT; END IF;
    END PROCESS;

    stim_process : PROCESS --reset
    BEGIN
        tb_rst <= '1';
        WAIT FOR C_CLK_PERIOD * 2; 
        tb_rst <= '0';
        WAIT; 
    END PROCESS;

END structure;