# Tools
LEX = flex

# Flags
CFLAGS = -Wall -Wextra

# Files
LEXER = lexer.l
LEXER_C = lex.yy.c

# Default target → ONLY generate lex.yy.c
all: $(LEXER_C)

# Generate C file from Flex
$(LEXER_C): $(LEXER)
	$(LEX) $(LEXER)

# Clean generated files
clean:
	rm -f $(LEXER_C)

# Rebuild from scratch
rebuild: clean all