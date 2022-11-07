# compiler
GXX := g++

# compiler flags
GXXFLAGS :=

# target executable
TARGET := PDPTWSE.out

# header files
INCLUDES := -I src/brkga/include

# source files
SOURCES := src/brkga/lib/idata.cpp

# object files
# src/brkga/lib/ -> build/
OBJECTS := $(patsubst src/brkga/lib/%,build/%,$(SOURCES))
# .cpp -> .o
OBJECTS := $(patsubst %.cpp,%.o,$(OBJECTS))

all: $(TARGET)

$(TARGET): src/brkga/PDPTWSE.cpp $(OBJECTS) src/brkga/include/
	$(GXX) $(GXXFLAGS) $(INCLUDES) src/brkga/PDPTWSE.cpp -o $@ $(OBJECTS)

build/idata.o: src/brkga/lib/idata.cpp
	mkdir -p $(dir $@)
	$(GXX) $(GXXFLAGS) $(INCLUDES) -c src/brkga/lib/idata.cpp -o $@

clean:
	$(RM) -r build
	$(RM) $(TARGET)

# This is an easier to use and modify makefile, but it is slightly more difficult to read than the simple one:
# #
# # 'make depend' uses makedepend to automatically generate dependencies 
# #               (dependencies are added to end of Makefile)
# # 'make'        build executable file 'mycc'
# # 'make clean'  removes all .o and executable files
# #

# # define the C compiler to use
# CC = gcc

# # define any compile-time flags
# CFLAGS = -Wall -g

# # define any directories containing header files other than /usr/include
# #
# INCLUDES = -I/home/newhall/include  -I../include

# # define library paths in addition to /usr/lib
# #   if I wanted to include libraries not in /usr/lib I'd specify
# #   their path using -Lpath, something like:
# LFLAGS = -L/home/newhall/lib  -L../lib

# # define any libraries to link into executable:
# #   if I want to link in libraries (libx.so or libx.a) I use the -llibname 
# #   option, something like (this will link in libmylib.so and libm.so:
# LIBS = -lmylib -lm

# # define the C source files
# SRCS = emitter.c error.c init.c lexer.c main.c symbol.c parser.c

# # define the C object files 
# #
# # This uses Suffix Replacement within a macro:
# #   $(name:string1=string2)
# #         For each word in 'name' replace 'string1' with 'string2'
# # Below we are replacing the suffix .c of all words in the macro SRCS
# # with the .o suffix
# #
# OBJS = $(SRCS:.c=.o)

# # define the executable file 
# MAIN = mycc

# #
# # The following part of the makefile is generic; it can be used to 
# # build any executable just by changing the definitions above and by
# # deleting dependencies appended to the file from 'make depend'
# #

# .PHONY: depend clean

# all:    $(MAIN)
#         @echo  Simple compiler named mycc has been compiled

# $(MAIN): $(OBJS) 
#         $(CC) $(CFLAGS) $(INCLUDES) -o $(MAIN) $(OBJS) $(LFLAGS) $(LIBS)

# # this is a suffix replacement rule for building .o's from .c's
# # it uses automatic variables $<: the name of the prerequisite of
# # the rule(a .c file) and $@: the name of the target of the rule (a .o file) 
# # (see the gnu make manual section about automatic variables)
# .c.o:
#         $(CC) $(CFLAGS) $(INCLUDES) -c $<  -o $@

# clean:
#         $(RM) *.o *~ $(MAIN)

# depend: $(SRCS)
#         makedepend $(INCLUDES) $^

# # DO NOT DELETE THIS LINE -- make depend needs it