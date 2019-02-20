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
        xp_parse,
        create_an_array_of_the_xml_nodes,
        convert_to_xml_blocks,
        transform_block_into_text_nodes_named_tuple

    include("xmlparser.jl")

end