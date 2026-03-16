#modified LVB 27/6/2021 to make depmod a separate line item for install
export ARCH := arm64
export CROSS_COMPILE := /home/lsx/source/linux/rk356x_linux/prebuilts/gcc/linux-x86/aarch64/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-


SHELL = /bin/bash
ifneq ($(xvc_bar_num),)
	XVC_FLAGS += -D__XVC_BAR_NUM__=$(xvc_bar_num)
endif

ifneq ($(xvc_bar_offset),)
	XVC_FLAGS += -D__XVC_BAR_OFFSET__=$(xvc_bar_offset)
endif

$(warning XVC_FLAGS: $(XVC_FLAGS).)

topdir := $(shell cd $(src)/.. && pwd)

TARGET_MODULE:=xdma

EXTRA_CFLAGS := -I$(topdir)/include $(XVC_FLAGS)
#EXTRA_CFLAGS += -D__LIBXDMA_DEBUG__
#EXTRA_CFLAGS += -DINTERNAL_TESTING

# ifneq ($(KERNELRELEASE),)
# 	$(TARGET_MODULE)-objs := libxdma.o xdma_cdev.o cdev_ctrl.o cdev_events.o cdev_sgdma.o cdev_xvc.o cdev_bypass.o xdma_mod.o xdma_thread.o
# 	obj-m := $(TARGET_MODULE).o
# else
# 	BUILDSYSTEM_DIR:=/lib/modules/$(shell uname -r)/build
# 	PWD:=$(shell pwd)

$(TARGET_MODULE)-objs := libxdma.o xdma_cdev.o cdev_ctrl.o cdev_events.o cdev_sgdma.o cdev_xvc.o cdev_bypass.o xdma_mod.o xdma_thread.o
obj-m := $(TARGET_MODULE).o
BUILDSYSTEM_DIR:=/home/lsx/source/linux/rk356x_linux/kernel  # Linux kernel path
PWD:=$(shell pwd)

all :
	$(MAKE) -C $(BUILDSYSTEM_DIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(BUILDSYSTEM_DIR) M=$(PWD) clean
	@/bin/rm -f *.ko modules.order *.mod.c *.o *.o.ur-safe .*.o.cmd

install: all
	$(MAKE) -C $(BUILDSYSTEM_DIR) M=$(PWD) modules_install
	depmod -A

# endif
