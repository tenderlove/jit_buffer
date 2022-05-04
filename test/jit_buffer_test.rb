require "helper"
require "jit_buffer"

class JITBufferTest < Minitest::Test
  def test_make_writeable
    jit = JITBuffer.new 4096
    jit.writeable!
    jit.putc 46
  end

  def test_putc
    jit = JITBuffer.new 4096
    jit.writeable!
    assert_equal 0, jit.pos
    jit.putc 46
    assert_equal 1, jit.pos
    jit.seek 0
    assert_equal 46, jit.getc
  end

  def test_seek_too_far
    jit = JITBuffer.new 4096
    assert_raises do
      jit.seek 4097
    end
  end

  def test_write_too_far
    jit = JITBuffer.new 4096
    jit.writeable!
    jit.seek 4095
    jit.putc 46
    assert_raises do
      jit.putc 46
    end
  end

  def test_read_too_far
    jit = JITBuffer.new 4096
    jit.seek 4095
    jit.getc
    assert_raises do
      jit.getc
    end
  end

  def test_execute
    jit = JITBuffer.new 4096

    bytes = [0x48, 0xc7, 0xc0, 0x2b, 0x00, 0x00, 0x00, # x86_64 mov rax, 0x2b
             0xc3,                                     # x86_64 ret
             0xeb, 0xf6,                               # x86 jmp
             0x80, 0xd2,                               # ARM movz X11, 0x7b7
             0x60, 0x05, 0x80, 0xd2,                   # ARM movz X0, #0x2b
             0xc0, 0x03, 0x5f, 0xd6]                   # ARM ret

    jit.writeable!

    jit.write bytes.pack("C*")

    jit.executable!
    func = Fiddle::Function.new(jit.to_i + 8, [], Fiddle::TYPE_INT)
    assert_equal 43, func.call
  end

  def test_invalid_write
    jit = JITBuffer.new 4096
    assert_raises do
      jit.write "foo"
    end
  end

  def test_oob_write
    jit = JITBuffer.new 4096
    jit.seek 4095

    jit.writeable!
    assert_raises(JITBuffer::OutOfBoundsException) do
      jit.write "foooooo"
    end
  end

  def test_write
    jit = JITBuffer.new 4096

    bytes = "foo".b
    jit.writeable!
    pos = jit.pos
    jit.write bytes
    assert_equal pos + bytes.bytesize, jit.pos

    jit.seek pos
    assert_equal bytes, jit.read(bytes.bytesize)
  end

  def test_read
    jit = JITBuffer.new 4096

    bytes = "foo".b
    jit.writeable!
    pos = jit.pos
    jit.write bytes
    jit.seek pos
    assert_equal pos, jit.pos
    assert_equal bytes, jit.read(bytes.bytesize)
    assert_equal pos + bytes.bytesize, jit.pos
  end

  def test_read_oob
    jit = JITBuffer.new 4096

    jit.seek 4095
    assert_raises do
      jit.read 3
    end
  end

  def test_to_i
    jit = JITBuffer.new 4096
    assert jit.to_i
  end
end
