library ieee;
use ieee.std_logic_1164.all;

-- A entidade da Unidade de Controle
entity control_unit is
    port (
        -- Entradas
        clk        : in  std_logic;
        reset      : in  std_logic;
        opcode_in  : in  std_logic_vector(7 downto 0); -- Vindo do IR[23:16]
        operand1   : in  std_logic_vector(7 downto 0); -- Vindo do IR[15:8]
        operand2   : in  std_logic_vector(7 downto 0); -- Vindo do IR[7:0]
        
        -- Saídas de Controle (Sinais para o seu Datapath)
        -- (Estes são exemplos, você deve adaptá-los)
        
        -- Controle do PC e IR
        pc_en          : out std_logic; -- '1' = PC + 1 (ou carrega em desvio)
        ir_load_en     : out std_logic; -- '1' = Carrega IR com a instrução vinda da pseudo "MEM"

        -- Controle do Banco de Registradores
        --rf_write_en    : out std_logic; -- '1' = Habilita escrita no registrador 'Rd' NÃO VAI SER ASSIM, UC CONTROLA TODOS OS REGISTRADORES (MENOS OS DE FLAG)
        
        -- Controle da ALU
        ALU_Sel         : out std_logic_vector(4 downto 0); -- Código da operação da ALU
        A               : out std_logic_vector(7 downto 0);
        B               : out std_logic_vector(7 downto 0);
        Resultado       : in std_logic_vector(7 downto 0);

        --alu_src_b_sel  : out std_logic; -- '0' = Fonte é Reg 'Rb'; '1' = Fonte é Imediato UC QUEM VAI VER ISSO
        -- Controle do Resultado (MUX de escrita)
        --reg_write_src_sel : out std_logic; -- '0' = Resultado vem da ALU; '1' = Vem do I/O (futuro) NÃO SEI SE PRECISA
        
        -- Controle Movimentacao de Bit
        entrada          : out std_logic_vector(7 downto 0);
        saida            : in std_logic_vector(7 downto 0);

        decoder_mov     : out std_logic_vector(7 downto 0);
        decoder_shift_l : out std_logic_vector(7 downto 0);
        decoder_shift_r : out std_logic_vector(7 downto 0);
        decoder_set_bit : out std_logic_vector(7 downto 0);
        decoder_bit_pos : out std_logic_vector(7 downto 0);

        --Controle dos Registradores
        we_reg          : out std_logic_vector(7 downto 0);
        addr_reg        : out std_logic_vector(7 downto 0);
        data_reg        : out std_logic_vector(7 downto 0);

        q_0             : in std_logic_vector(7 downto 0);
        q_1             : in std_logic_vector(7 downto 0);
        q_2             : in std_logic_vector(7 downto 0);
        q_3             : in std_logic_vector(7 downto 0);

        --Controle das Flags
        LD_ZF           : out std_logic_vector(7 downto 0);
        LD_CF           : out std_logic_vector(7 downto 0);
        LD_SF           : out std_logic_vector(7 downto 0);
        LD_RF           : out std_logic_vector(7 downto 0);
        LD_IF           : out std_logic_vector(7 downto 0);
        LD_DF           : out std_logic_vector(7 downto 0);
        LD_OF           : out std_logic_vector(7 downto 0);

        set_IF          : out std_logic_vector(7 downto 0);
        set_DF          : out std_logic_vector(7 downto 0);
       -- Controle do Processador
        halt_out       : out std_logic  -- '1' = Para o processador
    );
end entity control_unit;

architecture fsm of control_unit is

    -- 1. Definição dos Estados da FSM (Ciclo Multi-Ciclo)
    type state_type is (
        S_RESET,
        S_FETCH,          -- Busca instrução da ROM (requer 1 ciclo)
        S_DECODE,         -- Decodifica o opcode_in (1 ciclo)
        S_EXECUTE,        -- Executa a operação na ALU (1 ciclo)
        S_WRITEBACK,      -- Escreve o resultado no registrador (1 ciclo)
        S_HALT            -- Estado de parada
    );
    signal state : state_type;

    -- 2. Constantes para Opcodes  (para legibilidade)
    -- Grupo: Controle
    constant OP_NOP  : std_logic_vector(7 downto 0) := x"00";
    constant OP_HALT : std_logic_vector(7 downto 0) := x"01";
    -- Grupo: Mov.
    constant OP_MOV_REG : std_logic_vector(7 downto 0) := x"10";
    constant OP_MOV_IMM : std_logic_vector(7 downto 0) := x"11";
    -- Grupo: ULA Aritmética (Reg)
    constant OP_ADD : std_logic_vector(7 downto 0) := x"40";
    constant OP_SUB : std_logic_vector(7 downto 0) := x"41";
    constant OP_MUL : std_logic_vector(7 downto 0) := x"42";
    constant OP_DIV : std_logic_vector(7 downto 0) := x"43";
    constant OP_MOD : std_logic_vector(7 downto 0) := x"44";
    constant OP_INC : std_logic_vector(7 downto 0) := x"45";
    constant OP_DEC : std_logic_vector(7 downto 0) := x"46";
    -- Grupo: ULA Aritmética (Imm)
    constant OP_ADD_IMM : std_logic_vector(7 downto 0) := x"50";
    constant OP_SUB_IMM : std_logic_vector(7 downto 0) := x"51";
    -- Grupo: ULA Lógica (Reg)
    constant OP_AND : std_logic_vector(7 downto 0) := x"60";
    constant OP_OR  : std_logic_vector(7 downto 0) := x"61";
    constant OP_NOT : std_logic_vector(7 downto 0) := x"62";
    constant OP_XOR : std_logic_vector(7 downto 0) := x"63";
    -- Grupo: ULA Lógica (Imm)
    constant OP_AND_IMM : std_logic_vector(7 downto 0) := x"68";
    constant OP_OR_IMM  : std_logic_vector(7 downto 0) := x"69";
    constant OP_XOR_IMM : std_logic_vector(7 downto 0) := x"6A";
    -- Grupo: ULA Shift / Bit
    constant OP_SHL : std_logic_vector(7 downto 0) := x"70";
    constant OP_SHR : std_logic_vector(7 downto 0) := x"71";
    constant OP_SET : std_logic_vector(7 downto 0) := x"72";
    constant OP_CLR : std_logic_vector(7 downto 0) := x"73";
    constant OP_TST : std_logic_vector(7 downto 0) := x"74";
    -- Grupo: ULA Comparação
    constant OP_CMP_REG : std_logic_vector(7 downto 0) := x"78";
    constant OP_CMP_IMM : std_logic_vector(7 downto 0) := x"79";

    -- 3. Constantes para os sinais da ALU (Exemplos)
    constant ALU_OP_ADD  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_OP_SUB  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OP_AND  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_OP_OR   : std_logic_vector(3 downto 0) := "0100";
    constant ALU_OP_XOR  : std_logic_vector(3 downto 0) := "0101";
    constant ALU_OP_NOT  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_OP_SHL  : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OP_SHR  : std_logic_vector(3 downto 0) := "1000";
    constant ALU_OP_INC  : std_logic_vector(3 downto 0) := "1001";
    constant ALU_OP_DEC  : std_logic_vector(3 downto 0) := "1010";
    constant ALU_OP_PASS_B : std_logic_vector(3 downto 0) := "1011"; -- Para MOV

    -- 4. Constantes para os registradores
    constant REG0 : std_logic_vector(7 downto 0) := "00000000";
    constant REG1 : std_logic_vector(7 downto 0) := "00000001";
    constant REG2 : std_logic_vector(7 downto 0) := "00000010";
    constant REG3 : std_logic_vector(7 downto 0) := "00000011";

begin

    -- 3. Processo principal da FSM (Síncrono - Define o próximo estado)
    process (clk, reset)
    begin
        if reset = '1' then
            state <= S_RESET;
        elsif rising_edge(clk) then
        
            case state is
            
                when S_RESET =>
                    state <= S_FETCH;
                    
                when S_FETCH =>
                    state <= S_DECODE; -- Transição incondicional

                when S_DECODE =>
                    -- Após decodificar, todas as instruções vão para Execução
                    -- Exceto HALT, que vai para S_HALT
                    if opcode_in = OP_HALT then 
                        state <= S_HALT;
                    else
                        state <= S_EXECUTE;
                    end if;

                when S_EXECUTE =>
                    -- Decidimos se precisamos escrever no registrador
                    case opcode_in is

                        -- Operações que NÃO fazem nada (NOP ou ignoradas)
                        when OP_NOP => 
                            state <= S_FETCH;
                            
                        -- Todas as outras vão para o Writeback
                        when others =>
                            state <= S_WRITEBACK;
                    end case;
                    
                when S_WRITEBACK =>
                    state <= S_FETCH; -- Volta para o início

                when S_HALT =>
                    state <= S_HALT; -- Permanece parado

            end case;
        end if;
    end process;

    -- 4. Lógica de Saída (Combinacional - Define os sinais de controle)
    -- Define os sinais de controle com base no ESTADO ATUAL
    process (
        state,
        opcode_in, operand1, operand2, 
        q_0, q_1, q_2, q_3, saida) --saida na vdd é in, vem da movimentação de bit
    begin
        -- --- VALORES PADRÃO (INATIVOS) ---
        -- Define todos os sinais como '0' (inativos) por padrão
        -- Isso evita a inferência de latches e é a prática mais segura
        pc_en          <= '0';
        ir_load_en     <= '0';
        ALU_Sel         <= "0000"; -- NOP da ALU
        halt_out       <= '0';

        -- --- ATIVA SINAIS COM BASE NO ESTADO ATUAL ---
        case state is
        
            when S_FETCH =>
                -- Habilita o PC para incrementar (PC = PC + 1)
                pc_en      <= '1';
                -- Habilita o IR para carregar a nova instrução
                ir_load_en <= '1';
                
            when S_DECODE =>
                -- Nenhum sinal ativo. Apenas gasta um ciclo para a lógica
                -- de decodificação estabilizar (se necessário).
                null;
                
            when S_EXECUTE =>
                -- Este é o estado principal.
                -- Decodifica o opcode_in para configurar a ALU
                
                -- 1. Seleciona a Fonte B da ALU
                -- É um imediato ou um registrador?
                case opcode_in is
                    when OP_MOV_IMM | OP_ADD_IMM | OP_SUB_IMM | OP_AND_IMM |
                         OP_OR_IMM | OP_XOR_IMM | OP_CMP_IMM => --não sei
                    when others =>
                        
                end case;
                
                -- 2. Define a Operação da ALU
                case opcode_in is
                    -- Aritmética
                    when OP_ADD | OP_ADD_IMM => ALU_Sel <= ALU_OP_ADD; 
                    when OP_SUB | OP_SUB_IMM | OP_CMP_REG | OP_CMP_IMM => ALU_Sel <= ALU_OP_SUB; 
                    when OP_INC => ALU_Sel <= ALU_OP_INC; 
                    when OP_DEC => ALU_Sel <= ALU_OP_DEC; 
                    -- Lógica
                    when OP_AND | OP_AND_IMM | OP_TST => ALU_Sel <= ALU_OP_AND; 
                    when OP_OR  | OP_OR_IMM  => ALU_Sel <= ALU_OP_OR; 
                    when OP_XOR | OP_XOR_IMM => ALU_Sel <= ALU_OP_XOR; 
                    when OP_NOT => ALU_Sel <= ALU_OP_NOT; 
                    -- Movimentação
                    when OP_MOV_REG => -- MOV[OPCODE] destination[OPERND1], source [OPERAND2]
                        case operand1 is
                            when REG0 => destination := "00";
                            when REG1 => destination := "01";
                            when REG2 => destination := "10";
                            when others => destination := "11";
                        end case;

                        case operand2 is
                            when REG0 => source := q_0;
                            when REG1 => source := q_1;
                            when REG2 => source := q_2;
                            when others => source := q_3;
                        end case;
                        
                        data_reg <= operand2;
                        addr_reg <= destination; --(R0 = 00; R1 = 01; R2 = 10; R3 =11)
                        we_reg <= 1;
                        
                    when OP_MOV_IMM => ALU_Sel <= ALU_OP_PASS_B; -- ALU faz "resultado = Imediato"
                    -- Shift
                    when OP_SHL => ALU_Sel <= ALU_OP_SHL; 
                    when OP_SHR => ALU_Sel <= ALU_OP_SHR; 

                    --Comparação e teste
                    when OP_CMP_REG => --definir
                    when OP_CMP_IMM => --definir
                    when OP_TST => --definir
                    
                    -- MUL, DIV, MOD, SET, CLR não foram implementados neste exemplo
                    when others => null;
                end case;

            when S_WRITEBACK =>
                -- Habilita a escrita no banco de registradores
                --rf_write_en <= '1';
                -- Seleciona a fonte dos dados (vem da ALU)
                --reg_write_src_sel <= '0'; 
                
            when S_HALT =>
                -- Ativa o sinal de parada
                halt_out <= '1';

            when others =>
                null;

        end case;
    end process;

end architecture fsm;
