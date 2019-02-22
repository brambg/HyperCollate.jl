#=
test_hypercollate:
- Julia version: 
- Author: bramb
- Date: 2019-02-20
=#
using Test

@testset "hypercollate" begin
    using HyperCollate

    xml = "<text><s><subst><del>Dit kwam van een</del><add>De</add></subst> te streng doorgedreven rationalisatie</s></text>"

    struct Triple
        element = ""
        text = IOBuffer
        tail = IOBuffer
    end

    mutable struct Context
        last_element_is_open = false
        triples = []
        text = IOBuffer
        tail = IOBuffer
    end
    ctx = Context()

    cbs = XPCallbacks()
    cbs.start_element = function(h,name,attrs)
        triple = Triple()
        triple.element = name
        push!(h.data.triples,triple)
        h.data.last_element_is_open = true
    end
    cbs.end_element = function(h,name)
        println(h)
        println(name)
    end
    cbs.character_data = function(h,txt)
        println(h)
        println(txt)
    end
    parse(xml,cbs,data=ctx)

    root  = xp_parse(xml)
    push!(elements_to_handle,root)
    while (!isempty(elements_to_handle) && typeof(elements_to_handle[1]) == String)
        print(string_buf,pop!(descendants))
    end
    while (!isempty(elements_to_handle))
        element_or_string = pop!(elements_to_handle)
        a = "<$(element.name)>"
        descendants = element.elements
        string_buf = IOBuffer()
        while (!isempty(descendants) && typeof(descendants[1]) == String)
            print(string_buf,pop!(descendants))
        end
        if (!isempty(descendants))
            pushfirst!(elements_to_handle,descendants)
        end
        inner_string = takebuf_string(string_buf)
        push!(tuples,(a,inner_string))
    end
    println(tuples)

end
