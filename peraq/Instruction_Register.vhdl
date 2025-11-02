LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Instruction_Register IS
    PORT (
        clk        : IN  STD_LOGIC;
        rst        : IN  STD_LOGIC;
        ir_load_en : IN  STD_LOGIC;
        data_in    : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
        opcode_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        op1_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        op2_out    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END Instruction_Register;

ARCHITECTURE rtl OF Instruction_Register IS
    SIGNAL s_ir : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS => '0');
BEGIN

    -- CORREÇÃO: Padronizado para Reset SÍNCRONO e RISING_EDGE
    process(clk)
    begin
        if falling_edge(clk) then 
            if rst = '1' then
                s_ir <= (OTHERS => '0');
            elsif ir_load_en = '1' then
                s_ir <= data_in;
            end if;
        end if;
    end process;
    
    opcode_out <= s_ir(23 DOWNTO 16); 
    op1_out    <= s_ir(15 DOWNTO 8);
    op2_out    <= s_ir(7 DOWNTO 0); 

END rtl;