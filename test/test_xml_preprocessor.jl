#=
test_xml_preprocessor:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-21
=#

using Test, HyperCollate

test_subst_wrapping(xml::String, expected::String) = @test add_subst(xml) == expected

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
            expected = "<x>bla1 <subst><del>bla2</del>\n <add>bla3</add></subst> bla4</x>"
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
            xml = """
            <xml><s>...weinig van pas komen
            <del type="crossedOut" rend="grey pencil" hand="#RB" resp="#EB">zoo, o.m. in de                  sexueele opvoeding <lb/>van den troo<del type="crossedOut" rend="grey pencil" hand="#RB" resp="#EB">p</del><add place="supralinear" hand="#RB" rend="grey pencil" resp="#EB">n</add>o<add place="supralinear" rend="grey pencil" hand="#RB" resp="#EB">p</add>volger...</del></s></xml>
            """
            expected = """
            something...
            """
            test_subst_wrapping(xml,expected)
        end

        @testset "del/add nested in add" begin
            xml = "<x>bla1 <del>bla2</del>\n <add>bla3 <del>something</del><add>word</add></add> bla4</x>"
            expected = "<x>bla1 <subst><del>bla2</del>\n <add>bla3 <subst><del>something</del><add>word</add></subst></add></subst>bla4</x>"
            test_subst_wrapping(xml,expected)
        end

        @testset "del/add nested in solitary del" begin
            ENV["JULIA_DEBUG"] = "all"
            xml = "<p>De te streng doorgedreven rationalisatie van zijn prinsenjeugd had dit <del>met <del>hem</del><add>zich</add></del> meegebracht.</p>"
            expected = "<p>De te streng doorgedreven rationalisatie van zijn prinsenjeugd had dit <del>met <subst><del>hem</del><add>zich</add></subst></del> meegebracht.</p>"
            test_subst_wrapping(xml,expected)
            ENV["JULIA_DEBUG"] = ""
        end

    end

    # @testset "handling milestones" begin
    #     xml = "<x>word <milestone/> word</x>"
    #     test_subst_wrapping(xml,xml)
    # end
end