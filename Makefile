
$(shell mkdir -p build)

all: build/beak build/beak-config build/beak-push build/beak-status build/beak-mount build/beak-umount

build/beak: beak.sh
	cp beak.sh build/beak
	chmod a+x build/beak

build/beak-config: beak-config.sh
	cp beak-config.sh build/beak-config
	chmod a+x build/beak-config

build/beak-push: beak-push.sh
	cp beak-push.sh build/beak-push
	chmod a+x build/beak-push

build/beak-status: beak-status.sh
	cp beak-status.sh build/beak-status
	chmod a+x build/beak-status

build/beak-mount:  beak-mount.sh
	cp beak-mount.sh build/beak-mount
	chmod a+x build/beak-mount

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
