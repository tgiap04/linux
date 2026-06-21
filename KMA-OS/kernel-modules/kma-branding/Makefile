obj-m := kma-branding.o

KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(CURDIR)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

load:
	sudo insmod kma-branding.ko

unload:
	sudo rmmod kma-branding

reload: unload load
