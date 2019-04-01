#=
collater:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-15
=#

using MetaGraphs,Combinatorics

@enum(CollationState,
     needs_witness, ready_to_collate, is_collated
)

# import Base.isequal, Base.hash

mutable struct CollationGraph
    sigils::Vector{String}
    graph::MetaDiGraph

    CollationGraph() = new([], MetaDiGraph(SimpleDiGraph()))
end

function rank(cg::CollationGraph)
    ranking = Ranking()
    nodes_to_rank = []
    return ranking
end

function to_dot(cg::CollationGraph)
    digraph = _collationgraph_as_dot(cg)
    dot = """
    digraph CollationGraph {
        rankdir=LR
        labelloc=b
        color=white
        edge [arrowsize=0.5]
        $digraph
    }
    """
    return dot
end

function _collationgraph_as_dot(cg::CollationGraph)
    mg = cg.graph
    nodes_buf = IOBuffer()
    for n in 1:nv(mg)
        type = get_prop(mg,n,:type)
        if (type == TEXTNODE)
            text = get_prop(mg,n,:text)
            node_def = """v$n[shape=box;label="$text"]"""
        else
            node_def = """v$n[shape=circle;width=0.05;label=""]"""
        end
        println(nodes_buf,node_def)
    end
    nodes = String(take!(nodes_buf))

    edges_buf = IOBuffer()
    for e in edges(mg)
        edge_def = """v$(e.src) -> v$(e.dst)"""
        println(edges_buf,edge_def)
    end
    edgesstring = String(take!(edges_buf))

    dot = """
    $nodes
    $edgesstring
    """
    return dot
end

function to_html(cg::CollationGraph)
    stringbuf = IOBuffer()
    for s in reverse(cg.sigils)
        columns = "<td>some text</td>"
        row = """
        <tr><th>$s</th>$columns</tr>
        """
        println(stringbuf,row)
    end
    tablerows = String(take!(stringbuf))
    html =
    """
    <table>
    $tablerows
    </table>
    """
    return html
end

mutable struct Collation
    variantwitness_graphs::Dict{String,MetaDiGraph}
    state::CollationState
    graph::CollationGraph

    Collation() = new(Dict{String,MetaDiGraph}(),needs_witness,CollationGraph())
end

function add_witness!(collation::Collation, sigil::String, xml::String)
    wvg = to_graph(xml)
    set_props!(wvg,Dict(:sigil => sigil))
    collation.variantwitness_graphs[sigil] = wvg
    collation.state = length(collation.variantwitness_graphs) < 2 ? needs_witness : ready_to_collate
end

mutable struct Match
    witness_vertex_map::Dict{String,Integer}
    ranking_map::Dict{String,Integer}

    function Match(s1::String, v1::Integer, s2::String, v2::Integer)
        m = new(Dict{String,Integer}(),Dict{String,Integer}())
        m.witness_vertex_map[s1] = v1
        m.witness_vertex_map[s2] = v2
        return m
    end
end

set_rank!(match::Match, sigil::String, rank::Integer) = match.ranking_map[sigil] = rank

has_witness(m::Match, sigil::String) = haskey(m.witness_vertex_map,sigil)

# sigils(m::Match) = keys(m.witness_vertex_map)
function sigils(m::Match)
    return collect(keys(m.witness_vertex_map))
end

lowest_rank_for_witnesses_other_than(m::Match, s::String) = minimum([p[2] for p in m.ranking_map if p[1] != s])


mutable struct Ranking
    by_vertex::Dict{Integer,Integer}
    by_rank::Dict{Integer,Set{Integer}}

    Ranking() = new(Dict{Integer,Integer}(),Dict{Integer,Set{Integer}}())
end

apply(ranking::Ranking, vertex::Integer) = ranking.by_vertex[vertex]

function collate!(collation::Collation)
    sigils = sort(collect(keys(collation.variantwitness_graphs)))
    witnesses = [collation.variantwitness_graphs[s] for s in sigils]
    rankings = [ranking(wg) for wg in witnesses]

    matches = potential_matches(witnesses,rankings)
    @debug for m in matches
        @show(m)
    end
    collated_vertex_map = Dict{Integer,Integer}()
    first = popfirst!(witnesses)
    initialize(collation.graph,collated_vertex_map,first)
    matches_sorted_by_rank_per_witness = sort_and_filter_matches_by_witness(matches, sigils)
    @debug(matches_sorted_by_rank_per_witness)
    for s in sigils
        sorted_matches = matches_sorted_by_rank_per_witness[s]
        witness = collation.variantwitness_graphs[s]
        collate(collation.graph,witness,sorted_matches,collated_vertex_map)
    end
    collation.state = is_collated
    return collation
end

function potential_matches(witnesses, rankings)
    all_potential_matches = Set{Match}()
    vertex_to_match = Dict{Integer,Match}()

    for tuple in [t for t in permutations(1:length(witnesses), 2) if t[1] < t[2]]
        witness1 = witnesses[tuple[1]]
        ranking1 = rankings[tuple[1]]
        witness2 = witnesses[tuple[2]]
        ranking2 = rankings[tuple[2]]
        match!(all_potential_matches, vertex_to_match,witness1,witness2,ranking1,ranking2)
#         end_match = get_end_match(witness1,ranking1,witness2,ranking2)
#         push!(all_potential_matches, end_match)
    end
    return all_potential_matches
end

function match!(all_potential_matches, vertex_to_match, witness1, witness2, ranking1, ranking2)
    traversal1 = traversal(witness1)
    traversal2 = traversal(witness2)
    sigil1 = get_sigil(witness1)
    sigil2 = get_sigil(witness2)
    for v1 in traversal1
        text1 = get_prop(witness1,v1,:text)
        for v2 in traversal2
            text2 = get_prop(witness2,v2,:text)
#             println("$sigil1:$v1:$text1 == $sigil2:$v2:$text2 ?")
            if text1 == text2
                match = Match(sigil1, v1, sigil2, v2)
                set_rank!(match, sigil1, apply(ranking1,v1))
                set_rank!(match, sigil2, apply(ranking2,v2))
                push!(all_potential_matches, match)
                vertex_to_match[v1] = match
                vertex_to_match[v2] = match
            end
        end
    end
end

traversal(witness) = topological_sort_by_dfs(witness)

# function get_end_match(witness1, ranking1, witness2, ranking2)
#     endvertex1 = nv(witness1)
#     endvertex2 = nv(witness2)
#     endmatch = Match(endvertex1,endvertex2)
# end

function ranking(variantwitness_graph::MetaDiGraph)
    ranking = Ranking()
    for v in vertices(variantwitness_graph)
        rank = -1
        for inv in inneighbors(variantwitness_graph,v)
            if !haskey(ranking.by_vertex,inv)
                ranking.by_vertex[inv] = -1
            end
            rank = max(rank,ranking.by_vertex[inv])
        end
        rank += 1
        ranking.by_vertex[v] = rank;
        if !haskey(ranking.by_rank,rank)
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

function get_sigil(mg::MetaDiGraph)
    get_prop(mg,:sigil)
end

function sort_and_filter_matches_by_witness(matches, sigils)
    return Dict{String,Vector{Match}}(s => filter_and_sort_matches_for_witness(matches,s) for s in sigils)
end

function filter_and_sort_matches_for_witness(matches,sigil)
    function my_isless(match1::Match,match2::Match)
        rank1 = match1.ranking_map[sigil]
        rank2 = match2.ranking_map[sigil]
        if rank1 == rank2
            rank1 = lowest_rank_for_witnesses_other_than(match1,sigil)
            rank2 = lowest_rank_for_witnesses_other_than(match2,sigil)
        end
        return rank1 < rank2
    end
    @debug(matches)
    filtered_matches = [m for m in matches if has_witness(m,sigil)]
    @debug(filtered_matches)
    return collect(sort(filtered_matches, lt=my_isless))
end

function add_collation_node!(collation_graph,collated_vertex_map,v,witnessgraph)
    if !haskey(collated_vertex_map,v)


#       TextNode collationNode = collationGraph.addTextNodeWithTokens(tokenVertex.getToken());
#       collationNode.addBranchPath(tokenVertex.getSigil(), tokenVertex.getBranchPath());
#         collated_vertex_map[v] = collationnode
#       collatedTokenVertexMap.put(tokenVertex, collationNode);
#       addMarkupHyperEdges(collationGraph, witnessGraph, markupNodeIndex, tokenVertex, collationNode);
    end
end

function collate(collation_graph::CollationGraph,witness,sorted_matches,collated_vertex_map)
    base_ranking = rank(collation_graph)

#     sigils = collation_graph.sigils
#     filtered_matches = filter(m -> !isempty(intersect(sigils(m),sigils)),sorted_matches)
    p(m::Match) = !isempty(sigils(m))
    filtered_matches = filter(p ,sorted_matches)
    witnesssigil = get_sigil(witness)
end
