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
    insns = [
      movz(0, 42),
      ret
    ].pack("L<L<")

    jit.writeable!

    jit.write insns

    jit.executable!
    func = jit.to_function([], Fiddle::TYPE_INT)
    assert_equal 42, func.call
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

  # ARM instructions
  def movz reg, imm
    insn = 0b0_10_100101_00_0000000000000000_00000
    insn |= (1 << 31)  # 64 bit
    insn |= (imm << 5) # immediate
    insn |= reg        # reg
  end

  def ret xn = 30
    insn = 0b1101011_0_0_10_11111_0000_0_0_00000_00000
    insn |= (xn << 5)
    insn
  end
end
