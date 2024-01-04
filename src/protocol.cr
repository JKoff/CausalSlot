class ReadProtocol
  def initialize(io : IO)
    @io = io
  end

  def start
    # Magic number (8 bytes)
    IO::ByteFormat::NetworkEndian.encode(0x5662207738999ecc_u64, @io)
    # Protocol version (8 bytes)
    IO::ByteFormat::NetworkEndian.encode(1_u64, @io)
  end

  def send(version : UInt64, data : Bytes)
    # Size of version + data part (8 bytes)
    IO::ByteFormat::NetworkEndian.encode(8_u64 + data.bytesize.to_u64, @io)
    # Version (8 bytes)
    IO::ByteFormat::NetworkEndian.encode(version.to_u64, @io)
    # Data (variable bytes)
    @io.write data
  end
end

class WriteProtocol
  def initialize(io : IO)
    @io = io
  end

  def start
    # Magic number (8 bytes)
    magic = IO::ByteFormat::NetworkEndian.decode(UInt64, @io)
    if magic != 0x5662207738999ecc_u64
      raise "Invalid magic number"
    end

    # Protocol version (8 bytes)
    protovsn = IO::ByteFormat::NetworkEndian.decode(UInt64, @io)
    if protovsn != 1_u64
      raise "Invalid protocol version"
    end
  end

  def versions : Array(UInt64)
    # Causal versions to delete count (8 bytes)
    numversions = IO::ByteFormat::NetworkEndian.decode(UInt64, @io)

    # Causal versions to delete (8 bytes each)
    versions = [] of UInt64
    numversions.times do
      versions << IO::ByteFormat::NetworkEndian.decode(UInt64, @io)
    end

    versions
  end

  def payload : Bytes
    # Size (8 bytes)
    payloadsize = IO::ByteFormat::NetworkEndian.decode(UInt64, @io)

    # Data (variable)
    payload = Bytes.new(payloadsize)
    actual_payloadsize = @io.read(payload)
    if actual_payloadsize != payloadsize
      raise "Invalid payload size"
    end

    payload
  end

  def send(version : UInt64)
    # New version ID (8 bytes)
    IO::ByteFormat::NetworkEndian.encode(version.to_u64, @io)
  end
end
