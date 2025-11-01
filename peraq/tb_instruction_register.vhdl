LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Instruction_Register_tb IS
END Instruction_Register_tb;

ARCHITECTURE Behavioral OF Instruction_Register_tb IS

    -- Component
    COMPONENT Instruction_Register IS
        PORT (
            clk        : IN  STD_LOGIC;
            rst        : IN  STD_LOGIC;
            ir_load_en : IN  STD_LOGIC;
            data_in    : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
            opcode_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            op1_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            op2_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    -- Sinais de teste
    SIGNAL clk        : STD_LOGIC := '0';
    SIGNAL rst        : STD_LOGIC := '0';
    SIGNAL ir_load_en : STD_LOGIC := '0';
    SIGNAL data_in    : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
    SIGNAL opcode_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL op1_out    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL op2_out    : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Clock period
    CONSTANT clk_period : TIME := 10 ns;

BEGIN

    -- Instância do DUT (Device Under Test)
    UUT: Instruction_Register
        PORT MAP (
            clk        => clk,
            rst        => rst,
            ir_load_en => ir_load_en,
            data_in    => data_in,
            opcode_out => opcode_out,
            op1_out    => op1_out,
            op2_out    => op2_out
        );

    -- Geração de clock
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period/2;
        clk <= '1';
        WAIT FOR clk_period/2;
    END PROCESS;

    -- Estímulos de teste
    stim_proc : PROCESS
    BEGIN
        -- Reset inicial
        rst <= '1';
        WAIT FOR 15 ns;
        rst <= '0';
        WAIT FOR clk_period;

        -- Teste 1: Carrega uma instrução
        data_in <= x"11AA01";  -- MOV R1, #xAA
        ir_load_en <= '1';
        WAIT FOR clk_period;
        ir_load_en <= '0';
        WAIT FOR clk_period;

        REPORT "T1 - opcode=" & to_hstring(opcode_out) &
               " op1=" & to_hstring(op1_out) &
               " op2=" & to_hstring(op2_out);

        -- Teste 2: Tenta mudar data_in sem enable (não deve mudar)
        data_in <= x"400102";  -- ADD R1, R2
        WAIT FOR clk_period;
        REPORT "T2 - (sem load) opcode=" & to_hstring(opcode_out);

        -- Teste 3: Carrega nova instrução
        ir_load_en <= '1';
        WAIT FOR clk_period;
        ir_load_en <= '0';
        WAIT FOR clk_period;
        REPORT "T3 - opcode=" & to_hstring(opcode_out) &
               " op1=" & to_hstring(op1_out) &
               " op2=" & to_hstring(op2_out);

        -- Teste 4: Reset no meio
        rst <= '1';
        WAIT FOR clk_period;
        rst <= '0';
        WAIT FOR clk_period;
        REPORT "T4 - após reset opcode=" & to_hstring(opcode_out);

        WAIT;
    END PROCESS;

END Behavioral;
