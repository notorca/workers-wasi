# disable built-in rules
.SUFFIXES:

all: dist/index.mjs

ci: test
	npm pack --pack-destination ./build --quiet
	@git diff --exit-code HEAD # error on unexpected changes, eg. out of date package-lock.json

test: all
	cd ./test && $(MAKE)

clean:
	rm -rf ./dist/
	rm -rf ./build/
	rm -rf ./node_modules/
	rm -rf ./test/node_modules/

WASI_SDK_PATH := ./deps/wasi-sdk-16.0
WASI_SYSROOT  := $(abspath ${WASI_SDK_PATH}/share/wasi-sysroot)

export CC      := $(abspath ${WASI_SDK_PATH}/bin/clang) -target wasm32-wasi --sysroot=${WASI_SYSROOT}
export CFLAGS  := -Oz -flto -I ./deps/rapidjson/include -I./deps/littlefs -fno-exceptions -include ./src/config.h -Wexit-time-destructors
export LDFLAGS := -lstdc++ -flto -Wl,--allow-undefined -mexec-model=reactor
export CXXFLAGS := -std=c++20

WASM_OBJ := \
	./build/obj/deps/littlefs/lfs.o \
	./build/obj/deps/littlefs/lfs_util.o \
	./build/obj/deps/littlefs/bd/lfs_rambd.o \
	./build/obj/src/memfs.o \
	./build/obj/src/util.o

HEADERS := $(wildcard ./src/*.h)
build/obj/%.o: %.c $(HEADERS) $(WASI_SDK_PATH)
	mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $< -o $@

build/obj/%.o: %.cc $(HEADERS) $(WASI_SDK_PATH)
	mkdir -p $(@D)
	$(CC) -c $(CFLAGS) $(CXXFLAGS) $< -o $@

dist/memfs.wasm: $(WASM_OBJ)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) $(LDFLAGS) $(WASM_OBJ) -o $@

node_modules: ./package.json ./package-lock.json
	npm install --no-audit --no-optional --no-fund --no-progress --quiet
	touch $@

dist/index.mjs: $(wildcard ./src/**) node_modules dist/memfs.wasm
	sed -i 's/^class Asyncify/export class Asyncify/g' ./deps/asyncify/asyncify.mjs
	$(shell npm bin)/tsc -p ./tsconfig.json
	$(shell npm bin)/esbuild --bundle ./src/index.ts --outfile=$@ --format=esm --log-level=warning --external:*.wasm

$(WASI_SDK_PATH):
	mkdir -p $(@D)
	curl -sLo wasi-sdk.tar.gz https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-16/wasi-sdk-16.0-linux.tar.gz
	echo '10df3418485e60b9283c1132102f8d3ca34b4fbe8c4649e30282ee84fe42d788 wasi-sdk.tar.gz' | sha256sum -c
	tar zxf wasi-sdk.tar.gz --touch -C deps
	rm wasi-sdk.tar.gz
