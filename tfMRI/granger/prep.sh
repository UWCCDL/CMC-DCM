#!/bin/bash

for file in *_cmc.txt; do
    id=`echo $file | cut -f1 -d_`;
    mkdir sub-$id;
    mv $file sub-$id;
done

for j in `ls -d sub-*`; do
    cd $j;  id=`echo $j | cut -f2 -d-`;
    echo $id;
    mv ${id}_cmc.txt cmc.txt;
    cd ..;
done
