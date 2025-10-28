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
} Table1; 

Table1 opcodes[] = { // TODO ia implementar uma tabela pra ficar mais facil adicionar mais comandos e dps fz a tabela de registradores.
    {"MOV", "0001", 2},
    {"MOV2", "0031", 2},
    {"End", "", 0} // So pra saber quando essa porra terminou
};
// Funcoes ----
int convertMnemonic(char* binary, int nParameters){ // Funcao que valida os parametros e escreve as instrucoes no arquivo binario
    char* params[nParameters];

    // Preenche o array dos parametros separando o que sobrou da linha utilizando "," como delimitador
    for (int i=0; i<nParameters; i++){
        params[i] = strtok(NULL, ","); 
    }
    if((strtok(NULL, ",") != NULL) || (params[nParameters-1] == NULL)){ // Gera erro caso o numero de parametros esteja errado
        return 1;
    }
    fwrite(binary, sizeof(char), strlen(binary), binaryFile);
    fwrite("\n", sizeof(char), 1, binaryFile); //Faz a quebra de linha

    return 0;
}
int compileLine(char* line, int lineNumber){
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
    while(i != -1){ // Faz busca para cada opcode na tabela
        if(strcmp(mnemonic, opcodes[i].mnemonic) == 0){ // Caso encontre o mnemonico
            nParameters = opcodes[i].nParameters;
            opcode = opcodes[i].opcode;
            char* parameters[nParameters];
            i = -2; // Quebra do while
            
            // Preenche o array dos parametros separando o que sobrou da linha utilizando "," como delimitador
            for (int j=0; j<nParameters; j++){
                parameters[j] = strtok(NULL, ","); 
            }
            if((strtok(NULL, ",") != NULL) || (parameters[nParameters-1] == NULL)){ // Gera erro caso o numero de parametros esteja errado
                printf("Erro nos parametros!. Linha %i\n", lineNumber);
                error = 1;
            }
            //
            fwrite(opcode, sizeof(char), strlen(opcode), binaryFile);
            fwrite("\n", sizeof(char), 1, binaryFile); //Faz a quebra de linha

        }else if(strcmp(opcodes[i].opcode, "End") == 0){ // Caso nao encontre o mnemonico
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
    binaryFile = fopen("binary.bin", "wb");
    if(binaryFile == NULL){
        printf("Erro ao gerar codigo binario!");
        return 1;
    }

    char buffer[1024];
    
    int lineNumber = 1; // Numero para contar em qual linha o leitor se encontra
    while(fgets(buffer, 1024, assemblyFile) != NULL){
        compileLine(buffer, lineNumber); // Retorna 1 caso a linha seja compilada com sucesso e 0 se tiver algum erro.
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
