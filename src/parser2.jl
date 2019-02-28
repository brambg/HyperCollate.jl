#=
parser2:
- Julia version: 
- Author: bramb
- Date: 2019-02-28
=#
using Query
using LibExpat
using DataStructures

@enum(TextState,TEXT,TAIL)

mutable struct Element
    name::String
    attributes::Dict{String,String}
    parent::Element

    function Element(name::String)
        new(name,Dict{String,String}())
    end
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

    function Context()
        last_element_is_open = false
        triples = []
        text = IOBuffer()
        tail = IOBuffer()
        text_state = TEXT;
        open_elements = []
        new(last_element_is_open,triples,text,tail,text_state,open_elements)
    end
end

function get_triples(xml::String)
    ctx = Context()

    cbs = XPCallbacks()
    cbs.start_element = function(h, name, attrs)
#         println("<$name>")
        triple = Triple()
        triple.element = Element(name)
        push!(h.data.triples,triple)
        h.data.last_element_is_open = true
        h.data.text_state = TEXT
        if (!isempty(h.data.open_elements))
            parent = h.data.open_elements[1]
            triple.element.parent = parent
        end
        pushfirst!(h.data.open_elements,triple.element)
    end
    cbs.end_element = function(h, name)
#         println("</$name>")
        h.data.text_state = TAIL
        popfirst!(h.data.open_elements)
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

parent(x) = isdefined(x.element, :parent) ? x.element.parent : "XML"

function group_triples(triples)
    return triples |> @groupby(parent(_)) |> collect
end

function serialize_text(t::Triple)
    return String(take!(t.text))
end

function serialize_tail(t::Triple)
    return String(take!(t.tail))
end

function serialize_group(g)
    buf = IOBuffer()
    if (length(g) > 1)
        print(buf,"<|")
        for t in g
            print(buf,serialize_text(t),"|")
        end
        print(buf,">",serialize_tail(g[end]))
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