require 'mkmf'

raise unless have_header "sys/mman.h"

have_const 'MAP_JIT', 'sys/mman.h'

have_func 'pthread_jit_write_protect_np'
have_func 'mach_task_self'

create_makefile('jit_buffer')
