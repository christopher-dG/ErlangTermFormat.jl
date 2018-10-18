module ErlangTermFormat

export encode, decode

const VERSION_MAGIC = 131

const U = UInt8
const UV = Vector{U}

include("decode.jl")
include("encode.jl")

end
