#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0x9aa6980d, "mutex_lock" },
	{ 0x9aa6980d, "mutex_unlock" },
	{ 0x9c4ed43a, "alt_cb_patch_nops" },
	{ 0xe8213e80, "_printk" },
	{ 0x40a621c5, "scnprintf" },
	{ 0xd09b06f5, "kstrtoint" },
	{ 0xd272d446, "__stack_chk_fail" },
	{ 0xdd6830c7, "sysfs_emit" },
	{ 0xac2615e9, "init_net" },
	{ 0xf3a021a9, "nf_unregister_net_hook" },
	{ 0xcb8b6ec6, "kfree" },
	{ 0x2974fb97, "sysfs_remove_group" },
	{ 0xcae0a75f, "kobject_put" },
	{ 0xbd03ed67, "random_kmalloc_seed" },
	{ 0x573bbb73, "kmalloc_caches" },
	{ 0xe4865267, "__kmalloc_cache_noprof" },
	{ 0x25081731, "kobject_create_and_add" },
	{ 0xaffc4ab7, "sysfs_create_group" },
	{ 0x9207e931, "nf_register_net_hook" },
	{ 0x46c12dd3, "kstrndup" },
	{ 0x41495f0d, "strim" },
	{ 0x7f018c63, "strchr" },
	{ 0x8df65c54, "module_layout" },
};

static const u32 ____version_ext_crcs[]
__used __section("__version_ext_crcs") = {
	0x9aa6980d,
	0x9aa6980d,
	0x9c4ed43a,
	0xe8213e80,
	0x40a621c5,
	0xd09b06f5,
	0xd272d446,
	0xdd6830c7,
	0xac2615e9,
	0xf3a021a9,
	0xcb8b6ec6,
	0x2974fb97,
	0xcae0a75f,
	0xbd03ed67,
	0x573bbb73,
	0xe4865267,
	0x25081731,
	0xaffc4ab7,
	0x9207e931,
	0x46c12dd3,
	0x41495f0d,
	0x7f018c63,
	0x8df65c54,
};
static const char ____version_ext_names[]
__used __section("__version_ext_names") =
	"mutex_lock\0"
	"mutex_unlock\0"
	"alt_cb_patch_nops\0"
	"_printk\0"
	"scnprintf\0"
	"kstrtoint\0"
	"__stack_chk_fail\0"
	"sysfs_emit\0"
	"init_net\0"
	"nf_unregister_net_hook\0"
	"kfree\0"
	"sysfs_remove_group\0"
	"kobject_put\0"
	"random_kmalloc_seed\0"
	"kmalloc_caches\0"
	"__kmalloc_cache_noprof\0"
	"kobject_create_and_add\0"
	"sysfs_create_group\0"
	"nf_register_net_hook\0"
	"kstrndup\0"
	"strim\0"
	"strchr\0"
	"module_layout\0"
;

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "B88B03E7818D73F6DB63A34");
