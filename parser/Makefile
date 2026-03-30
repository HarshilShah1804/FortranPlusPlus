# Compiler (not really needed now)
CC = gcc

# Tools
YACC = yacc

# Files
PARSER = parser.y
PARSER_C = y.tab.c
PARSER_H = y.tab.h

# Default target → ONLY generate parser files
all: $(PARSER_C) $(PARSER_H)

# Generate C + header from Yacc
$(PARSER_C) $(PARSER_H): $(PARSER)
	$(YACC) -d -v $(PARSER)

# Clean generated files
clean:
	rm -f $(PARSER_C) $(PARSER_H) y.output

# Rebuild
rebuild: clean all