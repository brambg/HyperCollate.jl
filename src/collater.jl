#=
collater:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-15
=#

using MetaGraphs,Combinatorics,LightGraphs

@enum(CollationState,
     needs_witness, ready_to_collate, is_collated
)

# import Base.isequal, Base.hash

mutable struct CollationGraph
    sigils::Vector{String}
    graph::MetaDiGraph
    startvertex::Integer
    endvertex::Integer

    function CollationGraph()
        cg = new([], MetaDiGraph(SimpleDiGraph()),1,2)
        add_vertex!(cg.graph,:begin,1) # startvertex
        cg.startvertex = vertices(cg.graph)[1]
        add_vertex!(cg.graph,:end,1) # endvertex
        cg.endvertex = vertices(cg.graph)[2]
        return cg
     end
end

# inneighbors(cg::CollationGraph, vertex) = inneigbors(cg.graph,vertex)
# outneighbors(cg::CollationGraph, vertex) = outneigbors(cg.graph,vertex)

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
    vertices_buf = IOBuffer()
    for n in 1:nv(mg)
        type = get_prop(mg,n,:type)
        if (type == TEXTNODE)
            text = get_prop(mg,n,:text)
            vertex_def = """v$n[shape=box;label="$text"]"""
        else
            vertex_def = """v$n[shape=circle;width=0.05;label=""]"""
        end
        println(vertices_buf,vertex_def)
    end
    vertices = String(take!(vertices_buf))

    edges_buf = IOBuffer()
    for e in edges(mg)
        edge_def = """v$(e.src) -> v$(e.dst)"""
        println(edges_buf,edge_def)
    end
    edgesstring = String(take!(edges_buf))

    dot = """
    $vertices
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
get_sigils(m::Match) = collect(keys(m.witness_vertex_map))

lowest_rank_for_witnesses_other_than(m::Match, s::String) = minimum([p[2] for p in m.ranking_map if p[1] != s])

mutable struct CollatedMatch
    collated_vertex::Integer
    collated_vertex_rank::Integer
    witness_vertex::Integer
    witness_vertex_rank::Integer
    sigils::Set{String}
    branch_paths::Dict{String,Vector{Integer}}

    function CollatedMatch(collated_vertex, witness_vertex, witness_vertex_rank)
        _sigils = Set{String}()
        _branch_paths = Dict{String,Vector{Integer}}()
        return new(collated_vertex,-1,witness_vertex,witness_vertex_rank,_sigils,_branch_paths)
    end
end

mutable struct Ranking
    by_vertex::Dict{Integer,Integer}
    by_rank::Dict{Integer,Set{Integer}}

    Ranking() = new(Dict{Integer,Integer}(),Dict{Integer,Set{Integer}}())
end

apply(ranking::Ranking, vertex::Integer) = ranking.by_vertex[vertex]

mutable struct CollationGraphRanking
    by_vertex::Dict{Integer,Integer}
    by_rank::Dict{Integer,Set{Integer}}

    function CollationGraphRanking(cg::CollationGraph)
        by_vertex = Dict{Integer,Integer}()
        by_rank = Dict{Integer,Set{Integer}}()
        vertices_to_rank = []
        push!(vertices_to_rank, cg.startvertex)
        while !isempty(vertices_to_rank)
            vertex = popfirst!(vertices_to_rank)
            can_rank = true
            rank = -1
            for n in inneighbors(cg.graph,vertex)
                if haskey(by_vertex,n)
                    incoming_rank = by_vertex[n]
                    rank = max(rank, incoming_rank)
                else
                    can_rank = false
                end
            end
            for n in outneighbors(cg.graph,vertex)
                push!(vertices_to_rank,n)
            end
            if can_rank
                rank = rank + 1
                by_vertex[vertex] = rank
                if !haskey(by_rank,rank)
                    by_rank[rank] = Set()
                end
                push!(by_rank[rank],vertex)
            end
        end
        return new(by_vertex,by_rank)
    end
end

apply(ranking::CollationGraphRanking, vertex::Integer) = ranking.by_vertex[vertex]

function collate!(collation::Collation)
    sigils = sort(collect(keys(collation.variantwitness_graphs)))
    witnesses = [collation.variantwitness_graphs[s] for s in sigils]
    rankings = [ranking(wg) for wg in witnesses]

    matches = potential_matches(witnesses,rankings)
#     @debug for m in matches
#         @show(m)
#     end
    collated_vertex_map = Dict{Integer,Integer}()
    first = popfirst!(witnesses)
    initialize(collation.graph,collated_vertex_map,first)
    matches_sorted_by_rank_per_witness = sort_and_filter_matches_by_witness(matches, sigils)
    print_matches_sorted_by_rank_per_witness(matches_sorted_by_rank_per_witness,collation)
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
        type1 = get_prop(witness1,v1,:type)
        for v2 in traversal2
            text2 = get_prop(witness2,v2,:text)
            type2 = get_prop(witness2,v2,:type)
#             println("$sigil1:$v1:$text1 == $sigil2:$v2:$text2 ?")
            if text1 == text2 && type1 == type2 == TEXTNODE
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
        for inv in inneighbors(variantwitness_graph.graph,v)
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
    for wtn in [x for x in vertices(witnessgraph) if get_prop(witnessgraph,x,:type) == TEXTNODE]
        add_collation_vertex!(collation_graph,collated_vertex_map,wtn,witnessgraph)
    end
    _debug_metagraph(witnessgraph)
    _debug_collationgraph(collation_graph)
    add_edges!(collation_graph, collated_vertex_map, witnessgraph);
    _debug_collationgraph(collation_graph)
end

function first_matching_edge(cg::CollationGraph,f)
    next = iterate(Iterators.filter(f,edges(cg.graph)))
    return next == nothing ? nothing : next[1]
end

function add_edges!(cg::CollationGraph,collated_vertex_map,witnessgraph)
    @show(collated_vertex_map)
    sigil = get_sigil(witnessgraph)
    for tv in keys(collated_vertex_map)
#         @show(tv)
        incoming = incoming_text_vertices(witnessgraph,tv)
        for itv in incoming
#             @show(itv)
            source = collated_vertex_map[itv]
            dest = collated_vertex_map[tv]
            existing_target_vertices = outneighbors(cg.graph,source)
            if (dest in existing_target_vertices)
                isrelevant(e) = e.src==source && e.dst==dest
                edge = first_matching_edge(cg,isrelevant)
                sigils = get_prop(cg.graph,edge,:sigils)
                push!(sigils,sigil)
                set_prop!(cg.graph,edge,:sigils,sigils)
            else
                sigils = Set{String}()
                push!(sigils,sigil)
                add_edge!(cg.graph,source,dest,:sigils,sigils)
            end
        end
    end
    head_text_vertices = get_prop(witnessgraph,1,:type) == TEXTNODE ? [1] : outgoing_text_vertices(witnessgraph,1)
    @show(head_text_vertices)
    for tv in head_text_vertices
        destination = collated_vertex_map[tv]
        isrelevant(e) = e.src==cg.startvertex && e.dst==destination
        edge = first_matching_edge(cg,isrelevant)
        if edge != nothing
            sigils = get_prop(cg.graph,edge,:sigils)
            push!(sigils,sigil)
            set_prop!(cg.graph,edge,:sigils,sigils)
        else
            sigils = Set{String}()
            push!(sigils,sigil)
            add_edge!(cg.graph,cg.startvertex,destination,:sigils,sigils)
        end
    end
    last = nv(witnessgraph)
    tail_text_vertices = get_prop(witnessgraph,last,:type) == TEXTNODE ? [last] : incoming_text_vertices(witnessgraph,nv(witnessgraph))
    @show(tail_text_vertices)
    for tv in tail_text_vertices
        source = collated_vertex_map[tv]
        isrelevant(e) = e.src==source && e.dst==cg.endvertex
        edge = first_matching_edge(cg,isrelevant)
        if edge != nothing
            sigils = get_prop(cg.graph,edge,:sigils)
            push!(sigils,sigil)
            set_prop!(cg.graph,edge,:sigils,sigils)
        else
            sigils = Set{String}()
            push!(sigils,sigil)
            add_edge!(cg.graph,source,cg.endvertex,:sigils,sigils)
        end
    end

end

function incoming_text_vertices(g::MetaDiGraph,v::Int)
    itn = Vector{Int}()
    for n in inneighbors(g,v)
#         @show(get_prop(g,n,:type))
        if get_prop(g,n,:type) == TEXTNODE
            push!(itn,n)
        else
            for m in incoming_text_vertices(g,n)
                push!(itn,m)
            end
        end
    end
    return itn
end

function outgoing_text_vertices(g::MetaDiGraph,v::Int)
    itn = Vector{Int}()
    for n in outneighbors(g,v)
        if get_prop(g,n,:type) == TEXTNODE
            push!(itn,n)
        else
            for m in outgoing_text_vertices(g,n)
                push!(itn,m)
            end
        end
    end
    return itn
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
#     println("matches ($(length(matches)))")
#     display_matches(matches)
    filtered_matches = [m for m in matches if has_witness(m,sigil)]
#     println("filtered matches ($(length(filtered_matches)))")
#     display_matches(filtered_matches)
    return collect(sort(filtered_matches, lt=my_isless))
end

function add_collation_vertex!(collation_graph::CollationGraph,collated_vertex_map,v::Int,witnessgraph)
    if !haskey(collated_vertex_map,v)
        text = get_prop(witnessgraph,v,:text)
        collation_vertex = add_text_vertex!(collation_graph,text)
#       collationNode.addBranchPath(tokenVertex.getSigil(), tokenVertex.getBranchPath());
        collated_vertex_map[v] = collation_vertex
#       addMarkupHyperEdges(collationGraph, witnessGraph, markupNodeIndex, tokenVertex, collationNode);
    end
end

function add_text_vertex!(cg::CollationGraph,text::String)
    add_vertex!(cg.graph)
    v = nv(cg.graph)
    set_props!(cg.graph,v,Dict(:text => text))
    return v
end

function collate(collation_graph::CollationGraph,witness,sorted_matches,collated_vertex_map)
    base_ranking = CollationGraphRanking(collation_graph)
    p(m::Match) = !isempty(get_sigils(m))
    filtered_matches = filter(p ,sorted_matches)
    witnesssigil = get_sigil(witness)
    push!(collation_graph.sigils,witnesssigil)
    collated_matches = get_collated_matches(collated_vertex_map,filtered_matches,witnesssigil)
    rank_adjusted = [adjust_rank(m, base_ranking) for m in collated_matches]
    match_list = unique(rank_adjusted)
    optimal_match_list = get_optimal_match_list(match_list)
end

function adjust_rank(m::CollatedMatch, base_ranking::CollationGraphRanking)
    vertex = m.collated_vertex
    m.collated_vertex_rank = apply(base_ranking,vertex)
    return m
end

function get_collated_matches(collated_vertex_map,filtered_matches,witnesssigil)
    return [collated_match(match, witnesssigil, collated_vertex_map) for match in filtered_matches]
end

function collated_match(match, witnesssigil, collated_vertex_map)
    _sigils = get_sigils(match)
    other_sigil = _sigils[findfirst(x->x!=witnesssigil, _sigils)]
    vertex = match.witness_vertex_map[other_sigil]
    vertex2 = match.witness_vertex_map[witnesssigil]
    @show(collated_vertex_map)
    vertex = collated_vertex_map[vertex]
    vertex_rank = match.ranking_map[witnesssigil]
    return CollatedMatch(vertex,vertex2,vertex_rank)
end

function display_matches(matches,collation)
    ms = []
    for m in matches
        sigils=sort(collect(keys(m.witness_vertex_map)))
        w = []
        for s in sigils
            vertex = m.witness_vertex_map[s]
            text = get_prop(collation.variantwitness_graphs[s],vertex,:text)
            text = replace(text, r"\s+" => " ")
            rank = m.ranking_map[s]
            push!(w,"$s:$rank:$vertex:'$text'")
        end
        match_string = join(sort(w),",\t")
        push!(ms,match_string)
    end
#     println(join(sort(ms),"\n"))
    println(join(ms,"\n"))
end

function print_matches_sorted_by_rank_per_witness(matches_sorted_by_rank_per_witness,collation)
    sigils=sort(collect(keys(matches_sorted_by_rank_per_witness)))
    for s in sigils
        println(s)
        display_matches(matches_sorted_by_rank_per_witness[s],collation)
    end
end

function _debug_collationgraph(cg::CollationGraph)
    println("CollationGraph")
    _debug_metagraph(cg.graph)
end

function _debug_metagraph(mg::MetaDiGraph)
    for v in vertices(mg)
        println("$v ",props(mg,v))
    end
    for e in edges(mg)
        println("$e ", props(mg,e))
    end
    println()
end