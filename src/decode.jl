function decode(s::UVec)
    v = s[1]
    v == VERSION_MAGIC || error("Unknown ETF version $v")
    return first(decode_from_tag(s[2:end]))
end

decode(s::AbstractString) = decode(UVec(s))

function decode_from_tag(s::UVec)
    t = s[1]
    haskey(TAGS, t) || error("Unknown ETF tag $t")
    return eval(Symbol("decode_", TAGS[t]))(s[2:end])
end

decode_small_integer(s::UVec) = s[1], 1
decode_integer(s::UVec) = decode_int(s, Int32, 4), 4
decode_float(s::UVec) = parse(Float64, String(s[1:31])), 31  # TODO: Less janky?
decode_small_tuple(s::UVec) = decode_tuple(s[2:end], s[1])
decode_large_tuple(s::UVec) = decode_tuple(s[5:end], decode_int(s, UInt32, 4))

function decode_tuple(s::UVec, n::Integer)
    xs = []
    sizehint!(xs, n)
    start = 1

    for _ in 1:n
        val, sz = decode_from_tag(s[start:end])
        push!(xs, val)
        start += sz + 1  # Account for the tag byte.
    end

    return Tuple(xs), start
end

decode_int(s::UVec, T::Type{<:Integer}, sz::Int) = ntoh(first(reinterpret(T, s[1:sz])))
