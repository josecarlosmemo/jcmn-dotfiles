#!/usr/bin/env bash

if [ $# -eq 0 ]
  then
    echo "Please pass a matlab file."
fi

matlab -nosplash -nodesktop -r "pause(1);clc;run('$1');pause(10);exit;"

