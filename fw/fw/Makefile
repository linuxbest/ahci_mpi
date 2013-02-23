##############################################################################
# Product: Makefile for DPP example, EK-LM3811, QK kernel, GNU/Sourcery G++
# Last Updated for Version: 4.2.02
# Date of the Last Update:  Sep 07, 2011
#
#                    Q u a n t u m     L e a P s
#                    ---------------------------
#                    innovating embedded systems
#
# Copyright (C) 2002-2011 Quantum Leaps, LLC. All rights reserved.
#
# This software may be distributed and modified under the terms of the GNU
# General Public License version 2 (GPL) as published by the Free Software
# Foundation and appearing in the file GPL.TXT included in the packaging of
# this file. Please note that GPL Section 2[b] requires that all works based
# on this software must also be made publicly available under the terms of
# the GPL ("Copyleft").
#
# Alternatively, this software may be distributed and modified under the
# terms of Quantum Leaps commercial licenses, which expressly supersede
# the GPL and are specifically designed for licensees interested in
# retaining the proprietary status of their code.
#
# Contact information:
# Quantum Leaps Web site:  http://www.quantum-leaps.com
# e-mail:                  info@quantum-leaps.com
##############################################################################
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
#QPC := /p/sf/ppc-platform/qpc
#ifndef QPC
#$(error The QPC environment variable must be defined)
#endif

#-----------------------------------------------------------------------------
# general utilities
#
RM = del

#-----------------------------------------------------------------------------
# tools
#
XIL   := /opt/ise13.4/ISE_DS/
CROSS := ${XIL}/EDK/gnu/microblaze/lin/bin/
CC    := ${CROSS}mb-gcc
CPP   := ${CROSS}mb-g++
AS    := ${CROSS}mb-as
LINK  := ${CROSS}mb-gcc
SIZE  := ${CROSS}mb-size
BIN   := ${CROSS}mb-objcopy
RM    := rm -rf
MKDIR := mkdir
OD    := ${CROSS}mb-objdump
D2M   := ${XIL}/ISE/bin/lin/data2mem
#-----------------------------------------------------------------------------
# directories
#
QP_PORT_DIR := .
APP_DIR     := .
LIB_DIR     :=

# source directories
VPATH = ../

# Output file basename
OUTPUT    := ahci-qk

# include directories
INCLUDES  = -I$(QPC)/include	\
	-I$(QP_PORT_DIR) \
	-I.. -I../include/

NP := 4
# defines
DEFINES = -DPORT_NR=${NP} -mcpu=v8.20.b -DGITVERSION="0x$(shell git describe --always)"

#-----------------------------------------------------------------------------
# files
#

# assembler source files
ASM_SRCS  := 
ASM0_SRCS :=

# C source files
C_SRCS := $(wildcard *.c) qep.c  qhsm_dis.c  qhsm_ini.c  qhsm_top.c  sata_mpi.c

# C++ source files
CPP_SRCS :=	$(wildcard *.cpp)


LD_SCRIPT := microblaze_0_linker_script.ld

#-----------------------------------------------------------------------------
# build options for various configurations
#
ifeq (rel, $(CONF))       # Release configuration ............................

BIN_DIR := rel
#LIBS    := -lqk -lqf -lqep

ASFLAGS = 

CFLAGS = -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift -Wall \
	-mlittle-endian -Os $(INCLUDES) $(DEFINES) -DNDEBUG

CPPFLAGS = -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift \
	-mlittle-endian -Wall -fno-rtti -fno-exceptions \
	-Os $(INCLUDES) $(DEFINES) -DNDEBUG

LINKFLAGS = -T$(LD_SCRIPT) -mlittle-endian \
	-Xlinker -Map=$(BIN_DIR)/$(OUTPUT).map \
	-L$(QP_PORT_DIR)/$(BIN_DIR)

else ifeq (spy, $(CONF))  # Spy configuration ................................

C_SRCS += qs_blk.c  qs_byte.c  qs_.c  qs.c  qs_f32.c  qs_f64.c  qs_mem.c  qs_str.c  qs_u64.c

BIN_DIR := spy
#LIBS    := -lqk -lqf -lqep

ASFLAGS = -g 

CFLAGS = -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift -Wall \
	-mlittle-endian -Os $(INCLUDES) $(DEFINES) -DQ_SPY

CPPFLAGS = -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift \
	-mlittle-endian -Wall -fno-rtti -fno-exceptions \
	-Os $(INCLUDES) $(DEFINES) -DQ_SPY

LINKFLAGS = -T$(LD_SCRIPT) -mlittle-endian \
	-Xlinker -Map=$(BIN_DIR)/$(OUTPUT).map \
	-L$(QP_PORT_DIR)/$(BIN_DIR)

else                     # default Debug configuration .......................

BIN_DIR := dbg
#LIBS    := -lqk -lqf -lqep

ASFLAGS = -mlittle-endian

CFLAGS = -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift -Wall \
	-mlittle-endian -Os $(INCLUDES) $(DEFINES) #-DMPI_TRACE

CPPFLAGS = -mxl-pattern-compare -mno-xl-soft-mul -mxl-barrel-shift \
	-mlittle-endian -Wall -fno-rtti -fno-exceptions \
	-g -O $(INCLUDES) $(DEFINES)

LINKFLAGS = -T$(LD_SCRIPT) -mlittle-endian \
	-Xlinker -Map=$(BIN_DIR)/$(OUTPUT).map \
	-L$(QP_PORT_DIR)/$(BIN_DIR)

endif


ASM_OBJS     := $(patsubst %.s,%.o,$(ASM_SRCS)) $(patsubst %.S,%.o,$(ASM0_SRCS))
C_OBJS       := $(patsubst %.c,%.o,$(C_SRCS))
CPP_OBJS     := $(patsubst %.cpp,%.o,$(CPP_SRCS))

TARGET_BIN   := $(BIN_DIR)/$(OUTPUT).hex
TARGET_ELF   := $(BIN_DIR)/$(OUTPUT).elf
TARGET_ASM   := $(BIN_DIR)/$(OUTPUT).s
ASM_OBJS_EXT := $(addprefix $(BIN_DIR)/, $(ASM_OBJS))
C_OBJS_EXT   := $(addprefix $(BIN_DIR)/, $(C_OBJS))
C_DEPS_EXT   := $(patsubst %.o, %.d, $(C_OBJS_EXT))
CPP_OBJS_EXT := $(addprefix $(BIN_DIR)/, $(CPP_OBJS))
CPP_DEPS_EXT := $(patsubst %.o, %.d, $(CPP_OBJS_EXT))


#-----------------------------------------------------------------------------
# rules
#

all: $(BIN_DIR) $(TARGET_BIN)

$(BIN_DIR):
	@echo
	mkdir -p $@

$(TARGET_BIN): $(TARGET_ELF)
	$(SIZE) $<
	$(BIN) -O ihex $< $@
	$(OD) -dx $(TARGET_ELF) > ${TARGET_ASM}

$(TARGET_ELF) : $(ASM_OBJS_EXT) $(C_OBJS_EXT) $(CPP_OBJS_EXT)
	$(LINK) $(LINKFLAGS) -o $@ $^ $(LIBS)

$(BIN_DIR)/%.d : %.c
	$(CC) -MM -MT $(@:.d=.o) $(CFLAGS) $< > $@

$(BIN_DIR)/%.d : %.cpp
	$(CPP) -MM -MT $(@:.d=.o) $(CPPFLAGS) $< > $@

$(BIN_DIR)/%.o : %.s
	$(AS) $(ASFLAGS) $< -o $@

$(BIN_DIR)/%.o : %.s
	$(CC) -c $(ASFLAGS) $< -o $@

$(BIN_DIR)/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN_DIR)/%.o : %.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

-include $(C_DEPS_EXT) $(CPP_DEPS_EXT)


.PHONY : clean
clean:
	-$(RM) $(BIN_DIR)/*.o \
	$(BIN_DIR)/*.d \
	$(BIN_DIR)/*.hex \
	$(BIN_DIR)/*.elf \
	$(BIN_DIR)/*.map

show:
	@echo CONF = $(CONF)
	@echo ASM_SRCS = $(ASM_SRCS)
	@echo C_SRCS = $(C_SRCS)
	@echo CPP_SRCS = $(CPP_SRCS)
	@echo ASM_OBJS_EXT = $(ASM_OBJS_EXT)
	@echo C_OBJS_EXT = $(C_OBJS_EXT)
	@echo C_DEPS_EXT = $(C_DEPS_EXT)
	@echo CPP_DEPS_EXT = $(CPP_DEPS_EXT)
	@echo TARGET_ELF = $(TARGET_ELF)

TOPDIR := /prj/hw/sata/
sim: all
	${D2M} -bm microblaze_0.bmm -bd ${TARGET_ELF} -bx ${TOPDIR}/simulation/behavioral -p xc5vfx100tff1136-1
	${D2M} -bm microblaze_0.bmm -bd ${TARGET_ELF} -o h ahci_rom
	${BIN} ${TARGET_ELF} $(BIN_DIR)/$(OUTPUT).bin -O binary
	bin2c fw_mpi < $(BIN_DIR)/$(OUTPUT).bin > /p/sf/ppc-platform/linux26-fdcr/drivers/ata/ahci_mpi_fw.h
	./build_sym ${TARGET_ELF} 
	cp mb_trace.h ${TOPDIR}/systemc/
