#=
test_collater:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-18
=#

using Test
using HyperCollate,MetaGraphs

@testset "collater" begin
    include("util.jl")

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

    add_witness!(collation,"Q",f_xml)
    @test collation.state == ready_to_collate

    collate!(collation)
    @test collation.state == is_collated
    @show(collation)
    
end

@testset "ranking" begin
    xml = """
    <text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>
    """

    vwg = to_graph(xml)
    r = ranking(vwg)
    @show(r)
    for v in keys(r.by_vertex)
        str = get_prop(vwg,v,:text)
        println("$str : $(r.by_vertex[v])")
    end
    for rank in sort(collect(keys(r.by_rank)))
        println("$rank : $(r.by_rank[rank])")
    end
end
