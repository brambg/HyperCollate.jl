#=
display:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-12
=#

using MetaGraphs

import Base.display

function Base.display(mime::MIME"image/svg+xml", mg::MetaGraph)
    _display_svg(mg)
end

function Base.display(mime::MIME"image/png", mg::MetaGraph)
    _display_png(mg)
end

function _display_svg(x)
    file = "tmp.dot"
    write(file,to_dot(x))
    display("image/svg+xml", read(`dot -Tsvg $file`,String))
    rm(file)
end

function _display_png(x)
    file = "tmp.dot"
    write(file,to_dot(x))
    display("image/png", read(`dot -Tpng -Gfontname=Sans $file`))
    rm(file)
end

show_svg(mg::MetaGraph) = display("image/svg+xml",mg)

show_png(mg::MetaGraph) = display("image/png",mg)