obj-m := kma-vfs-guard.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(CURDIR)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

load:
	sudo insmod kma-vfs-guard.ko protected_paths="/home/kma/src"

unload:
	sudo rmmod kma-vfs-guard

reload: unload load
