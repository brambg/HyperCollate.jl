#=
collater:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-15
=#

using MetaGraphs

@enum(CollationState,
     needs_witness, ready_to_collate, is_collated
)
mutable struct Collation
    variantwitness_graphs::Dict{String,MetaGraph}
    state::CollationState
    Collation() = new(Dict{String,MetaGraph}(),needs_witness)
end

function add_witness!(collation::Collation, sigil::String, xml::String)
    wvg = to_graph(xml)
    collation.variantwitness_graphs[sigil] = wvg
    collation.state = length(collation.variantwitness_graphs) < 2 ? needs_witness : ready_to_collate
end

function collate!(collation::Collation)
    rankings = []

    collation.state = is_collated
end

mutable struct Ranking
    by_vertex::Dict{Int,Int}
    by_rank::Dict{Int,Set{Int}}

    Ranking() = new(Dict{Int,Int}(),Dict{Int,Set{Int}}())
end

function ranking(variantwitness_graph::MetaGraph)
    ranking = Ranking()
    for v in vertices(variantwitness_graph)
        rank = -1
        for inv in inneighbors(variantwitness_graph,v)
            if (!haskey(ranking.by_vertex,inv))
                ranking.by_vertex[inv] = -1
            end
            rank = max(rank,ranking.by_vertex[inv])
        end
        rank += 1
        ranking.by_vertex[v]=rank;
        if (!haskey(ranking.by_rank,rank))
            ranking.by_rank[rank] = Set()
        end
        push!(ranking.by_rank[rank],v);
    end
    return ranking
end