library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cu_registers_mux is
end entity;

architecture behavioral of tb_cu_registers_mux is

    constant CLK_PERIOD : time := 10 ns;

    -- sinais de clock e reset
    signal clk_tb   : std_logic := '0';
    signal reset_tb : std_logic := '1';

    -- sinais da unidade de controle (usados apenas para compatibilidade)
    signal opcode_in_tb : std_logic_vector(7 downto 0) := (others => '0');
    signal A_tb         : std_logic_vector(7 downto 0) := (others => '0');
    signal flags_in_tb  : std_logic_vector(6 downto 0) := (others => '0');
    signal pc_en_tb, ir_load_en_tb, rf_write_en_tb, alu_src_b_sel_tb, halt_out_tb : std_logic;
    signal alu_op_tb : std_logic_vector(4 downto 0);
    signal shifter_ctrl_out_tb : std_logic_vector(1 downto 0);
    signal reg_write_src_sel_tb : std_logic_vector(1 downto 0);
    signal ld_alu_flags_out_tb, ld_shf_flags_out_tb : std_logic;

    -- sinais do regfile
    signal rf_we_tb    : std_logic := '0';
    signal rf_addr_tb  : unsigned(1 downto 0) := (others => '0');
    signal rf_data_tb  : std_logic_vector(7 downto 0) := (others => '0');
    signal q_0_tb, q_1_tb, q_2_tb, q_3_tb : std_logic_vector(7 downto 0);

    -- sinais do mux
    signal mux_sel_tb  : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_a_out_tb: std_logic_vector(7 downto 0);

    -- função auxiliar para exibir std_logic_vector como string
    function to_string(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
    begin
        for i in slv'range loop
            if slv(i) = '1' then
                result(i - slv'low + 1) := '1';
            elsif slv(i) = '0' then
                result(i - slv'low + 1) := '0';
            else
                result(i - slv'low + 1) := 'X';
            end if;
        end loop;
        return result;
    end function;

begin

    -------------------------------------------------------------------
    -- Instâncias dos módulos
    -------------------------------------------------------------------
    U_CU: entity work.control_unit
        port map (
            clk => clk_tb,
            reset => reset_tb,
            opcode_in => opcode_in_tb,
            A => A_tb,
            flags_in => flags_in_tb,
            pc_en => pc_en_tb,
            ir_load_en => ir_load_en_tb,
            rf_write_en => rf_write_en_tb,
            alu_op => alu_op_tb,
            alu_src_b_sel => alu_src_b_sel_tb,
            shifter_ctrl_out => shifter_ctrl_out_tb,
            reg_write_src_sel => reg_write_src_sel_tb,
            ld_alu_flags_out => ld_alu_flags_out_tb,
            ld_shf_flags_out => ld_shf_flags_out_tb,
            halt_out => halt_out_tb
        );

    U_RF: entity work.regfile
        port map (
            clk  => clk_tb,
            rst  => reset_tb,
            we   => rf_we_tb,
            addr => rf_addr_tb,
            data => rf_data_tb,
            q_0  => q_0_tb,
            q_1  => q_1_tb,
            q_2  => q_2_tb,
            q_3  => q_3_tb
        );

    U_MUX_A: entity work.mux_a
        port map (
            q_0 => q_0_tb,
            q_1 => q_1_tb,
            q_2 => q_2_tb,
            q_3 => q_3_tb,
            sel => mux_sel_tb,
            reg_a_out => reg_a_out_tb
        );

    -------------------------------------------------------------------
    -- Geração do clock
    -------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -------------------------------------------------------------------
    -- Estímulos
    -------------------------------------------------------------------
    stim_proc : process
    begin
        report "Iniciando simulação de escrita sequencial nos registradores..." severity note;

        -- reset
        reset_tb <= '1';
        wait for CLK_PERIOD * 2;
        reset_tb <= '0';
        report "Reset liberado." severity note;

        -------------------------------------------------------------------
        -- Escrita em cada registrador (regfile escreve em rising_edge)
        -------------------------------------------------------------------
        -- R0 = 0x88
        rf_addr_tb <= "00";
        rf_data_tb <= x"88";
        rf_we_tb   <= '1';
        wait until rising_edge(clk_tb);
        mux_sel_tb <= (others => '0'); -- seleciona R0
        report "Escrevendo em R0 valor: " & to_string(rf_data_tb) severity note;
        wait for 5 ns;
        report "MUX selecionou R0 -> Saída MUX: " & to_string(reg_a_out_tb) severity note;

        -- R1 = 0x44
        rf_addr_tb <= "01";
        rf_data_tb <= x"44";
        rf_we_tb   <= '1';
        wait until rising_edge(clk_tb);
        mux_sel_tb <= "00000001";
        report "Escrevendo em R1 valor: " & to_string(rf_data_tb) severity note;
        wait for 5 ns;
        report "MUX selecionou R1 -> Saída: " & to_string(reg_a_out_tb) severity note;

        -- R2 = 0xCC
        rf_addr_tb <= "10";
        rf_data_tb <= x"CC";
        rf_we_tb   <= '1';
        wait until rising_edge(clk_tb);
        mux_sel_tb <= "00000010";
        report "Escrevendo em R2 valor: " & to_string(rf_data_tb) severity note;
        wait for 5 ns;
        report "MUX selecionou R2 -> Saída: " & to_string(reg_a_out_tb) severity note;

        -- R3 = 0x22
        rf_addr_tb <= "11";
        rf_data_tb <= x"22";
        rf_we_tb   <= '1';
        wait until rising_edge(clk_tb);
        mux_sel_tb <= "00000011";
        report "Escrevendo em R3 valor: " & to_string(rf_data_tb) severity note;
        wait for 5 ns;
        report "MUX selecionou R3 -> Saída: " & to_string(reg_a_out_tb) severity note;

        rf_we_tb <= '0';
        report "Final da simulação." severity note;
        wait;
    end process;

end architecture;