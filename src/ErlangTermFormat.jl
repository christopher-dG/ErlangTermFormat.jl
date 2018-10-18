module ErlangTermFormat

export encode, decode

const VERSION_MAGIC = 131

const UVec = Vector{UInt8}

const TAGS = Dict(
    # 70 => :new_float,
    # 77  => :bit_binary,
    # 82  => :atom_cache,
    97  => :small_integer,
    98  => :integer,
    # 99  => :float,
    # 100 => :atom,
    # 101 => :reference,
    # 102 => :port,
    # 103 => :pid,
    104 => :small_tuple,
    105 => :large_tuple,
    # 106 => :nil,
    # 107 => :string,
    # 108 => :list,
    # 109 => :binary,
    # 110 => :small_big,
    # 111 => :large_big,
    # 112 => :new_fun,
    # 113 => :export,
    # 114 => :new_reference,
    # 115 => :small_atom,
    # 116 => :map,
    # 117 => :fun,
    # 118 => :atom_utf8,
    # 119 => :small_atom_utf8,
)

include("decode.jl")
include("encode.jl")

end
