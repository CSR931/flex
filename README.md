# Flex/Bison
编译原理实验相关自学

### 实验环境
**并未采用Windows WSL或者MSYS2，而是轻量的WinFlex+MinGW**

下载WinFlexBison
https://github.com/lexxmark/winflexbison/releases

下载MinGW-w64
https://github.com/niXman/mingw-builds-binaries/releases
下载x86_64-posix-seh版本

**配置环境变量**

“此电脑”，“系统属性”，“环境变量”，“***（用户名）的用户变量”里找到PATH，双击打开，新建，输入
```
C:\winflex
C:\mingw64\bin
（以此地址为例）
```
上移到靠前位置，全选确定，关闭
重新打开CMD界面验证
```
win_flex --version
gcc --version
where win_flex
where gcc
```
## 词法分析
### **.l文件结构

在实验文件夹中新建，编码选ANSI或者UTF-8

文件结构：（用%%分隔区域）

定义区：选项、C 头文件、正则表达式的命名定义

%%

规则区：正则表达式及对应的 C 动作

%%

用户代码区：main 等 C 函数

**详细结构**
```
├── 定义段（%{ ... %}）
│   ├── 头文件包含
│   ├── 全局变量（g_out 输出文件指针）
│   └── emit() 函数（输出 Token）
├── 选项声明
│   ├── %option noyywrap   不依赖 yywrap
│   └── %option yylineno   自动维护行号
├── 正则别名定义
│   ├── DIGIT, LETTER, ID, INTCONST, STRCHARS
│   └── 多行注释起始条件 %x ML_COMMENT
├── 规则段（%% ... %%）
│   ├── 多行注释 /* */ 规则
│   ├── 单行注释 // 规则
│   ├── 格式字符串规则
│   ├── 关键字规则（12个）
│   ├── 标识符规则
│   ├── 数字常量规则
│   ├── 双字符运算符规则
│   ├── 单字符运算符/界符规则
│   ├── 空白符规则
│   └── 非法字符规则（报错不中断）
└── 用户代码段
    └── main()
        ├── 打开 testfile.txt 和 output.txt
        ├── 调用 yylex() 启动扫描
        └── 关闭文件
```

### 词法分析工作流程与运行
```
规则文件 hello.l
      | flex hello.l
      v
生成的 C 文件 lex.yy.c
      | gcc lex.yy.c -o hello
      v
可执行程序 hello
      | 读取输入文本
      v
输出识别结果
```
将textfile.txt放入实验文件夹

打开CMD，进入实验文件夹，具体代码：
```
win_flex lexer.l
gcc lex.yy.c -o lexer.exe
lexer.exe
```

## 语法分析
### **.y文件结构

1. 声明部分（第一个 %% 之前）
```
%glr-parser                    // 启用 GLR 模式，允许处理冲突

%{
#include <stdio.h>
...
void print_nonterm(const char* name);
%}

%token INTTK CONSTTK ...       // 声明所有终结符（Token）
%nonassoc IFTK                 // 优先级声明，解决悬空 else
%left OR AND ...
%right ASSIGN

%start CompUnit                // 指定起始符号
```
C 声明区 (%{ ... %})：嵌入 C 头文件、全局变量、函数原型。这里的代码会被原样复制到生成的 parser.tab.c 顶部。

Token 声明：告诉 Bison 哪些符号是终结符（由 Flex 返回）。Bison 会自动为每个 Token 分配一个整数编号（从 258 开始）。

优先级与结合性：%left、%right、%nonassoc 定义了运算符的优先级和结合方向，用于解决表达式中的 shift/reduce 冲突。例如 %left PLUS MINU 表示加减左结合，优先级低于乘除。

起始符号：%start CompUnit 指定文法开始的地方。

2. 规则部分（两个 %% 之间）
规则形如：
```
左部 : 右部1 { 动作1 }
     | 右部2 { 动作2 }
     ;
```
左部：非终结符（语法成分）。

右部：终结符和非终结符组成的序列。

动作：归约时执行的 C 代码。花括号内的代码会被插入到生成的 yyparse() 函数中，当这条产生式被归约时执行。

空产生式：/* empty */ 表示可以匹配空串。

3. 用户子程序部分（第二个 %% 之后）
```
void print_nonterm(const char* name) { ... }
void yyerror(const char* s) { ... }
int main() { ... }
```
放置辅助函数的实现，如 print_nonterm（过滤并输出非终结符）、yyerror（错误处理）、main（入口函数）。

### Flex和Bison的底层逻辑
**Flex 的工作机制**

• Flex 将正则表达式编译成一个确定性有限自动机（DFA），运行时逐字符驱动 DFA 状态转移。

• 当遇到匹配最长规则的模式时，执行对应动作（通常是 fprintf 输出 Token 文本并 return 类型编号）。

• 例如输入 int，DFA 匹配到关键字规则，输出 "INTTK int\n"，返回 INTTK。

**Bison 的工作机制**

• Bison 根据文法生成 LALR(1) 分析表（Action/Goto 表）。分析表决定了在给定当前状态和下一个 Token 时，是移进（shift）还是归约（reduce）。

• 移进：将当前 Token 压入分析栈，并转到新状态。

• 归约：弹出栈顶若干符号（对应产生式右部长度），将左部非终结符压入栈，并根据 Goto 表转至下一状态。

• 分析过程中不断调用 yylex() 获取 Token，直到遇到 $end（文件结束）且归约到起始符号 CompUnit。

### 语法分析工作流程与运行
将textfile.txt放入实验文件夹

打开CMD，进入实验文件夹，具体代码：
```
win_bison -d parser.y
win_flex lexer.l
gcc lex.yy.c parser.tab.c -o compiler.exe
compiler.exe
```
