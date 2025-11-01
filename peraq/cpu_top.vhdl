LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Esta é a "Fase 1": O esqueleto do seu processador
-- Ele junta o PC, a Memória de ROM, o IR e a UDC.
ENTITY cpu_top IS
    PORT (
        clk      : IN  STD_LOGIC;
        reset    : IN  STD_LOGIC;
        
        -- Saída de controle para o testbench poder parar a simulação
        halt_out : OUT STD_LOGIC
    );
END cpu_top;

ARCHITECTURE structural OF cpu_top IS

    -- === 1. DECLARAÇÃO DE TODOS OS COMPONENTES ===

    -- Unidade de Controle (UDC)
    COMPONENT control_unit IS
        PORT (
            clk                 : IN  STD_LOGIC;
            reset               : IN  STD_LOGIC;
            opcode_in           : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
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

    -- Contador de Programa (PC)
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

    -- Memória de Instruções (ROM)
    COMPONENT Instruction_Memory IS
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;
    
    -- Registrador de Instrução (IR)
    COMPONENT Instruction_Register IS
        PORT (
            clk        : IN  STD_LOGIC;
            rst        : IN  STD_LOGIC;
            ir_load_en : IN  STD_LOGIC;
            data_in    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            opcode_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            op1_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            op2_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    --ULA
    COMPONENT ULA IS
    PORT (
        A         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        B         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        ALU_Sel   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        Resultado : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        Flags     : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
    END COMPONENT;

    --Movimentc bit
    COMPONENT movimentacao_bits IS
        PORT (
            -- sinais de controle
            clk             : IN  STD_LOGIC;
            reset           : IN  STD_LOGIC;
            -- barramento de dados de 8 bits
            entrada         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            saida           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            -- SINAIS DE CONTROLE DO DECODER
            decoder_mov     : IN  STD_LOGIC;
            decoder_shift_l : IN  STD_LOGIC;
            decoder_shift_r : IN  STD_LOGIC;
            decoder_set_bit : IN  STD_LOGIC;
            decoder_bit_pos : IN  STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    --Regfile
    COMPONENT regfile IS
        PORT (
            clk          : IN  STD_LOGIC;
            rst          : IN  STD_LOGIC;
            we           : IN  STD_LOGIC;
            addr         : IN  UNSIGNED(1 DOWNTO 0);      -- 2 bits (4 registradores)
            data         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_0          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_1          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_2          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            q_3          : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    --MUX src B
    COMPONENT mux_alu_src_b IS
    PORT (
        -- Entradas de dados
        data_reg_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Valor do registrador
        data_op2_in   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Valor imediato (op2)
        
        -- Sinal de controle da UC
        alu_src_b_sel : IN  STD_LOGIC;                     -- 0=registrador, 1=immediate
        
        -- Saída
        data_out      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)   -- Para ALU
    );
    END COMPONENT mux_alu_src_b;
    
    -- === 2. SINAIS DE CONEXÃO (FIOS) ===
    
    -- Fio: PC -> Memória
    SIGNAL s_pc_addr_out : UNSIGNED(7 DOWNTO 0);
    
    -- Fio: Memória -> IR
    SIGNAL s_mem_data_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Fio: IR -> UDC
    SIGNAL s_ir_opcode_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

    --Fios: IR -> ULA
    signal s_ir_op1_out : STD_LOGIC_VECTOR(7 downto 0);
    signal s_ir_op2_out : STD_LOGIC_VECTOR(7 downto 0);
    
    -- Fios: UDC -> ULA
    SIGNAL s_alu_op        : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL s_alu_data_out  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL s_alu_flags_out : STD_LOGIC_VECTOR(4 DOWNTO 0);


    -- Fios: UDC -> PC e UDC -> IR
    SIGNAL s_pc_en      : STD_LOGIC;
    SIGNAL s_ir_load_en : STD_LOGIC;
    
    -- Fios: UDC -> MUXs
    SIGNAL s_rf_data_b_out  : STD_LOGIC_VECTOR(7 downto 0); -- Dado do registrador B
    SIGNAL s_alu_src_b_sel  : STD_LOGIC;                    -- Controle da UC
    SIGNAL s_alu_src_b_data : STD_LOGIC_VECTOR(7 downto 0); -- Saída do MUX para ALU

    -- Sinais "Dummy" (para amarrar portas não usadas da UDC nesta fase)
    SIGNAL s_dummy_A_in     : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_dummy_flags_in : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');

BEGIN

    -- === 3. INSTANCIAÇÃO DOS COMPONENTES ===

    -- 1. O Contador de Programa (PC)
    UUT_PC : Program_Counter
        PORT MAP (
            clk         => clk,            -- Entrada do Testbench
            rst         => reset,          -- Entrada do Testbench
            pc_en       => s_pc_en,        -- Fio vindo da UDC
            pc_load_en  => '0',            -- Amarrado em '0' (Jumps são Fase 5)
            data_in     => (OTHERS => '0'),-- Amarrado em '0' (Jumps são Fase 5)
            pc_out      => s_pc_addr_out   -- Saída vai para a Memória
        );
        
    -- 2. A Memória de Instruções (ROM)
    UUT_Mem : Instruction_Memory
        PORT MAP (
            Address  => s_pc_addr_out, -- Entrada vem do PC
            Data_Out => s_mem_data_out -- Saída vai para o IR
        );
        
    -- 3. O Registrador de Instrução (IR)
    UUT_IR : Instruction_Register
        PORT MAP (
            clk        => clk,            -- Entrada do Testbench
            rst        => reset,          -- Entrada do Testbench
            ir_load_en => s_ir_load_en,   -- Fio vindo da UDC
            data_in    => s_mem_data_out, -- Entrada vem da Memória
            opcode_out => s_ir_opcode_out, -- Saída vai para a UDC
            op1_out    => s_ir_op1_out,
            op2_out    => s_ir_op2_out
        );

    -- 4. A Unidade de Controle (UDC)
    UUT_Control_Unit : control_unit
        PORT MAP (
            clk                 => clk,
            reset               => reset,
            opcode_in           => s_ir_opcode_out,   -- Entrada vem do IR
            flags_in            => s_dummy_flags_in,  -- Amarrado (Fase 5)
            
            -- Saídas do Ciclo de Busca
            pc_en               => s_pc_en,           -- Saída vai para o PC
            ir_load_en          => s_ir_load_en,      -- Saída vai para o IR
            halt_out            => halt_out,          -- Saída vai para o Testbench
            
            -- Saídas não usadas nesta Fase (deixamos "abertas")
            rf_write_en         => OPEN,
            alu_op              => s_alu_op,
            alu_src_b_sel => s_alu_src_b_sel,
            shifter_ctrl_out    => OPEN,
            reg_write_src_sel   => OPEN,
            ld_alu_flags_out    => OPEN,
            ld_shf_flags_out    => OPEN
        );

    -- 5. ULA
    UUT_ULA : ULA
        PORT MAP (
            A         => open,    -- definir, vem do mux a?
            B         => open,   -- definir Do mux src B?  
            ALU_Sel   => s_alu_op,           -- Da Control Unit  
            Resultado => open,     -- definir Para mux que seleciona saida
            Flags     => s_alu_flags_out     -- definir: Para Control Unit?
    );

    -- 6. Movimentação de Bit
    UUT_Shifter : movimentacao_bits
        PORT MAP (
            clk             => clk,
            reset           => reset,
            entrada         => open,
            saida           => open, -- Saída para mux que seleciona esse ou ula p/ reg file
            -- Sinais de controle
            decoder_mov     => s_decoder_mov, --definir: encaixar isso nos comandos uc
            decoder_shift_l => s_decoder_shift_l, 
            decoder_shift_r => s_decoder_shift_r,
            decoder_set_bit => s_decoder_set_bit,
            decoder_bit_pos => s_decoder_bit_pos
        );

    -- 7. Regfile
    UUT_Register_File : regfile
        PORT MAP (
            clk  => clk,
            rst  => reset,
            we   => OPEN, --definir: vemda uc
            addr => OPEN, --defnir: uc?
            data => OPEN, --definir: saída do mux de saida
            q_0  => OPEN, --definir: muxs a e b
            q_1  => OPEN,
            q_2  => OPEN,
            q_3  => OPEN
        );

    --Mux que seleciona se B imediato ou reg
    UUT_MUX_ALU_SRC_B : mux_alu_src_b
        PORT MAP (
            data_reg_in   => s_rf_data_b_out,   -- definir vem do mux b
            data_op2_in   => s_ir_op2_out,      -- Valor imediato da instrução
            alu_src_b_sel => s_alu_src_b_sel,   -- Controle da UC
            data_out      => s_alu_src_b_data   -- Para entrada B da ALU e/ou do shifter
        );
END structural;