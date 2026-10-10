%{
#include <stdio.h>
#include <string.h>

FILE* g_out = NULL;

void emit(const char* type, const char* text) {
    fprintf(g_out, "%s %s\n", type, text);
}

//正则别名别写注释
/* 扫描完一个文件直接结束、维护行号，\n自动+1 */
/* %x ML_COMMENT用于多行注释的状态切换，理解为DFA的子状态 */
%}

%option noyywrap yylineno

DIGIT      [0-9]
LETTER     [a-zA-Z_]
ID         {LETTER}({LETTER}|{DIGIT})*
INTCONST   {DIGIT}+
STRCHARS   \"([^"\\]|\\.)*\"

%x ML_COMMENT

%%
"/*"              { BEGIN(ML_COMMENT); }
<ML_COMMENT>"*/"  { BEGIN(INITIAL); }
<ML_COMMENT>\n    { }
<ML_COMMENT>.     { }
<ML_COMMENT><<EOF>> {
    fprintf(stderr, "error: unterminated /* comment at line %d\n", yylineno);
    BEGIN(INITIAL);
}

"//".*            { }

{STRCHARS}        { emit("STRCON", yytext); }

"const"           { emit("CONSTTK", yytext); }
"int"             { emit("INTTK",   yytext); }
"void"            { emit("VOIDTK",  yytext); }
"main"            { emit("MAINTK",  yytext); }
"if"              { emit("IFTK",    yytext); }
"else"            { emit("ELSETK",  yytext); }
"while"           { emit("WHILETK", yytext); }
"break"           { emit("BREAKTK", yytext); }
"continue"        { emit("CONTINUETK", yytext); }
"return"          { emit("RETURNTK", yytext); }
"getint"          { emit("GETINTTK", yytext); }
"printf"          { emit("PRINTFTK", yytext); }

{ID}              { emit("IDENFR", yytext); }

{INTCONST}        { emit("INTCON", yytext); }

"=="              { emit("EQL",  yytext); }
"!="              { emit("NEQ",  yytext); }
"<="              { emit("LEQ",  yytext); }
">="              { emit("GEQ",  yytext); }
"&&"              { emit("AND",  yytext); }
"||"              { emit("OR",   yytext); }

"="   { emit("ASSIGN", yytext); }
"<"   { emit("LSS",  yytext); }
">"   { emit("GRE",  yytext); }
"+"   { emit("PLUS", yytext); }
"-"   { emit("MINU", yytext); }
"*"   { emit("MULT", yytext); }
"/"   { emit("DIV",  yytext); }
"%"   { emit("MOD",  yytext); }
"!"   { emit("NOT",  yytext); }
"("   { emit("LPARENT", yytext); }
")"   { emit("RPARENT", yytext); }
"["   { emit("LBRACK",  yytext); }
"]"   { emit("RBRACK",  yytext); }
"{"   { emit("LBRACE",  yytext); }
"}"   { emit("RBRACE",  yytext); }
","   { emit("COMMA",   yytext); }
";"   { emit("SEMICN",  yytext); }

[ \t\r]+          { }
\n                { }

. {
    fprintf(stderr, "lex error: unknown char '%s' at line %d\n", yytext, yylineno);
}

%%

int main() {
    yyin = fopen("testfile.txt", "r");
    if (!yyin) {
        fprintf(stderr, "cannot open testfile.txt\n");
        return 1;
    }
    g_out = fopen("output.txt", "w");
    if (!g_out) {
        fclose(yyin);
        fprintf(stderr, "cannot open output.txt\n");
        return 1;
    }

    yylineno = 1;
    yylex();

    fclose(yyin);
    fclose(g_out);
    return 0;
}
