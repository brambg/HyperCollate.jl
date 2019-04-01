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
ends_subst(t::XMLToken) = isa(t,TextToken) ? !isempty(strip(t.text)) : (isa(t,XMLStartElement) && (t.name != "del" && t.name != "add") || isa(t,XMLEndElement))
is_whitespace(t::XMLToken) = isa(t,TextToken) && isempty(strip(t.text))

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
    tail::String

    SubstContext() = new(IOBuffer(),_normal,false,"")
end

function add_subst(xml::String)::String
    contexts = []
    push!(contexts,SubstContext())
    tokens = tokenize(strip(xml))
    ti = 1
    max=length(tokens)
    while ti<=max
        t = tokens[ti]
        @debug("$(contexts[1].state) | $(string_value(t))")
        if isopendel(t) && contexts[1].state != _after_del && contexts[1].state != _after_add
            @debug(1," push!")
            pushfirst!(contexts,SubstContext())
            (contexts[1].state != _subst) && (contexts[1].state = _tentative_subst)
            print(contexts[1].buf,string_value(t))

        elseif contexts[1].state == _tentative_subst && isclosedel(t)
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
                ti -= 1
                deleteat!(contexts,1)
                @debug("pop!")
            else
                @debug(3.2)
                if !(isa(t,TextToken) && isempty(strip(t.text))) # ignore whitespace tokens between subst elements
                    print(contexts[1].buf,string_value(t))
                end
                contexts[1].state = _subst
                contexts[1].subst = true
            end

        elseif contexts[1].state == _subst && iscloseadd(t)
            @debug(4)
            print(contexts[1].buf,string_value(t))
            contexts[1].state = _after_add

        elseif contexts[1].state == _after_add
            if ends_subst(t) || isopendel(t)
                @debug(5.1)
                print(contexts[2].buf, "<subst>", String(take!(contexts[1].buf)), "</subst>", contexts[1].tail)
                ti -= 1
                deleteat!(contexts,1)
                @debug("pop!")
            elseif is_whitespace(t)
                @debug(5.2)
                contexts[1].tail = t.text
            elseif isopenadd(t)
                @debug(5.3)
                print(contexts[1].buf,string_value(t))
                contexts[1].state = _subst
            else
                @debug(5.4)
                print(contexts[1].buf,string_value(t))
            end

        elseif contexts[1].state == _subst && ti == max
            @debug(6)
            print(contexts[2].buf, String(take!(contexts[1].buf)), contexts[1].tail)
            ti -= 1
            deleteat!(contexts,1)
            @debug("pop!")

        else
            @debug(7)
            print(contexts[1].buf, string_value(t))
        end
        ti += 1
    end
    return strip(String(take!(contexts[1].buf)))
end
