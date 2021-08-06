//any c function declaration 
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//#define YYDEBUG 1
#define YYERROR_VERBOSE 1

void clear();
int yyerror(char* s);
int yylex();

void print_symbolTable();
void ST_row(int i);

void declare(char id,int type);
void declare_initalize(char id,int type);

void open_scope();
void end_scope();
void check_scope(char var);

int add_label();
int get_label(int ind);

void case_open();

int  find_func(char* name,int num_parameters,int * types);
void save_func(char* name,int num_parameters,int * types);


FILE *fptr;
FILE *STfptr;

int cur_scope = 0;
int symbols[52];            //1 declared, 2 initizalized
int types[52];
int scope[52];
int is_init[52];
int constant[52];

int start = 1;
int not_def   = 0;
int not_type  = 0;
int	after_hp = 0;
int cur_reg = 0;
int switch_reg   = 0;
int switch_start = 0;


int labels = 0;
int nested_labels[50];
int last_nested_idx = 0;

char* func_names[100];
int  func_num_arg[100];
int  func_typ_arg[100][100];
int  func_num = 0;
int  cur_num_arg = 0;
int  cur_typ_arg[100]; 
int  functin_return = 0;
int  func = 0 ;
int  func_return = 0;

int stack[100];
int end_stack = 0;

char par_func[100]; 
int  par_func_num;
%}

// definitions
//union bridge
%union {
  int INTGR; 
  char * STRNG; 
  float FLT; 
  char CHR;
  }
//tokenss
%token IF ELSE FOR WHILE SWITCH CASE DO BREAK DEFAULT 
%token INTEGER_TYPE FLOAT_TYPE STRING_TYPE CHAR_TYPE CONST_TYPE
%token <INTGR> INTEGER 
%token <FLT> FLOAT
%token <CHR> CHAR 
%token <STRNG> STRING 
%token <STRNG> FUNC 
%token RETURN DEF
%token EXIT
%token <CHR> ID
%type <INTGR> math_exp
%type <INTGR> init_num
%type <CHR> init_char
%type <CHR> variables
%type <CHR> call_function_r
%left '*' '/'
%left '^' '&' '|'
%left '+' '-'
%left AND OR NOT EQ NEQ GTE LTE GT LT INC DEC



//start
%start statement

%%
statement	: conditions_statement              {clear();}
          | variables ';'                     {clear();}
          | constants ';'                     {clear();} 
          | assign_statement ';'              {clear();}
          | def_functions                     {clear();}
          | function                          {clear();}
          | call_function ';'                 {clear();}
          | EXIT          ';'                 {exit(EXIT_SUCCESS);}
          | error ';'                         { yyerrok;}
          | statement conditions_statement    {clear();}
          | statement variables        ';'    {clear();}
          | statement constants        ';'    {clear();} 
          | statement def_functions           {clear();}
          | statement function                {clear();}
          | statement call_function    ';'    {clear();}
          | statement assign_statement ';'    {clear();}
          | statement EXIT ';'                {exit(EXIT_SUCCESS);}
          | statement error ';'              { yyerrok;};


variables   : INTEGER_TYPE ID {declare($2,1);}
            | FLOAT_TYPE   ID {declare($2,2);}  
            | STRING_TYPE  ID {declare($2,3);}
            | CHAR_TYPE    ID {declare($2,4);}
            | INTEGER_TYPE ID '=' math_exp {declare_initalize($2,1);is_init[$2-'a'] = 1;}
            | FLOAT_TYPE   ID '=' math_exp {declare_initalize($2,2);is_init[$2-'a'] = 1;}
            | STRING_TYPE  ID '=' init_char {declare($2,3);}
            | CHAR_TYPE    ID '=' init_char {declare($2,4);};

constants   : CONST_TYPE INTEGER_TYPE ID '=' math_exp	 { constant_declare($3,1);is_init[$3-'a'] = 1;}
	          | CONST_TYPE FLOAT_TYPE   ID '=' math_exp	 { constant_declare($3,2);is_init[$3-'a'] = 1;}
	          | CONST_TYPE STRING_TYPE  ID '=' init_char { constant_declare($3,3);is_init[$3-'a'] = 1;}
	          | CONST_TYPE CHAR_TYPE    ID '=' init_char { constant_declare($3,4);is_init[$3-'a'] = 1;};

init_num    : INTEGER {$$=$1; fprintf(fptr,"MOV R%d, %d\n",cur_reg++ ,$1);if(func == 1){fprintf(fptr,"Push R%d\n",cur_reg-1);stack[end_stack++]=cur_reg-1;}}
            | FLOAT   {$$=$1; fprintf(fptr,"MOV R%d, %f\n",cur_reg++,$1);if(func == 1){fprintf(fptr,"Push R%d\n",cur_reg-1);stack[end_stack++]=cur_reg-1;}}
            | ID {int idx = $1-'a';
                      if((types[idx] == 1 || types[idx] == 0)&& is_init[idx] == 1  && (scope[idx] ==  cur_scope || scope[idx] == 0 ) )fprintf(fptr,"MOV R%d, %c\n",cur_reg++ ,$1);
                      else if (!(types[idx] == 1 || types[idx] == 0)){not_type = 1;fprintf(fptr,"Type MisMatch\n",$1);}
                      else {not_def = 1;fprintf(fptr,"Variable %c not defined\n",$1);}if(func == 1){fprintf(fptr,"Push R%d\n",cur_reg-1);stack[end_stack++]=cur_reg-1;}};

init_char   : STRING {$$=$1; fprintf(fptr,"MOV R%d, %d\n",cur_reg++ ,$1);if(func == 1){fprintf(fptr,"Push R%d\n",cur_reg-1);stack[end_stack++]=cur_reg-1;}}
            | CHAR   {$$=$1; fprintf(fptr,"MOV R%d, %f\n",cur_reg++,$1);if(func == 1){fprintf(fptr,"Push R%d\n",cur_reg-1);stack[end_stack++]=cur_reg-1;}}
            | ID   {int idx = $1-'a';
                    if(types[idx] == 3 && is_init[idx] == 1 && (scope[idx] ==  cur_scope || scope[idx] == 0) )fprintf(fptr,"MOV R%d, %c\n",cur_reg++ ,$1);
                    else if (types[idx] != 3){not_type = 1;fprintf(fptr,"Type MisMatch\n",$1);}
                    else {not_def = 1;fprintf(fptr,"Variable %c not defined\n",$1);}if(func == 1){fprintf(fptr,"Push R%d\n",cur_reg-1);stack[end_stack++]=cur_reg-1;}};

//Math Expressions
assign_statement : ID '=' math_exp {assign($1);}
                 | ID '=' CHAR {assign($1);};

math_exp   : math_exp '+' term {math_op("ADD");}
           | math_exp '-' term {math_op("SUB");}
           | math_exp '%' term {math_op("MOD");}
           | math_exp '&' term {math_op("AND");}
           | math_exp '|' term {math_op("OR");}
           | term {;};

term      :  init_num '/' term {math_op("DIV");}
          |  term '*' init_num {math_op("MUL");}
          |  init_num  {;};


//Conditional 
conditions_statement  :  if_statement {;}
		                  |  while_loop   {;}
		                  |  do_while     {;}	
                      |  for_loop     {;}
                      |  switch_statement {;};
                      

condition     :'(' condition ')'        {;}
              | condition AND condition {math_op("AND");}
              | condition OR condition  {math_op("OR");}
              | NOT condition {fprintf(fptr,"NOT R%d R%d\n",cur_reg-1,cur_reg-1);}
              | condition_term {;};
              
condition_term: math_exp EQ math_exp  {math_op("CMPE");}
              | math_exp NEQ math_exp {math_op("CMPNE");}
              | math_exp GTE math_exp {math_op("CMPGE");}
              | math_exp GT math_exp  {math_op("CMPGT");}
              | math_exp LT math_exp  {math_op("CMPLT");}
              | math_exp LTE math_exp {math_op("CMPLE");};	

if_statement  :  IF '('condition')' bracket_open statement bracket_close ELSE if_statement {;}
		          |  IF '('condition')' bracket_open statement bracket_close ELSE '{' statement '}' {;}
		          |  IF '('condition')' bracket_open statement bracket_close {;};

while_loop    : WHILE {fprintf(fptr,"LABLE%d : \n", add_label());} '(' condition ')' bracket_open statement close_loop {;};

do_while      : DO    {fprintf(fptr,"LABLE%d : \n", add_label());} '{' {open_scope();} statement '}' {end_scope();} WHILE '('condition')' ';' {fprintf(fptr,"JT R%d LABLE%d\n", cur_reg-1, get_label(0));};		
		
for_loop      : FOR '(' assign_statement ';' {fprintf(fptr,"LABLE%d : ", add_label());} condition ';' {fprintf(fptr,"JF R%d LABLE%d\n", cur_reg-1, add_label());open_scope();} assign_statement ')' '{' statement  close_loop  {;}
              | FOR '(' {open_scope();} variables ';' {fprintf(fptr,"LABLE%d : ", add_label());} condition ';'{fprintf(fptr,"JF R%d LABLE%d\n", cur_reg-1, add_label());} assign_statement ')' '{' statement close_loop {;};

switch_statement  : SWITCH {switch_reg = cur_reg;} '(' init_num ')' '{' cases default '}' {fprintf(fptr,"LABLE%d : \n", switch_start);};
			
cases   : CASE {if(switch_start != 0){cur_reg++;}} math_exp {case_open();} ':' statement	{;}
        | cases BREAK ';' {fprintf(fptr,"JMP LABLE%d\n",switch_start);}
	      | cases cases {;};

default : 
        | DEFAULT ':' statement {fprintf(fptr,"LABLE%d : \n", get_label(0));}
        | DEFAULT ':'  BREAK ';'{fprintf(fptr,"LABLE%d : \n", get_label(0));fprintf(fptr,"JMP LABLE%d\n",switch_start);};

bracket_open  : '{' {fprintf(fptr,"JF R%d LABLE%d\n", cur_reg-1, add_label());open_scope();};
bracket_close : '}' {fprintf(fptr,"LABLE%d : \n", get_label(0));end_scope();};

close_loop: '}' {fprintf(fptr,"JMP LABLE%d : \n", get_label(1)); fprintf(fptr,"LABLE%d : \n", get_label(0));end_scope();}

//Functions

def_functions : start_func FUNC '(' def_argument ')' ';' {save_func($2,cur_num_arg,cur_typ_arg);printf(fptr,"Names = %s",func_names[0]);}; 

function      : start_func FUNC '(' argument ')' '{'  {fprintf(fptr,"%s :\n",$2);assign_par();open_scope();printf(fptr,"Find Function in %d",find_function($2,cur_num_arg,cur_typ_arg));} statement return_s func_return {;}
              | start_func FUNC '(' argument ')' '{'  {fprintf(fptr,"%s :\n",$2);assign_par();open_scope();printf(fptr,"Find Function in %d",find_function($2,cur_num_arg,cur_typ_arg));}  return_s func_return {;};

start_func    : DEF {func = 1;};

call_function  : FUNC '(' parameter ')' {stack[end_stack++] = functin_return;fprintf(fptr,"Push FUNC%d\n",functin_return);fprintf(fptr,"CALL %s\n",$1);printf(fptr,"Find Function in %d\n",find_function($1,cur_num_arg,cur_typ_arg));fprintf(fptr,"FUNC%d : \n",functin_return++);}
               | call_function_r FUNC '(' parameter ')' {stack[end_stack++] = functin_return;fprintf(fptr,"Push FUNC%d\n",functin_return);fprintf(fptr,"CALL %s\n",$2);printf(fptr,"Find Function in %d\n",find_function($2,cur_num_arg,cur_typ_arg));fprintf(fptr,"FUNC%d : \n",functin_return++);fprintf(fptr,"Pop R%d\n",cur_reg++);assign($1); is_init[$1-'a'] = 1;}
               | ID '='  FUNC {func = 1;} '(' parameter ')' {stack[end_stack++] = functin_return;fprintf(fptr,"Push FUNC%d\n",functin_return);fprintf(fptr,"CALL %s\n",$3);printf(fptr,"Find Function in %d\n",find_function($3,cur_num_arg,cur_typ_arg));fprintf(fptr,"FUNC%d : \n",functin_return++);fprintf(fptr,"Pop R%d\n",cur_reg++);assign($1); is_init[$1-'a'] = 1;};

argument    : 
            | variables  {par_func_num++;cur_num_arg++;}
		        | argument ',' argument {;};

return_s    :
            | RETURN math_exp ';' {fprintf(fptr,"Push R%d\n",cur_reg-1);}
            | RETURN init_char';' {fprintf(fptr,"Push R%d\n",cur_reg-1);};

func_return : '}' {end_scope();fprintf(fptr,"POP R%d\n",cur_reg);fprintf(fptr,"JMP R%d\n",cur_reg);};

def_argument  : 
              | types   {cur_num_arg++;}
		          | def_argument ',' def_argument {;};

types         : INTEGER_TYPE {cur_typ_arg[cur_num_arg] = 1;}
              | FLOAT_TYPE   {cur_typ_arg[cur_num_arg] = 2;}
              | STRING_TYPE  {cur_typ_arg[cur_num_arg] = 3;}
              | CHAR_TYPE    {cur_typ_arg[cur_num_arg] = 4;};


call_function_r : INTEGER_TYPE ID '='  {declare($2,0); is_init[$2-'a'] = 1;$$=$2;}
                | FLOAT_TYPE   ID '='  {declare($2,1); is_init[$2-'a'] = 1;$$=$2;}
                | STRING_TYPE  ID '='  {declare($2,2); is_init[$2-'a'] = 1;$$=$2;}
                | CHAR_TYPE    ID '='  {declare($2,3); is_init[$2-'a'] = 1;$$=$2;};

//will consider all int and float convert to int and char and string convert to string 
parameter  : 
           | math_exp  {cur_typ_arg[cur_num_arg] = 1;cur_num_arg++;}
           | init_char {cur_typ_arg[cur_num_arg] = 3;cur_num_arg++;}
           | parameter ',' parameter {;};

%%

//
void declare(char id,int type)
{
  int idx = id - 'a';
  if(symbols[idx] == 0)
  {
      types[idx]    = type;
      symbols[idx]  = 1;
      constant[idx] = 0;
      if (func == 1){
        par_func[par_func_num] = id;
        scope[idx]    = cur_scope+1;
      }else {
        scope[idx]    = cur_scope;
      }
      printf(fptr,"-----------------------------------------cur_num_arg = %d",cur_num_arg);
      cur_typ_arg[cur_num_arg] = type;
      ST_row(idx);
  }else
  {
      fprintf(fptr,"Syntax Error : %d is an already declared variable\n", id );
  }
  
}

void constant_declare(char id,int type)
{
  int idx = id - 'a';
	if(symbols[idx] == 0) {
    types[idx]   = type;
    symbols[idx] = 1;
    constant[idx] = 1;
    scope[idx]   = cur_scope;
    cur_typ_arg[cur_num_arg] = type;
    printf(fptr,"type = %d",types[idx]);
		fprintf(fptr,"MOV %c,R%d\n",id,--cur_reg);
    ST_row(idx);
	} else {
		fprintf(fptr,"Syntax Error : %c is an already declared\n", id);
	}
}

void assign(char id){
  int idx = id - 'a';
  if(not_def == 1 || not_type == 1){not_type = 0;not_def = 0;return;}
	if(symbols[idx] != 0)
  {
		if(constant[idx] == 0) 
    {
      if(cur_reg ==0){cur_reg = 1;}
			fprintf(fptr,"MOV %c,R%d\n",id,--cur_reg);
			symbols[idx] = 2;
      if(is_init[idx] == 0){is_init[idx] = 1;ST_row(idx);}
      if(func == 1)scope[idx]    = cur_scope;
		} 
    else 
    {
			fprintf(fptr,"Syntax Error : %c is a constant\n", id);
		}
	} else {
		fprintf(fptr,"Syntax Error : %c is not declared\n", id);
	}
}

void declare_initalize(char id,int type){
  int idx = id - 'a';
	if(symbols[idx] == 0)
  {
    types[idx]   = type;
    symbols[idx] = 2;
    scope[idx]   = cur_scope;
    constant[idx] = 0;
    cur_typ_arg[cur_num_arg] = type;
    if(is_init[idx] == 0){is_init[idx] = 1;ST_row(idx);}
    printf(fptr,"type = %d",types[idx]);
		if(start)
    {
			fprintf(fptr,"MOV %c,R%d\n",id,--cur_reg);
		}
    else
    {
			if(after_hp)
				fprintf(fptr,"MOV %c,R4\n",id);
			else
				fprintf(fptr,"MOV %c,R0\n",id);
		}
	}
  else 
  {
		fprintf(fptr,"Syntax Error : %c is an already declared variable\n", id);
	}
}
//
void math_op(char * op)
{
  int r3,r2,r1;
  if (cur_reg != 1){
    r3 = --cur_reg;
    r2 = --cur_reg;
    r1 = cur_reg;
    //if (cur_reg == 0){cur_reg++;}
  }else{
    r3 = cur_reg;
    r2 = --cur_reg;
    r1 = cur_reg;
    //cur_reg++;
  }
  fprintf(fptr,"%s R%d,R%d,R%d\n", op, r1, r2 ,r3 );
  cur_reg++;
  
}
//brackets
void open_scope() {
	cur_scope++;
}
void end_scope() {
	for (int i = 0; i < 52; i++) {
			if (scope[i] == cur_scope ) {
				scope[i] = -1;
				symbols[i] = 0;
			}
	}
	cur_scope--;
}
int add_label()
{
	labels++;
	last_nested_idx ++;
	nested_labels[last_nested_idx] = labels;
	return labels;
}

int get_label(int ind)
{
	int label = nested_labels[last_nested_idx-ind];
	return label;
}

//
void case_open()
{
  int lable;
  if(switch_start == 0)
  {
    lable = add_label();
    switch_start = lable;
  }
  else{
    fprintf(fptr,"LABLE%d :\n",get_label(0));
  }
  fprintf(fptr,"CMPE R%d R%d R%d\n",cur_reg-1,switch_reg,cur_reg-1);
  fprintf(fptr,"JF R%d LABLE%d\n", cur_reg-2, add_label());
  open_scope();
}     
//
void check_scope(char var)
{
  if(symbols[var-'a'] == 1)
  {
    fprintf(fptr,"Error: %c is not initialized\n", var);
  }
  else if(symbols[var-'a'] == 2)
  {
      fprintf(fptr,"MOV R%d, %c\n",cur_reg++,var);
  }
  else {
    fprintf(fptr,"Error: %c is not declared\n", var);
  }
}

///////Functions////////
void save_func(char* name,int num_parameters,int * types)
{
  printf(fptr,"Name = %s\n",name);
  func_names[func_num]   = name;
  printf(fptr,"Name = %s\n",func_names[func_num]);
  func_num_arg[func_num] = num_parameters;
  for (int i =0; i < 100; i++){func_typ_arg[func_num][i] = types[i];}
  func_num += 1;
  cur_num_arg = 0;
}
int find_function(char* name,int num_parameters,int * types)
{
  int i = 0;
  int find_num = -1;
  cur_num_arg = 0;
  while (i < func_num+1)
  {
    printf(fptr,"Name = %s and %s\n",func_names[i], name);
    printf(fptr,"find_num = %d\n\n",find_num);
    if(func_names[i] != NULL && strcmp(name,func_names[i]) == 0)
    {
      int j;
      if(num_parameters == func_num_arg[i])
      {
        j = 0;
        printf(fptr,"matching1 %d %d\n",func_typ_arg[i][j],types[j]);
        while(func_typ_arg[i][j] == types[j] && types[j]!=0)
        {
          printf(fptr,"matching %d %d\n",func_typ_arg[i][j],types[j]);
          j++;
          find_num = i;
        }
        
        if(types[j] == 0 && j ==0 && func_typ_arg[i][j] == types[j]){find_num = i;}
        if(types[j] != 0 && func_typ_arg[i][j] != types[j])
        { 
          find_num = -1;
        }
        else{return find_num;}
      }
    }
    i++;
  }
  return find_num;
}
void assign_par()
{
  for (int i = 0;i<par_func_num;i++)
  {
    int idx = par_func[i] - 'a';
    fprintf(fptr,"Pop R%d\n",stack[end_stack-par_func_num+i]);
    fprintf(fptr,"MOV %c, R%d\n",par_func[i],stack[end_stack-par_func_num+i]);
    scope[idx] = cur_scope+1;
    is_init[idx] = 1;
  }
  end_stack-=par_func_num;
  par_func_num = 0;
  func = 0;
}

void clear()
{
  cur_reg = 0;
  start = 1;
	after_hp = 0;
	//fprintf(fptr,"\n");
}

int yyerror(char* s)
{
  fprintf(stderr, "%s\n",s);
  return 1;
}
int yywrap()
{
  return(1);
}
void print_symbolTable(){
  fprintf(STfptr,"Variable  ");
  fprintf(STfptr,"Type      ");
  fprintf(STfptr,"Scope     ");
  fprintf(STfptr,"is_init   ");
  fprintf(STfptr,"is_const  \n");
}
void ST_row(int i){
  fprintf(STfptr,"%c         ",i+'a');
  if(types[i] == 1){fprintf(STfptr,"int           ");}
  else if(types[i] == 2){fprintf(STfptr,"float         ");}
  else if(types[i] == 3){fprintf(STfptr,"string        ");}
  else if(types[i] == 4){fprintf(STfptr,"char          ");}
  fprintf(STfptr,"%d         ",scope[i]);
  fprintf(STfptr,"%d         ",is_init[i]);
  fprintf(STfptr,"%d         \n",constant[i]);
}
int main(void) {
  char chr;
  //yydebug = 1;
  fptr = fopen("C:\\Users\\Salma Ibrahim\\Desktop\\out.txt","w");
  STfptr = fopen("C:\\Users\\Salma Ibrahim\\Desktop\\SymbolTable.txt","w");
  print_symbolTable();

  yyparse();
  scanf("%c",&chr);
  fclose(fptr);
  fclose(STfptr);
  return 0;
}