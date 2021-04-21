%{


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int yylex(void);
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int checkSubAlias (char *check, char *word);
int runSetEnv(char *var, char *word);
int runPrintEnv(void);
int runPrintAlias(void);
int runPrintEnvF(char* io, char* file);
int runPrintAliasF(char* io, char* file);
int runPrintCmd(void);
int resetCmdTbl(void);
int runUnAlias(char* name);
int runUnEnv(char* name);
int runExec(char command[][100], int n);
int cnt = 0;

#define READ 0
#define WRITE 1

#define STDIN 0
#define STDOUT 1


%}

%union {char *string; int count;}

%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS SETENV UNSETENV PRINTENV META END IO
%type <string> cmd
%type <count> args

%%
cmd_line:
	BYE END 		                {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS END						{runPrintAlias(); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
	| UNALIAS STRING END			{runUnAlias($2); return 1;}
	| UNSETENV STRING END			{runUnEnv($2); return 1;}
	| SETENV STRING STRING END		{runSetEnv($2, $3); return 1;}
	| PRINTENV END					{runPrintEnv(); return 1;}
	| cmd END    				    {runPrintCmd(); return 1;}
	| PRINTENV IO STRING END		{runPrintEnvF($2, $3); return 1;}
	| ALIAS IO STRING END			{runPrintAliasF($2, $3); return 1;}

cmd:
	STRING args			             {strcpy(cmdTable.cmd[cmdIndex], $1); cmdTable.argc[cmdIndex] = 								  $2;  cmdIndex++;}
  | STRING args META cmd             {strcpy(cmdTable.cmd[cmdIndex], $1); cmdTable.argc[cmdIndex] = $2;										    cmdIndex++;}
  | STRING args IO STRING 			 {strcpy(cmdTable.cmd[cmdIndex], $1); cmdTable.argc[cmdIndex] = $2;										    cmdIndex++; strcpy(cmdTable.io[0], $3); strcpy(														 cmdTable.files[0],$4);}
  | STRING args IO STRING IO STRING  {strcpy(cmdTable.cmd[cmdIndex], $1); cmdTable.argc[cmdIndex] = $2;										    cmdIndex++; strcpy(cmdTable.io[0], $3); strcpy(														 cmdTable.files[0],$4); strcpy(cmdTable.io[1], $5); strcpy(														 cmdTable.files[1],$6);}

args:
  STRING args                     { strcpy(cmdTable.args[argsIndex], $1); argsIndex++; 									             $$ = ++cnt; }
  | 							  {$$ = 0; cnt = 0;}


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

	//check if alias is trying to alias itself (a=a)
	if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would createeee a loop.\n", name);
			return 1;
		}
	//recursively check if a loop is present in aliasing
	else if(checkSubAlias(name, word) == 1){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}

	for (int i = 0; i < aliasIndex; i++) {
		if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
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

int checkSubAlias (char *check, char *word) {
	
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(aliasTable.name[i], word) == 0) {

			if(strcmp(aliasTable.word[i], check) == 0) {
				return 1;
			}
			else {
			    int x = checkSubAlias(check, aliasTable.word[i]);
			    if (x == 1) {
			    	return 1;
			    }
			}

		}

	}
	return 0;
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


//Print Environment Variables to file
int runPrintEnvF(char *io, char *file) {

int pid;

//Fork child
if ((pid = fork()) < 0) {
	printf("Fork Error\n");
}

else if (pid == 0)
{

	int fd1;

       if (strcmp(io, ">>") == 0) {
       		fd1 = open(file, O_WRONLY | O_APPEND | O_CREAT, 0777);
       }
       else {
       		fd1 = creat(file , 0644) ;
       }
           

        dup2(fd1, STDOUT_FILENO);
        close(fd1);

    for (int i = 0; i < varIndex; i++) {
		printf("%s=%s\n", varTable.var[i], varTable.word[i]);
	}
	exit(1);
}
else
{
	int status;
    /* Be parental */
    while (!(wait(&status) == pid)) ; 
}
return 1;


}



//Print Aliases to file
int runPrintAliasF(char *io, char *file) {

int pid;

//Fork child
if ((pid = fork()) < 0) {
	printf("Fork Error\n");
}

else if (pid == 0)
{

	int fd1;

       if (strcmp(io, ">>") == 0) {
       		fd1 = open(file, O_WRONLY | O_APPEND | O_CREAT, 0777);
       }
       else {
       		fd1 = creat(file , 0644) ;
       }
           

        dup2(fd1, STDOUT_FILENO);
        close(fd1);

	for (int i = 0; i < aliasIndex; i++) {
		printf("%s=%s\n", aliasTable.name[i], aliasTable.word[i]);
	}
	exit(1);
}
else
{
	int status;
    /* Be parental */
    while (!(wait(&status) == pid)) ; 
}
return 1;


}


int runUnAlias(char *name) {

	int pos = 0;
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, aliasTable.name[i]) == 0){
			pos = i;
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


int runUnEnv(char *name) {

	int pos = 0;

	if(strcmp(name,"PATH") == 0 || strcmp(name,"HOME") == 0 || strcmp(name,"PROMPT") == 0 || strcmp(name,"PWD") == 0) {

		printf("Cannot unset variable: %s\n", name);
		return 1;

	}


	for (int i = 0; i < varIndex; i++) {
		if(strcmp(name, varTable.var[i]) == 0){
			pos = i;
			break;
		}
		if( i == (varIndex - 1)) {
			printf("Error, variable \"%s\" does not exist.\n", name);
			return 1;
		}
	}
	for (int i = pos; i < varIndex; i++) {
		strcpy(varTable.var[i], varTable.var[i+1]);
		strcpy(varTable.word[i], varTable.word[i+1]);
	}
	varIndex--;
	return 1;

}



int runExec(char command[][100], int n) {

   bool found = false;
   if(  (command[0][0] == '.') || (command[0][0] == '/') ) {
        ;
   }
   else {

   char * path = strdup(varTable.word[3]);
   char * token = strtok(path, ":");

   struct stat statbuf;
   


   // loop through the string to extract all other tokens
   while( token != NULL ) {

      char *result = malloc(strlen(token) + strlen(command[0]) + 1); // +1 null-terminator

	   strcpy(result, token);
	   strcat(result, "/");
	   strcat(result, command[0]);

       if (stat(result,&statbuf) == 0) {
       		strcpy(command[0], result);
       		free(result);
       		found = true;
       		break;
       }
 
 
	   free(result);
	   
	  token = strtok(NULL, ":");

   }

   }

   if (!found) {
   		printf("Command not found\n");
   		_exit(EXIT_FAILURE);
   		
   }

   char *args[n];
   for(int i = 0; i < n-1; i++) {

 		args[i] = strdup(command[i]);
 		
 
  }
  args[n-1] = NULL;



  execv(args[0], args);

  _exit(EXIT_FAILURE);

 



}



int resetCmdTbl() {

	for(int i = 0; i < 100; i++) {

		strcpy(cmdTable.cmd[i], "");
		cmdTable.argc[i] = 0;
		strcpy(cmdTable.args[i] ,"");
		cmdIndex = 0;
		argsIndex = 0;


	}
	strcpy(cmdTable.io[0], "");
	strcpy(cmdTable.cmd[1], "");
	strcpy(cmdTable.files[0], "");
	strcpy(cmdTable.files[1], "");
	return 1;
}


int runPrintCmd() {

    
    //create process list and pipes for each command
    int in = 0;
    int out = 0;
    pid_t pid;
    int status;
    int fds [cmdIndex-1][2];
    int looper = argsIndex;


    //Check command table for file redirection types
	if (strcmp(cmdTable.io[0], "<") == 0) {
	    in = 1;
	}
	else if (cmdTable.io[0][0] == '>') {
	    out = 1;
	}
	if (cmdTable.io[1][0] == '>') {
	    out = 2;
	}

    for(int i = 0; i < cmdIndex - 1; i++) {
         if(pipe(fds[i]) < 0) {
            printf("Couldn't Pipe\n");
            exit(EXIT_FAILURE);
         }
    }

    //Loop through all commands in the command table
    for (int i = 0; i < cmdIndex; i++) {


        //create string array for arguments
        char argv[cmdTable.argc[i] + 2][100];
        strcpy(argv[0], cmdTable.cmd[cmdIndex - i - 1]);

        //loop through arguments in commad Table
        for(int j = 0; j < cmdTable.argc[cmdIndex - i - 1]; j++) {
                if (cmdTable.argc[cmdIndex - i - 1] == 0) {break;}
                else {
                  
                    strcpy(argv[j+1], cmdTable.args[looper - argsIndex]);
                    argsIndex--;
    
                }
        }

        //create child process
        pid = fork();

        if (pid < 0)
        {
            perror("error fork()");
            exit(EXIT_FAILURE);
        }

        if (pid == 0)
        {
            
            //if not last command redirect output
            if (i < cmdIndex - 1)
            {
                dup2(fds[i][WRITE], STDOUT);
 
            }
            else {
                
                //check for file output
			    if (out)
			    {
			        int fd1;
			        if (out == 2 ) {
			           if (strcmp(cmdTable.io[1], ">>") == 0) {
			                fd1 = open(cmdTable.files[1], O_WRONLY | O_APPEND | O_CREAT, 0777);
			           }
			           else {
			                fd1 = creat(cmdTable.files[1] , 0644) ;
			           }
			           
			        }
			        else {

			            if (strcmp(cmdTable.io[0], ">>") == 0) {
			                fd1 = open(cmdTable.files[0], O_WRONLY | O_APPEND | O_CREAT, 0777);
			           }
			           else {
			                fd1 = creat(cmdTable.files[0] , 0644) ;
			           }
			        }

			        dup2(fd1, STDOUT_FILENO);
			        close(fd1);
			    }




            }


            //if not first process redirect input
            if (i > 0)
            {
                dup2(fds[i - 1][READ], STDIN);
            }
            else {

               //Check if there is file input redirection

            	if (in) {
					        int fd0 = open(cmdTable.files[0], O_RDONLY);
					        dup2(fd0, STDIN_FILENO);
					        close(fd0);
					    }

            }
            
            for(int j = 0; j < cmdIndex -1; j++) {
                close(fds[j][0]);
                close(fds[j][1]);
            }


            //call exec function
            runExec(argv,cmdTable.argc[i] + 2);
         
    
        }

    }
    
    for(int j = 0; j < cmdIndex -1; j++) {
                close(fds[j][0]);
                close(fds[j][1]);
            }

    for(int i = 0; i < cmdIndex; i++) {
         wait(&status);
    }


    resetCmdTbl();
    return 1;
    
    }