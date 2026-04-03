set -e
set -x

# Compile the project
cd ./lexer
make clean && make

cd ../parser
make clean && make
cd ../

gcc lexer/lex.yy.c parser/y.tab.c ast/ast.c ast/ast_builders.c ast/ast_utils.c ast/ast_print.c -o parser_out
