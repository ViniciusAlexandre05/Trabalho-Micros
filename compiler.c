#include <stdio.h>
#include <string.h>

// Globals
int error = 0; // Flag de erro para identificar caso tenha acontecido algum problema durante a compilacao. Nao gerar codigo invalido e relatar problemas.
FILE* binaryFile; // Arquivo binario onde sera escrito


// Tabela de opcodes
typedef struct {
    char* opcode;
    char* binary;
    int  parNumber;
} Table1; 

Table1 opcodes[] = { // TODO ia implementar uma tabela pra ficar mais facil adicionar mais comandos e dps fz a tabela de registradores.
    {"MOV", "00000001", 2},
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
    char* binary;
    
    // int i = 0;
    // while(i != -1){

    // }
    // Definicao do binario e numero de parametros
    if (strcmp(mnemonic, "MOV") == 0){
        nParameters = 2;
        binary = "00000000";
        if(convertMnemonic(binary, nParameters)){ // Converte a linha e em caso de erro retorna 1;
            error = 1;
            printf("Erro nos parametros!. Linha %i\n", lineNumber);
        }
    }
    else {
        printf("Erro ao ler mnemonico!. Linha %i: \"%s\" \n",lineNumber, mnemonic);
        error = 1;
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
