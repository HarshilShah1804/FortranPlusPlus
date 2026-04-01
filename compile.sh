set -e
set -x

# Compile the project
cd ./lexer
make clean && make

cd ../parser
make clean && make
cd ../

gcc lexer/lex.yy.c parser/y.tab.c -o parser_out