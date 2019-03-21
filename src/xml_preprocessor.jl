#=
xml_preprocessor:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-21
=#

const _DEBUG = false

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

function add_subst(xml::String)::String
    outbuf = IOBuffer()
    tmpbuf = IOBuffer()
    state = _normal
    subst = false
    for t in tokenize(xml)
        _DEBUG && println("$state | $(string_value(t))")
        if isopendel(t)
            _DEBUG && println(1)
            (state != _subst) && (state = _tentative_subst)
            print(tmpbuf,string_value(t))

        elseif isclosedel(t)
            _DEBUG && println(2)
            print(tmpbuf,string_value(t))
            state = _after_del

        elseif state == _after_del
            if ends_subst(t)
                _DEBUG && println(3.1)
                if subst
                    print(outbuf, "<subst>", String(take!(tmpbuf)), "</subst>")
                else
                    print(outbuf, String(take!(tmpbuf)))
                end
                print(outbuf, string_value(t))
                state = _normal
                subst = false
            else
                _DEBUG && println(3.2)
                print(tmpbuf,string_value(t))
                state = _subst
                subst = true
            end

        elseif state == _subst && iscloseadd(t)
            _DEBUG && println(4)
            print(tmpbuf,string_value(t))
            state = _after_add

        elseif state == _after_add
            if ends_subst(t)
                _DEBUG && println(5.1)
                print(outbuf, "<subst>", String(take!(tmpbuf)), "</subst>")
                print(outbuf, string_value(t))
                state = _normal
                subst = false
            else
                _DEBUG && println(5.2)
                print(tmpbuf,string_value(t))
            end

        else
            _DEBUG && println(6)
            if (state == _normal)
                print(outbuf, String(take!(tmpbuf)))
                print(outbuf, string_value(t))
            else
                print(tmpbuf, string_value(t))
            end
        end
    end
    return strip(String(take!(outbuf)))
end

#=
state: :normal, :tentative_subst, :subst, :after_del, :after_add
start in state normal
if :normal && <del> -> :tentative_subst, store output in tmpbuf
if </del> -> :after_del
if :after_del && non-whitespace text -> :normal, add tmpbuf + text
if :after_del && (whitespace text || <add> || <del>) -> :subst
if :subst && </add> -> :after_add
if :after_add 
=#