#!/bin/bash
#Author: Dominik Duric



function check_file {
    if [ ! -f "$1" ]
    then
        printf "the publickey is not a valid file\n"
        usage $2
        exit 1
    fi
}

function usage {
    printf "Error\n"
    printf "usage:\n"
    printf "    $1 backup signature publickey\n"
    printf "  all arguments must be files\n"
}

needed_args=3

if [ $# -ne ${needed_args} ] 
then
    usage $0
    exit 1
fi

backup=$1
signature=$2
publickey=$3

# check if ${backup} is valid as a file
check_file $0 $backup
# check if ${signature} is valid as a file
check_file $0 $signature
# check if ${publickey} is valid as a file
check_file $0 $publickey

verification=`openssl rsautl -verify -inkey ${publickey} -pubin -in ${signature} | awk '{print $2}'`
hash=`openssl dgst -sha256 ${backup} | awk '{print $2}'`

if [ "${verification}" == "${hash}" ]
then
    printf "Signature verified successfully\n"
else
    printf "Signature validation error\n"
    exit 1
fi

openssl aes-256-cbc -d -in ${backup} -out ${backup::-4} -k "safeKeyTrustMe" 1>/dev/null 2>&1

if [ $? -eq 0 ]
then
    printf "Backup decrypted successfully\n"
else
    printf "decryption not succesful\n"
    exit 1
fi

# remove the suffix enc from file
backup=${backup::-4}

# remove suffix .tar.gz from backup to use as restore folder
restore_path=/home/$USER/restored/${backup:5:-7}

mkdir -p ${restore_path}

tar -xvzf ${backup} -C ${restore_path} 1>/dev/null 2>&1

if [ $? -eq 0 ]
then
    printf "Backup restored successfully to ${restore_path}\n"
else
    printf "Backup could not be restored\n"
    exit 1
fi
