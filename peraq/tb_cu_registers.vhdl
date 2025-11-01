library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_cu_registers is
end entity tb_cu_registers;

architecture behavioral of tb_cu_registers is

    -- Constantes para o Test Bench
    constant CLK_PERIOD : time := 10 ns;
    
    -- Sinais de interconexão entre Control Unit e Test Bench
    signal clk_tb        : std_logic := '0';
    signal reset_tb      : std_logic := '1';
    signal opcode_in_tb  : std_logic_vector(7 downto 0) := (others => '0');
    signal A_tb          : std_logic_vector(7 downto 0) := (others => '0');
    signal flags_in_tb   : std_logic_vector(6 downto 0) := (others => '0');
    
    -- Sinais de Controle (Saídas da Control Unit)
    signal pc_en_tb          : std_logic;
    signal ir_load_en_tb     : std_logic;
    signal rf_write_en_tb    : std_logic;
    signal alu_op_tb         : std_logic_vector(4 downto 0);
    signal alu_src_b_sel_tb  : std_logic;
    signal shifter_ctrl_out_tb: std_logic_vector(1 downto 0);
    signal reg_write_src_sel_tb: std_logic_vector(1 downto 0);
    signal ld_alu_flags_out_tb: std_logic;
    signal ld_shf_flags_out_tb: std_logic;
    signal halt_out_tb       : std_logic;
    
    -- Sinais para o Register File (Entradas e Saídas)
    signal rf_write_addr_tb : unsigned(1 downto 0) := (others => '0'); -- Endereço de Escrita (simulado)
    signal rf_write_data_tb : std_logic_vector(7 downto 0) := x"AA";  -- Dado de Escrita (simulado)
    signal q_0_tb           : std_logic_vector(7 downto 0);
    signal q_1_tb           : std_logic_vector(7 downto 0);
    signal q_2_tb           : std_logic_vector(7 downto 0);
    signal q_3_tb           : std_logic_vector(7 downto 0);

    -- Constantes de Opcode (para reuso)
    constant OP_MOV_IMM : std_logic_vector(7 downto 0) := x"11";
    constant OP_HALT    : std_logic_vector(7 downto 0) := x"01";

    -- Função auxiliar para converter std_logic_vector em string
    function to_string(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            case slv(i) is
                when '0' => result(i - slv'low + 1) := '0';
                when '1' => result(i - slv'low + 1) := '1';
                when others => result(i - slv'low + 1) := 'X';
            end case;
        end loop;
        return result;
    end function;

begin

    ------------------------------------------------------------------------
    -- 1. Instanciação da Control Unit (DUT1)
    ------------------------------------------------------------------------
    DUT_CU: entity work.control_unit
        port map (
            clk          => clk_tb,
            reset        => reset_tb,
            opcode_in    => opcode_in_tb,
            A            => A_tb,
            flags_in     => flags_in_tb,
            
            -- Saídas de Controle
            pc_en        => pc_en_tb,
            ir_load_en   => ir_load_en_tb,
            rf_write_en  => rf_write_en_tb,
            alu_op       => alu_op_tb,
            alu_src_b_sel=> alu_src_b_sel_tb,
            shifter_ctrl_out => shifter_ctrl_out_tb,
            reg_write_src_sel => reg_write_src_sel_tb,
            ld_alu_flags_out => ld_alu_flags_out_tb,
            ld_shf_flags_out => ld_shf_flags_out_tb,
            halt_out     => halt_out_tb
        );
        
    ------------------------------------------------------------------------
    -- 2. Instanciação do Register File (DUT2)
    ------------------------------------------------------------------------
    DUT_RF: entity work.regfile
        port map (
            clk          => clk_tb,
            rst          => reset_tb,
            we           => rf_write_en_tb,       -- Conexão CU -> RF
            addr         => rf_write_addr_tb,     -- Endereço de escrita
            data         => rf_write_data_tb,     -- Dado a escrever
            q_0          => q_0_tb,
            q_1          => q_1_tb,
            q_2          => q_2_tb,
            q_3          => q_3_tb
        );
        
    ------------------------------------------------------------------------
    -- 3. Geração de Clock
    ------------------------------------------------------------------------
    clock_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process clock_process;

    ------------------------------------------------------------------------
    -- 4. Processo de Estímulo e Verificação
    ------------------------------------------------------------------------
    stimulus_process : process
    begin
        REPORT "Iniciando Simulação..." SEVERITY NOTE;

        -- 1. Reset (Inicialização)
        reset_tb <= '1';
        wait for CLK_PERIOD * 2;
        reset_tb <= '0';
        REPORT "Reset Liberado. Entrando em S_FETCH." SEVERITY NOTE;

        -- Configuração dos registradores para escrita (R2)
        rf_write_addr_tb <= to_unsigned(2, 2); -- Queremos escrever no R2
        rf_write_data_tb <= x"AA";             -- Dado simulado (AAh)

        ----------------------------------------------------------------
        -- Ciclo de Instrução (MOV R2, #AA)
        ----------------------------------------------------------------

        -- S_FETCH
        wait until rising_edge(clk_tb);
        REPORT "Estado: S_FETCH. Opcode lido: " & to_string(opcode_in_tb) SEVERITY NOTE;
        opcode_in_tb <= OP_MOV_IMM;

        -- S_DECODE
        wait until rising_edge(clk_tb);
        REPORT "Estado: S_DECODE. Proximo: S_EXECUTE." SEVERITY NOTE;

        -- S_EXECUTE
        wait until rising_edge(clk_tb);
        REPORT "Estado: S_EXECUTE. Proximo: S_WRITEBACK." SEVERITY NOTE;

        -- S_WRITEBACK
        wait until rising_edge(clk_tb);
        REPORT "Estado: S_WRITEBACK. rf_write_en_tb deve ser '1'." SEVERITY NOTE;

        -- Aguarda um pequeno tempo após a escrita
        wait for 6 ns;

        -- Verificação da escrita
        if q_2_tb = x"AA" then
            REPORT "VERIFICACAO: Escrita em R2 (q_2_tb) BEM-SUCEDIDA: " & to_string(q_2_tb) SEVERITY NOTE;
        else
            REPORT "ERRO DE VERIFICACAO: R2 (q_2_tb) tem valor incorreto: " & to_string(q_2_tb) SEVERITY ERROR;
        end if;

        ----------------------------------------------------------------
        -- Instrução de HALT (verificação do estado final)
        ----------------------------------------------------------------
        opcode_in_tb <= OP_HALT;

        -- S_FETCH
        wait until rising_edge(clk_tb);

        -- S_DECODE (detecta HALT)
        wait until rising_edge(clk_tb);
        REPORT "Estado: S_DECODE (HALT detectado). Proximo: S_HALT." SEVERITY NOTE;

        -- S_HALT
        wait until rising_edge(clk_tb);
        REPORT "Estado: S_HALT. halt_out_tb deve ser '1'." SEVERITY NOTE;

        if halt_out_tb = '1' then
            REPORT "VERIFICACAO: HALT BEM-SUCEDIDO (halt_out_tb='1')." SEVERITY NOTE;
        else
            REPORT "ERRO DE VERIFICACAO: HALT falhou (halt_out_tb='0')." SEVERITY ERROR;
        end if;

        ----------------------------------------------------------------
        -- Fim da simulação
        ----------------------------------------------------------------
        wait for CLK_PERIOD * 10;
        REPORT "Fim da simulação." SEVERITY NOTE;
        wait;
    end process stimulus_process;

end architecture behavioral;