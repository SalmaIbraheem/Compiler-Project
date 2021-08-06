#Compiler Project 

It's a Compiler for a language that follows the syntax rules which are explained in the Proposal.pdf

#How to run:
* Run App.exe that will open a window then write the code that you want to comply 
* if it contains a semantic error it should show an error in the GUI, 
* if it contains a syntax error the program will stop, and the symbol table will be shown in a file called ‘SymbolTable.txt’ and the equivalent quadruples will be shown in the window or in a file called
‘out.txt’

We also include hello.exe so you could run it and type the program directly in the command window 
#Command to run lex and yacc from hello.exe:
* bison --yacc yacc.y -d
* flex lex.l
* gcc lex.yy.c y.tab.c -o hello.exe


You will see some test cases included in the folder TestCases and in the proposal also include a detailed explanation for them
