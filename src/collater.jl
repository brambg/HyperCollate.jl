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
    set_props!(wvg,Dict(:sigil => sigil))
    collation.variantwitness_graphs[sigil] = wvg
    collation.state = length(collation.variantwitness_graphs) < 2 ? needs_witness : ready_to_collate
end

function collate!(collation::Collation)
    sigils = sort(collect(keys(collation.variantwitness_graphs)))
    witnesses = [collation.variantwitness_graphs[s] for s in sigils]
    rankings = [ranking(wg) for wg in witnesses]

    matches = potential_matches(witnesses,rankings)
    collation_graph = CollationGraph()
    collated_vertex_map = Dict{Int,Int}()
    first = popfirst!(witnesses)
    initialize(collation_graph,collated_vertex_map,first)
    matches_sorted_by_rank_per_witness = sort_and_filter_matches_by_witness(matches, sigils)
    for wg in witnesses
        sorted_matches = matches_sorted_by_rank_per_witness[wg]
        collate(collation_graph,wg,sorted_matches,markup_node_index,collated_vertex_map)
    end
    collation.state = is_collated
    collation.graph = collation_graph
end

function potential_matches(witnesses, rankings)

end

mutable struct CollationGraph
    sigils::Vector{String}
    CollationGraph() = new([])
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
        ranking.by_vertex[v] = rank;
        if (!haskey(ranking.by_rank,rank))
            ranking.by_rank[rank] = Set()
        end
        push!(ranking.by_rank[rank],v);
    end
    return ranking
end

function initialize(collation_graph, collated_vertex_map, witnessgraph)
    sigil = get_sigil(witnessgraph)
    push!(collation_graph.sigils,sigil)
#     addMarkupNodes(collationGraph, markupNodeIndex, witnessGraph);
    collated_vertex_map[1] = 1
#     collatedTokenVertexMap.put(witnessGraph.getStartTokenVertex(), collationGraph.getTextStartNode());
    for v in [x for x in vertices(witnessgraph) if get_prop(witnessgraph,x,:type) == TEXTNODE]
        add_collation_node!(collation_graph,collated_vertex_map,v,witnessgraph)
    end
#     collated_vertex_map[witnessgraph]
#     collatedTokenVertexMap.put(witnessGraph.getEndTokenVertex(), collationGraph.getTextEndNode());
#     addEdges(collationGraph, collatedTokenVertexMap);
end

function get_sigil(mg::MetaGraph)
    get_prop(mg,:sigil)
end

function sort_and_filter_matches_by_witness(matches, sigils)
#       Map<String, List<Match>> sortAndFilterMatchesByWitness(Set<Match> matches, List<String> sigils) {
#     Map<String, List<Match>> map = new HashMap<>();
#     sigils.forEach(s -> {
#       List<Match> sortedMatchesForWitness = filterAndSortMatchesForWitness(matches, s);
#       map.put(s, sortedMatchesForWitness);
#     });
#     return map;
#   }
end

function add_collation_node!(collation_graph,collated_vertex_map,v,witnessgraph)
    if (!haskey(collated_vertex_map,v))
#     if (!collatedTokenVertexMap.containsKey(tokenVertex)) {
#       TextNode collationNode = collationGraph.addTextNodeWithTokens(tokenVertex.getToken());
#       collationNode.addBranchPath(tokenVertex.getSigil(), tokenVertex.getBranchPath());
#       collatedTokenVertexMap.put(tokenVertex, collationNode);
#       addMarkupHyperEdges(collationGraph, witnessGraph, markupNodeIndex, tokenVertex, collationNode);
#     }
    end
end