#=
xml_preprocessor:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-21
=#

isopendel(t::XMLToken) = isa(t,XMLStartElement) && t.name == "del"
isclosedel(t::XMLToken) = isa(t,XMLEndElement) && t.name == "del"
isopenadd(t::XMLToken) = isa(t,XMLStartElement) && t.name == "add"
iscloseadd(t::XMLToken) = isa(t,XMLEndElement) && t.name == "add"
ends_subst(t::XMLToken) = isa(t,TextToken) ? !isempty(strip(t.text)) : (t.name != "del" && t.name != "add")

@enum SubstState begin
    _normal
    _tentative_subst
    _subst
    _after_del
    _after_add
end

mutable struct SubstContext
    buf::IOBuffer
    state::SubstState
    subst::Bool

    SubstContext() = new(IOBuffer(),_normal,false)
end

function add_subst(xml::String)::String
    contexts = []
    push!(contexts,SubstContext())
    for t in tokenize(xml)
        @debug("$(contexts[1].state) | $(string_value(t))")
        if isopendel(t) && contexts[1].state != _after_del
            @debug(1," push!")
            pushfirst!(contexts,SubstContext())
            (contexts[1].state != _subst) && (contexts[1].state = _tentative_subst)
            print(contexts[1].buf,string_value(t))

        elseif isclosedel(t)
            @debug(2)
            print(contexts[1].buf,string_value(t))
            contexts[1].state = _after_del

        elseif contexts[1].state == _after_del
            if ends_subst(t)
                @debug(3.1)
                outbuf = contexts[2].buf
                if contexts[1].subst
                    print(outbuf, "<subst>", String(take!(contexts[1].buf)), "</subst>")
                else
                    print(outbuf, String(take!(contexts[1].buf)))
                end
                print(outbuf, string_value(t))
#                 contexts[1].state = _normal
#                 contexts[1].subst = false
                deleteat!(contexts,1)
                @debug("pop!")
            else
                @debug(3.2)
                print(contexts[1].buf,string_value(t))
                contexts[1].state = _subst
                contexts[1].subst = true
            end

        elseif contexts[1].state == _subst && iscloseadd(t)
            @debug(4)
            print(contexts[1].buf,string_value(t))
            contexts[1].state = _after_add

        elseif contexts[1].state == _after_add
            if ends_subst(t)
                @debug(5.1)
                while contexts[1].state == _after_add
                    end_subst!(contexts)
                    @debug("pop!")
                end
#                 @show(contexts[1].state)
                print(contexts[1].buf, string_value(t))
            else
                @debug(5.2)
                print(contexts[1].buf,string_value(t))
            end

        else
            if (contexts[1].state == _normal)
                @debug(6.1)
                print(contexts[1].buf, string_value(t))
            else
                @debug(6.2)
                print(contexts[1].buf, string_value(t))
            end
        end
    end
#     @show(length(contexts))
    return strip(String(take!(contexts[1].buf)))
end

function end_subst!(contexts)
    print(contexts[2].buf, "<subst>", String(take!(contexts[1].buf)), "</subst>")
    deleteat!(contexts,1)
end
