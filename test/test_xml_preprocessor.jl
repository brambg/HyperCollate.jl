#=
test_xml_preprocessor:
- Julia version: 1.1.0
- Author: bramb
- Date: 2019-03-21
=#

using Test, HyperCollate

test_subst_wrapping(xml::String, expected::String) = @test add_subst(xml) == expected

@testset "wrapping non-nested add/del in subst" begin
    xml = """
    <xml>Hoe zoet moet nochtans zijn dit <del>werven om</del><add>trachten naar</add> een vrouw,
    de ongewisheid vóór de liefelijke toestemming!</xml>
    """

    expected = """
    <xml>Hoe zoet moet nochtans zijn dit <subst><del>werven om</del><add>trachten naar</add></subst> een vrouw,
    de ongewisheid vóór de liefelijke toestemming!</xml>"""

    test_subst_wrapping(xml,expected)

    xml = "<x>bla1 <del>bla2</del><add>bla3</add> bla4</x>"
    expected = "<x>bla1 <subst><del>bla2</del><add>bla3</add></subst> bla4</x>"
    test_subst_wrapping(xml,expected)

    xml = "<x>bla1 <del>bla2</del> something <add>bla3</add> bla4</x>"
    expected = "<x>bla1 <del>bla2</del> something <add>bla3</add> bla4</x>"
    test_subst_wrapping(xml,expected)

    xml = "<x>bla1 <del>bla2</del>\n <add>bla3</add> bla4</x>"
    expected = "<x>bla1 <subst><del>bla2</del>\n <add>bla3</add></subst> bla4</x>"
    test_subst_wrapping(xml,expected)

    xml = "<x>something <del>not this</del><del>or this</del><add>but this</add> something else</x>"
    expected = "<x>something <subst><del>not this</del><del>or this</del><add>but this</add></subst> something else</x>"
    test_subst_wrapping(xml,expected)
end

@testset "wrapping nested add/del in subst" begin
    xml = "<x>bla1 <del>bla2</del>\n <add>bla3 <del>something</del><add>word</add></add> bla4</x>"
    expected = "<x>bla1 <subst><del>bla2</del>\n <add>bla3 <subst><del>something</del><add>word</add></add></subst></subst>bla4</x>"
    test_subst_wrapping(xml,expected)
end

@testset "handling milestones" begin
    xml = "<x>word <milestone/> word</x>"
    test_subst_wrapping(xml,xml)
end