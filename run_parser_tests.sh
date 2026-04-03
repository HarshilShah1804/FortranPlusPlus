#!/bin/bash

PARSER=./parser_out
TESTS_DIR=./tests
PASS=0
FAIL=0

for f in $TESTS_DIR/*.f90; do
    test_name=$(basename "$f")
    output=$($PARSER "$f" 2>&1)
    
    if echo "$output" | grep -q "Parsing done!"; then
        echo "PASS  $test_name"
        PASS=$((PASS + 1))
    else
        echo "FAIL  $test_name"
        echo "      $(echo "$output" | grep -A 3 'PARSE ERROR')"
        FAIL=$((FAIL + 1))
    fi
done

echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "TOTAL : $((PASS + FAIL))"