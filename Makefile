
$(shell mkdir -p build)

all: build/beak build/beak-config build/beak-push build/beak-mount build/beak-umount

build/beak: beak.sh
	cp beak.sh build/beak
	chmod a+x build/beak

build/beak-%: beak-%.sh
	cp $< $@
	chmod a+x $@

install: all
	cp build/beak /usr/local/bin/
	chmod a+x /usr/local/bin/beak
	cp build/beak-* /usr/local/bin/
	chmod a+x /usr/local/bin/beak-*
	cp beak.1 /usr/local/share/man/man1


clean:
	rm -f build/* *~
