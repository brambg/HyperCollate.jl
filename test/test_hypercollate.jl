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
    tuples = []
    root  = xp_parse(xml)
    element = "<$(root.name)>"
    


end
