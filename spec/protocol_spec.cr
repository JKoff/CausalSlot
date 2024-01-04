require "spec"
require "../src/protocol"

describe ReadProtocol do
  it "handles multiple versions" do
    io = IO::Memory.new(capacity: 256)
    protocol = ReadProtocol.new(io)
    protocol.start
    protocol.send 1212, Slice(UInt8).new(8, 0xAA)
    protocol.send 3434, Slice(UInt8).new(4, 0xFF)
    io.to_slice.hexstring.should eq (
      "5662207738999ecc0000000000000001" +                  # magic number and protocol version
      "000000000000001000000000000004bcaaaaaaaaaaaaaaaa" +  # version 1212
      "000000000000000c0000000000000d6affffffff"            # version 3434
    )
  end
end

describe WriteProtocol do
  it "handles multiple versions" do
    input = IO::Memory.new(capacity: 256)
    input.write "5662207738999ecc0000000000000001".hexbytes       # magic number and protocol version
    input.write "0000000000000002".hexbytes                       # number of versions to delete
    input.write "00000000000000010000000000000002".hexbytes       # versions to delete
    input.write "0000000000000010".hexbytes                       # payload size
    input.write "5ca1ab1eca11ab1eba5eba11acc01ade".hexbytes       # payload
    input.rewind

    output = IO::Memory.new(capacity: 256)

    protocol = WriteProtocol.new(IO::Stapled.new(input, output))
    protocol.start
    protocol.versions.should eq [1, 2]

    protocol.payload.hexstring.should eq "5ca1ab1eca11ab1eba5eba11acc01ade"

    protocol.send 0x1005e1eaf
    output.to_slice.hexstring.should eq "00000001005e1eaf"
  end

  it "handles zero versions" do
    input = IO::Memory.new(capacity: 256)
    input.write "5662207738999ecc0000000000000001".hexbytes       # magic number and protocol version
    input.write "0000000000000000".hexbytes                       # number of versions to delete, zero
    input.write "0000000000000010".hexbytes                       # payload size
    input.write "5ca1ab1eca11ab1eba5eba11acc01ade".hexbytes       # payload
    input.rewind

    output = IO::Memory.new(capacity: 256)

    protocol = WriteProtocol.new(IO::Stapled.new(input, output))
    protocol.start
    protocol.versions.should be_empty

    protocol.payload.hexstring.should eq "5ca1ab1eca11ab1eba5eba11acc01ade"

    protocol.send 0x1005e1eaf
    output.to_slice.hexstring.should eq "00000001005e1eaf"
  end
end
