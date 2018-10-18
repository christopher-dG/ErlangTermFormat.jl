const DECODER_TAGS = Dict(
    70 => :new_float,
    # 77  => :bit_binary,
    # 82  => :atom_cache,
    97  => :small_integer,
    98  => :integer,
    99  => :float,
    100 => :atom,
    # 101 => :reference,
    # 102 => :port,
    # 103 => :pid,
    104 => :small_tuple,
    105 => :large_tuple,
    106 => :nil,
    # 107 => :string,
    # 108 => :list,
    # 109 => :binary,
    110 => :small_big,
    111 => :large_big,
    # 112 => :new_fun,
    # 113 => :export,
    # 114 => :new_reference,
    115 => :small_atom,
    116 => :map,
    # 117 => :fun,
    118 => :atom_utf8,
    119 => :small_atom_utf8,
)

function decode(s::UV)
    v = s[1]
    v == VERSION_MAGIC || error("Unknown ETF version $v")
    return first(decode_from_tag(s[2:end]))
end
decode(s::AbstractString) = decode(UV(s))

function decode_from_tag(s::UV)
    t = s[1]
    haskey(DECODER_TAGS, t) || error("Unknown ETF tag $t")
    return eval(Symbol(:decode_, DECODER_TAGS[t]))(s[2:end])
end

# Integers

decode_small_integer(s::UV) = s[1], 1
function decode_integer(s::UV, T::Type{<:Integer}=Int32, sz::Int=4, be=true)
    n = first(reinterpret(T, s[1:sz]))
    return be ? ntoh(n) : n, sz
end
function decode_big(s::UV, T::Type{<:Integer}, sz::Int)
    len = decode_integer(s, T, sz, false)
    neg = s[sz + 1] == 1

    # http://erlang.org/doc/apps/erts/erl_ext_dist.html#small_big_ext
    B = BigInt(256)
    n = sum(map(p -> p[2] * B^(p[1]-1), enumerate(s[2+sz:end])))

    return neg ? -n : n, sz + 1 + n
end
decode_small_big(s::UV) = decode_big(s, UInt8, 1)
decode_large_big(s::UV) = decode_big(s, UInt32, 4)

# Floats

decode_float(s::UV) = parse(Float64, String(s[1:31])), 31
decode_new_float(s::UV) = ntoh(first(reinterpret(Float64, s[1:8]))), 8

# Tuples

function decode_tuple(s::UV, n::Integer)
    xs = []
    start = 1

    for _ in 1:n
        x, sz = decode_from_tag(s[start:end])
        push!(xs, x)
        start += sz + 1  # Account for the tag byte.
    end

    return Tuple(xs), start
end
decode_small_tuple(s::UV) = decode_tuple(s[2:end], s[1])
decode_large_tuple(s::UV) = decode_tuple(s[5:end], decode_integer(s, UInt32, 4, true)[1])

# Atoms

function decode_atom(s::UV, T::Type{<:Integer}=UInt16, sz::Int=2)
    len, _ = decode_integer(s, T, sz, true)
    s = Symbol(s[1+sz:sz+len])
    s === :nil ? nothing : s, sz + len
end
decode_small_atom(s::UV) = decode_atom(s, UInt8, 1)
decode_atom_utf8(s::UV) = decode_atom(s, UInt16, 2)
decode_small_atom_utf8(s::UV) = decode_atom(s, UInt8, 1)

# Lists

decode_nil(s::UV) = [], 0

# Maps

function decode_map(s::UV)
    len, _ = decode_integer(s, UInt32, 4, true)
    d = Dict()
    start = 5
    for _ in 1:len
        k, sz = decode_from_tag(s[start:end])
        start += sz + 1  # Account for the tag byte.
        v, sz = decode_from_tag(s[start:end])
        start += sz + 1
        d[k] = v
    end

    return d, start
end
