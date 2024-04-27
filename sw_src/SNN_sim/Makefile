# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -Wextra -g -std=c99

# Source files
SOURCES = tinyODIN.c

# Object files
OBJECTS = $(SOURCES:.c=.o)

# Executable name
EXECUTABLE = tinyODIN

# Default target
all: $(EXECUTABLE)

# Rule for linking object files into the executable
$(EXECUTABLE): $(OBJECTS)
	$(CC) $(CFLAGS) $^ -o $@ 

# Rule for compiling C source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean target
clean:
	rm -f $(OBJECTS) $(EXECUTABLE)