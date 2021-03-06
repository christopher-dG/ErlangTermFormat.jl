const U = UInt8

"""
    encode(x) -> Vector{$U}

Encode some [ETF](http://erlang.org/doc/apps/erts/erl_ext_dist.html) data.
"""
encode(x) = U[VERSION_MAGIC; _encode(x)]

_encode(x) = error("Unknown ETF type $(typeof(x))")

# Integers

# Note: Encoding with precision does not include the tag byte.
_encode(x::Integer, p::Integer) = reverse(reinterpret(U, [x]))[end-p+1:end]
function _encode(x::Integer)
     return if 0 <= x <= 255
         U[97, x]
     elseif typemin(Int32) <= x <= typemax(Int32)
         U[98; _encode(x, 4)]
     else
         n = Int(x < 0)
         digs = digits(U, x; base=256)
         if -(BigInt(256)^255) < x < BigInt(256)^255
             U[110; round(U, log(256, abs(x))) + 1; n; digs]
         else
             U[111; _encode(round(UInt32, log(256, abs(x))) + 1, 4); n; digs]
         end
     end
end

# Floats

_encode(x::AbstractFloat) = U[V, 70, reverse(reinterpret(U, [x]))...]

# Tuples

function _encode(x::Tuple)
    len = length(x)
    tag = len <= typemax(U) ? 104 : 105
    return U[tag; _encode(len)[2:end]; vcat(_encode.(x)...)]
end

# Atoms

function _encode(x::Symbol)
    # This one is a weird, ATOM_EXT is deprecated but latest OTP still uses it.
    # Also the length limit for atoms is supposedly 255, which would fit in SMALL_ATOM_EXT.
    # However atoms of any length up to 255 are encoded as ATOM_EXT.
    # We're just going to do what the spec actually says, except for the atom length limit.
    s = Vector{U}(string(x))
    len = length(s)
    return len <= typemax(U) ? U[119; len; s] : U[118; _encode(len, 2); s]
end
_encode(x::Bool) = _encode(Symbol(x))
_encode(::Nothing) = _encode(:nil)

# Lists

function _encode(x::AbstractArray)
    return isempty(x) ? U[106] : U[108; _encode(length(x), 4); _encode.(x)...; 106]
end
_encode(x::Vector{U}) = U[107; _encode(length(x), 2); x]

# Maps

function _encode(x::AbstractDict)
    return U[
        116;
        _encode(length(x), 4);
        vcat(_encode.(vcat([[p.first, p.second] for p in x]...))...);
    ]
end

# Strings

_encode(x::AbstractString) = U[109; _encode(length(x), 4); Vector{U}(x)]
