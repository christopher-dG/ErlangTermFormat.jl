module ErlangTermFormat

export encode, decode

const VERSION_MAGIC = 0x83

include("decode.jl")
include("encode.jl")

end
