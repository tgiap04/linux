// SPDX-License-Identifier: GPL-2.0
/*
 * kma-branding.c — KMA OS boot banner loadable kernel module
 *
 * Prints welcome message and ASCII logo on module load.
 * Add to /etc/modules for auto-load on boot.
 */
#include <linux/module.h>
#include <linux/kernel.h>

#define KMA_MODULE_NAME "kma-branding"
#define KMA_BANNER \
	"\n" \
	"  ╔══════════════════════════════════════╗\n" \
	"  ║       Welcome to KMA OS             ║\n" \
	"  ║  Minimalist Linux Kernel             ║\n" \
	"  ╚══════════════════════════════════════╝\n\n"

#define KMA_LOGO \
	"     ╔═╗╦ ╦╦═╗╔═╗╔╦╗╔═╗╔═╗╦ ╦\n" \
	"     ║  ╠═╣╠╦╝║ ║ ║║╠═╣║  ╠═╣\n" \
	"     ╚═╝╩ ╩╩╚═╚═╝═╩╝╩ ╩╚═╝╩ ╩\n" \
	"     ─── Minimalist Linux ───\n"

static int __init kma_branding_init(void)
{
	pr_info("%s", KMA_LOGO);
	pr_info("%s", KMA_BANNER);
	return 0;
}

static void __exit kma_branding_exit(void)
{
	pr_info("kma-branding: module unloaded\n");
}

module_init(kma_branding_init);
module_exit(kma_branding_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("KMA OS");
MODULE_DESCRIPTION("KMA OS boot banner module");
MODULE_VERSION("1.0.0");
