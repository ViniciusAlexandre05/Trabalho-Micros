LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;             -- Para REPORT, LINE, STRING, WRITE
USE IEEE.STD_LOGIC_TEXTIO.ALL;  -- Para WRITE (STD_LOGIC_VECTOR)

-- A entidade do testbench é vazia
ENTITY tb_instruction_memory IS
END tb_instruction_memory;

ARCHITECTURE sim OF tb_instruction_memory IS

    -- 1. Declarar o Componente que vamos testar (Unit Under Test - UUT)
    -- A declaração deve ser IDÊNTICA à entidade do seu arquivo.
    COMPONENT Instruction_Memory
        PORT (
            Address  : IN  UNSIGNED(7 DOWNTO 0);
            Data_Out : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
        );
    END COMPONENT;

    -- 2. Sinais (Signals) para conectar ao UUT
    SIGNAL s_Address  : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_Data_Out : STD_LOGIC_VECTOR(23 DOWNTO 0);

BEGIN

    -- 3. Instanciar o UUT
    -- "uut" é um nome comum para "Unit Under Test"
    uut : Instruction_Memory
        PORT MAP (
            Address  => s_Address,
            Data_Out => s_Data_Out
        );

    -- 4. Processo de Estímulo (Stimulus Process)
    -- Este processo irá gerar os sinais de entrada (o endereço)
    -- e verificar a saída.
    stim_proc : PROCESS
        -- Variável para formatar a linha de texto do REPORT
        VARIABLE line_out : LINE;
    BEGIN
        
        REPORT "Iniciando simulacao da Instruction_Memory..." SEVERITY NOTE;

        -- Loop para ler as 10 primeiras posições (0 a 9)
        FOR i IN 0 TO 9 LOOP
            
            -- Aplica o endereço 'i' ao sinal de entrada
            s_Address <= TO_UNSIGNED(i, 8); -- Converte o inteiro 'i' para UNSIGNED de 8 bits

            -- Aguarda 10 ns. 
            -- Como a memória é combinacional, o dado aparece "instantaneamente".
            -- Este WAIT é apenas para podermos ver a mudança na simulação.
            WAIT FOR 10 ns;

            -- Imprime o resultado no console
            line_out := new string'("");
            WRITE(line_out, STRING'("Endereco: "));
            WRITE(line_out, i);
            WRITE(line_out, STRING'(", Dado: "));
            WRITE(line_out, s_Data_Out); -- Escreve o STD_LOGIC_VECTOR
            REPORT line_out.all SEVERITY NOTE; -- Envia a linha formatada para o log

        END LOOP;

        REPORT "Simulacao concluida." SEVERITY NOTE;
        
        -- Para a simulação indefinidamente
        WAIT; 
        
    END PROCESS stim_proc;

END ARCHITECTURE sim;