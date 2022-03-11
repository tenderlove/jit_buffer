#include <ruby.h>
#include <sys/mman.h>
#include <mach/vm_prot.h>
#include <mach/mach_init.h>
#include <pthread.h>

#if HAVE_SYS_ICACHE_INVALIDATE
#include <libkern/OSCacheControl.h>
#endif

#if HAVE_PTHREAD_JIT_WRITE_PROTECT_NP
static VALUE
rb_pthread_jit_write_protect_np(VALUE mod, VALUE v)
{
    if (RTEST(v)) {
        pthread_jit_write_protect_np(1);
    }
    else {
        pthread_jit_write_protect_np(0);
    }

    return Qnil;
}
#endif

#if HAVE_SYS_ICACHE_INVALIDATE
static VALUE
rb_sys_icache_invalidate(VALUE mod, VALUE addr, VALUE len)
{
    sys_icache_invalidate((void *)(NUM2ULONG(addr)), NUM2INT(len));

    return Qnil;
}
#endif

void Init_jit_buffer() {
    VALUE rb_cJITBuffer = rb_define_class("JITBuffer", rb_cObject);
    VALUE rb_mMMap = rb_define_module_under(rb_cJITBuffer, "MMAP");

    rb_define_const(rb_mMMap, "PROT_READ", INT2NUM(PROT_READ));
    rb_define_const(rb_mMMap, "PROT_WRITE", INT2NUM(PROT_WRITE));
    rb_define_const(rb_mMMap, "PROT_EXEC", INT2NUM(PROT_EXEC));
    rb_define_const(rb_mMMap, "VM_PROT_COPY", INT2NUM(VM_PROT_COPY));
    rb_define_const(rb_mMMap, "VM_PROT_READ", INT2NUM(VM_PROT_READ));
    rb_define_const(rb_mMMap, "VM_PROT_EXECUTE", INT2NUM(VM_PROT_EXECUTE));
    rb_define_const(rb_mMMap, "MAP_PRIVATE", INT2NUM(MAP_PRIVATE));
    rb_define_const(rb_mMMap, "MAP_ANON", INT2NUM(MAP_ANON));
#if HAVE_CONST_MAP_JIT
    rb_define_const(rb_mMMap, "MAP_JIT", INT2NUM(MAP_JIT));
#endif

#if HAVE_PTHREAD_JIT_WRITE_PROTECT_NP
    rb_define_module_function(rb_mMMap, "pthread_jit_write_protect_np", rb_pthread_jit_write_protect_np, 1);
#endif

#if HAVE_SYS_ICACHE_INVALIDATE
    rb_define_module_function(rb_mMMap, "sys_icache_invalidate", rb_sys_icache_invalidate, 2);
#endif
}
