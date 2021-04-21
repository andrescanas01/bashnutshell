# Nutshell
Andres Canas

## Description
The purpose of this project is to create a bash-like shell using lex and yacc. The project uses FLEX and BISON implementation. The shell is unix based. It never quits unless the command 'bye' is inputted. 


## Design	
This shell system is designed using C. The two main modules are the scanner (nutshscanner.l) and the parser (nutshparser.y). The scanner reads and tokenizes the text. The parser structures the shell language to make sense of the tokens. Recursion is used in the parser to understand the variable number of arguments common to any shell. A global.h file is used to store variables, commands, and paths available to all shell files.


## Verification
This project contains a make file which can be used to build the flex and bison files, as well as the executable program ‘nutshell.’ Make clean and make can be used to easily rebuild the program after adjustments are made to the code. ./nutshell will start your shell. Or run the command from any directory!


## Project Breakdown
The team members working on this project were Andres Canas and Darren Wang. Unfortunately, Darren Wang was not able to continue with this project. The completed features are broken down by team members as follows:

Andres:  
All built in commands.  
Alias expansion.  
Environment variable expansion.\ 
Error handling\
Parser Recursion\
Single Non-built in command with any variable number of arguments\
Searching command in path environment variable\ 
Single Non-built in command IO output redirection.  

Darren:\
TBD


## None-completed Features 
Piping\
IO input redirection\
Wild card matching



Thank you, for any questions please email andrescanas001@ufl.edu

