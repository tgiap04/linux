savedcmd_framing.o := gcc -Wp,-MMD,./.framing.o.d -nostdinc -I/usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include -I/usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated -I/usr/src/linux-headers-7.0.0-22-generic/include -I/usr/src/linux-headers-7.0.0-22-generic/include -I/usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi -I/usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/uapi -I/usr/src/linux-headers-7.0.0-22-generic/include/uapi -I/usr/src/linux-headers-7.0.0-22-generic/include/generated/uapi -include /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler-version.h -include /usr/src/linux-headers-7.0.0-22-generic/include/linux/kconfig.h -I/usr/src/linux-headers-7.0.0-22-generic/ubuntu/include -include /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler_types.h -D__KERNEL__ -mlittle-endian -DCC_USING_PATCHABLE_FUNCTION_ENTRY -DKASAN_SHADOW_SCALE_SHIFT= -std=gnu11 -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -mgeneral-regs-only -DCONFIG_CC_HAS_K_CONSTRAINT=1 -Wno-psabi -mabi=lp64 -fno-asynchronous-unwind-tables -fno-unwind-tables -mbranch-protection=pac-ret -Wa,-march=armv8.5-a -DARM64_ASM_ARCH='"armv8.5-a"' -ffixed-x18 -DKASAN_SHADOW_SCALE_SHIFT= -fno-delete-null-pointer-checks -O2 -fno-allow-store-data-races -fstack-protector-strong -fno-omit-frame-pointer -fno-optimize-sibling-calls -ftrivial-auto-var-init=zero -fzero-init-padding-bits=all -fno-stack-clash-protection -fzero-call-used-regs=used-gpr -fpatchable-function-entry=4,2 -fsanitize=shadow-call-stack -fmin-function-alignment=8 -fstrict-flex-arrays=3 -fms-extensions -fno-strict-overflow -fno-stack-check -fconserve-stack -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Werror=strict-prototypes -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=1024 -Wno-main -Wno-type-limits -Wno-dangling-pointer -Wvla-larger-than=1 -Wno-pointer-sign -Wcast-function-type -Wno-unterminated-string-initialization -Wno-array-bounds -Wno-stringop-overflow -Wno-alloc-size-larger-than -Wimplicit-fallthrough=5 -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-packed-not-aligned -Wno-format-overflow -Wno-format-truncation -Wno-stringop-truncation -Wno-override-init -Wno-missing-field-initializers -Wno-shift-negative-value -Wno-maybe-uninitialized -Wno-sign-compare -Wno-unused-parameter -g -gdwarf-5 -mstack-protector-guard=sysreg -mstack-protector-guard-reg=sp_el0 -mstack-protector-guard-offset=1912  -fsanitize=bounds-strict -fsanitize=shift -fsanitize=bool -fsanitize=enum    -DMODULE  -DKBUILD_BASENAME='"framing"' -DKBUILD_MODNAME='"covert"' -D__KBUILD_MODNAME=covert -c -o framing.o framing.c  

source_framing.o := framing.c

deps_framing.o := \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler-version.h \
    $(wildcard include/config/CC_VERSION_TEXT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kconfig.h \
    $(wildcard include/config/CPU_BIG_ENDIAN) \
    $(wildcard include/config/BOOGER) \
    $(wildcard include/config/FOO) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler_types.h \
    $(wildcard include/config/DEBUG_INFO_BTF) \
    $(wildcard include/config/PAHOLE_HAS_BTF_TAG) \
    $(wildcard include/config/FUNCTION_ALIGNMENT) \
    $(wildcard include/config/CC_HAS_SANE_FUNCTION_ALIGNMENT) \
    $(wildcard include/config/X86_64) \
    $(wildcard include/config/ARM64) \
    $(wildcard include/config/LD_DEAD_CODE_DATA_ELIMINATION) \
    $(wildcard include/config/LTO_CLANG) \
    $(wildcard include/config/HAVE_ARCH_COMPILER_H) \
    $(wildcard include/config/KCSAN) \
    $(wildcard include/config/CC_HAS_ASSUME) \
    $(wildcard include/config/CC_HAS_COUNTED_BY) \
    $(wildcard include/config/FORTIFY_SOURCE) \
    $(wildcard include/config/UBSAN_BOUNDS) \
    $(wildcard include/config/CC_HAS_COUNTED_BY_PTR) \
    $(wildcard include/config/CC_HAS_MULTIDIMENSIONAL_NONSTRING) \
    $(wildcard include/config/UBSAN_INTEGER_WRAP) \
    $(wildcard include/config/CFI) \
    $(wildcard include/config/ARCH_USES_CFI_GENERIC_LLVM_PASS) \
    $(wildcard include/config/CC_HAS_BROKEN_COUNTED_BY_REF) \
    $(wildcard include/config/CC_HAS_ASM_INLINE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler-context-analysis.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler_attributes.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler-gcc.h \
    $(wildcard include/config/ARCH_USE_BUILTIN_BSWAP) \
    $(wildcard include/config/SHADOW_CALL_STACK) \
    $(wildcard include/config/KCOV) \
    $(wildcard include/config/CC_HAS_TYPEOF_UNQUAL) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/compiler.h \
    $(wildcard include/config/ARM64_PTR_AUTH_KERNEL) \
    $(wildcard include/config/ARM64_PTR_AUTH) \
    $(wildcard include/config/BUILTIN_RETURN_ADDRESS_STRIPS_PAC) \
  framing.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/types.h \
    $(wildcard include/config/HAVE_UID16) \
    $(wildcard include/config/UID16) \
    $(wildcard include/config/ARCH_DMA_ADDR_T_64BIT) \
    $(wildcard include/config/PHYS_ADDR_T_64BIT) \
    $(wildcard include/config/64BIT) \
    $(wildcard include/config/ARCH_32BIT_USTAT_F_TINODE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/types.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/uapi/asm/types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/int-ll64.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/int-ll64.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/bitsperlong.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitsperlong.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/bitsperlong.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/posix_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/stddef.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/stddef.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/posix_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/posix_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/spinlock.h \
    $(wildcard include/config/SMP) \
    $(wildcard include/config/DEBUG_SPINLOCK) \
    $(wildcard include/config/PREEMPTION) \
    $(wildcard include/config/DEBUG_LOCK_ALLOC) \
    $(wildcard include/config/PREEMPT_RT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/typecheck.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/preempt.h \
    $(wildcard include/config/PREEMPT_COUNT) \
    $(wildcard include/config/DEBUG_PREEMPT) \
    $(wildcard include/config/TRACE_PREEMPT_TOGGLE) \
    $(wildcard include/config/PREEMPT_NOTIFIERS) \
    $(wildcard include/config/PREEMPT_DYNAMIC) \
    $(wildcard include/config/PREEMPT_NONE) \
    $(wildcard include/config/PREEMPT_VOLUNTARY) \
    $(wildcard include/config/PREEMPT) \
    $(wildcard include/config/PREEMPT_LAZY) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/linkage.h \
    $(wildcard include/config/ARCH_USE_SYM_ANNOTATIONS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/stringify.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/export.h \
    $(wildcard include/config/MODVERSIONS) \
    $(wildcard include/config/GENDWARFKSYMS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/compiler.h \
    $(wildcard include/config/TRACE_BRANCH_PROFILING) \
    $(wildcard include/config/PROFILE_ALL_BRANCHES) \
    $(wildcard include/config/OBJTOOL) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/rwonce.h \
    $(wildcard include/config/LTO) \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/rwonce.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kasan-checks.h \
    $(wildcard include/config/KASAN_GENERIC) \
    $(wildcard include/config/KASAN_SW_TAGS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kcsan-checks.h \
    $(wildcard include/config/KCSAN_WEAK_MEMORY) \
    $(wildcard include/config/KCSAN_IGNORE_ATOMICS) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/linkage.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/cleanup.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/err.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/uapi/asm/errno.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/errno.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/errno-base.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/args.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/preempt.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/thread_info.h \
    $(wildcard include/config/THREAD_INFO_IN_TASK) \
    $(wildcard include/config/GENERIC_ENTRY) \
    $(wildcard include/config/ARCH_HAS_PREEMPT_LAZY) \
    $(wildcard include/config/HAVE_ARCH_WITHIN_STACK_FRAMES) \
    $(wildcard include/config/SH) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/limits.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/limits.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/limits.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bug.h \
    $(wildcard include/config/GENERIC_BUG) \
    $(wildcard include/config/PRINTK) \
    $(wildcard include/config/BUG_ON_DATA_CORRUPTION) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/bug.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/asm-bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/brk-imm.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE_DETAILED) \
    $(wildcard include/config/BUG) \
    $(wildcard include/config/GENERIC_BUG_RELATIVE_POINTERS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/instrumentation.h \
    $(wildcard include/config/NOINSTR_VALIDATION) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/once_lite.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/panic.h \
    $(wildcard include/config/PANIC_TIMEOUT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/stdarg.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/printk.h \
    $(wildcard include/config/MESSAGE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_QUIET) \
    $(wildcard include/config/EARLY_PRINTK) \
    $(wildcard include/config/PRINTK_INDEX) \
    $(wildcard include/config/DYNAMIC_DEBUG) \
    $(wildcard include/config/DYNAMIC_DEBUG_CORE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/init.h \
    $(wildcard include/config/MEMORY_HOTPLUG) \
    $(wildcard include/config/HAVE_ARCH_PREL32_RELOCATIONS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/build_bug.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kern_levels.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/ratelimit_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bits.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/bits.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/const.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/const.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/bits.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/overflow.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/const.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/param.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/param.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/param.h \
    $(wildcard include/config/HZ) \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/param.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/spinlock_types_raw.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/spinlock_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/qspinlock_types.h \
    $(wildcard include/config/NR_CPUS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/qrwlock_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/byteorder.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/byteorder/little_endian.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/byteorder/little_endian.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/swab.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/swab.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/uapi/asm/swab.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/swab.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/byteorder/generic.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/lockdep_types.h \
    $(wildcard include/config/PROVE_RAW_LOCK_NESTING) \
    $(wildcard include/config/LOCKDEP) \
    $(wildcard include/config/LOCK_STAT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/dynamic_debug.h \
    $(wildcard include/config/JUMP_LABEL) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/jump_label.h \
    $(wildcard include/config/HAVE_ARCH_JUMP_LABEL_RELATIVE) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/jump_label.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/insn.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/insn-def.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/restart_block.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/time64.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/math64.h \
    $(wildcard include/config/ARCH_SUPPORTS_INT128) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/math.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/asm/div64.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/div64.h \
    $(wildcard include/config/CC_OPTIMIZE_FOR_PERFORMANCE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/kernel.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/sysinfo.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/math64.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/time64.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/time.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/time_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/errno.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/errno.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/current.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bitops.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/generic-non-atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/barrier.h \
    $(wildcard include/config/ARM64_PSEUDO_NMI) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/alternative-macros.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/cpucaps.h \
    $(wildcard include/config/ARM64_EPAN) \
    $(wildcard include/config/ARM64_SVE) \
    $(wildcard include/config/ARM64_SME) \
    $(wildcard include/config/ARM64_CNP) \
    $(wildcard include/config/ARM64_MTE) \
    $(wildcard include/config/ARM64_BTI) \
    $(wildcard include/config/ARM64_TLB_RANGE) \
    $(wildcard include/config/ARM64_POE) \
    $(wildcard include/config/ARM64_GCS) \
    $(wildcard include/config/ARM64_HAFT) \
    $(wildcard include/config/UNMAP_KERNEL_AT_EL0) \
    $(wildcard include/config/ARM64_ERRATUM_843419) \
    $(wildcard include/config/ARM64_ERRATUM_1742098) \
    $(wildcard include/config/ARM64_ERRATUM_2645198) \
    $(wildcard include/config/ARM64_ERRATUM_2658417) \
    $(wildcard include/config/CAVIUM_ERRATUM_23154) \
    $(wildcard include/config/NVIDIA_CARMEL_CNP_ERRATUM) \
    $(wildcard include/config/ARM64_WORKAROUND_REPEAT_TLBI) \
    $(wildcard include/config/ARM64_ERRATUM_3194386) \
    $(wildcard include/config/HW_PERF_EVENTS) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/asm/cpucap-defs.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/barrier.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/bitops.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/builtin-__ffs.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/builtin-ffs.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/builtin-__fls.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/builtin-fls.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/ffz.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/fls64.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/sched.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/hweight.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/arch_hweight.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/const_hweight.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/cmpxchg.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/lse.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/atomic_ll_sc.h \
    $(wildcard include/config/CC_HAS_K_CONSTRAINT) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/alternative.h \
    $(wildcard include/config/MODULES) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/atomic_lse.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/atomic/atomic-arch-fallback.h \
    $(wildcard include/config/GENERIC_ATOMIC64) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/atomic/atomic-long.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/atomic/atomic-instrumented.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/instrumented.h \
    $(wildcard include/config/DEBUG_ATOMIC) \
    $(wildcard include/config/DEBUG_ATOMIC_LARGEST_ALIGN) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kmsan-checks.h \
    $(wildcard include/config/KMSAN) \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/instrumented-atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/lock.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/instrumented-lock.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/non-atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/non-instrumented-non-atomic.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/le.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/bitops/ext2-atomic-setbit.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/thread_info.h \
    $(wildcard include/config/ARM64_SW_TTBR0_PAN) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/memory.h \
    $(wildcard include/config/ARM64_VA_BITS) \
    $(wildcard include/config/ARM64_16K_PAGES) \
    $(wildcard include/config/KASAN_SHADOW_OFFSET) \
    $(wildcard include/config/KASAN) \
    $(wildcard include/config/ARM64_4K_PAGES) \
    $(wildcard include/config/RANDOMIZE_BASE) \
    $(wildcard include/config/KASAN_HW_TAGS) \
    $(wildcard include/config/DEBUG_VIRTUAL) \
    $(wildcard include/config/EFI) \
    $(wildcard include/config/ARM_GIC_V3_ITS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/sizes.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/page-def.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/page.h \
    $(wildcard include/config/PAGE_SHIFT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/mmdebug.h \
    $(wildcard include/config/DEBUG_VM) \
    $(wildcard include/config/DEBUG_VM_IRQSOFF) \
    $(wildcard include/config/DEBUG_VM_PGFLAGS) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/boot.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/sections.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/sections.h \
    $(wildcard include/config/HAVE_FUNCTION_DESCRIPTORS) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/sysreg.h \
    $(wildcard include/config/BROKEN_GAS_INST) \
    $(wildcard include/config/ARM64_PA_BITS_52) \
    $(wildcard include/config/ARM64_64K_PAGES) \
    $(wildcard include/config/AMPERE_ERRATUM_AC04_CPU_23) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kasan-tags.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/gpr-num.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/asm/sysreg-defs.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bitfield.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/memory_model.h \
    $(wildcard include/config/FLATMEM) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP) \
    $(wildcard include/config/SPARSEMEM) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/pfn.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/stack_pointer.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/irqflags.h \
    $(wildcard include/config/PROVE_LOCKING) \
    $(wildcard include/config/TRACE_IRQFLAGS) \
    $(wildcard include/config/IRQSOFF_TRACER) \
    $(wildcard include/config/PREEMPT_TRACER) \
    $(wildcard include/config/DEBUG_IRQFLAGS) \
    $(wildcard include/config/TRACE_IRQFLAGS_SUPPORT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/irqflags_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/irqflags.h \
    $(wildcard include/config/ARM64_DEBUG_PRIORITY_MASKING) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/ptrace.h \
    $(wildcard include/config/COMPAT) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/cpufeature.h \
    $(wildcard include/config/ARM64_BTI_KERNEL) \
    $(wildcard include/config/ARM64_PA_BITS) \
    $(wildcard include/config/ARM64_HW_AFDBM) \
    $(wildcard include/config/ARM64_AMU_EXTN) \
    $(wildcard include/config/ARM64_LPA2) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/cputype.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/hwcap.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/hwcap.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/log2.h \
    $(wildcard include/config/ARCH_HAS_ILOG2_U32) \
    $(wildcard include/config/ARCH_HAS_ILOG2_U64) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kernel.h \
    $(wildcard include/config/PREEMPT_VOLUNTARY_BUILD) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_CALL) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_KEY) \
    $(wildcard include/config/PREEMPT_) \
    $(wildcard include/config/DEBUG_ATOMIC_SLEEP) \
    $(wildcard include/config/MMU) \
    $(wildcard include/config/DYNAMIC_FTRACE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/align.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/align.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/array_size.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/container_of.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kstrtox.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/minmax.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/sprintf.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/static_call_types.h \
    $(wildcard include/config/HAVE_STATIC_CALL) \
    $(wildcard include/config/HAVE_STATIC_CALL_INLINE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/trace_printk.h \
    $(wildcard include/config/TRACING) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/instruction_pointer.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/util_macros.h \
    $(wildcard include/config/FOO_SUSPEND) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/wordpart.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/cpumask.h \
    $(wildcard include/config/FORCE_NR_CPUS) \
    $(wildcard include/config/HOTPLUG_CPU) \
    $(wildcard include/config/DEBUG_PER_CPU_MAPS) \
    $(wildcard include/config/CPUMASK_OFFSTACK) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bitmap.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/find.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/string.h \
    $(wildcard include/config/BINARY_PRINTF) \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/string.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/string.h \
    $(wildcard include/config/ARCH_HAS_UACCESS_FLUSHCACHE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/fortify-string.h \
    $(wildcard include/config/CC_HAS_KASAN_MEMINTRINSIC_PREFIX) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bitmap-str.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/cpumask_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/threads.h \
    $(wildcard include/config/BASE_SMALL) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/gfp_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/numa.h \
    $(wildcard include/config/NUMA_KEEP_MEMINFO) \
    $(wildcard include/config/NUMA) \
    $(wildcard include/config/HAVE_ARCH_NODE_DEV_GROUP) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/nodemask.h \
    $(wildcard include/config/HIGHMEM) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/nodemask_types.h \
    $(wildcard include/config/NODES_SHIFT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/random.h \
    $(wildcard include/config/VMGENID) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/list.h \
    $(wildcard include/config/LIST_HARDENED) \
    $(wildcard include/config/DEBUG_LIST) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/poison.h \
    $(wildcard include/config/ILLEGAL_POINTER_VALUE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/random.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/ioctl.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/uapi/asm/ioctl.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/ioctl.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/asm-generic/ioctl.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/irqnr.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/irqnr.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/sparsemem.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/pgtable-prot.h \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_WP) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/pgtable-hwdef.h \
    $(wildcard include/config/PGTABLE_LEVELS) \
    $(wildcard include/config/ARM64_CONT_PTE_SHIFT) \
    $(wildcard include/config/ARM64_CONT_PMD_SHIFT) \
    $(wildcard include/config/ARM64_VA_BITS_52) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/pgtable-types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/pgtable-nop4d.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/rsi.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/rsi_cmds.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/arm-smccc.h \
    $(wildcard include/config/HAVE_ARM_SMCCC) \
    $(wildcard include/config/ARM) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/uuid.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/rsi_smc.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/ptrace.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/sve_context.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/irqchip/arm-gic-v3-prio.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/stacktrace/frame.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/percpu.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/percpu.h \
    $(wildcard include/config/HAVE_SETUP_PER_CPU_AREA) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/percpu-defs.h \
    $(wildcard include/config/ARCH_MODULE_NEEDS_WEAK_PER_CPU) \
    $(wildcard include/config/DEBUG_FORCE_WEAK_PER_CPU) \
    $(wildcard include/config/AMD_MEM_ENCRYPT) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/bottom_half.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/lockdep.h \
    $(wildcard include/config/DEBUG_LOCKING_API_SELFTESTS) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/smp.h \
    $(wildcard include/config/UP_LATE_INIT) \
    $(wildcard include/config/CSD_LOCK_WAIT_DEBUG) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/smp_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/llist.h \
    $(wildcard include/config/ARCH_HAVE_NMI_SAFE_CMPXCHG) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/smp.h \
    $(wildcard include/config/ARM64_ACPI_PARKING_PROTOCOL) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/asm/mmiowb.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/mmiowb.h \
    $(wildcard include/config/MMIOWB) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/spinlock_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/rwlock_types.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/spinlock.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/asm/qspinlock.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/qspinlock.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/generated/asm/qrwlock.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/asm-generic/qrwlock.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/processor.h \
    $(wildcard include/config/KUSER_HELPERS) \
    $(wildcard include/config/ARM64_FORCE_52BIT) \
    $(wildcard include/config/HAVE_HW_BREAKPOINT) \
    $(wildcard include/config/ARM64_TAGGED_ADDR_ABI) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/cache.h \
    $(wildcard include/config/ARCH_HAS_CACHE_LINE_SIZE) \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/cache.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/cache.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/kasan-enabled.h \
    $(wildcard include/config/ARCH_DEFER_KASAN) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/static_key.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/mte-def.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/vdso/processor.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/vdso/processor.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/hw_breakpoint.h \
    $(wildcard include/config/CPU_PM) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/virt.h \
    $(wildcard include/config/KVM) \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/kasan.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/mte-kasan.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/pointer_auth.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/uapi/linux/prctl.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/spectre.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/asm/fpsimd.h \
  /usr/src/linux-headers-7.0.0-22-generic/arch/arm64/include/uapi/asm/sigcontext.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/rwlock.h \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/spinlock_api_smp.h \
    $(wildcard include/config/INLINE_SPIN_LOCK) \
    $(wildcard include/config/INLINE_SPIN_LOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK_BH) \
    $(wildcard include/config/UNINLINE_SPIN_UNLOCK) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/GENERIC_LOCKBREAK) \
  /usr/src/linux-headers-7.0.0-22-generic/include/linux/rwlock_api_smp.h \
    $(wildcard include/config/INLINE_READ_LOCK) \
    $(wildcard include/config/INLINE_WRITE_LOCK) \
    $(wildcard include/config/INLINE_READ_LOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_LOCK_BH) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_READ_TRYLOCK) \
    $(wildcard include/config/INLINE_WRITE_TRYLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_BH) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQRESTORE) \

framing.o: $(deps_framing.o)

$(deps_framing.o):
