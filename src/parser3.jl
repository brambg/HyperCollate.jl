#=
parser3:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-05
=#

using LightGraphs,MetaGraphs,LibExpat

abstract type XMLToken end

struct XMLStartElement <: XMLToken
    name::String
    attrs::Dict{String,String}
end

struct XMLEndElement <: XMLToken
    name::String
end

mutable struct TextToken <: XMLToken
    text::String
end

mutable struct GraphBuildContext
    divergencenodes::Vector{Integer}
    open_tags::Vector{String}
    last_unconnected_node::Integer
    branch_ends::Dict{Integer,Vector{Integer}}

    GraphBuildContext() = new([],[],0,Dict{Integer,Vector{Integer}}())
end

struct GraphBuilder
  metagraph::MetaDiGraph
  context::GraphBuildContext

  GraphBuilder() = new(MetaDiGraph(SimpleDiGraph()),GraphBuildContext())
end

@enum(VertexType,TEXTNODE,DIVERGENCE,CONVERGENCE)

is_divergence_element(name::String) = name in ["subst", "choice", "app"]
is_optional_element(name::String) = name in ["del", "add"]

function add_divergence_node!(gb::GraphBuilder)
    add_vertices!(gb.metagraph.graph,1)
    v = nv(gb.metagraph.graph)
    set_props!(gb.metagraph,v,Dict(:type => DIVERGENCE, :text => "<"))
    return v
end

function add_convergence_node!(gb::GraphBuilder)
    add_vertices!(gb.metagraph.graph,1)
    v = nv(gb.metagraph.graph)
    set_props!(gb.metagraph,v,Dict(:type => CONVERGENCE, :text => ">"))
    return v
end

function grow_graph!(gb::GraphBuilder, startelement::XMLStartElement)
#     @show(gb)
#     @show(startelement)
#     @show(startelement.name,is_optional_element(startelement.name),!parent_is_divergence_element(gb))
    if (is_divergence_element(startelement.name)) || (is_optional_element(startelement.name) && !parent_is_divergence_element(gb))
        v = add_divergence_node!(gb)
        push!(gb.context.divergencenodes,v)
        add_edge!(gb.metagraph.graph,gb.context.last_unconnected_node,v)
        gb.context.last_unconnected_node = v
        gb.context.branch_ends[v] = []
    end
    push!(gb.context.open_tags,startelement.name)

#     println()
    return gb
end

parent_is_divergence_element(gb::GraphBuilder) = !isempty(gb.context.open_tags) && is_divergence_element(gb.context.open_tags[end])

function grow_graph!(gb::GraphBuilder, endelement::XMLEndElement)
#     @show(gb)
#     @show(endelement)

    pop!(gb.context.open_tags)
    if (is_divergence_element(endelement.name)) || (is_optional_element(endelement.name) && !parent_is_divergence_element(gb))
        v = add_convergence_node!(gb)
        variation = pop!(gb.context.divergencenodes)
        for n in gb.context.branch_ends[variation]
            add_edge!(gb.metagraph.graph,n,v)
        end
        if is_optional_element(endelement.name)
            add_edge!(gb.metagraph.graph,gb.context.last_unconnected_node,v)
            add_edge!(gb.metagraph.graph,variation,v)
        end
        gb.context.last_unconnected_node = v

    elseif (parent_is_divergence_element(gb))
        variation = gb.context.divergencenodes[end]
        branch_ends = gb.context.branch_ends[variation]
        push!(branch_ends,gb.context.last_unconnected_node)
        gb.context.branch_ends[variation] = branch_ends
        gb.context.last_unconnected_node = variation
    end

#     println()
    return gb
end

function grow_graph!(gb::GraphBuilder, texttoken::TextToken)
#     @show(gb)
#     @show(texttoken)

    add_vertices!(gb.metagraph.graph,1)
    v = nv(gb.metagraph.graph)
    set_props!(gb.metagraph,v,Dict(:type => TEXTNODE,:text => texttoken.text))
    add_edge!(gb.metagraph.graph,gb.context.last_unconnected_node,v)
    gb.context.last_unconnected_node = v

#     println()
    return gb
end

function tokenize(xml::AbstractString)::Vector{XMLToken}
    tokens = []
    cbs = XPCallbacks()
    cbs.start_element = function(h, name, attrs)
        push!(h.data, XMLStartElement(name,attrs))
    end
    cbs.end_element = function(h, name)
        push!(h.data, XMLEndElement(name))
    end
    cbs.character_data = function(h, txt)
        if (isa(h.data[end],TextToken))
            h.data[end].text *= txt
        else
            push!(h.data, TextToken(txt))
        end
    end
    parse(xml,cbs,data = tokens)
    return tokens
end

to_graph(xml::String) = reduce(grow_graph!, tokenize(xml); init = GraphBuilder()).metagraph

function string_value(t::XMLStartElement)
    attribs = isempty(t.attrs) ? "" : " " * join( ["$k=\"$(t.attrs[k])\"" for k in keys(t.attrs)], " ")
    return "<$(t.name)$attribs>"
end

string_value(t::XMLEndElement) = "</$(t.name)>"

string_value(t::TextToken) = "$(t.text)"

function to_dot(mg::MetaDiGraph)
    digraph = _metagraph_as_dot(mg)

    dot = """
    digraph VariantGraph {
        rankdir=LR
        labelloc=b
        color=white
        edge [arrowsize=0.5]
        $digraph
    }
    """
    return dot
end

function _metagraph_as_dot(mg::MetaDiGraph)
    nodes_buf = IOBuffer()
    for n in 1:nv(mg.graph)
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
    for e in edges(mg.graph)
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
