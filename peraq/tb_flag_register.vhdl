LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL; -- Importante para a função to_hex_8bit

-- Este é um Teste de Unidade SIMPLES apenas para o Flag_Register
ENTITY tb_flag_register IS
END tb_flag_register;

ARCHITECTURE Behavioral OF tb_flag_register IS

    -- 1. Componente a ser testado
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
            R_FLAGS : OUT STD_LOGIC_VECTOR(6 DOWNTO 0) -- (6)Z, (5)C, (4)S, (3)P, (2)I, (1)D, (0)O
        );
    END COMPONENT;

    -- 2. Sinais para controlar o UUT
    SIGNAL tb_clk   : STD_LOGIC := '0';
    SIGNAL tb_rst   : STD_LOGIC := '0';
    
    SIGNAL s_ld_zf, s_ld_cf, s_ld_sf, s_ld_pf, s_ld_if, s_ld_df, s_ld_of : STD_LOGIC := '0';
    SIGNAL s_set_zf, s_set_cf, s_set_sf, s_set_pf, s_set_if, s_set_df, s_set_of : STD_LOGIC := '0';
    
    SIGNAL s_r_flags : STD_LOGIC_VECTOR(6 DOWNTO 0); -- Saída de 7 bits

    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- =================================================================
    -- ==      FUNÇÃO DE CONVERSÃO VHDL-93 (REUTILIZADA)            ==
    -- =================================================================
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
    -- =================================================================

BEGIN

    -- 3. Instanciar o Componente
    UUT_Flag_Reg : Flag_Register
        PORT MAP (
            clk     => tb_clk,
            rst     => tb_rst,
            LD_ZF   => s_ld_zf, LD_CF   => s_ld_cf, LD_SF   => s_ld_sf,
            LD_PF   => s_ld_pf, LD_IF   => s_ld_if, LD_DF   => s_ld_df,
            LD_OF   => s_ld_of,
            set_ZF  => s_set_zf, set_CF  => s_set_cf, set_SF  => s_set_sf,
            set_PF  => s_set_pf, set_IF  => s_set_if, set_DF  => s_set_df,
            set_OF  => s_set_of,
            R_FLAGS => s_r_flags
        );

    -- 4. Gerador de Clock
    Clock_Process : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD / 2;
        tb_clk <= NOT tb_clk;
    END PROCESS;

    -- 5. Processo de Estímulo
    Stimulus_Process : PROCESS
    BEGIN
        REPORT "--- Testbench Flag_Register (Hex) iniciado ---";
        
        -- ==============================================
        -- Teste 1: Reset Síncrono
        -- ==============================================
        REPORT "TESTE 1: Resetando...";
        tb_rst <= '1';
        WAIT UNTIL rising_edge(tb_clk);
        tb_rst <= '0';
        WAIT FOR 1 ns; 
        
        --  *** CORRIGIDO AQUI (Pad 7 bits para 8 bits) ***
        ASSERT s_r_flags = "0000000"
            REPORT "FALHA TESTE 1: Reset falhou! Valor: x" & to_hex_8bit('0' & s_r_flags)
            SEVERITY ERROR;
        REPORT "SUCESSO TESTE 1: Reset OK. Flags = x" & to_hex_8bit('0' & s_r_flags);
        
        -- ==============================================
        -- Teste 2: Setar ZF (bit 6) e OF (bit 0)
        -- ==============================================
        REPORT "TESTE 2: Setando ZF e OF...";
        s_ld_zf <= '1'; s_set_zf <= '1';
        s_ld_of <= '1'; s_set_of <= '1';
        
        WAIT UNTIL rising_edge(tb_clk); -- Escrita síncrona
        
        s_ld_zf <= '0';
        s_ld_of <= '0';
        WAIT FOR 1 ns;
        
        --  *** CORRIGIDO AQUI (Valor esperado "1000001") ***
        ASSERT s_r_flags = "1000001"
            REPORT "FALHA TESTE 2: Setar ZF/OF falhou! Valor: x" & to_hex_8bit('0' & s_r_flags)
            SEVERITY ERROR;
        REPORT "SUCESSO TESTE 2: Set ZF/OF OK. Flags = x" & to_hex_8bit('0' & s_r_flags);
        
        -- ==============================================
        -- Teste 3: Teste de "Hold" (LD = '0')
        -- ==============================================
        REPORT "TESTE 3: Hold (LD=0), mudando entradas 'set'...";
        
        s_set_zf <= '0'; s_set_cf <= '1'; s_set_sf <= '1'; s_set_pf <= '1';
        s_set_if <= '1'; s_set_df <= '1'; s_set_of <= '0';
        
        WAIT UNTIL rising_edge(tb_clk);
        WAIT FOR 1 ns;
        
        --  *** CORRIGIDO AQUI (Valor deve ser mantido) ***
        ASSERT s_r_flags = "1000001"
            REPORT "FALHA TESTE 3: Hold falhou! Valor mudou para: x" & to_hex_8bit('0' & s_r_flags)
            SEVERITY ERROR;
        REPORT "SUCESSO TESTE 3: Hold OK. Valor mantido: x" & to_hex_8bit('0' & s_r_flags);
        
        -- ==============================================
        -- Teste 4: Limpar ZF (bit 6), Setar CF (bit 5)
        -- ==============================================
        REPORT "TESTE 4: Limpando ZF, Setando CF...";
        
        s_ld_zf <= '1'; s_set_zf <= '0'; -- Limpa ZF
        s_ld_cf <= '1'; s_set_cf <= '1'; -- Seta CF
        
        WAIT UNTIL rising_edge(tb_clk);
        
        s_ld_zf <= '0';
        s_ld_cf <= '0';
        WAIT FOR 1 ns;
        
        --  *** CORRIGIDO AQUI (Valor esperado "0100001") ***
        ASSERT s_r_flags = "0100001"
            REPORT "FALHA TESTE 4: Limpar ZF/Setar CF falhou! Valor: x" & to_hex_8bit('0' & s_r_flags)
            SEVERITY ERROR;
        REPORT "SUCESSO TESTE 4: Carga parcial OK. Flags = x" & to_hex_8bit('0' & s_r_flags);
        
        REPORT "--- Testbench Flag_Register finalizado ---";
        WAIT;
        
    END PROCESS Stimulus_Process;

END Behavioral;