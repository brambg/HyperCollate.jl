#=
test_xml_preprocessor:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-21
=#

using Test, HyperCollate

test_subst_wrapping(xml::String, expected::String) = @test add_subst(xml) == expected

macro debug_on()
    return :(ENV["JULIA_DEBUG"] = "all")
end

macro debug_off()
    return :(ENV["JULIA_DEBUG"] = "")
end


@testset "automatic subst wrapping" begin
    @testset "wrapping non-nested add/del in subst" begin
        @testset "hoe zoet..." begin
            xml = """
            <xml>Hoe zoet moet nochtans zijn dit <del>werven om</del><add>trachten naar</add> een vrouw,
            de ongewisheid vóór de liefelijke toestemming!</xml>
            """

            expected = """
            <xml>Hoe zoet moet nochtans zijn dit <subst><del>werven om</del><add>trachten naar</add></subst> een vrouw,
            de ongewisheid vóór de liefelijke toestemming!</xml>"""

            test_subst_wrapping(xml,expected)
        end

        @testset "simple del/add" begin
            xml = "<x>bla1 <del>bla2</del><add>bla3</add> bla4</x>"
            expected = "<x>bla1 <subst><del>bla2</del><add>bla3</add></subst> bla4</x>"
            test_subst_wrapping(xml,expected)
        end

        @testset "don't wrap solitary del/add" begin
            xml = "<x>bla1 <del>bla2</del> something <add>bla3</add> bla4</x>"
            expected = "<x>bla1 <del>bla2</del> something <add>bla3</add> bla4</x>"
            test_subst_wrapping(xml,expected)
        end

        @testset "ignore whitespace between del/add" begin
            xml = "<x>bla1 <del>bla2</del>\n <add>bla3</add> bla4</x>"
            expected = "<x>bla1 <subst><del>bla2</del><add>bla3</add></subst> bla4</x>"
            test_subst_wrapping(xml,expected)
        end

        @testset "wrap del/del/add combo" begin
            xml = "<x>something <del>not this</del><del>or this</del><add>but this</add> something else</x>"
            expected = "<x>something <subst><del>not this</del><del>or this</del><add>but this</add></subst> something else</x>"
            test_subst_wrapping(xml,expected)
        end
    end

    @testset "wrapping nested add/del in subst" begin
        @testset "brulez 01r nested del" begin
#             @debug_on()
            xml = """
            <xml><s>...weinig van pas komen
            <del type="crossedOut" rend="grey pencil" hand="#RB" resp="#EB">zoo, o.m. in de sexueele opvoeding van den troo<del type="crossedOut" rend="grey pencil" hand="#RB" resp="#EB">p</del><add place="supralinear" hand="#RB" rend="grey pencil" resp="#EB">n</add>o<add place="supralinear" rend="grey pencil" hand="#RB" resp="#EB">p</add>volger...</del></s></xml>
            """
            expected = """
<xml><s>...weinig van pas komen
<del hand="#RB" rend="grey pencil" resp="#EB" type="crossedOut">zoo, o.m. in de sexueele opvoeding van den troo<subst><del hand="#RB" rend="grey pencil" resp="#EB" type="crossedOut">p</del><add place="supralinear" hand="#RB" rend="grey pencil" resp="#EB">n</add></subst>o<add place="supralinear" hand="#RB" rend="grey pencil" resp="#EB">p</add>volger...</del></s></xml>"""
            test_subst_wrapping(xml,expected)
#             println(add_subst(xml))
#             @debug_off()
        end

        @testset "brulez 01r nested del 2" begin
#             @debug_on()
            xml = """<s>weinig van pas komen
<del>,</del><add>:</add>
<del>zoo, o.m. in de sexueele opvoeding van den troo<del>p</del><add>n</add>o<add>p</add>volger...</del>
</s>"""
            expected = """<s>weinig van pas komen
<subst><del>,</del><add>:</add></subst>
<del>zoo, o.m. in de sexueele opvoeding van den troo<subst><del>p</del><add>n</add></subst>o<add>p</add>volger...</del></s>"""
            test_subst_wrapping(xml,expected)
#             @debug_off()
        end

        @testset "del/add nested in add" begin
            xml = "<x>bla1 <del>bla2</del>\n <add>bla3 <del>something</del><add>word</add></add> bla4</x>"
            expected = "<x>bla1 <subst><del>bla2</del><add>bla3 <subst><del>something</del><add>word</add></subst></add></subst> bla4</x>"
            test_subst_wrapping(xml,expected)
        end

        @testset "del/add nested in solitary del" begin
            xml = "<p>De te streng doorgedreven rationalisatie van zijn prinsenjeugd had dit <del>met <del>hem</del><add>zich</add></del> meegebracht.</p>"
            expected = "<p>De te streng doorgedreven rationalisatie van zijn prinsenjeugd had dit <del>met <subst><del>hem</del><add>zich</add></subst></del> meegebracht.</p>"
            test_subst_wrapping(xml,expected)
        end

        @testset "Old Miss: del in add" begin
            @debug_on()
            xml = "<s>Old Miss <del>Hare</del><add><del><unclear>Scovell</unclear></del></add><add><del>McGlone</del><add>McGlone</add></add> always sings at this hour.</s>"
            expected = "<s>Old Miss <subst><del>Hare</del><add><del><unclear>Scovell</unclear></del></add><add><subst><del>McGlone</del><add>McGlone</add></subst></add></subst> always sings at this hour.</s>"
            test_subst_wrapping(xml,expected)
            @debug_off()
        end

    end

    # @testset "handling milestones" begin
    #     xml = "<x>word <milestone/> word</x>"
    #     test_subst_wrapping(xml,xml)
    # end
end