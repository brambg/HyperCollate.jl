"""
# module HyperCollate

- Julia version: 
- Author: bramb
- Date: 2019-02-20

# Examples

```jldoctest
julia>using HyperCollate
```
"""
module HyperCollate

    export
        tokenize,
        to_graph,
        to_dot,
        string_value,
        Collation,add_witness!,collate!,needs_witness,ready_to_collate,is_collated,
        ranking,
        add_subst
#         xp_parse,
#         create_an_array_of_the_xml_nodes,
#         convert_to_xml_blocks,
#         transform_block_into_text_nodes_named_tuple,
#         get_triples,group_triples,serialize_grouped_triples,to_graph

#     include("xmlparser.jl")
    include("parser3.jl")
    include("xml_preprocessor.jl")
    include("collater.jl")
    include("display.jl")

end