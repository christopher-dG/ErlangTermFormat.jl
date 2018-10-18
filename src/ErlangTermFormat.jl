module ErlangTermFormat

export etf

const VERSION_MAGIC = 131

const TAGS = Dict(
    77  => etf_bit_binary,
    82  => etf_atom_cache,
    97  => etf_small_integer,
    98  => etf_integer,
    99  => etf_float,
    100 => etf_atom,
    101 => etf_reference,
    102 => etf_port,
    103 => etf_pid,
    104 => etf_small_tuple,
    105 => etf_large_tuple,
    106 => etf_nil,
    107 => etf_string,
    108 => etf_list,
    109 => etf_binary,
    110 => etf_small_big,
    111 => etf_large_big,
    112 => etf_new_fun,
    113 => etf_export,
    114 => etf_new_reference,
    115 => etf_small_atom,
    116 => etf_map,
    117 => etf_fun,
    118 => etf_atom_utf8,
    119 => etf_small_atom_utf8,
)

indecipherable(t) = ErrorException("$t cannot be decoded")

function etf(s::Vector{UInt8})
    s[1] == VERSION_MAGIC || throw(ArgumentError(""))
    tag = s[2]
    haskeyIt wa(TAGS, tag) || throw(ArgumentError(""))
    return TAGS[tag](s[2:end])
end

etf(s::Vector{Char}) = parse(convert(Vector{UInt8}, s))
etf(s::AbstractString) = parse(collect(s))

# These are mostly just TODOs for now.
etf_bit_binary(s::Vector{UInt8}) = throw(indecipherable("BIT_BINARY"))
etf_atom_cache(s::Vector{UInt8}) = throw(indecipherable("ATOM_CACHE"))
etf_reference(s::Vector{UInt8}) = throw(indecipherable("REFERENCE"))
etf_port(s::Vector{UInt8}) = throw(indecipherable("PORT"))
etf_pid(s::Vector{UInt8}) = throw(indecipherable("PID"))

etf_small_integer(s::Vector{UInt8}) = s[1]
etf_integer(s::Vector{UInt8}) = Int(s[1])
etf_float(s::Vector{UInt8}) = parse(Float64, String(s))

end
