#=
parser2:
- Julia version:
- Author: bramb
- Date: 2019-02-28
=#
using Query,LibExpat,DataStructures,LightGraphs,MetaGraphs

@enum(TextState,TEXT,TAIL)

mutable struct Element
    name::String
    attributes::Dict{String,String}
    in_text_divergence::Bool
    parent::Element

    Element(name::String) = new(name,Dict{String,String}(),false)
end

mutable struct Triple
    element::Element
    text
    tail

    function Triple()
        element = Element("")
        text = IOBuffer()
        tail = IOBuffer();
        new(element,text,tail)
    end
end

mutable struct Context
    last_element_is_open::Bool
    triples::Array{Triple}
    text
    tail
    text_state::TextState
    open_elements::Array{Element}
    open_divergence_elements::Array{Element}

    function Context()
        last_element_is_open = false
        triples = []
        text = IOBuffer()
        tail = IOBuffer()
        text_state = TEXT;
        open_elements = []
        open_divergence_elements = []
        new(last_element_is_open,triples,text,tail,text_state,open_elements,open_divergence_elements)
    end
end

is_divergence_element(name::String) = name in ["subst", "choice", "app"]

function get_triples(xml::String)
    ctx = Context()

    cbs = XPCallbacks()
    cbs.start_element = function(h, name, attrs)
#         println("<$name>")
        triple = Triple()
        triple.element = Element(name)
        triple.element.in_text_divergence = !isempty(h.data.open_divergence_elements)
        push!(h.data.triples,triple)
        h.data.last_element_is_open = true
        h.data.text_state = TEXT
        if (!isempty(h.data.open_elements))
            parent = h.data.open_elements[1]
            triple.element.parent = parent
        end
        pushfirst!(h.data.open_elements,triple.element)
        if (is_divergence_element(triple.element.name))
            pushfirst!(h.data.open_divergence_elements,triple.element)
        end
    end
    cbs.end_element = function(h, name)
#         println("</$name>")
        h.data.text_state = TAIL
        popfirst!(h.data.open_elements)
        if (is_divergence_element(name))
            popfirst!(h.data.open_divergence_elements)
        end
    end
    cbs.character_data = function(h, txt)
#         println("\"$txt\"")
        # now we add to either text or tail, depending on text_state
        if (h.data.text_state == TEXT)
            print(h.data.triples[end].text,txt)
        else
            print(h.data.triples[end].tail,txt)
        end
    end

    parse(xml,cbs,data = ctx)
    return ctx.triples
end

parent(x::Triple) = isdefined(x.element, :parent) ? x.element.parent : "XML"

group_triples(triples) = triples |> @groupby(parent(_)) |> collect

serialize_text(t::Triple) = String(take!(t.text))

serialize_tail(t::Triple) = String(take!(t.tail))

function serialize_group(g)
    buf = IOBuffer()
    if (length(g) > 1)
        if (g[1].element.in_text_divergence)
            print(buf,"<|")
            for t in g
                print(buf,serialize_text(t),"|")
            end
            print(buf,">",serialize_tail(g[end]))
        else
            for t in g
                print(buf,serialize_text(t),serialize_tail(t))
            end
        end
    else
        print(buf,serialize_text(g[1]),serialize_tail(g[1]))
    end
    return String(take!(buf))
end

function serialize_grouped_triples(grouped_triples)
    serbuf = IOBuffer()
    for group in grouped_triples
        print(serbuf,serialize_group(group))
    end
    return String(take!(serbuf))
end

@enum(VertexType,TEXTNODE,DIVERGENCE,CONVERGENCE)

function to_graph(grouped_triples)
    mg = MetaGraph(SimpleGraph())
    for group in grouped_triples
        for triple in group
            text = serialize_text(triple)
            @show(text)
            if (!isempty(text))
                add_vertices!(mg.graph,1)
                v = nv(mg.graph)
                set_props!(mg,v,Dict(:type => TEXTNODE,:text => text))
                v>1 && add_edge!(mg.graph, v-1, v)
            end
            tail = serialize_tail(triple)
            @show(tail)
            if (!isempty(tail))
                add_vertices!(mg.graph,1)
                v = nv(mg.graph)
                set_props!(mg,v,Dict(:type => TEXTNODE,:text => tail))
                v>1 && add_edge!(mg.graph, v-1, v)
            end
        end
    end
    return mg
end
