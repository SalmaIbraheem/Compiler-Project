%{
#include "y.tab.h"
%}

DIGIT  [0-9]
LETTER [a-zA-Z]

%%
"if"      return (IF);
"else"    return (ELSE);
"while"	  return (WHILE);
"for"     return (FOR);
"switch"  return (SWITCH);
"case"    return (CASE);
"default" return (DEFAULT);
"do"	  return (DO);
"break"   return (BREAK);




[*+-/=%;&|^(){}:]  {return yytext[0];}

"&&"		return (AND);
"||"		return(OR);
"!"			return(NOT);
"=="		return(EQ);
"!="		return(NEQ);
">="		return(GTE);
"<="		return(LTE);
">"			return(GT);
"<"			return(LT);
"++"		return(INC);
"--"		return(DEC);


"int"			return (INTEGER_TYPE);
"float"			return (FLOAT_TYPE);
"string"  		return (STRING_TYPE);
"char"			return (CHAR_TYPE);
"const"   		return (CONST_TYPE);

"def"			return (DEF);
"return"		return (RETURN);

"exit"		    return (EXIT);

[ \t\n]+        ;        	/* ignore whitespace */


-?{DIGIT}+				 	{	yylval.INTGR = atoi(yytext); return(INTEGER);}

-?{DIGIT}*"."{DIGIT}+       {	yylval.FLT = atof(yytext); return(FLOAT);}

\'.\'						{ 	yylval.CHR = yytext[1]; return(CHAR); }

\"[0-9a-zA-Z ]+\" 			{ 	yylval.STRNG = yytext; return(STRING); }


{LETTER} 					{	yylval.CHR = yytext[0]; return(ID);}	
[a-zA-Z][a-zA-Z]+		    {   yylval.STRNG = strdup(yytext); return(FUNC);}



%%
