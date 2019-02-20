#=
runtests:
- Julia version: 
- Author: bramb
- Date: 2019-02-20
=#
using Test

@testset "all tests" begin
    include("test_hypercollate.jl")
end