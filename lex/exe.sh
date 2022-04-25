#!/usr/bin/env bash
prog_name=scanner
if [[ -n "$1" ]]
then
    cat input.txt| ./$1 >out.txt
else
    cat input.txt| ./$prog_name >out.txt
fi