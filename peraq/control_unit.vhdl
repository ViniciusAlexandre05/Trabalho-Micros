library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- UNIDADE DE CONTROLE (VERSÃO FINAL)
-- Correção: Agora força a escrita no R3 ("11")
entity control_unit is
    port (
        -- Entradas
        clk         : in  std_logic;
        reset       : in  std_logic;
        opcode_in   : in  std_logic_vector(7 downto 0); 
        flags_in    : in  std_logic_vector(6 downto 0);
        
        -- Saídas de Controle
        pc_en       : out std_logic;
        ir_load_en  : out std_logic;
        rf_write_en : out std_logic;
        
        -- CORREÇÃO: Nova porta para o endereço de escrita
        reg_write_addr : out std_logic_vector(1 downto 0); -- Força o R3

        -- Controle da ALU
        alu_op      : out std_logic_vector(4 downto 0);
        alu_src_b_sel : out std_logic;

        -- Controle do Shifter
        shifter_ctrl_out  : out std_logic_vector(1 downto 0);
        reg_write_src_sel : out std_logic;
        
        -- Controle de Carga dos Flags
        ld_alu_flags_out  : out std_logic;
        ld_shf_flags_out  : out std_logic;
        halt_out          : out std_logic
    );
end entity control_unit;

architecture fsm of control_unit is

    type state_type is (
        S_RESET, S_FETCH, S_DECODE, S_EXECUTE, S_WRITEBACK, S_HALT
    );
    signal state : state_type; 
    
    -- Macros: Opcodes
    constant OP_NOP     : std_logic_vector(7 downto 0) := x"00";
    constant OP_HALT    : std_logic_vector(7 downto 0) := x"01";
    constant OP_MOV_REG : std_logic_vector(7 downto 0) := x"10";
    constant OP_MOV_IMM : std_logic_vector(7 downto 0) := x"11";
    constant OP_ADD     : std_logic_vector(7 downto 0) := x"40";
    constant OP_SUB     : std_logic_vector(7 downto 0) := x"41";
    constant OP_AND     : std_logic_vector(7 downto 0) := x"42";
    constant OP_OR      : std_logic_vector(7 downto 0) := x"43";
    constant OP_XOR     : std_logic_vector(7 downto 0) := x"44";
    constant OP_NOT     : std_logic_vector(7 downto 0) := x"45";
    constant OP_CMP     : std_logic_vector(7 downto 0) := x"47";
    constant OP_NAND    : std_logic_vector(7 downto 0) := x"48";
    constant OP_NOR     : std_logic_vector(7 downto 0) := x"49";
    constant OP_XNOR    : std_logic_vector(7 downto 0) := x"4A";
    constant OP_PASS_B  : std_logic_vector(7 downto 0) := x"4B";
    constant OP_ADD_IMM : std_logic_vector(7 downto 0) := x"50";
    constant OP_SUB_IMM : std_logic_vector(7 downto 0) := x"51";
    constant OP_AND_IMM : std_logic_vector(7 downto 0) := x"62";
    constant OP_OR_IMM  : std_logic_vector(7 downto 0) := x"63";
    constant OP_XOR_IMM : std_logic_vector(7 downto 0) := x"64";
    constant OP_SHL     : std_logic_vector(7 downto 0) := x"70";
    constant OP_SHR     : std_logic_vector(7 downto 0) := x"71";
    constant OP_CMP_REG : std_logic_vector(7 downto 0) := x"78";
    constant OP_CMP_IMM : std_logic_vector(7 downto 0) := x"79";

    -- Macros: Operações da ALU
    constant ALU_OP_ADD    : std_logic_vector(4 downto 0) := "00000";
    constant ALU_OP_SUB    : std_logic_vector(4 downto 0) := "00001";
    constant ALU_OP_CMP    : std_logic_vector(4 downto 0) := "00010";
    constant ALU_OP_AND    : std_logic_vector(4 downto 0) := "00110";
    constant ALU_OP_OR     : std_logic_vector(4 downto 0) := "00111";
    constant ALU_OP_XOR    : std_logic_vector(4 downto 0) := "01000";
    constant ALU_OP_NOT    : std_logic_vector(4 downto 0) := "01001";
    constant ALU_OP_NAND   : std_logic_vector(4 downto 0) := "01110";
    constant ALU_OP_NOR    : std_logic_vector(4 downto 0) := "01111";
    constant ALU_OP_XNOR   : std_logic_vector(4 downto 0) := "10000";
    constant ALU_OP_PASS_B : std_logic_vector(4 downto 0) := "10001";

begin
    
    -- Processo 1: Lógica Síncrona (Reset Síncrono e rising_edge)
    process (clk)
    begin
        if rising_edge(clk) then 
            if reset = '1' then
                state <= S_RESET;
            else
                case state is
                    when S_RESET =>
                        state <= S_FETCH;
                    when S_FETCH =>
                        state <= S_DECODE;
                    when S_DECODE =>
                        if opcode_in = OP_HALT then
                            state <= S_HALT;
                        else
                            state <= S_EXECUTE;
                        end if;
                    when S_EXECUTE =>
                        case opcode_in is
                            when OP_CMP | OP_CMP_IMM | OP_CMP_REG | OP_NOP | OP_HALT =>
                                state <= S_FETCH;
                            when others =>
                                state <= S_WRITEBACK;
                        end case;
                    when S_WRITEBACK =>
                        state <= S_FETCH;
                    when S_HALT =>
                        state <= S_HALT;
                    when others =>
                        state <= S_HALT;
                end case;
            end if;
        end if;
    end process;

    -- Processo 2: Lógica Combinacional
    process (state, opcode_in)
    begin
        -- Valores Padrão (para evitar latches)
        pc_en       <= '0';
        ir_load_en  <= '0';
        rf_write_en <= '0';
        reg_write_addr <= "00"; -- Padrão
        alu_op      <= "00000"; 
        alu_src_b_sel <= '0'; 
        shifter_ctrl_out  <= "00"; 
        reg_write_src_sel <= '0'; 
        ld_alu_flags_out  <= '0';
        ld_shf_flags_out  <= '0';
        halt_out          <= '0';

        case state is
            when S_RESET =>
                null; 

            when S_FETCH =>
                ir_load_en <= '1'; 

            when S_DECODE =>
                pc_en <= '1'; 

            when S_EXECUTE =>
                -- Lógica do Datapath (para Flags)
                case opcode_in is
                    when OP_MOV_IMM | OP_ADD_IMM | OP_SUB_IMM | 
                         OP_AND_IMM | OP_OR_IMM | OP_XOR_IMM | OP_CMP_IMM =>
                        alu_src_b_sel <= '1';
                    when others =>
                        alu_src_b_sel <= '0';
                end case;
                
                case opcode_in is
                    when OP_ADD | OP_ADD_IMM => alu_op <= ALU_OP_ADD;
                    when OP_SUB | OP_SUB_IMM => alu_op <= ALU_OP_SUB;
                    when OP_AND | OP_AND_IMM => alu_op <= ALU_OP_AND;
                    when OP_OR  | OP_OR_IMM  => alu_op <= ALU_OP_OR;
                    when OP_XOR | OP_XOR_IMM => alu_op <= ALU_OP_XOR;
                    when OP_NOT             => alu_op <= ALU_OP_NOT;
                    when OP_NAND            => alu_op <= ALU_OP_NAND;
                    when OP_NOR             => alu_op <= ALU_OP_NOR;
                    when OP_XNOR            => alu_op <= ALU_OP_XNOR;
                    when OP_CMP | OP_CMP_REG | OP_CMP_IMM => alu_op <= ALU_OP_CMP; 
                    when OP_MOV_REG | OP_MOV_IMM | OP_PASS_B => alu_op <= ALU_OP_PASS_B;
                    when others             => alu_op <= "00000"; 
                end case;
                
                case opcode_in is
                    when OP_SHL => shifter_ctrl_out <= "01";
                    when OP_SHR => shifter_ctrl_out <= "10";
                    when others => shifter_ctrl_out <= "00";
                end case;
                
                -- Lógica de Carga dos Flags
                case opcode_in is
                    when OP_ADD | OP_ADD_IMM | OP_SUB | OP_SUB_IMM |
                         OP_AND | OP_AND_IMM | OP_OR  | OP_OR_IMM  |
                         OP_XOR | OP_XOR_IMM | OP_NOT | OP_NAND |
                         OP_NOR | OP_XNOR |
                         OP_CMP | OP_CMP_REG | OP_CMP_IMM =>
                        ld_alu_flags_out <= '1'; 
                    when OP_SHL | OP_SHR =>
                        ld_shf_flags_out <= '1'; 
                    when others =>
                        null;
                end case;
            
            when S_WRITEBACK =>
                -- Ativa a escrita
                rf_write_en <= '1'; 
                
                -- CORREÇÃO: Força o endereço de escrita para "11" (R3)
                reg_write_addr <= "11";
                
                -- Lógica do Datapath (Duplicada)
                case opcode_in is
                    when OP_MOV_IMM | OP_ADD_IMM | OP_SUB_IMM | 
                         OP_AND_IMM | OP_OR_IMM | OP_XOR_IMM | OP_CMP_IMM =>
                        alu_src_b_sel <= '1'; 
                    when others =>
                        alu_src_b_sel <= '0'; 
                end case;
                
                case opcode_in is
                    when OP_ADD | OP_ADD_IMM => alu_op <= ALU_OP_ADD;
                    when OP_SUB | OP_SUB_IMM => alu_op <= ALU_OP_SUB;
                    when OP_AND | OP_AND_IMM => alu_op <= ALU_OP_AND;
                    when OP_OR  | OP_OR_IMM  => alu_op <= ALU_OP_OR;
                    when OP_XOR | OP_XOR_IMM => alu_op <= ALU_OP_XOR;
                    when OP_NOT             => alu_op <= ALU_OP_NOT;
                    when OP_NAND            => alu_op <= ALU_OP_NAND;
                    when OP_NOR             => alu_op <= ALU_OP_NOR;
                    when OP_XNOR            => alu_op <= ALU_OP_XNOR;
                    when OP_CMP | OP_CMP_REG | OP_CMP_IMM => alu_op <= ALU_OP_CMP; 
                    when OP_MOV_REG | OP_MOV_IMM | OP_PASS_B => alu_op <= ALU_OP_PASS_B;
                    when others             => alu_op <= "00000"; 
                end case;
                
                case opcode_in is
                    when OP_SHL => shifter_ctrl_out <= "01";
                    when OP_SHR => shifter_ctrl_out <= "10";
                    when others => shifter_ctrl_out <= "00";
                end case;
                
                case opcode_in is
                    when OP_SHL | OP_SHR =>
                        reg_write_src_sel <= '1'; 
                    when others =>
                        reg_write_src_sel <= '0'; 
                end case;

            when S_HALT =>
                halt_out <= '1'; 
                
            when others =>
                halt_out <= '1';
        end case;
    end process;

end architecture fsm;