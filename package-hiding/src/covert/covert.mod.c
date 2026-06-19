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
	{ 0x0ba9d9cf, "skb_copy_bits" },
	{ 0xb7253d38, "sysfs_create_file_ns" },
	{ 0xe8df05fe, "csum_partial" },
	{ 0xfbe7861b, "memcpy" },
	{ 0x1de65285, "kernel_kobj" },
	{ 0x11f4259a, "_raw_spin_lock_irqsave" },
	{ 0xdd6830c7, "sysfs_emit" },
	{ 0xd272d446, "dump_stack" },
	{ 0xe8213e80, "_printk" },
	{ 0x329fc928, "in4_pton" },
	{ 0xe3da47a4, "csum_tcpudp_nofold" },
	{ 0xd272d446, "__stack_chk_fail" },
	{ 0x70c4e12e, "sysfs_remove_file_ns" },
	{ 0x90a48d82, "__ubsan_handle_out_of_bounds" },
	{ 0xf3a021a9, "nf_unregister_net_hook" },
	{ 0x9207e931, "nf_register_net_hook" },
	{ 0xac2615e9, "init_net" },
	{ 0x024e3107, "vprintk" },
	{ 0x444885a7, "_raw_spin_unlock_irqrestore" },
	{ 0x0e9cab28, "memset" },
	{ 0x83480373, "param_ops_charp" },
	{ 0x418dcb63, "__pskb_pull_tail" },
	{ 0x25081731, "kobject_create_and_add" },
	{ 0x058c185a, "jiffies" },
	{ 0x30eb81ed, "__dynamic_pr_debug" },
	{ 0x83480373, "param_ops_int" },
	{ 0xcae0a75f, "kobject_put" },
	{ 0x8df65c54, "module_layout" },
};

static const u32 ____version_ext_crcs[]
__used __section("__version_ext_crcs") = {
	0x0ba9d9cf,
	0xb7253d38,
	0xe8df05fe,
	0xfbe7861b,
	0x1de65285,
	0x11f4259a,
	0xdd6830c7,
	0xd272d446,
	0xe8213e80,
	0x329fc928,
	0xe3da47a4,
	0xd272d446,
	0x70c4e12e,
	0x90a48d82,
	0xf3a021a9,
	0x9207e931,
	0xac2615e9,
	0x024e3107,
	0x444885a7,
	0x0e9cab28,
	0x83480373,
	0x418dcb63,
	0x25081731,
	0x058c185a,
	0x30eb81ed,
	0x83480373,
	0xcae0a75f,
	0x8df65c54,
};
static const char ____version_ext_names[]
__used __section("__version_ext_names") =
	"skb_copy_bits\0"
	"sysfs_create_file_ns\0"
	"csum_partial\0"
	"memcpy\0"
	"kernel_kobj\0"
	"_raw_spin_lock_irqsave\0"
	"sysfs_emit\0"
	"dump_stack\0"
	"_printk\0"
	"in4_pton\0"
	"csum_tcpudp_nofold\0"
	"__stack_chk_fail\0"
	"sysfs_remove_file_ns\0"
	"__ubsan_handle_out_of_bounds\0"
	"nf_unregister_net_hook\0"
	"nf_register_net_hook\0"
	"init_net\0"
	"vprintk\0"
	"_raw_spin_unlock_irqrestore\0"
	"memset\0"
	"param_ops_charp\0"
	"__pskb_pull_tail\0"
	"kobject_create_and_add\0"
	"jiffies\0"
	"__dynamic_pr_debug\0"
	"param_ops_int\0"
	"kobject_put\0"
	"module_layout\0"
;

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "9A6CBC639F310465867B75B");
