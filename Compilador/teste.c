#include <stdio.h>
#include <string.h>

char* removeSpaces(char *str) {
    int j = 0;
    int flag = 0;
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
int main(){
    char teste[] = "12, 1344,  14414       ,";
    printf("%s111", removeSpaces(teste));
}