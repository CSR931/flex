# flex
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

### 工作流程与运行
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

