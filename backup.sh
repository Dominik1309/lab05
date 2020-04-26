#!/bin/bash
# Author: Dominik Duric

function nrFiles {
    count=`find $1 -type f | wc -l`
    printf $count
}

function nrDirectories {
    count=`find $1 -type d | wc -l`
    printf $count
}

user=`whoami`
let counter=0
dirs=()

# Get arguments with loop
if [ $# -gt 0 ]
then
    for i in $@
    do
        if [ -d "$i" ]
        then
            dirs+=($i)
        else
            printf "Path is not valid, no backup possible $i\n"
        fi
    done
else
    user_home=/home/$user
    printf "Falling back to default path $user_home because of no arguments \n"
    dirs+=$user_home
fi

# Backup provided path loop
for dir in "${dirs[@]}"
do
    counter=$(( $counter + 1 )) 
    backup=/tmp/${user}_home_`date +%d_%m_%Y_%H_%M_%S_%3N`.tar.gz

    nr_files=`nrFiles $dir`
    nr_dirs=`nrDirectories $dir`

    counter=$(( $counter + $nr_files ))
    counter=$(( $counter + $nr_dirs ))

    printf "Starting backup of $dir \n"

    # backup directory
    tar -czvf ${backup} ${dir} 1>/dev/null 2>&1

    printf "Backup created successfully\n"
    printf "Details:                                `ls -lisa ${backup}`\n"

    printf "Number of files                         $nr_files\n"
    printf "Number of directories                   $nr_dirs\n"

    files_backup=`tar -tvf $backup | egrep "^-" | wc -l`
    dirs_backup=`tar -tvf $backup | egrep "^d" | wc -l`

    printf "\n"
    printf "Enrypting\n"
    openssl aes-256-cbc -e -in ${backup} -out ${backup}_enc -k "superSafeHolyMolyKey" 1>/dev/null 2>&1
    
    # remove unencrypted file
    rm ${backup}

    printf "Generating hash\n"
    openssl dgst -sha256 -out ${backup}_hash ${backup}_enc

    printf "Signing\n"
    openssl rsautl -sign -inkey private.key -in ${backup}_hash -out ${backup}_signature 1>/dev/null 2>&1

    rm ${backup}_hash

    printf "\n"
    printf "Performing sanity checks \n"
    printf "Checking number of files                "
    if [ $files_backup -eq $nr_files ] 
    then
        printf "OK\n"
    else
        printf "NOK\n"
    fi

    printf "Checking number of directories          "
    if [ $dirs_backup == $nr_dirs ] 
    then
        printf "OK\n"
    else
        printf "NOK\n"
    fi

    printf "Signature                               ${backup}_signature\n"
    printf "Enrypted backup                         ${backup}_enc\n"
    
done

printf "Overall counter:                        $counter\n"
