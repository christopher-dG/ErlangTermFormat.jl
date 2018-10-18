function decode(s::UVec)
    v = s[1]
    v == VERSION_MAGIC || error("Unknown ETF version $v")
    return first(decode_from_tag(s[2:end]))
end
decode(s::AbstractString) = decode(UVec(s))

function decode_from_tag(s::UVec)
    t = s[1]
    haskey(TAGS, t) || error("Unknown ETF tag $t")
    return eval(Symbol(:decode_, TAGS[t]))(s[2:end])
end

# Integers

decode_small_integer(s::UVec) = s[1], 1
function decode_integer(s::UVec, T::Type{<:Integer}=Int32, sz::Int=4, be=false)
    n = first(reinterpret(T, s[1:sz]))
    return be ? ntoh(n) : n
end
function decode_big(s::UVec, T::Type{<:Integer}, sz::Int)
    len = decode_integer(s, T, sz, false)
    neg = s[sz + 1] == 1

    # http://erlang.org/doc/apps/erts/erl_ext_dist.html#small_big_ext
    B = BigInt(256)
    n = sum(map(p -> p[2] * B^(p[1]-1), enumerate(s[2+sz:end])))

    return neg ? -n : n, sz + 1 + n
end
decode_small_big(s::UVec) = decode_big(s, UInt8, 1)
decode_large_big(s::UVec) = decode_big(s, UInt32, 4)

# Floats

decode_float(s::UVec) = parse(Float64, String(s[1:31])), 31
decode_new_float(s::UVec) = ntoh(first(reinterpret(Float64, s[1:8]))), 8

# Tuples

function decode_tuple(s::UVec, n::Integer)
    xs = []
    start = 1

    for _ in 1:n
        x, sz = decode_from_tag(s[start:end])
        push!(xs, x)
        start += sz + 1  # Account for the tag byte.
    end

    return Tuple(xs), start
end
decode_small_tuple(s::UVec) = decode_tuple(s[2:end], s[1])
decode_large_tuple(s::UVec) = decode_tuple(s[5:end], decode_integer(s, UInt32, 4, true))

# Atoms

function decode_atom(s::UVec, T::Type{<:Integer}=UInt16, n::Int=2)
    len = decode_integer(s, T, sz, true)
    s = Symbol(s[1+sz:sz+n])
    s === :nil ? nothing : s, sz + n
end
decode_small_atom(s::UVec) = decode_atom(s, UInt8, 1)
decode_atom_utf8(s::UVec) = decode_atom(s, UInt16, 2)
decode_small_atom_utf8(s::UVec) = decode_atom(s, UInt8, 1)
decode_nil(s::UVec) = nothing, 0
