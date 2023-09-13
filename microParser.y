

%{
    #include <stdio.h>
    #include <stdlib.h>
	#include <iostream>
    #include <string>
    #include <vector>
    #include "classes/symbolTableStack.hpp"
	#include "classes/codeObject.hpp"
    #include "classes/ast.cpp"
    #include "classes/assemblyCode.hpp"

    
	using namespace std;

	extern "C" FILE *yyin;
	extern "C" int yyparse();
    extern "C" int yylex();
    void yyerror(const char *message);

    SymbolTableStack *tableStack = new SymbolTableStack();
	CodeObject *threeAC = new CodeObject(tableStack);
    AssemblyCode *assembly_code = new AssemblyCode();

%}

%token PROGRAM _BEGIN END FUNCTION READ WRITE IF ELSE FI FOR ROF RETURN VOID


%token STRING
%token <floatval>FLOATLITERAL
%token <intval>INTLITERAL
%token <floatval>FLOAT
%token <strval>STRINGLITERAL 
%token <intval>INT
%token <strval>IDENTIFIER

%token ADD SUBTRACT MULTIPLY DIVIDE ASSIGNMENT
%token ET NET LT GT OB CB LTE GTE
%token SEMICOLON COMMA



%type <strval> str id
%type <strlist> id_list id_tail
%type <intval> var_type
%type <astnode> mulop addop primary postfix_expr factor_prefix factor expr_prefix expr 
%type <astnode> return_stmt call_expr
%type <astlist> expr_list expr_list_tail

%union {
    int intval;
    float floatval;
    std::string* strval;
    std::vector<std::string*> *strlist;

	ASTNode *astnode;
	std::vector<ASTNode*> *astlist;
}


%%

program: 			PROGRAM id _BEGIN 
					{
						tableStack->addNewTable("GLOBAL");
					}
					pgm_body END  ;
id: 				IDENTIFIER ;
pgm_body: 			decl func_declarations ;
decl: 				string_decl decl | var_decl decl |  ;

string_decl: 		STRING id ASSIGNMENT str SEMICOLON 
					{
						tableStack->insertSymbol(*($2), "STRING", *($4));
					};
str: 				STRINGLITERAL  ;

var_decl: 			var_type id_list SEMICOLON 
					{
		                std::string str_type = "";
		                std::vector<std::string*> list = *$2;
		                for (int i = list.size(); i != 0; --i)
		                {
		                    if ($1 == FLOAT)
		                    {
		                        tableStack->insertSymbol(*(list[i-1]), "FLOAT");
		                    }
		                    else if ($1 == INT)
		                    {
		                        tableStack->insertSymbol(*(list[i-1]), "INT");
		                    }
		                }
		            };
var_type: 			FLOAT { $$ = FLOAT; } | INT { $$ = INT;} ;
any_type: 			var_type | VOID ;
id_list: 			id id_tail 
					{
                        $$ = $2;
                        $$->push_back($1);
                    };
id_tail: 			COMMA id id_tail
					{
                        $$ = $3;
                        $$->push_back($2);
                    } |
					{
                        std::vector<std::string*>* temp = new std::vector<std::string*>;
                        $$ = temp;
                    } ;

param_decl_list: 	param_decl param_decl_tail |  ;
param_decl: 		var_type id
					{
                        if ($1 == FLOAT)
                            tableStack->insertSymbol(*$2, "FLOAT", true);
                        else if ($1 == INT)
                            tableStack->insertSymbol(*$2, "INT", true);
                    } ;
param_decl_tail: 	COMMA param_decl param_decl_tail |  ;

func_declarations: 	func_decl func_declarations |  ;
func_decl: 			FUNCTION any_type id 
					{
                        tableStack->addNewTable(*($3));
                    } OB param_decl_list CB _BEGIN func_body END ;
func_body: 			decl stmt_list ;

stmt_list: 			stmt stmt_list |  ;
stmt: 				base_stmt | if_stmt | for_stmt ;
base_stmt: 			assign_stmt | read_stmt | write_stmt | return_stmt ;

assign_stmt: 		assign_expr SEMICOLON ;

assign_expr: 		id ASSIGNMENT expr 
					{
                        ASTNode * node = new ASTNode_Assign(tableStack->findEntry(*$1));
                        node->right = $3;
                        node->generateCode(threeAC);
                    };

read_stmt: 			READ OB id_list CB SEMICOLON
					{
                        std::vector<std::string*> list = *($3);
                        for (int i = list.size(); i != 0; --i)
                        {
                            std::string name = *(list[i-1]);
                            std::string type = tableStack->findType(name);
                            threeAC->addRead(name, type);
                        }
                    };

write_stmt: 		WRITE OB id_list CB SEMICOLON 
					{
                        std::vector<std::string*> list = *($3);
                        for (int i = list.size(); i != 0; --i)
                        {
                            std::string name = *(list[i-1]);
                            std::string type = tableStack->findType(name);
                            threeAC->addWrite(name, type);
                        }
                    };


return_stmt: 		RETURN expr SEMICOLON
					{
						ASTNode * retnode = new ASTNode_Return();
						retnode->right = $2;
						retnode->generateCode(threeAC);
					} ;

expr: 				expr_prefix factor
					{
                        if ($1 == nullptr)
                            $$ = $2;
                        else
                        {
                            $1->right = $2;
                            $$ = $1;
                        }
                    };

expr_prefix: 		expr_prefix factor addop 
					{
                        if ($1 == nullptr)
                            $3->left = $2;
                        else
                        {
                            $1->right = $2;
                            $3->left = $1;
                        }
                        $$ = $3;
                    }	|
					{ $$ = nullptr; };

factor: 			factor_prefix postfix_expr 
					{
                        if ($1 == nullptr)
                            $$ = $2;
                        else
                        {
                            $1->right = $2;
                            $$ = $1;
                        }
                    };

factor_prefix: 		factor_prefix postfix_expr mulop 
					{
                        if ($1 == nullptr)
                            $3->left = $2;
                        else
                        {
                            $1->right = $2;
                            $3->left = $1;
                        }
                        $$ = $3;
                    }	|  
					{ $$ = nullptr; };


postfix_expr: 		primary 
					{ $$ = $1; }	| 
					call_expr 
					{ $$ = $1; };

call_expr: 			id OB expr_list CB 
					{
						$$ = new ASTNode_CallExpr(*($1), $3);
						
						//callnode -> generateCode(threeAC);
					};

expr_list: 			expr expr_list_tail 
					{
                        $$ = $2;
                        $$->push_back($1);
                    } |  
					{
                        std::vector<ASTNode*>* temp = new std::vector<ASTNode*>;
                        $$ = temp;
                    };

expr_list_tail: 	COMMA expr expr_list_tail 
					{
                        $$ = $3;
                        $$->push_back($2);
                    } | 
					{
                        std::vector<ASTNode*>* temp = new std::vector<ASTNode*>;
                        $$ = temp;
                    } ;

primary: 			OB expr CB 
					{ $$ = $2; 											} 
					| id 
					{ $$ = new ASTNode_ID(tableStack->findEntry(*$1)); 	}
					| INTLITERAL 
					{ $$ = new ASTNode_INT($1); 						}
					| FLOATLITERAL
					{ $$ = new ASTNode_FLOAT($1); 						};


addop: 				ADD 
					{ $$ = new ASTNode_Expr('+'); }
					| SUBTRACT 
					{ $$ = new ASTNode_Expr('-'); };

mulop: 				MULTIPLY 
					{ $$ = new ASTNode_Expr('*'); }
					| DIVIDE
					{ $$ = new ASTNode_Expr('/'); } ;

if_stmt: 			IF
					{
                        tableStack->addNewTable();
                    } OB cond CB decl stmt_list else_part FI ;
else_part: 			ELSE 
					{
                        tableStack->addNewTable();
                    } decl stmt_list |  ;
cond: 				expr compop expr ;
compop: 			LT | GT | ET | NET | LTE | GTE ;

init_stmt: 			assign_expr |  ;
incr_stmt: 			assign_expr |  ;

for_stmt: 			FOR
					{
                        tableStack->addNewTable();
                    } OB init_stmt SEMICOLON cond SEMICOLON incr_stmt CB decl stmt_list ROF ;

%%

void yyerror(const char *message)
    {
        // printf("Not Accepted\n");
        // exit(0);
        int err = 1;
    }

int main(int argc, char* argv[])
{
    /* Call the lexer, then quit. */
    
    FILE *file = fopen(argv[1], "r");
    yyin = file;
    int flag;
    flag = yyparse();
	fclose(yyin);


    if (flag == 0){
    	//printf("flag: %d", flag );
        //tableStack->printStack();
		assembly_code->generateCode(threeAC, tableStack);
		//tableStack->printStack();
		//printf("\n");
    	assembly_code->print();
    }

    else
    {
        printf("Grammer not accepted\n");
    }

    return 0;
}

