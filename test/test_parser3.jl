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
    @test map(string_value,tokens) == ["<text>", "<s>", "<subst>", "<del>", "Dit kwam van een", "</del>", "<add>", "De", "</add>", "</subst>", " te streng doorgedreven rationalisatie", "</s>", "</text>"]

    g = to_graph(xml)
#     @show(g)

    dot = to_dot(g)
    println(dot)

#     println(to_dot(to_graph("<x>De <a>kat</a> krabt <b>de krullen</b> van de trap</x>")))
#     println(to_dot(to_graph("<x>Donald smacked <choice><option>Huey</option><option>Dewey</option><option>Louie</option></choice> on his beak.</x>")))
    println(to_dot(to_graph("<xml>To be, or <subst><del>whatever</del><add>not to <subst><del>butterfly</del><add>be</add></subst></add></subst></xml>")))

end