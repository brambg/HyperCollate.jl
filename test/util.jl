#=
util:
- Julia version:
- Author: bramb
- Date: 2019-01-24
=#

macro debug_on()
    return :(ENV["JULIA_DEBUG"] = "all")
end

macro debug_off()
    return :(ENV["JULIA_DEBUG"] = "")
end

function _test_normalized_strings_are_equal(string1::String, string2::String)
    n1 = _normalize(string1)
    n2 = _normalize(string2)
    @test n1 == n2
end

function _normalize(string::String)
    trimmed_lines = map(l->strip(l), split(string,"\n"))
    trim = join(trimmed_lines,"\n")
    return replace(trim, r"\n\n+" => "\n")
end

function _print_dot(dot::String)
   out = """
   ---------- ✂ ------------------------------------------------------------------
   $(replace(dot, r"\n([\t ]*\n)+" => "\n"))
   -------------------------------------------------- ✂ --------------------------
   """
   println(out)
end