#=
test_collater:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-18
=#

using Test,WordTokenizers

include("util.jl")

# tokenize(string::String) = split(string, r"[\s,:;]+")

@testset "tokenizer" begin
    @testset "tokenize 1" begin
#         set_tokenizer(toktok_tokenize)
        @test tokenize("hello world") == ["hello", "world"]
        @test tokenize("hello, world") == ["hello", ",", "world"]
        @test tokenize("i can't stand that!") == ["i", "ca", "n't", "stand", "that", "!"]
    end
end
