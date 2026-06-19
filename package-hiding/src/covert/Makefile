obj-m := covert.o
covert-y := covert_main.o packet_parser.o tcp_embed.o udp_embed.o framing.o error_handler.o

KERNEL_DIR ?= /lib/modules/$(shell uname -r)/build
MAKE_DIR = make -C $(KERNEL_DIR) M=$(PWD)

.PHONY: all clean load unload reload

all:
	$(MAKE_DIR) modules

clean:
	$(MAKE_DIR) clean

load:
	sudo insmod covert.ko target_port=9999 target_ip="10.0.2.15"

unload:
	sudo rmmod covert

reload: unload load

log:
	dmesg | tail -50
