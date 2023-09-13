%{
	#include <iostream>
    #include <vector>
    #include <string>    
	#include "classes/ast.hpp"
	#include "microParser.hpp"

	extern "C" int yylex();
%}


%option noyywrap
%option yylineno
DIGIT [0-9]

%%


"PROGRAM"   {return PROGRAM;}
"BEGIN"     {return _BEGIN;}
"END"       {return END;}
"FUNCTION"  {return FUNCTION;}
"READ"      {return READ;}
"WRITE"     {return WRITE;}
"IF"        {return IF;}
"ELSE"      {return ELSE;}
"FI"        {return FI;}
"FOR"       {return FOR;}
"ROF"       {return ROF;}
"RETURN"    {return RETURN;}
"VOID"      {return VOID;}
"INT"       {return INT;}
"STRING"    {return STRING;}
"FLOAT"     {return FLOAT;}

"\""[^"\""]*"\""        {
							yylval.strval = new std::string(yytext);
							return STRINGLITERAL;	}
[0-9]+                	{	yylval.intval = atoi(yytext);
						return INTLITERAL;			}

[0-9]*"."[0-9]*			{	yylval.floatval = atof(yytext);
						return FLOATLITERAL;		}

[a-zA-Z][a-zA-Z0-9]*    {	yylval.strval = new std::string(yytext);
							return IDENTIFIER;		}

":="        {return ASSIGNMENT;}
"+"         {return ADD;}
"-"         {return SUBTRACT;}
"*"         {return MULTIPLY;}
"/"         {return DIVIDE;}
"="         {return ET;}
"!="        {return NET;}
"<"         {return LT;}
">"         {return GT;}
"("          {return OB;}
")"          {return CB;}
";"         {return SEMICOLON;}
","       {return COMMA;}
"<="        {return LTE;}
">="        {return GTE;}


#(.)*\n {

}
"\n" { }
. { }
(" ")* {  }
"\-\-"[^"\n"]*"\n"|"#"[^"\n"]*"\n" {
 			//Comments with # and --
					}

%%

// int yywrap()
//     {
//         return 1;
//     }
