LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;             -- Necessário para E/S de arquivos (TEXT, LINE)
USE IEEE.STD_LOGIC_TEXTIO.ALL;  -- Necessário para ler STD_LOGIC_VECTOR de uma LINE

ENTITY Instruction_Memory IS
    PORT (
        Address  : IN  UNSIGNED(7 DOWNTO 0);
        Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
END Instruction_Memory;

ARCHITECTURE Behavioral_FromFile OF Instruction_Memory IS

    -- Define o nome do arquivo a ser lido.
    -- Pode ser um GENERIC para maior flexibilidade.
    CONSTANT ROM_FILENAME : STRING := "binary.txt";

    -- Tipo da memória ROM (256 posições de 24 bits)
    TYPE rom_type IS ARRAY(0 TO 255) OF STD_LOGIC_VECTOR(23 DOWNTO 0);

    -- Função impura para ler o arquivo e inicializar a ROM.
    -- Esta função é executada uma vez antes do início da simulação.
    IMPURE FUNCTION init_rom_from_file (file_name : STRING) RETURN rom_type IS
        FILE rom_file     : TEXT OPEN READ_MODE IS file_name;
        VARIABLE line_rd  : LINE;
        VARIABLE rom_data : rom_type;

        -- Variáveis para armazenar os 3 bytes lidos
        VARIABLE byte_opc : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE byte_op1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE byte_op2 : STD_LOGIC_VECTOR(7 DOWNTO 0);

    BEGIN
        -- Inicializa a ROM inteira com NOPs (x"000000")
        -- Isso garante que posições não preenchidas pelo arquivo tenham um valor padrão.
        rom_data := (OTHERS => (OTHERS => '0'));

        -- Loop para ler as 256 instruções
        FOR i IN 0 TO 255 LOOP
            
            -- Para se o arquivo terminar antes
            IF ENDFILE(rom_file) THEN
                EXIT;
            END IF;

            -- 1. Ler Opcode (Byte 2)
            READLINE(rom_file, line_rd);
            READ(line_rd, byte_opc); -- Lê 8 bits da linha

            -- 2. Ler Operando 1 (Byte 1)
            IF ENDFILE(rom_file) THEN EXIT; END IF; -- Verificação de segurança
            READLINE(rom_file, line_rd);
            READ(line_rd, byte_op1); -- Lê 8 bits da linha

            -- 3. Ler Operando 2 (Byte 0)
            IF ENDFILE(rom_file) THEN EXIT; END IF; -- Verificação de segurança
            READLINE(rom_file, line_rd);
            READ(line_rd, byte_op2); -- Lê 8 bits da linha

            -- Concatena os 3 bytes (8 bits) para formar a instrução de 24 bits
            rom_data(i) := byte_opc & byte_op1 & byte_op2;

        END LOOP;

        FILE_CLOSE(rom_file);
        RETURN rom_data;

    END init_rom_from_file;

    -- Cria a ROM como um SIGNAL (não mais CONSTANT)
    -- E a inicializa chamando a função
    SIGNAL ROM_PROGRAM : rom_type := init_rom_from_file(ROM_FILENAME);

BEGIN

    -- A lógica de leitura da ROM (combinacional) permanece a mesma
    Data_Out <= ROM_PROGRAM(TO_INTEGER(Address));

END Behavioral_FromFile;