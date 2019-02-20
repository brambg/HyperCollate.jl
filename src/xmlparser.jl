#=
xmlparser:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-02-20
=#
# based on https://github.com/rhdekker/hypercollate_julia/blob/master/src/xmlparser.jl

using LibExpat
using DataStructures

# variant graph types and structs
abstract type VariantGraphNode end
struct StartNode <: VariantGraphNode end
struct TextNode <: VariantGraphNode
    content::String
end

# xml types and structs
mutable struct XMLBlock
    tag::String
    content::String
    tail::String
end

# type to group xml_blocks together
# The groups are not really necessary... Since they only contain the array
# they are a bit redundant.
mutable struct Group
    blocks::Array{XMLBlock}
end

# traverse all nodes of the XML tree in depth first fashion
# without recursion
# Initialize the deque with the children of the root
# daarna halen we er steeds 1 op
# Mocht dat een element zijn
# dan zetten we de kinderen daarvan weer op de deck.
# NOTE: maybe a stack is better here?
# for now we create an array with the result
# implementing it as an iterator would be nicer
function create_an_array_of_the_xml_nodes(root)
    result = Union{AbstractString, ETree}[]
    deck = deque(Union{AbstractString, ETree})
    push!(deck, root)

    while !isempty(deck)
        a = pop!(deck)
        push!(result, a)
        if typeof(a) == ETree
            for element in reverse(a.elements)
                push!(deck, element)
            end
        end
    end
    return result
end

function convert_to_xml_blocks(all_nodes)
    xml_blocks::Array{XMLBlock} = []
    for node in all_nodes
        if typeof(node) == ETree
            xml_block = XMLBlock(node.name, "", "")
            push!(xml_blocks, xml_block)
        else
            # node is a String
            xml_block = last(xml_blocks)
            if xml_block.content == ""
                xml_block.content = node
            else
                xml_block.tail = node
            end
        end
    end
    return xml_blocks
end

function is_xml_block_textual_variation_or_not(xml_block)
    # TODO: this should really be a constant
    # TODO: maybe also better to make it a set, depending on the size
    variation_tags = ["del", "add"]
    return xml_block.tag in variation_tags
end

# we hebben een fuctie nodig die bij elk xml block ervoor zorgt
# dat er nodes worden aangemaakt.
# dat is dus per xml block 1 of 2 text nodes
function create_nodes_for_each_xml_block(xml_blocks::Array{XMLBlock})
    nodes::Array{TextNode} = []
    for block in xml_blocks
        !isempty(block.content) && push!(nodes, TextNode(block.content))
        !isempty(block.tail) && push!(nodes, TextNode(block.tail))
    end
    return nodes
end

function transform_block_into_text_nodes_named_tuple(block::XMLBlock)
    isempty(block.content) && return (tag = block.tag)
    isempty(block.tail) && return (tag = block.tag, content = TextNode(block.content))
    return (tag = block.tag, content = TextNode(block.content), tail = TextNode(block.tail))
end

# function transform_block_into_text_nodes(block::XMLBlock)::Array{TextNode}
#     nodes = []
#     !isempty(block.content) && push!(nodes, TextNode(block.content))
#     !isempty(block.tail) && push!(nodes, TextNode(block.tail))
#     return nodes
# end


# NOTE: this should probably be done with a fold
# Basically what happens here is that I turn an array into an array of arrays, also
# known as a tree :-).
# NOTE: There is a group by function in JuliaCollections / IterTools.jl
# but this function only looks at one element at the time
# there must be another function that groups elements into (previous, current) tuples.
# Or is it a take until problem?
function partition_block_into_groups(all_block)
    groups = []
    # we willen over alle nodes lopen steeds per twee, dus we houden een previous bij..
    previous = undef
    for block in all_block
        if previous == undef
            previous = block
            # create a new group for the first block
            group = Group([])
            # and add the block to the group
            push!(group.blocks, block)
            # add the group to the result
            push!(groups, group)
            continue
        end
        # hmm dit doe ik niet goed
        # compare an aspect of the current block with the previous block
        # if the aspect is different, but it in a new block
        # otherwise
        a = is_xml_block_textual_variation_or_not(previous)
        b = is_xml_block_textual_variation_or_not(block)

        # TODO: here we also need to check whether there is trialing text
        # if there is trailing text in a then they can not be placed in the same group
        if (a == b)
            # voeg toe aan de vorige group
            previous_group = last(groups)
            push!(previous_group.blocks, block)
        else
            group = Group([])
            push!(group.blocks, block)
            push!(groups, group)
        end
        previous = block
    end
    return groups
end
