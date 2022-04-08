require "jit_buffer.so"
require "fiddle"

class Fiddle::Function
  def to_proc
    this = self
    lambda { |*args| this.call(*args) }
  end
end unless Fiddle::Function.method_defined?(:to_proc)

class JITBuffer
  VERSION = '1.0.0'

  class Exception < StandardError
  end

  class OutOfBoundsException < Exception
  end

  class ReadOnlyException < Exception
  end

  module MMAP
    include Fiddle

    def self.make_function name, args, ret
      ptr = Handle::DEFAULT[name]
      func = Function.new ptr, args, ret, name: name
      define_singleton_method name, &func.to_proc
    end

    make_function "munmap", [TYPE_VOIDP, # addr
                             TYPE_SIZE_T], # len
                             TYPE_INT

    make_function "mmap", [TYPE_VOIDP,
                           TYPE_SIZE_T,
                           TYPE_INT,
                           TYPE_INT,
                           TYPE_INT,
                           TYPE_INT], TYPE_VOIDP

    make_function "mprotect", [TYPE_VOIDP, TYPE_SIZE_T, TYPE_INT], TYPE_INT

    def self.mmap_buffer size
      ptr = mmap 0, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANON | MAP_JIT, -1, 0
      ptr.size = size
      ptr
    end
  end

  def self.new size
    x = super(MMAP.mmap_buffer(size), size)
    MMAP.pthread_jit_write_protect_np(true)
    x
  end

  attr_reader :pos

  def initialize memory, size
    @writeable = false
    @memory = memory
    @size   = size
    @pos    = 0
  end

  def putc byte
    raise(ReadOnlyException, "Buffer is read only!") unless @writeable
    raise(OutOfBoundsException, "Buffer full! #{pos} - #{@size}") if pos >= @size
    @memory[pos] = byte
    @pos += 1
  end

  def write bytes
    raise(ReadOnlyException, "Buffer is read only!") unless @writeable
    raise OutOfBoundsException if pos + bytes.bytesize >= @size
    @memory[pos, bytes.length] = bytes
    @pos += bytes.bytesize
  end

  def getc
    raise(OutOfBoundsException, "You've gone too far!") if pos >= @size
    x = @memory[pos]
    @pos += 1
    x
  end

  def read len
    raise(OutOfBoundsException, "You've gone too far!") if pos + len >= @size
    x = @memory[pos, pos + len]
    @pos += len
    x
  end

  def seek pos, whence = IO::SEEK_SET
    raise NotImplementedError if whence != IO::SEEK_SET
    raise OutOfBoundsException if pos >= @size

    @pos = pos
    self
  end

  def executable!
    MMAP.pthread_jit_write_protect_np true
    MMAP.sys_icache_invalidate @memory.to_i, @size
    @writeable = false
  end

  def writeable!
    MMAP.pthread_jit_write_protect_np false
    @writeable = true
  end

  def to_function params, ret
    Fiddle::Function.new @memory.to_i, params, ret
  end

  # Get the address of the executable memory
  def to_i
    @memory.to_i
  end
end
