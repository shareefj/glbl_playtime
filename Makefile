MAKE_DIR  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TEST_DIR  := $(abspath $(MAKE_DIR)/../verilator/firmware/tests)


SIM            = xcelium
TOPLEVEL_LANG  = verilog
TOPLEVEL       = clk_gate
MODULE        ?= tb
TESTCASE      ?=
COMPILE_ARGS  ?=
SIM_ARGS      ?=
PLUSARGS      ?=

export MODULE
export TESTCASE
export COCOTB_REDUCED_LOG_FMT=0

# ----------------------------------------------------------------------
# SGE Commands
# ----------------------------------------------------------------------

ifneq ($(SGE_O_HOST),)
QRSH=
else
QRSH=qrsh -V -now y -b y -cwd
endif


# ----------------------------------------------------------------------
# Source Files
# ----------------------------------------------------------------------

VERILOG_SOURCES ?= $(TOPLEVEL).v
VERILOG_SOURCES += glbl.v BUFGCE.v


COMPILE_ARGS += -define COCOTB_SIM
COMPILE_ARGS += -top $(TOPLEVEL) -top glbl


# ----------------------------------------------------------------------
# XRUN arguments
# ----------------------------------------------------------------------

WARNINGS   ?= LEXTSF SPDUSD
XRUN_NOWARN = $(addprefix -nowarn ,$(WARNINGS))

COMPILE_ARGS += -access +rwc -nolibcell $(XRUN_NOWARN)
COMPILE_ARGS += +libext+.v+.vh+.svh+.sv
COMPILE_ARGS += -createdebugdb

EXTRA_ARGS += -licqueue
EXTRA_ARGS += -64
EXTRA_ARGS += -timescale 1ps/1ps -override_timescale
EXTRA_ARGS += -relax # Needed due to Xcelium error E,TRMONDELT; possible Cocotb issue
EXTRA_ARGS += -abvfailurelimit 1

ifeq ($(DEBUG),1)
    EXTRA_ARGS += -pliverbose
    EXTRA_ARGS += -messages
    EXTRA_ARGS += -plidebug             # Enhance the profile output with PLI info
    EXTRA_ARGS += -plierr_verbose       # Expand handle info in PLI/VPI/VHPI messages
    EXTRA_ARGS += -vpicompat 1800v2005  #  <1364v1995|1364v2001|1364v2005|1800v2005> Specify the IEEE VPI
else
    EXTRA_ARGS += -plinowarn
endif

ifeq ($(GUI),1)
    SIM_ARGS += -gui
endif

ifeq ($(WAVES),1)
    SIM_ARGS += $(XRUN_TCL)
endif

# Xcelium will use default vlog_startup_routines symbol only if VPI library name is libvpi.so
GPI_ARGS = -loadvpi $(shell cocotb-config --lib-name-path vpi xcelium):vlog_startup_routines_bootstrap

build:
	xrun -elaborate $(EXTRA_ARGS) $(COMPILE_ARGS) $(VERILOG_INCLUDES) $(VERILOG_SOURCES) $(GPI_ARGS) -l build.log

run:
	xrun -R $(EXTRA_ARGS) $(SIM_ARGS) 2>&1 | tee sim.log