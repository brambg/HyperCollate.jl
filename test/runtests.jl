#=
runtests:
- Julia version: 
- Author: bramb
- Date: 2019-02-20
=#
using Test

@testset "all tests" begin
    include("test_hypercollate.jl")
    include("test_collater.jl")
    include("test_xmlparser.jl")
    include("test_parser2.jl")
end