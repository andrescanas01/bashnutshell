#include "stdbool.h"
#include <limits.h>

struct evTable {
   char var[128][100];
   char word[128][100];
};

struct aTable {
	char name[128][100];
	char word[128][100];
};

struct cTable {

	char cmd[100][100];
	int argc[100];
	char args[100][100];
	char io[2][2];
	char files[2][100];
};

char cwd[PATH_MAX];

char prior[100];

struct evTable varTable;

struct aTable aliasTable;

struct cTable cmdTable;

int aliasIndex, varIndex, cmdIndex, argsIndex;

char* subAliases(char* name);