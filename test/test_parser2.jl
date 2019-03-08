#=
test_hypercollate:
- Julia version: 
- Author: bramb
- Date: 2019-02-20
=#
using Test

@testset "parser2" begin
    include("../src/parser2.jl")

    xml = "<text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "<|Dit kwam van een|De|> te streng doorgedreven rationalisatie"
    @show(serialized)
    println()

    xml = "<xml>The rain in <subst><del>Cataluña</del><add>Spain</add></subst> falls mainly on the plain.</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "The rain in <|Cataluña|Spain|> falls mainly on the plain."
    @show(serialized)
    println()

    xml = "<xml>The rain in Spain falls mainly on the <subst><del>street</del><add>plain</add></subst>.</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "The rain in Spain falls mainly on the <|street|plain|>."
    @show(serialized)
    println()

    xml = "<xml>The rain in Spain falls mainly on the <app><rdg>street</rdg><rdg>plain</rdg></app>.</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "The rain in Spain falls mainly on the <|street|plain|>."
    @show(serialized)
    println()

    xml = "<xml>De <a>kat</a> krabt <b>de krullen</b> van de trap</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "De kat krabt de krullen van de trap"
    @show(serialized)
    println()

    xml = "<xml>To be, or <subst><del>whatever</del><add>not to <subst><del>butterfly</del><add>be</add></subst></add></subst></xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
#     @test serialized == "To be, or <|whatever|not to <|butterfly|be|>|>"
    @show(serialized)
    println()

end
