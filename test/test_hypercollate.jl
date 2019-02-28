#=
test_hypercollate:
- Julia version: 
- Author: bramb
- Date: 2019-02-20
=#
using Test

@testset "hypercollate" begin
    using HyperCollate
    using LibExpat
    using DataStructures

    @enum(TextState,TEXT,TAIL)

    xml = "<text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>"

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
    ctx = Context()

    cbs = XPCallbacks()
    cbs.start_element = function(h, name, attrs)
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
        h.data.text_state = TAIL
        pop!(h.data.open_elements)
    end
    cbs.character_data = function(h, txt)
        # now we add to either text or tail, depending on text_state
        if (h.data.text_state == TEXT)
            print(h.data.triples[end].text,txt)
        else
            print(h.data.triples[end].tail,txt)
        end
    end
    parse(xml,cbs,data = ctx)
    triples = ctx.triples
    @show(xml)
    for t in triples
        ename = t.element.name
        text = String(take!(t.text))
        tail = String(take!(t.tail))
        println("<$ename>$text</$ename>$tail")
    end

#     root  = xp_parse(xml)
#     push!(elements_to_handle,root)
#     while (!isempty(elements_to_handle) && typeof(elements_to_handle[1]) == String)
#         print(string_buf,pop!(descendants))
#     end
#     while (!isempty(elements_to_handle))
#         element_or_string = pop!(elements_to_handle)
#         a = "<$(element.name)>"
#         descendants = element.elements
#         string_buf = IOBuffer()
#         while (!isempty(descendants) && typeof(descendants[1]) == String)
#             print(string_buf,pop!(descendants))
#         end
#         if (!isempty(descendants))
#             pushfirst!(elements_to_handle,descendants)
#         end
#         inner_string = takebuf_string(string_buf)
#         push!(tuples,(a,inner_string))
#     end
#     println(tuples)

end
