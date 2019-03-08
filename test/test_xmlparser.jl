#=
test_xmlparser:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-02-20
=#
using Test

@testset "xmlparser" begin
    include("../src/xmlparser.jl")

    xml = "<xml>Mondays are <del>well good</del><add>def bad</add>!</xml>"
    root = xp_parse(xml)
    # dump(root)

    all_nodes = create_an_array_of_the_xml_nodes(root)
    blocks = convert_to_xml_blocks(all_nodes)
    println(blocks)

    # We mappen de XML blocks naar een combo van tag en nul of meer text nodes.

    tuples_of_tag_and_text_nodes::Array{NamedTuple} = []
    for block in blocks
        named_tuple = transform_block_into_text_nodes_named_tuple(block)
        push!(tuples_of_tag_and_text_nodes, named_tuple)
    end

    println(tuples_of_tag_and_text_nodes)

#     textNodes = create_nodes_for_each_xml_block(blocks)
#     println(textNodes)


    # de partities doen we later wel.
    #partitions = partition_block_into_groups(blocks)
    #println(partitions)
end
