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

    @show(xml)

    triples = get_triples(xml)
    g = group_triples(triples)
    print_text(g)

#     for t in triples
#         parent = isdefined(t.element, :parent) ? t.element.parent.name : ""
#         ename = t.element.name
#         text = String(take!(t.text))
#         tail = String(take!(t.tail))
#         println("<$ename^$parent>$text</$ename>$tail")
#     end



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
