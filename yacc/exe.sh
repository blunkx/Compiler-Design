#!/usr/bin/env bash
prog_name=parser
if [[ -n "$1" ]]
then
    cat $1| ./$prog_name >out.txt
else
    cat input.kt| ./$prog_name >out.txt
fi