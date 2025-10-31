#include <stdio.h>
#include <string.h>

// Globals
int error = 0; // Flag de erro para identificar caso tenha acontecido algum problema durante a compilacao. Nao gerar codigo invalido e relatar problemas.
FILE* binaryFile; // Arquivo binario onde sera escrito


// Tabela de opcodes
typedef struct {
    char* mnemonic;
    char* opcode;
    int  nParameters;
    char par1Type;
    char par2Type;
} OpcodeInfo;

// Tabela de registradores
typedef struct {
    char* reg;
    char* address;
} RegInfo;

OpcodeInfo opcodes[] = { // TODO ia implementar uma tabela pra ficar mais facil adicionar mais comandos e dps fz a tabela de registradores.
    // Controle
    {"NOP", "00000000", 0, 'N','N'}, // R = register, M = memory, V = imediato, N = NULL (nao possui 2 parametro)
    {"HALT", "00000001", 0, 'N','N'},
    // Memoria/mov
    {"MOV", "00010000", 2, 'R','R'},
    {"MOV", "00010001", 2, 'R','V'},
    {"LOAD", "00010010", 2, 'M','R'},
    {"STORE", "00010011", 2, 'R','M'},
    // Aritmetica
    {"ADD", "01000000", 2, 'R','R'},
    {"ADD", "01010000", 2, 'R','V'},
    {"SUB", "01000001", 2, 'R','R'},
    {"SUB", "01010001", 2, 'R','V'},
    {"MUL", "01000010", 2, 'R','R'},
    {"DIV", "01000011", 2, 'R','R'},
    {"MOD", "01000100", 2, 'R','R'},
    {"INC", "01000101", 1, 'R','N'},
    {"DEC", "01000110", 1, 'R','N'},
    // Logica
    {"AND", "01100000", 2, 'R','R'},
    {"AND", "01101000", 2, 'R','V'},
    {"OR", "01100001", 2, 'R','R'},
    {"OR", "01101001", 2, 'R','V'},
    {"NOT", "01100010", 1, 'R','N'},
    {"XOR", "01100011", 2, 'R','R'},
    {"XOR", "01101010", 2, 'R','V'},
    {"NAND", "01100100", 2, 'R','R'},
    {"NOR", "01100101", 2, 'R','R'},
    {"XNOR", "01100110", 2, 'R','R'},
    // Shift/Bit
    {"SHL", "01110000", 1, 'R','N'},
    {"SHR", "01110001", 1, 'R','N'},
    {"CMP", "01111000", 2, 'R','R'},
    {"CMP", "01111001", 2, 'R','V'},
    {"End", "", 0} // So pra saber quando essa porra terminou
};

RegInfo registers[] = {
    {"R0", "00000000"},
    {"R1", "00000001"},
    {"R2", "00000010"},
    {"R3", "00000011"},
    {"End", ""} // So pra saber quando essa porra terminou
};
// Funcoes ----
char* removeHashtag(char *str){
    for (int i=1; i< strlen(str)-1; i++){
        str[i-1] = str[i];
    }
    str[strlen(str)-1] = '\0';
    return str;
}
char* removeBrackets(char *str){
    for(int i=1; i < strlen(str)-2; i++){
        str[i-1] = str[i];
    }
    str[strlen(str)-2] = '\0';
    return str;
}
char* removeSpaces(char *str) {
    int j = 0;
    int flag = 0;
    if(str[strlen(str)-1] == '\n'){
        str[strlen(str)-1] = '\0';
    }
    for(int i = 0; (str[i]!='\0'); i++){
        if((str[i]!=' ')||(flag==0)){
            str[j] = str[i];
            if(str[i]==' '){
                flag=1;
            }
            j++;
        }
    }
    str[j] = '\0';
    return str;
}
int compileInstruction(char* mnemonic, char* parameters[], int nParameters){ // 0 - Tudo certo, 1 - Problema com parametros
    char parametersTypes[2] = {'N','N'}; // Inicia os 2 parametros como NULL
    
    // Define parameter types --------------------------------
    for(int i = 0; i < nParameters; i++){
        if(parameters[i][0] == 'R'){
            parametersTypes[i] = 'R';
        }
        else if(parameters[i][0] == '['){
            if(parameters[i][strlen(parameters[i])-1] == ']'){
                parameters[i] = removeBrackets(parameters[i]);
                parametersTypes[i] = 'M';
            }else{ // Em caso do colchete nao tiver fechado nessa porra esse caralho vai dar erro kkkkkkk
                
                parametersTypes[i] = 'N';
                return 1;
            }
        }
        else if(parameters[i][0] == '#'){
            parameters[i] = removeHashtag(parameters[i]);
            parametersTypes[i] = 'V';
        }
        else{
            parametersTypes[i] = 'N';
        }
    }
    // -------------------------------------------------------
    
    if(parametersTypes == NULL){return 1;} // Em caso de erro
    // Extrai os valores dos parametros ----------------------
    for(int i=0; i<nParameters; i++){
        if(parametersTypes[i] == 'R'){
            int j=0;
            while(j!=-1){
                if(strcmp(parameters[i],registers[j].reg) == 0){
                    parameters[i] = registers[j].address;
                    j=-2;
                }
                else if(strcmp(registers[j].reg,"End") == 0){
                    j=-2;
                    return 1;
                }
                j++;
            }
        }
        else if(parametersTypes[i] == 'M'){
            parameters[i] = parameters[i];
        }
        else if(parametersTypes[i] == 'V'){
            parameters[i] = parameters[i];
        }
    }
    // -------------------------------------------------------------
    if(parameters == NULL){return 1;} // Em caso de erro
    int i = 0;
    while(i!= -1){
        if((strcmp(opcodes[i].mnemonic, mnemonic) == 0) && (opcodes[i].par1Type==parametersTypes[0]) && (opcodes[i].par2Type==parametersTypes[1])){
            fwrite(opcodes[i].opcode, sizeof(char), strlen(opcodes[i].opcode), binaryFile);
            fwrite("\n", sizeof(char), 1, binaryFile); // Faz a quebra de linha
            for(int j = 0; j<nParameters; j++){
                fwrite(parameters[j], sizeof(char), strlen(parameters[j]), binaryFile);
                fwrite("\n", sizeof(char), 1, binaryFile); // Faz a quebra de linha
            }
            i=-2;
        }
        else if(strcmp(opcodes[i].mnemonic, "End") == 0){
            return 1;
            i=-2;
        }
        i++;
    }
    // Adicionar linhas adicionais para manter o numero fixo de 3 bytes de instrucao
    if(nParameters==0){
        fwrite("00000000", sizeof(char), 8, binaryFile);
        fwrite("\n", sizeof(char), 1, binaryFile); // Faz a quebra de linha
        fwrite("00000000", sizeof(char), 8, binaryFile);
        fwrite("\n", sizeof(char), 1, binaryFile); // Faz a quebra de linha
    }
    else if(nParameters==1){
        fwrite("00000000", sizeof(char), 8, binaryFile);
        fwrite("\n", sizeof(char), 1, binaryFile); // Faz a quebra de linha
    }
    return 0;
}
int compileLine(char line[], int lineNumber){
    // Remover comentarios
    if(line[0] == ';'){ // Se a linha inteira for comentario
        return 0;
    }
    line = strtok(line, ";"); // Separa uma linha de seus comentarios
    
    // Separa a instrucao do resto da linha e passa para a funcao de conversao com as caracteristicas daquela instrucao
    char* mnemonic = strtok(line, " ");
    int nParameters;
    char* opcode;
    
    int i = 0;
    // Limpa a linha de espacos e quebras de linha

    while(i != -1){ // Faz busca para cada opcode na tabela
        if(strcmp(mnemonic, opcodes[i].mnemonic) == 0){ // Caso encontre o mnemonico
            nParameters = opcodes[i].nParameters;
            char* parameters[nParameters];
            i = -2; // Quebra do while
            
            // Preenche o array dos parametros separando o que sobrou da linha utilizando "," como delimitador
            for (int j=0; j<nParameters; j++){
                parameters[j] = strtok(NULL, ","); 
            }
            if((strtok(NULL, ",") != NULL) || (parameters[nParameters-1] == NULL)){ // Gera erro caso o numero de parametros esteja errado
                printf("Erro nos parametros!. Linha %i\n", lineNumber);
                error = 1;
            }else{
                if(compileInstruction(mnemonic, parameters, nParameters) == 1){
                    printf("Erro nos parametros!. Linha %i\n", lineNumber);
                    error = 1;
                }
            }
            
        }else if(strcmp(opcodes[i].mnemonic, "End") == 0){ // Caso nao encontre o mnemonico
            printf("Erro ao ler mnemonico!. Linha %i: \"%s\" \n",lineNumber, mnemonic);
            i = -2; // Quebra do while
            error = 1;
        }
        i++;
        
    }
    return 0;
}

int main(){
    // Abrir o arquivo assembly que vai ser lido
    FILE* assemblyFile = fopen("assembly.txt", "r");
    if(assemblyFile == NULL){
        printf("%s", "Erro ao abrir o arquivo assembly!");
        return 1;
    }

    // Criar novo arquivo compilado em binario
    binaryFile = fopen("binary.txt", "wb");
    if(binaryFile == NULL){
        printf("Erro ao gerar codigo binario!");
        return 1;
    }

    char buffer[1024];
    
    int lineNumber = 1; // Numero para contar em qual linha o leitor se encontra
    while(fgets(buffer, 1024, assemblyFile) != NULL){
        if(buffer[0]!='\n'){
            compileLine(removeSpaces(buffer), lineNumber); // Retorna 1 caso a linha seja compilada com sucesso e 0 se tiver algum erro.
        }
        //Remove espacos indesejados da linha
        lineNumber = lineNumber + 1;
    }
    if(error){
        printf("Compilacao Finalizada com Problemas.. :(");
    }else{
        printf("Compilacao Finalizada com Sucesso!! :)");
    }
    fclose(assemblyFile);
    fclose(binaryFile);
    return 0;
} 
