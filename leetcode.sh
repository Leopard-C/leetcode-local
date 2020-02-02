#!/bin/bash

DEV_DIR=/home/icrystal/dev
LEETCODE_DIR="$DEV_DIR/cpp/leetcode"
THIS_FILE=$DEV_DIR/shell/leetcode/leetcode.sh


## 添加新的题目
#   
function process_new()
{
    clipboard_content=`xsel -o -b`
    line_num=`echo $clipboard_content | wc -l`
    let line_num=line_num-1
    dir_name=`echo $clipboard_content | head -1`
    class_def=`echo $clipboard_content | tail -$line_num`

    dir="$LEETCODE_DIR/$dir_name"
    if [ ! -d $dir ]; then
        mkdir -p $dir
    else
        echo "Error: Already exist, now you are in the directory"
        cd $dir
        return 1
    fi

    # 生成代码模板
    include_header='#include <algorithm>\n#include <iostream>\n'
    namespace='using namespace std;\n\n'
    #class_def=`echo $clipboard_content | tail -$line_num`
    main_func='int main() {\n\tSolution s;\n\n\tstd::cout << "OK!" << std::endl;\n}\n'

    echo "$include_header$namespace$class_def\n\n$main_func" > $dir/.template.cpp

    # 不同解题方案放在不同文件夹
    # 初始文件夹为solution1
    mkdir $dir/solution1
    cd $dir/solution1
    cp ../.template.cpp main.cpp
    vim main.cpp
}


## 初始化题目的新的解决方案
#
function process_init()
{
    if [ -e "../.template.cpp" ]; then
        cd ..
    fi

    if [ -e ".template.cpp" ]; then
        latestSolutionId=`ls -l |grep "^d" |wc -l`
        newSolutionId=$(($latestSolutionId+1))
        mkdir "solution$newSolutionId"
        cd "solution$newSolutionId"
        cp ../.template.cpp main.cpp
        vim main.cpp
    fi
}


## 提取Solution类的代码, 复制到剪贴板
#
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


## 进入指定题目的目录
#
function process_cd
{
    cd $LEETCODE_DIR

    # 进入题目的主目录
    if [[ $1 =~ ^[0-9]+$ ]]; then
        dir=`ls | grep "^$1"`
        if [ $? -eq 0 ]; then
            if [ $(echo $dir | wc -l) -eq 1 ]; then
                cd $dir
            else
                echo $dir
            fi
        else
            echo "ERROR: not found!"
            return 1
        fi
    else
        dir=`ls | grep "$1"`
        if [ $? -eq 0 ]; then
            cd $dir
        else
            echo "ERROR: not found!"
            return 1
        fi
    fi

    # 进入不同解题方案目录
    if [ $# -eq 1 ]; then
        process_cds
    else
        process_cds $2
    fi
}


# 进入不同解题方案目录
#
function process_cds()
{
    if [ $# -eq 0 ]; then
        latestSolutionId=`ls -l |grep "^d" |wc -l`
        solutionDir="solution$latestSolutionId"
        cd $solutionDir 
        echo "You are in solution $latestSolutionId directory"
    elif [ $# -eq 1 ]; then
        solutionDir="solution""$1"
        if [ -d $solutionDir ]; then
            cd $solutionDir
            echo "You are in solution $1 directory"
        else
            echo "Error: not found the solution"
            return 1
        fi
    fi
}

## main function
#
function main_func() 
{
    if [ $# -eq 0 ]; then
        if [ -f main.cpp ]; then
            vim main.cpp
        fi
        return 0
    fi

    case $1 in
    edit)
        line=`cat $THIS_FILE |grep "main_func()" -n |head -1 |awk -F ':' '{print $1}'`
        if [ $? -eq 0 ]; then
            vim $THIS_FILE +$line
        else
            vim $THIS_FILE
        fi
        ;;
    open | url)
        google-chrome https://leetcode-cn.com/problemset/all/\?difficulty\=%E7%AE%80%E5%8D%95
        ;;    
    home)
        cd $LEETCODE_DIR
        ;;
    cd)
        if [ $# -eq 1 ]; then
            cd $LEETCODE_DIR
        elif [ $# -eq 2 ]; then
            process_cd $2
        elif [ $# -eq 3 ]; then
            process_cd $2 $3
        fi
        ;;
    cds)
        if [ -e "../.template.cpp" ]; then
            cd ..
        fi

        if [ ! -e ".template.cpp" ]; then
            echo "Error: You are not in a question directory"
            return 1
        fi

        if [ $# -eq 1 ]; then
            process_cds
        elif [ $# -eq 2 ]; then
            process_cds $2
        fi
        ;;
    ls)
        $@ $LEETCODE_DIR
        ;;
    ll)
        ls -l $LEETCODE_DIR
        ;;
    new)
        if [ $# -eq 1 ]; then
            process_new
        else
            echo "ERROR: command 'init' doesn't accept any parameter"
        fi
        ;;
    init)
        if [ $# -eq 1 ]; then
            process_init
        else
            echo "ERROR: command 'init' doesn't accept any parameter"
        fi
        ;;
    submit | commit | c)
        process_submit
        ;;
    esac
}


main_func $@

