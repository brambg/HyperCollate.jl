using Test,HTTP,JSON,JSON2,Dates

@testset "hyper-collate server" begin
    base_url = "http://localhost:53861"
    endpoint = "/about"
    r = HTTP.get(base_url*endpoint)
    response_json = JSON.parse(String(r.body))
#     print(response_json)
    @test response_json["dotRendering"] == true
    @test response_json["appName"] == "HyperCollate Server"

    mutable struct About
        appName::String
        version::String
        startedAt::String
        commitId::String
        buildDate::String
        scmBranch::String
        dotRendering::Bool
        projectDirURI::String
    end

    r = HTTP.get(base_url*endpoint)
    json = String(HTTP.payload(r))
    @pretty json
    about = JSON2.read(json, About)
    @show(about)
    @test about.dotRendering == true
    @test about.appName == "HyperCollate Server"

    endpoint = "/collations"
    r = HTTP.get(base_url*endpoint)
    collation_urls = JSON.parse(String(HTTP.payload(r)))
    @show collation_urls
end

