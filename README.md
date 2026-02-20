# Lexical Analyzer: Specification and Documentation  
**Team – 7**

## Team Members
- **Chaitanya Sharma** – 23110072  
- **Harshil Shah** – 23110132  
- **Jeet Joshi** – 23110148  
- **Akshat Saurin Shah** - 23110293

---

# Overview

This document outlines the design and feature coverage of the lexical analyzer for the **Fortran-inspired language**.

The lexer is implemented using **Flex** and **C**.

It supports a robust subset of Fortran features, seamlessly handling:

- Case-insensitivity  
- Fortran-specific formatting rules  

---

# Supported Features

## 2.1 Keywords and Identifiers

### Control Flow
- `program`
- `end`
- `if`
- `then`
- `else`
- `do`
- `while`
- `select`
- `case`
- `default`
- `stop`
- `return`
- `call`

### Data Types
- `integer`
- `real`
- `logical`
- `character`
- `complex`
- `type`
- `class`

### Memory Management
- `allocate`
- `deallocate`
- `allocated`
- `pointer`
- `target`
- `allocatable`

### Subprograms
- `function`
- `subroutine`
- `recursive`
- `result`
- `module`
- `contains`
- `use`

### I/O Operations
- `print`
- `read`
- `write`
- `open`
- `close`
- `inquire`

### Attributes
- `intent`
- `in`
- `out`
- `inout`
- `implicit none`

### Identifiers
- Standard alphanumeric identifiers  
- Must start with a letter  
- May contain underscores  
- Case-insensitive  

---

## 2.2 Literals and Constants

### Integer Constants
- Base-10 sequences  
- Examples: `123`, `0`

### Real Constants
- Standard decimal notation  
- Fortran scientific notation using `E`  
- Examples:
  - `1.0`
  - `.5`
  - `2.0E-4`

### Logical Constants
- `.true.`
- `.false.`
- `.t.`
- `.f.`

### String Literals
- Supports both:
  - Single quotes: `'...'`
  - Double quotes: `"..."`

- Handles escaped inner quotes:
  - `""`
  - `''`

---

## 2.3 Operators

### Arithmetic Operators
- `+`
- `-`
- `*`
- `/`
- `**` (Exponentiation)

### Relational Operators
- `==`
- `/=`
- `<=`
- `>=`
- `<`
- `>`

### Logical Operators
- `.and.`
- `.or.`
- `.not.`

### Miscellaneous Operators
- `//` (String Concatenation)
- `%` (Derived Type Component Access)
- `=` (Assignment)
- `::` (Declaration Separator)

---

## 2.4 Miscellaneous Features

### Comments
- Single-line comments starting with `!`
- Custom multi-line block comments enclosed in:
  ```
  !* ... *!
  ```

### Line Continuations
- Supports Fortran continuation marker `&`
  - At the end of a line
  - Optionally at the beginning of the next line

### Preprocessor Directives
Supports C-style preprocessor directives:

- `#define`
- `#ifdef`
- `#ifndef`
- `#if`
- `#elif`
- `#else`
- `#undef`
- `#endif`

---

# Error Handling

The lexer handles the following errors:

### 1. Identifier Length
- Fortran limits identifiers to **63 characters**
- Uses `yyleng` to check length
- Emits:
  ```
  Identifier exceeds 63 chars
  ```

### 2. Unclosed Strings
- Detects strings that:
  - Open with a quote
  - Reach newline without closing
- Emits:
  ```
  Unclosed string literal
  ```

### 3. Stray Characters
- Any character not matching the defined grammar
- Emits:
  ```
  Stray character: 'X'
  ```

---

# How to Use

## Prerequisites
Ensure the following are installed:

- `flex`
- `gcc`
- `cmake`

---

## Compilation

```bash
make
```

---

## Running the Lexer

```bash
./lexer < input-file.f90
```

The lexer:

- Prints a formatted stream of tokens to **stdout**
- Returns tokens directly when integrated with a parser

---

# Example

## Input Program

```fortran
program assumed_rank
   integer :: assumed_rank(..)
end program
```

---

## Output Token Stream

```console
[Line 1  ]  PROGRAM                 Lexeme: "program"
[Line 1  ]  IDENTIFIER              Lexeme: "assumed_rank"
[Line 2  ]  INTEGER                 Lexeme: "integer"
[Line 2  ]  DECL_SEP                Lexeme: "::"
[Line 2  ]  IDENTIFIER              Lexeme: "assumed_rank"
[Line 2  ]  LPAREN                  Lexeme: "("
[Line 2  ]  ASSUMED_RANK_SPECIFIER  Lexeme: ".."
[Line 2  ]  RPAREN                  Lexeme: ")"
[Line 3  ]  END                     Lexeme: "end"
[Line 3  ]  PROGRAM                 Lexeme: "program"

------------------------------------------------
***Lexing successful***
Lexical Errors = 0
------------------------------------------------
```

---

# Summary

This lexical analyzer:

- Covers a comprehensive subset of Fortran
- Handles case-insensitivity
- Supports preprocessor directives
- Implements structured error handling
- Is compatible with parser integration
