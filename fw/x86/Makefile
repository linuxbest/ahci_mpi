# examples of invoking this Makefile:
# building configurations: Debug (default), Release, and Spy
# make
# make CONF=rel
# make CONF=spy
#
# cleaning configurations: Debug (default), Release, and Spy
# make clean
# make CONF=rel clean
# make CONF=spy clean

#-----------------------------------------------------------------------------
# NOTE: the Makefile expects that the QPC environment variable is defined
# and points to the QP/C installation directory
#
#QPC := ${shell pwd}/../qpc/
#ifndef QPC
#$(error The QPC environment variable must be defined)
#endif

#-----------------------------------------------------------------------------
# general utilities
#
RM = rm

#-----------------------------------------------------------------------------
# NOTE: this Makefile assumes that the MinGW\bin directory is added
# to the PATH variable.
#
CC    := gcc -m32
CPP   := g++
LINK  := gcc -m32                                            # for C programs
#LINK  := g++                                                # for C++ programs

#-----------------------------------------------------------------------------
# directories
#
QP_PORT_DIR := .
APP_DIR     := .

VPATH = $(APP_DIR)

# Output file basename
OUTPUT    := sata_mpi

# include directories
INCLUDES  = -I$(QPC)/include \
	-I$(QP_PORT_DIR) \
	-I.. -I. -I../include

# defines
DEFINES =

#-----------------------------------------------------------------------------
# files
#

# assembler source files
ASM_SRCS :=

# C source files
C_SRCS := $(wildcard *.c) qep.c  qhsm_dis.c  qhsm_ini.c  qhsm_top.c  sata_mpi.c

# C++ source files
CPP_SRCS := $(wildcard *.cpp)

LD_SCRIPT :=

VPATH = ../
#-----------------------------------------------------------------------------
# build options for various configurations
#

ifeq (rel, $(CONF))       # Release configuration ............................

BIN_DIR := rel
#LIBS    := -lqf -lqep

ASFLAGS =

CFLAGS = -c -Wall \
	-O2 $(INCLUDES) $(DEFINES) -DNDEBUG

CPPFLAGS = -c -Wall \
	-O2 $(INCLUDES) $(DEFINES) -DNDEBUG

LINKFLAGS = -L$(QP_PORT_DIR)/$(BIN_DIR)

else ifeq (spy, $(CONF))  # Spy configuration ................................

BIN_DIR := spy
#LIBS    := -lqf -lqep -lqs

ASFLAGS =

CFLAGS = -c -Wall \
	-g $(INCLUDES) $(DEFINES) -DQ_SPY

CPPFLAGS = -c -Wall \
	-g $(INCLUDES) $(DEFINES) -DQ_SPY

LINKFLAGS = -L$(QP_PORT_DIR)/$(BIN_DIR)

else                     # default Debug configuration .......................

BIN_DIR := dbg
#LIBS    := -lqf -lqep

ASFLAGS =

CFLAGS = -c -Wall \
	-g $(INCLUDES) $(DEFINES)

CPPFLAGS = -c -Wall \
	-g $(INCLUDES) $(DEFINES)

LINKFLAGS = -L$(QP_PORT_DIR)/$(BIN_DIR)


endif

CFLAGS += -D_SIM_

ASM_OBJS     := $(patsubst %.s,%.o,$(ASM_SRCS))
C_OBJS       := $(patsubst %.c,%.o,$(C_SRCS))
CPP_OBJS     := $(patsubst %.cpp,%.o,$(CPP_SRCS))

TARGET_BIN   := $(BIN_DIR)/$(OUTPUT).bin
TARGET_EXE   := $(BIN_DIR)/$(OUTPUT)
ASM_OBJS_EXT := $(addprefix $(BIN_DIR)/, $(ASM_OBJS))
C_OBJS_EXT   := $(addprefix $(BIN_DIR)/, $(C_OBJS))
C_DEPS_EXT   := $(patsubst %.o, %.d, $(C_OBJS_EXT))
CPP_OBJS_EXT := $(addprefix $(BIN_DIR)/, $(CPP_OBJS))
CPP_DEPS_EXT := $(patsubst %.o, %.d, $(CPP_OBJS_EXT))


#-----------------------------------------------------------------------------
# rules
#

all: $(BIN_DIR) $(TARGET_EXE)
#all: $(BIN_DIR) $(TARGET_BIN)

$(BIN_DIR):
	@echo
	mkdir -p $@

$(TARGET_BIN): $(TARGET_EXE)
	$(BIN) -O binary $< $@

$(TARGET_EXE) : $(ASM_OBJS_EXT) $(C_OBJS_EXT) $(CPP_OBJS_EXT)
	$(LINK) $(LINKFLAGS) -o $@ $^ $(LIBS)

$(BIN_DIR)/%.d : %.c
	$(CC) -MM -MT $(@:.d=.o) $(CFLAGS) $< > $@

$(BIN_DIR)/%.d : %.cpp
	$(CPP) -MM -MT $(@:.d=.o) $(CPPFLAGS) $< > $@

$(BIN_DIR)/%.o : %.s
	$(AS) $(ASFLAGS) $< -o $@

$(BIN_DIR)/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN_DIR)/%.o : %.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

-include $(C_DEPS_EXT) $(CPP_DEPS_EXT)


.PHONY : clean
clean:
	-$(RM) $(BIN_DIR)/*.o \
	$(BIN_DIR)/*.d \
	$(BIN_DIR)/$(OUTPUT) \
	$(BIN_DIR)/*.map
