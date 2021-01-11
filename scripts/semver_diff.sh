#!/usr/bin/env bash

# return sem_a - sem_b
# sem_a and sem_b must be of same semver length
# Ex:
# ./hack/semver_diff.sh 1.2.3 1.1.1
# 0.1.2

sem_a=$1
sem_b=$2

IFS=. arr_a=(${sem_a##*-})
IFS=. arr_b=(${sem_b##*-})

result=()

for i in "${!arr_a[@]}"; do
    result+=($((${arr_a[$i]}-${arr_b[$i]})))
done

IFS=. echo "${result[*]}"