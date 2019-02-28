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
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "<|Dit kwam van een|De|> te streng doorgedreven rationalisatie"
    @show(serialized)
    println()

    xml = "<xml>The rain in <subst><del>Cataluña</del><add>Spain</add></subst> falls mainly on the plain.</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "The rain in <|Cataluña|Spain|> falls mainly on the plain."
    @show(serialized)
    println()

    xml = "<xml>The rain in Spain falls mainly on the <subst><del>street</del><add>plain</add></subst>.</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "The rain in Spain falls mainly on the <|street|plain|>."
    @show(serialized)
    println()

    xml = "<xml>The rain in Spain falls mainly on the <app><rdg>street</rdg><rdg>plain</rdg></app>.</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "The rain in Spain falls mainly on the <|street|plain|>."
    @show(serialized)
    println()

    xml = "<xml>De <a>kat</a> krabt <b>de krullen</b> van de trap</xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "De kat krabt de krullen van de trap"
    @show(serialized)
    println()

    xml = "<xml>To be, or <subst><del>whatever</del><add>not to <subst><del>butterfly</del><add>be</add></subst></add></subst></xml>"
    @show(xml)
    serialized = get_triples(xml) |> group_triples |> serialize_grouped_triples
    @test serialized == "To be, or <|whatever|not to <|butterfly|be|>|>"
    @show(serialized)
    println()

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
