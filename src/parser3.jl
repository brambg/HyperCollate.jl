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

struct TextToken <: XMLToken
    text::String
end

mutable struct GraphBuildContext
    divergencenodes::Array{Int}
    GraphBuildContext() = new([])
end

struct GraphBuilder
  metagraph::MetaGraph
  context::GraphBuildContext

  GraphBuilder() = new(MetaGraph(SimpleGraph()),GraphBuildContext())
end

@enum(VertexType,TEXTNODE,DIVERGENCE,CONVERGENCE)

is_divergence_element(name::String) = name in ["subst", "choice", "app"]

function add_divergence_node!(gb::GraphBuilder)
    add_vertices!(gb.metagraph.graph,1)
    v = nv(gb.metagraph.graph)
    set_props!(gb.metagraph,v,Dict(:type => DIVERGENCE))
    return v
end

function add_convergence_node!(gb::GraphBuilder)
    add_vertices!(gb.metagraph.graph,1)
    v = nv(gb.metagraph.graph)
    set_props!(gb.metagraph,v,Dict(:type => CONVERGENCE))
    return v
end

function grow_graph!(gb::GraphBuilder, startelement::XMLStartElement)
    @show(gb)
    @show(startelement)

    if (is_divergence_element(startelement.name))
        v = add_divergence_node!(gb)
        push!(gb.context.divergencenodes,v)
    end

    println()
    return gb
end

function grow_graph!(gb::GraphBuilder, endelement::XMLEndElement)
    @show(gb)
    @show(endelement)

    if (is_divergence_element(endelement.name))
        v = add_convergence_node!(gb)
        pop!(gb.context.divergencenodes)
    end

    println()
    return gb
end

function grow_graph!(gb::GraphBuilder, texttoken::TextToken)
    @show(gb)
    @show(texttoken)

    add_vertices!(gb.metagraph.graph,1)
    v = nv(gb.metagraph.graph)
    set_props!(gb.metagraph,v,Dict(:type => TEXTNODE,:text => texttoken.text))

    println()
    return gb
end

function tokenize(xml::String)::Array{XMLToken}
    tokens = []
    cbs = XPCallbacks()
    cbs.start_element = function(h, name, attrs)
        push!(h.data, XMLStartElement(name,attrs))
    end
    cbs.end_element = function(h, name)
        push!(h.data, XMLEndElement(name))
    end
    cbs.character_data = function(h, txt)
        push!(h.data, TextToken(txt))
    end
    parse(xml,cbs,data = tokens)
    return tokens
end

to_graph(xml::String) = accumulate(grow_graph!,tokenize(xml); init = GraphBuilder())[1].metagraph

string(t::XMLStartElement) = "<$(t.name)>"

string(t::XMLEndElement) = "</$(t.name)>"

string(t::TextToken) = "$(t.text)"

