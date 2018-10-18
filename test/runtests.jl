using ErlangTermFormat
using Test

isdir("data") || error("Run generator.exs before testing")

const etfs = read.(joinpath.("data", readdir("data")), String)

@testset "ErlangTermFormat.jl" begin
    for e in etfs
        @test encode(decode(e)) == e
    end
end
