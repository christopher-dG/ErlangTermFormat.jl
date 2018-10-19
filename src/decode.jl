"""
    decode(s::Union{AbstractString, Vector{UInt8}})

Decode some [ETF](http://erlang.org/doc/apps/erts/erl_ext_dist.html) data.
"""
function decode(s::UV)
    v = s[1]
    v == VERSION_MAGIC || error("Unknown ETF version $v")
    return decode_from_tag(s[2:end])[1]
end
decode(s::AbstractString) = decode(UV(s))

function decode_from_tag(s::UV)
    t = s[1]
    haskey(DECODER_TAGS, t) || error("Unknown ETF tag $t")
    x, sz = DECODER_TAGS[t](s[2:end])
    return x, sz + 1  # Account for the tag byte.
end

function decode_multiple(s::UV, n::Integer)
    xs = []
    start = 1

    for _ in 1:n
        x, sz = decode_from_tag(s[start:end])
        push!(xs, x)
        start += sz
    end

    return xs, start - 1
end

# Integers

decode_small_integer(s::UV) = s[1], 1
function decode_integer(s::UV, T::Type{<:Integer}=Int32, sz::Int=4, be=true)
    n = reinterpret(T, s[1:sz])[1]
    return be ? ntoh(n) : n, sz
end
function decode_big(s::UV, T::Type{<:Integer}, sz::Int)
    len = decode_integer(s, T, sz, false)[1]
    neg = s[sz + 1] == 1

    # http://erlang.org/doc/apps/erts/erl_ext_dist.html#small_big_ext
    B = BigInt(256)
    n = sum(map(p -> p[2] * B^(p[1]-1), enumerate(s[2+sz:1+sz+len])))

    return neg ? -n : n, sz + 1 + n
end
decode_small_big(s::UV) = decode_big(s, UInt8, 1)
decode_large_big(s::UV) = decode_big(s, UInt32, 4)

# Floats

decode_float(s::UV) = parse(Float64, String(s[1:31])), 31
decode_new_float(s::UV) = ntoh(reinterpret(Float64, s[1:8])[1]), 8

# Tuples

function decode_tuple(s::UV, n::Integer)
    xs, sz = decode_multiple(s, n)
    return Tuple(xs), sz
end
decode_small_tuple(s::UV) = decode_tuple(s[2:end], s[1])
decode_large_tuple(s::UV) = decode_tuple(s[5:end], decode_integer(s, UInt32, 4, true)[1])

# Atoms

function decode_atom(s::UV, T::Type{<:Integer}=UInt16, sz::Int=2)
    len = decode_integer(s, T, sz, true)[1]
    s = Symbol(s[1+sz:sz+len])

    return if s === :nil
        nothing
    elseif s === :true
        true
    elseif s === :false
        false
    else
        s
    end, sz + len
end
decode_small_atom(s::UV) = decode_atom(s, UInt8, 1)
decode_atom_utf8(s::UV) = decode_atom(s, UInt16, 2)
decode_small_atom_utf8(s::UV) = decode_atom(s, UInt8, 1)

# Lists

decode_nil(s::UV) = [], 0
function decode_list(s::UV)
    # TODO: How to handle the tail?
    xs, sz = decode_multiple(s[5:end], decode_integer(s, UInt32, 4, true)[1])
    return xs, 4 + sz
end
function decode_string(s::UV)
    len = decode_integer(s, UInt16, 2, true)[1]
    return s[3:2+len], 2 + len
end

# Maps

function decode_map(s::UV)
    xs, sz = decode_multiple(s[5:end], 2 * decode_integer(s, UInt32, 4, true)[1])
    return Dict(xs[i] => xs[i+1] for i in 1:2:length(xs)), 4 + sz
end

# Strings

function decode_binary(s::UV)
    len = decode_integer(s, UInt32, 4, true)[1]
    return String(s[5:4+len]), 4 + len
end

const DECODER_TAGS = Dict(
    70 => decode_new_float,
    # 77  => decode_bit_binary,
    # 82  => decode_atom_cache,
    97  => decode_small_integer,
    98  => decode_integer,
    99  => decode_float,
    100 => decode_atom,
    # 101 => decode_reference,
    # 102 => decode_port,
    # 103 => decode_pid,
    104 => decode_small_tuple,
    105 => decode_large_tuple,
    106 => decode_nil,
    107 => decode_string,
    108 => decode_list,
    109 => decode_binary,
    110 => decode_small_big,
    111 => decode_large_big,
    # 112 => decode_new_fun,
    # 113 => decode_export,
    # 114 => decode_new_reference,
    115 => decode_small_atom,
    116 => decode_map,
    # 117 => decode_fun,
    118 => decode_atom_utf8,
    119 => decode_small_atom_utf8,
)
