"""
    decode(s)

Decode some [ETF](http://erlang.org/doc/apps/erts/erl_ext_dist.html) data.
"""
function decode(s)
    io = IOBuffer(s)
    v = first(read(io, 1))
    v == VERSION_MAGIC || error("Unknown ETF version $v")
    return decode_from_tag!(IOBuffer(s[2:end]))
end

function decode_from_tag!(io::IO)
    t = first(read(io, 1))
    haskey(DECODER_TAGS, t) || error("Unknown ETF tag $t")
    return DECODER_TAGS[t](io)
end

decode_multiple!(io::IO, n::Integer) = Any[decode_from_tag!(io) for _ in 1:n]

# Integers

decode_small_integer!(io::IO) = first(read(io, 1))
function decode_integer!(io::IO, T::Type{<:Integer}=Int32, sz::Int=4, be=true)
    n = first(reinterpret(T, read(io, sz)))
    return be ? ntoh(n) : n
end
function decode_big!(io::IO, T::Type{<:Integer}, sz::Int)
    len = decode_integer!(io, T, sz, false)
    neg = first(read(io, 1)) == 1

    # http://erlang.org/doc/apps/erts/erl_ext_dist.html#small_big_ext
    B = BigInt(256)
    n = sum(map(p -> p[2] * B^(p[1]-1), enumerate(read(io, len))))

    return neg ? -n : n
end
decode_small_big!(io::IO) = decode_big!(io, UInt8, 1)
decode_large_big!(io::IO) = decode_big!(io, UInt32, 4)

# Floats

decode_float!(io::IO) = parse(Float64, String(read(io, 31)))
decode_new_float!(io::IO) = ntoh(reinterpret(Float64, read(io, 8)))

# Tuples

decode_tuple!(io::IO, n::Integer) = Tuple(decode_multiple!(io, n))
function decode_small_tuple!(io::IO)
    len = first(read(io, 1))
    return decode_tuple!(io, len)
end
function decode_large_tuple!(io::IO)
    len = decode_integer!(io, UInt32, 4, true)
    decode_tuple!(io, len)
end

# Atoms

function decode_atom!(io::IO, T::Type{<:Integer}=UInt16, sz::Int=2)
    len = decode_integer!(io, T, sz, true)
    s = Symbol(read(io, len))

    return if s === :nil
        nothing
    elseif s === :true
        true
    elseif s === :false
        false
    else
        s
    end
end
decode_small_atom!(io::IO) = decode_atom!(io, UInt8, 1)
decode_atom_utf8!(io::IO) = decode_atom!(io, UInt16, 2)
decode_small_atom_utf8!(io::IO) = decode_atom!(io, UInt8, 1)

# Lists

decode_nil!(io::IO) = []
function decode_list!(io::IO)
    len = decode_integer!(io, UInt32, 4, true)
    xs = decode_multiple!(io, len)
    decode_from_tag!(io)
    return xs
end
function decode_string!(io::IO)
    len = decode_integer!(io, UInt16, 2, true)
    return read(io, len)
end

# Maps

function decode_map!(io::IO)
    len = decode_integer!(io, UInt32, 4, true)
    xs = decode_multiple!(io, 2 * len)
    return Dict{Any, Any}(xs[i] => xs[i+1] for i in 1:2:length(xs))
end

# Strings

function decode_binary!(io::IO)
    len = decode_integer!(io, UInt32, 4, true)
    return String(read(io, len))
end

const DECODER_TAGS = Dict(
    70 => decode_new_float!,
    # 77  => decode_bit_binary!,
    # 82  => decode_atom_cache!,
    97  => decode_small_integer!,
    98  => decode_integer!,
    99  => decode_float!,
    100 => decode_atom!,
    # 101 => decode_reference!,
    # 102 => decode_port!,
    # 103 => decode_pid!,
    104 => decode_small_tuple!,
    105 => decode_large_tuple!,
    106 => decode_nil!,
    107 => decode_string!,
    108 => decode_list!,
    109 => decode_binary!,
    110 => decode_small_big!,
    111 => decode_large_big!,
    # 112 => decode_new_fun!,
    # 113 => decode_export!,
    # 114 => decode_new_reference!,
    115 => decode_small_atom!,
    116 => decode_map!,
    # 117 => decode_fun!,
    118 => decode_atom_utf8!,
    119 => decode_small_atom_utf8!,
)
