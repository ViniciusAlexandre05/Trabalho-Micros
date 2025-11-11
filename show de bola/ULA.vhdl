LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ULA IS
    PORT (
        A         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        B         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        ALU_Sel   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        Resultado : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        Flags     : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
END ULA;

ARCHITECTURE Behavioral OF ULA IS
    CONSTANT C_SEL_WIDTH : INTEGER := 5;
    SUBTYPE T_ALU_SEL IS STD_LOGIC_VECTOR(C_SEL_WIDTH-1 DOWNTO 0);
    CONSTANT OP_ADD : T_ALU_SEL := "00000";
    CONSTANT OP_SUB : T_ALU_SEL := "00001";
    CONSTANT OP_CMP : T_ALU_SEL := "00010";
    CONSTANT OP_MUL : T_ALU_SEL := "00011";
    CONSTANT OP_DIV : T_ALU_SEL := "00100";
    CONSTANT OP_MOD : T_ALU_SEL := "00101";
    CONSTANT OP_AND : T_ALU_SEL := "00110";
    CONSTANT OP_OR  : T_ALU_SEL := "00111";
    CONSTANT OP_XOR : T_ALU_SEL := "01000";
    CONSTANT OP_NOT : T_ALU_SEL := "01001";
    CONSTANT OP_INC  : T_ALU_SEL := "01100";
    CONSTANT OP_DEC  : T_ALU_SEL := "01101";
    CONSTANT OP_NAND : T_ALU_SEL := "01110";
    CONSTANT OP_NOR  : T_ALU_SEL := "01111";
    CONSTANT OP_XNOR : T_ALU_SEL := "10000";
    CONSTANT OP_PASS_B : T_ALU_SEL := "10001";

BEGIN
    process(A, B, ALU_Sel)
        VARIABLE temp_resultado : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE temp_flags     : STD_LOGIC_VECTOR(4 DOWNTO 0);
        VARIABLE A_unsigned : UNSIGNED(7 DOWNTO 0);
        VARIABLE B_unsigned : UNSIGNED(7 DOWNTO 0);
        VARIABLE res_9bit   : UNSIGNED(8 DOWNTO 0);
        VARIABLE res_16bit  : UNSIGNED(15 DOWNTO 0);
        VARIABLE temp_PF    : STD_LOGIC;
    BEGIN
        temp_resultado := (OTHERS => '0');
        temp_flags     := (OTHERS => '0');
        A_unsigned     := UNSIGNED(A);
        B_unsigned     := UNSIGNED(B);
        
        CASE ALU_Sel IS
            WHEN OP_ADD => 
                res_9bit       := RESIZE(A_unsigned, 9) + RESIZE(B_unsigned, 9);
                temp_resultado := STD_LOGIC_VECTOR(res_9bit(7 DOWNTO 0));
                temp_flags(3)  := res_9bit(8);
                IF (A(7) = B(7)) AND (A(7) /= temp_resultado(7)) THEN temp_flags(1) := '1'; END IF;
            WHEN OP_SUB => 
                res_9bit       := RESIZE(A_unsigned, 9) - RESIZE(B_unsigned, 9);
                temp_resultado := STD_LOGIC_VECTOR(res_9bit(7 DOWNTO 0));
                temp_flags(3)  := NOT res_9bit(8);
                IF (A(7) /= B(7)) AND (B(7) = temp_resultado(7)) THEN temp_flags(1) := '1'; END IF;
            WHEN OP_CMP => 
                res_9bit       := RESIZE(A_unsigned, 9) - RESIZE(B_unsigned, 9);
                temp_resultado := STD_LOGIC_VECTOR(res_9bit(7 DOWNTO 0)); 
                temp_flags(3)  := NOT res_9bit(8);
                IF (A(7) /= B(7)) AND (B(7) = temp_resultado(7)) THEN temp_flags(1) := '1'; END IF;
            WHEN OP_MUL =>
                res_16bit      := A_unsigned * B_unsigned;
                temp_resultado := STD_LOGIC_VECTOR(res_16bit(7 DOWNTO 0));
                IF res_16bit(15 DOWNTO 8) /= 0 THEN temp_flags(3) := '1'; temp_flags(1) := '1'; END IF;
            WHEN OP_DIV =>
                IF B_unsigned = 0 THEN temp_resultado := (OTHERS => '1'); temp_flags(1)  := '1';
                ELSE temp_resultado := STD_LOGIC_VECTOR(A_unsigned / B_unsigned); END IF;
            WHEN OP_MOD =>
                IF B_unsigned = 0 THEN temp_resultado := (OTHERS => '1'); temp_flags(1)  := '1';
                ELSE temp_resultado := STD_LOGIC_VECTOR(A_unsigned REM B_unsigned); END IF;
            WHEN OP_AND => temp_resultado := A AND B;
            WHEN OP_OR  => temp_resultado := A OR B;
            WHEN OP_XOR => temp_resultado := A XOR B;
            WHEN OP_NOT => temp_resultado := NOT A;
            WHEN OP_INC =>
                res_9bit       := RESIZE(A_unsigned, 9) + 1;
                temp_resultado := STD_LOGIC_VECTOR(res_9bit(7 DOWNTO 0));
                temp_flags(3)  := res_9bit(8);
                IF A = "01111111" THEN temp_flags(1) := '1'; END IF;
            WHEN OP_DEC =>
                res_9bit       := RESIZE(A_unsigned, 9) - 1;
                temp_resultado := STD_LOGIC_VECTOR(res_9bit(7 DOWNTO 0));
                temp_flags(3)  := NOT res_9bit(8);
                IF A = "10000000" THEN temp_flags(1) := '1'; END IF;
            WHEN OP_NAND   => temp_resultado := A NAND B;
            WHEN OP_NOR    => temp_resultado := A NOR B;
            WHEN OP_XNOR   => temp_resultado := A XNOR B;
            WHEN OP_PASS_B => temp_resultado := B; temp_flags(3) := '0'; temp_flags(1) := '0';
            WHEN OTHERS => temp_resultado := (OTHERS => 'X'); temp_flags := (OTHERS => 'X');
        END CASE;
        
        temp_flags(2) := temp_resultado(7); --sinal
        IF UNSIGNED(temp_resultado) = 0 THEN temp_flags(4) := '1'; END IF; --zero
        temp_PF := '0';
        FOR i IN 0 TO 7 LOOP temp_PF := temp_PF XOR temp_resultado(i); END LOOP;
        temp_flags(0) := NOT temp_PF; --paridade

        Resultado <= temp_resultado;
        Flags     <= temp_flags;
    END process;
END Behavioral;