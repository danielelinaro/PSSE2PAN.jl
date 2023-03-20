using PSSE2PAN
using Documenter

DocMeta.setdocmeta!(PSSE2PAN, :DocTestSetup, :(using PSSE2PAN); recursive=true)

makedocs(;
    modules=[PSSE2PAN],
    authors="Daniele Linaro <danielelinaro@gmail.com> and contributors",
    repo="https://github.com/Daniele Linaro/PSSE2PAN.jl/blob/{commit}{path}#{line}",
    sitename="PSSE2PAN.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Daniele Linaro.github.io/PSSE2PAN.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Daniele Linaro/PSSE2PAN.jl",
    devbranch="main",
)
