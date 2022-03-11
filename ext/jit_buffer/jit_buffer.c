#include <ruby.h>
#include <sys/mman.h>
#include <mach/vm_prot.h>
#include <mach/mach_init.h>
#include <pthread.h>

#if HAVE_MACH_TASK_SELF
static VALUE
rb_mach_task_self(VALUE mod)
{
    return LONG2NUM((uintptr_t)mach_task_self());
}
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

#if HAVE_MACH_TASK_SELF
    rb_define_module_function(rb_mMMap, "mach_task_self", rb_mach_task_self, 0);
#endif
}
