.PHONY: help 
help:		## display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build:	## build the project
	zig build
b: build

build-web:	## build project for web
	zig build -Dtarget=wasm32-emscripten
bw: build-web

run:	## run the project
	zig build run
r: run

run-web:	## run the project in web server
	zig build run -Dtarget=wasm32-emscripten
rw: run-web

