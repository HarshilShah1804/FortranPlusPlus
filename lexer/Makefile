# Compiler
CC = gcc

# Tools
LEX = flex

# Flags
CFLAGS = -Wall -Wextra
LDFLAGS = -lfl

# Files
LEXER = lexer.l
LEXER_C = lex.yy.c
TARGET = lexer

# Default target
all: $(TARGET)

# Build lexer
$(TARGET): $(LEXER_C)
	$(CC) $(CFLAGS) $(LEXER_C) -o $(TARGET) $(LDFLAGS)

# Generate C file from Flex
$(LEXER_C): $(LEXER)
	$(LEX) $(LEXER)

# Clean generated files
clean:
	rm -f $(LEXER_C) $(TARGET)

# Rebuild from scratch
rebuild: clean all
