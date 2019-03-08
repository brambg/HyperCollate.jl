#=
test_parser3:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-05
=#

using Test

@testset "hypercollate" begin
    using HyperCollate
    include("util.jl")

    xml = "<text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>"
    @show(xml)
    tokens = tokenize(xml)
    @test map(string_value,tokens) == ["<text>", "<s>", "<subst>", "<del>", "Dit kwam van een", "</del>", "<add>", "De", "</add>", "</subst>", " te streng doorgedreven rationalisatie", "</s>", "</text>"]

    g = to_graph(xml)
    dot = to_dot(g)
    expected="""
    digraph VariantGraph {
        rankdir=LR
        labelloc=b
        color=white
        edge [arrowsize=0.5]
        v1[shape=circle;width=0.05;label=""]
        v2[shape=box;label="Dit kwam van een"]
        v3[shape=box;label="De"]
        v4[shape=circle;width=0.05;label=""]
        v5[shape=box;label=" te streng doorgedreven rationalisatie"]
        v1 -> v2
        v1 -> v3
        v2 -> v4
        v3 -> v4
        v4 -> v5
    }
    """
    _test_normalized_strings_are_equal(dot,expected)
    _print_dot(dot)

    expected = """
    digraph VariantGraph {
        rankdir=LR
        labelloc=b
        color=white
        edge [arrowsize=0.5]
        v1[shape=box;label="To be, or "]
        v2[shape=circle;width=0.05;label=""]
        v3[shape=box;label="whatever"]
        v4[shape=box;label="not to "]
        v5[shape=circle;width=0.05;label=""]
        v6[shape=box;label="butterfly"]
        v7[shape=box;label="be"]
        v8[shape=circle;width=0.05;label=""]
        v9[shape=circle;width=0.05;label=""]
        v1 -> v2
        v2 -> v3
        v2 -> v4
        v3 -> v9
        v4 -> v5
        v5 -> v6
        v5 -> v7
        v6 -> v8
        v7 -> v8
        v8 -> v9
    }
    """
    dot = (to_dot(to_graph("<xml>To be, or <subst><del>whatever</del><add>not to <subst><del>butterfly</del><add>be</add></subst></add></subst></xml>")))
    _test_normalized_strings_are_equal(dot,expected)
    _print_dot(dot)

    expected = """
    digraph VariantGraph {
        rankdir=LR
        labelloc=b
        color=white
        edge [arrowsize=0.5]
        v1[shape=box;label="pre "]
        v2[shape=circle;width=0.05;label=""]
        v3[shape=box;label="one "]
        v4[shape=box;label="golden goose"]
        v5[shape=box;label=" waddling"]
        v6[shape=box;label="two "]
        v7[shape=box;label="cooked hens"]
        v8[shape=box;label=" smelling"]
        v9[shape=box;label="three "]
        v10[shape=box;label="roasted ducks"]
        v11[shape=box;label=" cooling"]
        v12[shape=circle;width=0.05;label=""]
        v13[shape=box;label=" post"]
        v1 -> v2
        v2 -> v3
        v2 -> v6
        v2 -> v9
        v3 -> v4
        v4 -> v5
        v5 -> v12
        v6 -> v7
        v7 -> v8
        v8 -> v12
        v9 -> v10
        v10 -> v11
        v11 -> v12
        v12 -> v13
    }
    """
    dot = (to_dot(to_graph("<x>pre <app><rdg>one <b>golden goose</b> waddling</rdg><rdg>two <b>cooked hens</b> smelling</rdg><rdg>three <b>roasted ducks</b> cooling</rdg></app> post</x>")))
    _test_normalized_strings_are_equal(dot,expected)
    _print_dot(dot)

#     println(to_dot(to_graph("<x>De <a>kat</a> krabt <b>de krullen</b> van de trap</x>")))
#     println(to_dot(to_graph("<x>Donald smacked <choice><option>Huey</option><option>Dewey</option><option>Louie</option></choice> on his beak.</x>")))
end