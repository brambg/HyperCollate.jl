#=
test_parser3:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-05
=#

using Test

@testset "hypercollate" begin
    include( "../src/parser3.jl")

    xml = "<text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>"
    @show(xml)
    tokens = tokenize(xml)
    @test map(string,tokens) == ["<text>", "<s>", "<subst>", "<del>", "Dit kwam van een", "</del>", "<add>", "De", "</add>", "</subst>", " te streng doorgedreven rationalisatie", "</s>", "</text>"]

    g = to_graph(xml)
    @show(g)

end