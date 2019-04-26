#=
test_collater:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-18
=#

using Test
using HyperCollate,MetaGraphs

include("util.jl")

@testset "collater" begin
    @testset "collating 2 xml texts" begin
        f_xml = """
        <text>
            <s>Hoe zoet moet nochtans zijn dit <subst><del>werven om</del><add>trachten naar</add></subst> een vrouw,
                de ongewisheid vóór de liefelijke toestemming!</s>
        </text>
        """
        q_xml = """
        <text>
            <s>Hoe zoet moet nochtans zijn dit <subst><del>werven om</del><add>trachten naar</add></subst> een vrouw !
                Die dagen van nerveuze verwachting vóór de liefelijke toestemming.</s>
        </text>
        """
        collation = Collation()
        @test collation.state == needs_witness

        add_witness!(collation,"F",f_xml)
        @test collation.state == needs_witness
        _print_dot(to_dot(to_graph(f_xml)))

        add_witness!(collation,"Q",f_xml)
        @test collation.state == ready_to_collate
        _print_dot(to_dot(to_graph(q_xml)))

        collate!(collation)
        @test collation.state == is_collated
        @debug(collation)
        dot = to_dot(collation.graph)
        _print_dot(dot)
    end

    @testset "collating 2 xml texts: doorheen..." begin
        include("util.jl")
        @debug_on()
        f_xml = """<s>doorheen de <del><add>stille</add></del><add>luistille</add> gangen</s>"""
        q_xml = """<s>door<del>heen</del> de luistille gangen</s>"""
        collation = Collation()
        @test collation.state == needs_witness

        add_witness!(collation,"F",f_xml)
        @test collation.state == needs_witness
        _print_dot(to_dot(to_graph(f_xml)))

        add_witness!(collation,"Q",f_xml)
        @test collation.state == ready_to_collate
        _print_dot(to_dot(to_graph(q_xml)))

        collate!(collation)
        @test collation.state == is_collated
        @debug(collation)
        dot = to_dot(collation.graph)
        _print_dot(dot)

        expected_dot="""
        digraph CollationGraph {
            rankdir=LR
            labelloc=b
            color=white
            edge [arrowsize=0.5]
            something.....
        }
        """
        @debug_off()
        _test_normalized_strings_are_equal(dot,expected_dot)
    end

    @testset "ranking" begin
        xml = """
        <text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>
        """

        vwg = to_graph(xml)
        r = ranking(vwg)
        for v in keys(r.by_vertex)
            str = get_prop(vwg,v,:text)
            @debug("$str : $(r.by_vertex[v])")
        end
        for rank in sort(collect(keys(r.by_rank)))
            @debug("$rank : $(r.by_rank[rank])")
        end
    end

end
