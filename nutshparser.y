%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"

int yylex(void);
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runSetEnv(char *var, char *word);
int runPrintEnv(void);
int runPrintAlias(void);
int runUnAlias(char* name);
int runExec(char* command);
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS SETENV PRINTENV END

%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS END						{runPrintAlias(); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| UNALIAS STRING END				{runUnAlias($2); return 1;}
	| SETENV STRING STRING END		{runSetEnv($2, $3); return 1;}
	| PRINTENV END					{runPrintEnv(); return 1;}
	| STRING END					{runExec($1); return 1;}
%%

int yyerror(char *s) {
  printf("%s here\n",s);
  return 0;
  }
 

int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			strcpy(varTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(varTable.word[0], arg);
			return 1;
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
}

//Function for setting the alias
int runSetAlias(char *name, char *word) {
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would createeee a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}
	strcpy(aliasTable.name[aliasIndex], name);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}

//Function for setting environment variable
int runSetEnv(char *var, char *word) {
	for (int i = 0; i < varIndex; i++) {
		if(strcmp(varTable.var[i], var) == 0) {
			strcpy(varTable.word[i], word);
			return 1;
		}
	}
	strcpy(varTable.var[varIndex], var);
	strcpy(varTable.word[varIndex], word);
	varIndex++;

	return 1;
}

//Print Environment Variables
int runPrintEnv() {
	for (int i = 0; i < varIndex; i++) {
		printf("%s=%s\n", varTable.var[i], varTable.word[i]);
	}
	return 1;
}

int runPrintAlias() {
	for (int i = 0; i < aliasIndex; i++) {
		printf("%s=%s\n", aliasTable.name[i], aliasTable.word[i]);
	}
	return 1;
}


int runUnAlias(char *name) {

	int pos = 0;
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, aliasTable.name[i]) == 0){
			pos = 1;
			break;
		}
		if( i == (aliasIndex - 1)) {
			printf("Error, alias \"%s\" does not exist.\n", name);
			return 1;
		}
	}
	for (int i = pos; i < aliasIndex; i++) {
		strcpy(aliasTable.name[i], aliasTable.name[i+1]);
		strcpy(aliasTable.word[i], aliasTable.word[i+1]);
	}
	aliasIndex--;
	return 1;

}


int runExec(char *command) {

  char *binaryPath = "/bin/";
  char *result = malloc(strlen(binaryPath) + strlen(command) + 1); 
  strcpy(result, binaryPath);
  strcat(result, command);
  printf("%s\n", result);
  char *args[] = {result, "-lh", "/Users", NULL};
  //execv(result, args);
  free(result);
  return 1;

}







