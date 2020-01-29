#!/bin/bash

DEV_DIR=/home/icrystal/dev
LEETCODE_DIR="$DEV_DIR/cpp/leetcode"

function process_init()
{
    if [[ ! $1 =~ ^[0-9]+\. ]]; then
        echo "NOT INVALID NAME: [number].[name]"
        return 1
    fi

    dir=$LEETCODE_DIR/$1
    if [ ! -d $dir ]; then mkdir $dir; fi

    include_header='#include <algorithm>\n#include <iostream>\n'
    namespace='using namespace std;\n\n'
    class_def=`xsel -o -b`
    main_func='int main() {\n\tSolution s;\n\n\tstd::cout << "OK!" << std::endl;\n}\n'

    echo "$include_header$namespace$class_def\n\n$main_func" > $dir/main.cpp
    cd $dir
    vim main.cpp
}


function process_submit()
{
    if [ ! -f main.cpp ]; then return 1; fi

    start_line=`cat main.cpp| grep 'Solution' -n|head -1|awk -F ':' '{print $1}'`
    if [ $? -ne 0 ]; then return 2; fi
    array=(`cat main.cpp| grep '^};$' -n|awk -F ':' '{print $1}'`)
    if [ $? -ne 0 ]; then  return 2;  fi
    for var in $array;
    do
        if [ $var -ge $start_line ]; then
            end_line=$var
            sed -n "$start_line,$end_line p" main.cpp | xsel -i -b
            return 0
        fi
    done
}


function process_cd
{
    cd $LEETCODE_DIR
    if [[ $1 =~ ^[0-9]+$ ]]; then
        dir=`ls | grep "^$1"`
        if [ $? -eq 0 ]; then
            if [ $(echo $dir | wc -l) -eq 1 ]; then
                echo "OK!"
                cd $dir
            else
                echo $dir
            fi
        else
            echo "ERROR: not found!"
        fi
    else
        dir=`ls | grep "$1"`
        if [ $? -eq 0 ]; then
            echo "OK!"
            cd $dir
        else
            echo "ERROR: not found!"
        fi
    fi
}


if [ $# -ne 0 ]; then
    case $1 in
    edit)
        vim $DEV_DIR/shell/leetcode.sh
        ;;
    home)
        cd $LEETCODE_DIR
        ;;
    cd)
        if [ $# -eq 2 ]; then
            process_cd $2
        fi
        ;;
    init)
        if [ $# -eq 2 ]; then
            process_init $2
        else
            echo "ERROR: command 'init' accept one parameter"
        fi
        ;;
    submit | commit | c)
        parent_dir=$(dirname "$PWD")
        if [ "$parent_dir" = "$LEETCODE_DIR" ]; then
            process_submit
        else
            echo "ERROR"
        fi
        ;;
    esac
fi

