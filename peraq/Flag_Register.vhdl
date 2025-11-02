LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Flag_Register IS
    PORT (
        clk          : IN  STD_LOGIC;
        rst          : IN  STD_LOGIC;
        ld_alu_flags : IN  STD_LOGIC;
        ld_shf_flags : IN  STD_LOGIC;
        alu_flags_in : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        shf_flags_in : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        R_FLAGS      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END Flag_Register;

ARCHITECTURE rtl OF Flag_Register IS
    SIGNAL flags_s : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
BEGIN

    process(clk)
    begin
        -- CORREÇÃO: Mudado de falling_edge para RISING_EDGE
        if rising_edge(clk) then
            if rst = '1' then
                flags_s <= (OTHERS => '0');
            
            elsif ld_alu_flags = '1' then
                -- Mapeamento da ULA: (4=ZF, 3=CF, 2=SF, 1=OF, 0=PF)
                flags_s(6) <= alu_flags_in(4); -- ZF
                flags_s(5) <= alu_flags_in(3); -- CF
                flags_s(4) <= alu_flags_in(2); -- SF
                flags_s(3) <= alu_flags_in(0); -- PF
                flags_s(0) <= alu_flags_in(1); -- OF
            
            elsif ld_shf_flags = '1' then
                -- Mapeamento do Shifter: (3=ZF, 2=SF, 1=PF, 0=CF)
                flags_s(6) <= shf_flags_in(3); -- ZF
                flags_s(5) <= shf_flags_in(0); -- CF
                flags_s(4) <= shf_flags_in(2); -- SF
                flags_s(3) <= shf_flags_in(1); -- PF
                flags_s(0) <= '0';             -- Shifter não afeta OF
            end if;
        end if;
    end process;

    R_FLAGS <= flags_s;

END rtl;