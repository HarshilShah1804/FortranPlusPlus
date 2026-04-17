#!/bin/bash

OUT="output.txt"

# clear old output
> $OUT

echo "Test Outputs" >> $OUT
echo "=====================================" >> $OUT

echo "compiling..."
./compile.sh

echo "running standard tests..."
for f in tests/*.f90; do
    echo "running $f..."
    
    echo -e "\nFile: $f" >> $OUT
    echo "--- Source Code ---" >> $OUT
    cat "$f" >> $OUT
    
    echo -e "\n--- TAC Output ---" >> $OUT
    ./parser_out "$f" >> $OUT 2>&1
    
    echo -e "\n=====================================" >> $OUT
done

echo -e "\nERROR HANDLING TESTS" >> $OUT
echo "=====================================" >> $OUT

echo "running error handling tests..."
for f in tests/errors/*.f90; do
    echo "running $f..."
    
    echo -e "\nFile: $f" >> $OUT
    echo "--- Source Code ---" >> $OUT
    cat "$f" >> $OUT
    
    echo -e "\n--- Error Output ---" >> $OUT
    ./parser_out "$f" >> $OUT 2>&1
    
    echo -e "\n=====================================" >> $OUT
done

echo "done. saved to $OUT"