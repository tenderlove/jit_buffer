require "fiddle"

class Fiddle::Function
  def to_proc
    this = self
    lambda { |*args| this.call(*args) }
  end
end unless Fiddle::Function.method_defined?(:to_proc)

class JITBuffer
  VERSION = '1.0.4'

  class Exception < StandardError
  end

  class OutOfBoundsException < Exception
  end

  class ReadOnlyException < Exception
  end

  module MMAP
    include Fiddle

    PROT_READ   = 0x01
    PROT_WRITE  = 0x02
    PROT_EXEC   = 0x04

    MAP_SHARED  = 0x01
    MAP_PRIVATE = 0x02

    if RUBY_PLATFORM =~ /darwin/
      MAP_ANON    = 0x1000
      MAP_JIT     = 0x800
    else
      MAP_ANON    = 0x20
      MAP_JIT     = 0x0
    end

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

    begin
      make_function "pthread_jit_write_protect_np", [TYPE_INT], TYPE_VOID
      make_function "sys_icache_invalidate", [TYPE_VOIDP, -TYPE_INT], TYPE_VOID
    rescue Fiddle::DLError
    end

    def self.mmap_buffer size
      ptr = mmap 0, size, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANON | MAP_JIT, -1, 0
      ptr.size = size
      ptr
    end

    if respond_to?(:pthread_jit_write_protect_np)
      # MacOS
      def self.set_writeable ptr
        MMAP.pthread_jit_write_protect_np 0
      end

      def self.set_executable ptr
        MMAP.pthread_jit_write_protect_np 1
        MMAP.sys_icache_invalidate ptr, ptr.size
      end
    else
      # Linux
      def self.set_writeable ptr
        MMAP.mprotect ptr, ptr.size, PROT_READ | PROT_WRITE
      end

      def self.set_executable ptr
        MMAP.mprotect ptr, ptr.size, PROT_READ | PROT_EXEC
      end
    end
  end

  def self.new size
    super(MMAP.mmap_buffer(size), size)
  end

  attr_reader :pos, :size

  def initialize memory, size
    @writeable = false
    @memory = memory
    @size   = size
    @pos    = 0
    executable!
  end

  def [] a, b
    @memory[a, b]
  end

  def putc byte
    raise(ReadOnlyException, "Buffer is read only!") unless @writeable
    raise(OutOfBoundsException, "Buffer full! #{pos} - #{@size}") if pos >= @size
    @memory[pos] = byte
    @pos += 1
  end

  def write bytes
    raise(ReadOnlyException, "Buffer is read only!") unless @writeable
    raise OutOfBoundsException if pos + bytes.bytesize > @size
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
    raise(OutOfBoundsException, "You've gone too far!") if pos + len > @size
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
    MMAP.set_executable @memory.to_i
    @writeable = false
  end

  def writeable!
    MMAP.set_writeable @memory.to_i
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
