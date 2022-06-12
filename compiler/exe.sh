#!/usr/bin/env bash
prog_name=compiler
if [[ -n "$1" ]]
then
    cat $1| ./$prog_name >symbol_table.txt
    ./javaa output.jasm
else
    cat Kotlin/input.kt| ./$prog_name >symbol_table.txt
    ./javaa output.jasm
fi