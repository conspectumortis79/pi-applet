.PHONY: all build install uninstall clean

all: build

build:
	sh build.sh

install:
	sh install.sh

uninstall:
	sh uninstall.sh

clean:
	cd applet && cargo clean
