#=
test_match:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-04-15
=#

using Test
using HyperCollate,MetaGraphs

include("util.jl")

@testset "match" begin
    TokenVertex v1 = mockVertexWithSigil("A");
    TokenVertex v2 = mockVertexWithSigil("B");
    TokenVertex v3 = mockVertexWithSigil("C");
    TokenVertex v4 = mockVertexWithSigil("D");
    match = Match(v1, v2, v3, v4)//
    set_rank!(match,"A",1);
    set_rank!(match,"B",2);
    set_rank!(match,"C",3);
    set_rank!(match,"D",4);
    lowestRankForWitnessesOtherThan = getLowestRankForWitnessesOtherThan(match,"A");
    @test lowestRankForWitnessesOtherThan==2;
end