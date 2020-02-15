#!/bin/bash

DEV_DIR=/home/icrystal/dev
LEETCODE_DIR=$DEV_DIR/cpp/leetcode
CONFIG_DIR=$LEETCODE_DIR/.config
CONFIG_FILE=$CONFIG_DIR/data
THIS_FILE=$DEV_DIR/shell/leetcode/leetcode.sh


## Print Usage
#
function printUsage()
{
    echo "lc [command] [option]\n"
    echo "  commands:"
    echo "            new : new question"
    echo "           init : new solution of current question"
    echo "             cd : change to different question"
    echo "            cds : change to different solution of current question"
    echo "            url : open url in chrome browser"
    echo "       edit | e : edit current file"
    echo "       home | h : change directory to leetcode home"
    echo "     commit | c : copy class \"Solution\" to clipboard"
    echo "   template | t : edit template code file of current question"
    echo "    compile | b : compile the source file (b for build)"
    echo "        run | r : run the executable file"
}


## judge the special type of current directory
#
DIR_TYPE_UNKNOWN=0
DIR_TYPE_LEETCODE_DIR=1
DIR_TYPE_PROBLEM_DIR=2
DIR_TYPE_SOLUTION_DIR=3
function getCurrDirType()
{
    currDir=$(pwd)
    if [ ${#currDir} -lt ${#LEETCODE_DIR} ]; then
        return $DIR_TYPE_UNKNOWN
    fi

    if [ ! ${currDir:0:${#LEETCODE_DIR}} = $LEETCODE_DIR ]; then
        return $DIR_TYPE_UNKNOWN
    fi

    if [ ${#currDir} -eq ${#LEETCODE_DIR} ]; then
        return $DIR_TYPE_LEETCODE_DIR
    fi

    slash_count=0
    for i in $(seq $((${#LEETCODE_DIR}+1)) $((${#currDir}-1)))
    do
        char=${currDir:$i:1}
        if [ $char = '/' ]; then
            let slash_count=slash_count+1
        fi
    done

    if [ $slash_count -eq 0 ]; then
        return $DIR_TYPE_PROBLEM_DIR
    elif [ $slash_count -eq 1 ]; then
        return $DIR_TYPE_SOLUTION_DIR
    else
        return $DIR_TYPE_UNKNOWN
    fi
}



## Write config
#  $1: key
#  $2: oldValue
#  $3: newValue
#  $4: configFile
#
function writeConfig()
{
    if [ $# -ne 4 ]; then return 1; fi
    sed -i "s/$1=$2/$1=$3/g" $4
}


## 添加新的题目
#   
function process_new()
{
    clipboard_content=`xsel -o -b`
    echo $clipboard_content |grep --quiet -e "^[0-9]*\."
    if [ $? -ne 0 ]; then
        echo "Error, the content in the clipboard is invalid"
        return 1
    fi

    # New directory name
    dir_name=`echo $clipboard_content | head -1`
    writeConfig lc_latest $lc_latest $dir_name $CONFIG_FILE
    dir="$LEETCODE_DIR/$dir_name"
    if [ ! -d $dir ]; then
        mkdir -p $dir
    else
        echo "Error: Already exist, and now you are in the directory"
        cd $dir
        return 1
    fi

    # Body of class "Solution"
    line_num=`echo $clipboard_content | grep -n "class Solution" | awk -F ':' '{print $1}'`
    class_def=`echo $clipboard_content | sed -n "$line_num,100p"`

    # Description of new question
    # Definition for other data structure used
    echo $clipboard_content | grep -q "Definition" && \
        echo $clipboard_content | grep -q "/\*\*" && \
        echo $clipboard_content | grep -q "\*/"
    if [ $? -eq 0 ]; then
        line_num=`echo $clipboard_content | grep -n "/\*\*" | head -1 | awk -F ':' '{print $1}'`
        line_num1=`echo $clipboard_content | grep -n "Definition" | head -1 | awk -F ':' '{print $1}'`
        let line_num1=line_num1+1
        line_num2=`echo $clipboard_content | grep -n "*/" | head -1 | awk -F ':' '{print $1}'`
        definition=`echo $clipboard_content | sed -n "$line_num1,$line_num2""p" | \
            sed 's/^...//'`
        class_def="$definition""\n\n""$class_def"
    fi

    let line_num=line_num-1
    description=`echo $clipboard_content | \
        sed -n "2,$line_num""p" | \
        awk '{print "* " $0}' | \
        sed '1i\/**************************************************************' | \
        sed '$a\**************************************************************/'`
    echo $description > $dir/description

    # 生成代码模板
    namespace='using namespace std;\n'
    define='#define Log(x) cout << (x) << endl\n'
    header='#include <algorithm>\n#include <iostream>\n'
    STLs=(vector list queue map string)
    for stl in ${STLs[@]}
    do
        echo $class_def |grep -q ${stl}
        if [ $? -eq 0 ]; then
            header="$header""#include <""${stl}"">\n"
        fi
    done
    main_func='int main() {\n\tSolution s;\n\n\tLog("OK!");\n}\n'
    content="$header$namespace\n$define\n$class_def\n\n$main_func"
    echo $content > $dir/.template.cpp

    if [ $# -eq 1 ] &&  [ $1 = "-t" ]; then
        vim $dir/.template.cpp 
    fi

    # 不同解题方案放在不同文件夹
    # 初始文件夹为solution1
    mkdir $dir/solution1
    cd $dir/solution1
    cp $dir/.template.cpp main.cpp
    editMainCpp
}


## 初始化题目的新的解决方案
#
function process_init()
{
    getCurrDirType
    dirType=$?
    if [ $dirType -eq $DIR_TYPE_SOLUTION_DIR ]; then
        echo "helo"
        cd ..
    elif [ $dirType -lt $DIR_TYPE_PROBLEM_DIR ]; then
        echo "ERROR: You are not in a problem directory"
        return 1 
    fi

    if [ -e ".template.cpp" ]; then
        latestSolutionId=`ls -l |grep "^d" |wc -l`
        newSolutionId=$(($latestSolutionId+1))
        mkdir "solution$newSolutionId"
        cd "solution$newSolutionId"
        cp ../.template.cpp main.cpp
        editMainCpp
    fi
}


## 提取Solution类的代码, 复制到剪贴板
#
function process_submit()
{
    if [ ! -f main.cpp ]; then
        echo "ERROR: You are not int a solution directory"
        return 1;
    fi

    start_line=`cat main.cpp| grep 'Solution' -n|head -1|awk -F ':' '{print $1}'`
    if [ $? -ne 0 ]; then return 2; fi
    array=(`cat main.cpp| grep '^};$' -n|awk -F ':' '{print $1}'`)
    if [ $? -ne 0 ]; then return 2; fi
    for var in $array;
    do
        if [ $var -ge $start_line ]; then
            end_line=$var
            sed -n "$start_line,$end_line p" main.cpp | xsel -i -b
            echo "Copied to clipboard!"
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
                return 1
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
    getCurrDirType
    dirType=$?
    if [ $dirType -lt $DIR_TYPE_PROBLEM_DIR ]; then
        echo "ERROR: You are not in a problem directory"
        return 1
    fi

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


## edit main.cpp
#
function editMainCpp()
{
    if [ -e main.cpp ]; then
        line=`cat main.cpp |grep "class Solution" -n |head -1 |awk -F ':' '{print $1}'`
        let line=line+3
        vim main.cpp +$line
    else
        printUsage
    fi
}

## main function
#
function main_func() 
{
    if [ -d $CONFIG_DIR ]; then mkdir -p $CONFIG_DIR; fi
    if [ -e $CONFIG_FILE ]; then touch $CONFIG_FILE; fi        

    # read config file
    source $CONFIG_FILE

    if [ $# -eq 0 ]; then
        editMainCpp
        return 0
    fi

    case $1 in
        edit | e)
            if [ $# -eq 1 ]; then
                line=`cat $THIS_FILE |grep "main_func()" -n |head -1 |awk -F ':' '{print $1}'`
                vim $THIS_FILE +$line
            elif [ $# -eq 2 ]; then
                line=`cat $THIS_FILE |grep "$2" -n |head -1 |awk -F ':' '{print $1}'`
                vim $THIS_FILE +$line
            fi
            ;;
        open | url)
            google-chrome https://leetcode-cn.com/problemset/all/\?difficulty\=%E7%AE%80%E5%8D%95
            ;;
        config | cfg)
            if [ $# -eq 1 ]; then
                vim $CONFIG_FILE
            else
                writeConfig $2 `eval echo '$'"$2"` $3 $CONFIG_FILE
            fi
            ;;
        home | h)
            cd $LEETCODE_DIR
            echo "You are now in the HOME directory of LEETCODE."
            echo `pwd`
            ;;
        cd)
            if [ $# -eq 1 ]; then
                process_cd $lc_latest
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
        new | n)
            if [ $# -eq 1 ]; then
                process_new
            elif [ $# -eq 2 ]; then
                process_new $2
            else
                echo "ERROR: command 'new' accept once parameter at most."
                return 1
            fi
            ;;
        init)
            if [ $# -eq 1 ]; then
                process_init
            else
                echo "ERROR: command 'init' doesn't accept any parameter"
                return 1
            fi
            ;;
        submit | commit | c)
            process_submit
            ;;
        template | t)
            getCurrDirType
            dirType=$?
            if [ $dirType -eq $DIR_TYPE_SOLUTION_DIR ]; then
                cd ..
            elif [ $dirType -lt $DIR_TYPE_PROBLEM_DIR ]; then
                echo "ERROR: You are not in a problem directory"
                return 1 
            fi

            if [ -e .template.cpp ]; then
                vim .template.cpp
            else
                echo "ERROR: Not found file .template.cpp"
                return 1
            fi
            ;;
        compile | build | b)
            getCurrDirType
            if [ $? -ne $DIR_TYPE_SOLUTION_DIR ]; then
                echo "ERROR: You are not in a solution directory"
                return 1 
            fi

            if [ -e main.cpp ]; then
                g++ -o out main.cpp
                if [ $? -eq 0 ]; then
                    echo "Compiled successfully!"
                    echo "Run the program now? (Yes/No): \c"
                    read
                    case $REPLY in
                        [nN][oN]|[nN])
                            return 0
                            ;;
                        *)
                            echo "\n*********** Running ************"
                            ./out
                            echo "********************************"
                            ;;
                    esac
                fi
            else
                echo "ERROR: There is no main.cpp in the directory"
                return 1
            fi
            ;;
        run | r)
            if [ -e out ] && [ -x out ]; then
                echo "\n*********** Running ************"
                ./out
                echo "********************************"
            else
                echo "ERROR: No executable file named out"
                return 1
            fi
            ;;
        help | -h)
            printUsage
            ;;
        *)
            echo "Unknown command: ""$1"
            return 1
            ;;
    esac
}


main_func $@
return $?

