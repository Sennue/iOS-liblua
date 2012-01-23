OBJS     := libluasqlite3_loader.lua sqlite3.lua luasql-sqlite3.lua

TARGET   := library.aqd
SRC      := ./
BIN      := ../
LUAC     := luac
LUAFLAGS := -s -o
ALL      := $(patsubst %,$(BIN)/%,$(TARGET))
CLEAN    := $(ALL)

# build all targets (default)
.PHONY: all
all: $(ALL)

# shared scripts
$(BIN)/$(TARGET): $(patsubst %,$(SRC)/%,$(OBJS))
	$(LUAC) $(LUAFLAGS) $@ $+

# remove files that can be rebuilt
.PHONY: clean
clean:
	rm    -f $(CLEAN)

# remove targets and rebuild from scratch
.PHONY: force
force: clean all

