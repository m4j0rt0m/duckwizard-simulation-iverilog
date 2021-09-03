# Author:      Abraham J. Ruiz R.
# Description: Icarus Verilog Simulation Makefile
# Version:     1.2
# Url:         https://github.com/m4j0rt0m/duckwizard-simulation-iverilog

SHELL                := /bin/bash
REMOTE-URL-SSH       := git@github.com:m4j0rt0m/rtl-develop-template-simulation.git
REMOTE-URL-HTTPS     := https://github.com/m4j0rt0m/rtl-develop-template-simulation.git

MKFILE_PATH           = $(abspath $(firstword $(MAKEFILE_LIST)))
TOP_DIR               = $(shell dirname $(MKFILE_PATH))

### directories ###
SOURCE_DIR            = $(TOP_DIR)/src
SV2V_RTL_DIR          = $(TOP_DIR)/.sv2v
OUTPUT_DIR            = $(TOP_DIR)/build
SCRIPTS_DIR           = $(TOP_DIR)/scripts

### makefile includes ###
include $(SCRIPTS_DIR)/funct.mk
include $(SCRIPTS_DIR)/misc.mk

### external sources wildcards ###
EXT_VERILOG_SRC      ?=
EXT_VERILOG_HEADERS  ?=
EXT_PACKAGE_SRC      ?=
EXT_MEM_SRC          ?=
EXT_RTL_PATHS        ?=

### simulation sources directories ###
RTL_DIRS              = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname rtl \)))
INCLUDE_DIRS          = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname include \)))
PACKAGE_DIRS          = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname package \)))
MEM_DIRS              = $(wildcard $(shell find $(SOURCE_DIR) -type d \( -iname mem \)))
RTL_PATHS             = $(EXT_RTL_PATHS) $(RTL_DIRS) $(INCLUDE_DIRS) $(PACKAGE_DIRS) $(MEM_DIRS)

### sources wildcards ###
ifeq ("$(SV2V_RERUN)","yes")
VERILOG_SRC           = $(EXT_VERILOG_SRC) $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.v -o -iname \*.vhdl \))) $(wildcard $(SV2V_RTL_DIR)/*.v)
SVERILOG_SRC          =
SVERILOG_HEADERS      =
PACKAGE_SRC           =
else
VERILOG_SRC           = $(EXT_VERILOG_SRC) $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.v -o -iname \*.vhdl \)))
SVERILOG_SRC          = $(wildcard $(shell find $(RTL_DIRS) -type f \( -iname \*.sv \)))
SVERILOG_HEADERS      = $(wildcard $(shell find $(INCLUDE_DIRS) -type f \( -iname \*.svh -o -iname \*.sv \)))
PACKAGE_SRC           = $(EXT_PACKAGE_SRC) $(shell $(SCRIPTS_DIR)/order_sv_pkg $(wildcard $(shell find $(PACKAGE_DIRS) -type f \( -iname \*.sv \))))
endif
VERILOG_HEADERS       = $(EXT_VERILOG_HEADERS) $(wildcard $(shell find $(INCLUDE_DIRS) -type f \( -iname \*.h -o -iname \*.vh -o -iname \*.v \)))
MEM_SRC               = $(EXT_MEM_SRC) $(wildcard $(shell find $(MEM_DIRS) -type f \( -iname \*.bin -o -iname \*.hex \)))
RTL_SRC               = $(VERILOG_SRC) $(SVERILOG_SRC) $(VERILOG_HEADERS) $(SVERILOG_HEADERS) $(PACKAGE_SRC) $(MEM_SRC)

### include flags ###
INCLUDES_FLAGS        = $(addprefix -I, $(RTL_PATHS))

### simulation flags ###
SIM_TOOL             ?= iverilog
SIM_CREATE_VCD       ?= yes
ifeq ($(SIM_CREATE_VCD),yes)
VCD_FLAG              = -D__VCD__
else
VCD_FLAG              =
endif
SIM_OPEN_WAVE        ?= no
SIM_IVERILOG_FLAGS   ?= -o $(BUILD_DIR)/$(SIM_TOP_MODULE).tb -s $(SIM_TOP_MODULE) -g2012 -DSIMULATION $(VCD_FLAG) $(INCLUDES_FLAGS) $(PACKAGE_SRC) $(VERILOG_SRC) $(SVERILOG_SRC)
SIM_RUN_VVP          ?= vvp

### simulation objects ###
SIM_TOP_MODULE       ?=
BUILD_DIR             = $(OUTPUT_DIR)/$(SIM_TOP_MODULE)
RTL_OBJS              = $(VERILOG_SRC) $(SVERILOG_SRC) $(PACKAGE_SRC) $(VERILOG_HEADERS) $(SVERILOG_HEADERS) $(MEM_SRC)
VCD_FILE              = $(BUILD_DIR)/$(SIM_TOP_MODULE).vcd
GTK_FILE              = $(SCRIPTS_DIR)/$(SIM_TOP_MODULE).gtkw

all: sim

#H# sim             : Run simulation
ifeq ($(USE_SV2V),yes)
sv2v: sv2v-srcs
	$(MAKE) SV2V_RERUN=yes sim-sv2v
sim-sv2v: clean-top $(VCD_FILE)
else
sim: clean-top $(VCD_FILE)
endif

#H# veritedium      : Run veritedium AUTO features
veritedium:
	@echo -e "$(_flag_)Running Veritedium Autocomplete..."
	@$(foreach SRC,$(VERILOG_SRC),$(call veritedium-command,$(SRC)))
	@$(foreach SRC,$(SVERILOG_SRC),$(call veritedium-command,$(SRC)))
	@echo -e "$(_flag_)Deleting unnecessary backup files (*~ or *.bak)..."
	find ./* -name "*~" -delete
	find ./* -name "*.bak" -delete
	@echo -e "$(_flag_)Finished!$(_reset_)"

%.vcd: %.tb $(RTL_OBJS)
	@if [[ "$(SIM_TOOL)" == "iverilog" ]]; then\
		$(SIM_RUN_VVP) $<;\
	fi
	@if [[ "$(SIM_CREATE_VCD)" == "yes" ]]; then\
		mv $(SIM_TOP_MODULE).vcd $(VCD_FILE);\
		if [[ "$(SIM_OPEN_WAVE)" == "yes" ]]; then\
			if [[ -f "$(GTK_FILE)" ]]; then\
				echo -e "$(_info_)\n[INFO] Opening existing GTKW template...$(_reset_)";\
				gtkwave $(GTK_FILE);\
			else\
				gtkwave $(VCD_FILE);\
			fi;\
		fi;\
	fi

%.tb: $(RTL_OBJS)
	$(print-srcs-command)
	@mkdir -p $(BUILD_DIR)
	@if [[ "$(SIM_TOOL)" == "iverilog" ]]; then\
		$(SIM_TOOL) $(SIM_IVERILOG_FLAGS);\
	fi

#H# sv2v-srcs       : Convert RTL sources from SystemVerilog to Verilog (using sv2v tool)
sv2v-srcs: $(SVERILOG_SRC)
	@for src in $^; do $(MAKE) sv2v-convert SV2V_SOURCE=$${src}; done

#H# sv2v-convert    : Convert SystemVerilog module to Verilog
sv2v-convert: check-sv2v
	sv2v --write=$(SV2V_DEST) $(SV2V_FLAGS) $(SV2V_SOURCE)

#H# clean-top       : Delete Top module's build directory
clean-top:
	rm -rf $(BUILD_DIR)

#H# clean           : Clean build directory
clean:
	rm -rf build/*

#H# help            : Display help
help: Makefile $(SCRIPTS_DIR)/misc.mk
	@echo -e "\nSimulation Help\n"
	@sed -n 's/^#H#//p' $^
	@echo ""

.PHONY: all sim veritedium clean help
