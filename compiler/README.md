# Compiler Design Project03
## Compilation
Enter make in shell to compile all files.
```bash
make
```
It will compile the source code into binary named `compiler`.
## Input to the parser using shell pipes

1. Use `exe.sh` to execute the compiler, the defalut input file name is `input.kt`.<br />
2. You can also pass the file name as the first parameter for `exe.sh`.
```bash
./exe.sh [filename]
````
3. The shell script automatically generates an output file named `symbol_table.txt` and javabytecode named `output.jasm`.
4. Convert java bytecode to java executable using java assembler.
```bash
./javaa [filename]
````
