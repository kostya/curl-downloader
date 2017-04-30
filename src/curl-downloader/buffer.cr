class Curl::Buffer
  getter io

  def initialize
    @io = IO::Memory.new
    @io_bytesize = 0_u64
  end

  def receive_data(b : Bytes)
    @io.write(b)
    @io_bytesize += b.size
  end

  def bytesize
    @io_bytesize
  end
end
