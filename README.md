# JIT Buffer

This is a general purpose JIT Buffer object for building JITs in Ruby.

## Usage

Create a JIT Buffer, then specify the size.  The JIT Buffer can only be
writeable or executable, but not both at the same time.

It starts life as executable, so you need to mark it writeable before writing.

```ruby
# Make a buffer of size 4096
buffer = JITBuffer.new 4096

# Make writeable
buffer.writeable!

# Write some stuff
buffer.write "hello"
```

If you want to execute the JIT instructions, you need to mark it executable
again.

Here is a full example that only works on ARM64:

```ruby
require "jit_buffer"

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

buffer = JITBuffer.new 4096

# Assemble some instructions
insns = [
  movz(0, 42),  # mov X0, 42
  ret           # ret
].pack("L<L<")

# Write the instructions to the JIT buffer
buffer.writeable!
buffer.write insns
buffer.executable!

# Call the instructions.  We JIT'd a function that
# returns an integer "42"
func = buffer.to_function([], Fiddle::TYPE_INT)
puts func.call # returns 42
```
