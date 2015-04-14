#!/bin/bash

# descend into source directory
cd src/
# clean source directory
make clean
# compile model
make
# ascend to previous directory
cd ..
