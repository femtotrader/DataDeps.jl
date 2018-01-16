using DataDeps
using Base.Test

ENV["DATADEPS_ALWAY_ACCEPT"]=true

@testset "Pi" begin
    RegisterDataDep(
     "Pi",
     "There is no real reason to download Pi, unlike say lists of prime numbers, it is always faster to compute than it is to download. No matter how many digits you want.",
     "https://www.angio.net/pi/digits/10000.txt",
     sha2_256
    )

    pi_string = readstring(joinpath(datadep"Pi", "10000.txt"))
    @test parse(pi_string) ≈ π
    @test parse(BigFloat, pi_string) ≈ π

end

@testset "Primes" begin
    RegisterDataDep(
     "Primes",
     "These are the first 65 thousand primes. Still faster to calculate locally.",
     "http://staffhome.ecm.uwa.edu.au/~00061811/pub/primes.txt",

     "http://staffhome.ecm.uwa.edu.au/~00061811/pub/primes.sha256" |> download |> readstring |> split |> first
     #Important: this is a hash I didn't calculate, so is a test that our checksum methods actually align with the normal values.
    )

    data = readdlm(datadep"Primes"*"/primes.txt", ',')
    primes = data[4:end, 2] #skip fist 3

    #If these really are prime then will not have factors
    @test !any(isinteger.(primes./2))
    @test !any(isinteger.(primes./3))
    @test !any(isinteger.(primes./5))

end




@testset "MNIST" begin

    RegisterDataDep(
        "MNIST train",
        """
        Dataset: THE MNIST DATABASE of handwritten digits, (training subset)
        Authors: Yann LeCun, Corinna Cortes, Christopher J.C. Burges
        Website: http://yann.lecun.com/exdb/mnist/
        [LeCun et al., 1998a]
            Y. LeCun, L. Bottou, Y. Bengio, and P. Haffner.
            "Gradient-based learning applied to document recognition."
            Proceedings of the IEEE, 86(11):2278-2324, November 1998
        The files are available for download at the offical
        website linked above. We can download these files for you
        if you wish, but that doesn't free you from the burden of
        using the data responsibly and respect copyright. The
        authors of MNIST aren't really explicit about any terms
        of use, so please read the website to make sure you want
        to download the dataset.
        """,
        "http://yann.lecun.com/exdb/mnist/".*["train-images-idx3-ubyte.gz", "train-labels-idx1-ubyte.gz"];
        # Not providing a checksum at all so can check it gives output
        # TODO : automate this test with new 0.7 stuff
    )


    RegisterDataDep(
        "MNIST",
        """
        Dataset: THE MNIST DATABASE of handwritten digits
        Authors: Yann LeCun, Corinna Cortes, Christopher J.C. Burges
        Website: http://yann.lecun.com/exdb/mnist/
        [LeCun et al., 1998a]
            Y. LeCun, L. Bottou, Y. Bengio, and P. Haffner.
            "Gradient-based learning applied to document recognition."
            Proceedings of the IEEE, 86(11):2278-2324, November 1998
        The files are available for download at the offical
        website linked above. We can download these files for you
        if you wish, but that doesn't free you from the burden of
        using the data responsibly and respect copyright. The
        authors of MNIST aren't really explicit about any terms
        of use, so please read the website to make sure you want
        to download the dataset.
        """,
        "http://yann.lecun.com/exdb/mnist/".*["train-images-idx3-ubyte.gz", "train-labels-idx1-ubyte.gz", "t10k-images-idx3-ubyte.gz", "t10k-labels-idx1-ubyte.gz"],
        "0bb1d5775d852fc5bb32c76ca15a7eb4e9a3b1514a2493f7edfcf49b639d7975"
    )
read(datadep"MNIST"*"/train-labels-idx1-ubyte.gz")
    @test read(datadep"MNIST"*"/train-labels-idx1-ubyte.gz") == read(datadep"MNIST train"*"/train-labels-idx1-ubyte.gz")
end


@testset "UCI Banking" begin
    RegisterDataDep(
        "UCI Banking",
        """
        Dataset: Bank Marketing Data Set
        Authors: S. Moro, P. Cortez and P. Rita.
        Website: https://archive.ics.uci.edu/ml/datasets/bank+marketing

        This dataset is public available for research. The details are described in [Moro et al., 2014].
        Please include this citation if you plan to use this database:
        [Moro et al., 2014] S. Moro, P. Cortez and P. Rita. A Data-Driven Approach to Predict the Success of Bank Telemarketing. Decision Support Systems, Elsevier, 62:22-31, June 2014
        """,
        [
        "https://archive.ics.uci.edu/ml/machine-learning-databases/00222/bank.zip",
        "https://archive.ics.uci.edu/ml/machine-learning-databases/00222/bank-additional.zip"
        ],
        [(SHA.sha1, "785118991cd7d7ee7d8bf75ea58b6fae969ac185"),
         (SHA.sha3_224, "01b53f5b69d0b169070219b4391c623d84ab17d4cea8c8895cbf951d")];

         post_fetch_method = file->run(`unzip $file`)
    )

    data, header = readdlm(datadep"UCI Banking"*"/bank.csv", ';', header=true)
    @test size(header) == (1,17)
    @test size(data) == (4521,17)

end


@testset "UCI Adult, Hierarchical checksums" begin
    # This is an example of using hierachacy in the remote URLs,
    # and similar (partially matching up to depth) hierachacy in the checksums
    # for processing some groups of elements differently to others.
    # Doing this with checksums is not particularly useful
    # But the same thing applies to `fetch_method` and `post_fetch_method`.
    # So for example the
    RegisterDataDep(
        "UCI Adult",
        """
    	Dataset: Adult Data Set UCI ML Repository
    	Website: https://archive.ics.uci.edu/ml/datasets/Adult
    	Abstract : Predict whether income exceeds \$50K/yr based on census data.  Also known as "Census Income" dataset.

    	If you make use of this data it is requested that you cite:
    	- Lichman, M. (2013). UCI Machine Learning Repository [http://archive.ics.uci.edu/ml]. Irvine, CA: University of California, School of Information and Computer Science.
    	""",
        [
            [
                "https://archive.ics.uci.edu/ml/datasets/../machine-learning-databases/adult/adult.data",
                "https://archive.ics.uci.edu/ml/datasets/../machine-learning-databases/adult/adult.test"
            ],

            [
                "https://archive.ics.uci.edu/ml/datasets/../machine-learning-databases/adult/Index",
                [
                    "https://archive.ics.uci.edu/ml/datasets/../machine-learning-databases/adult/adult.names"
                    "https://archive.ics.uci.edu/ml/datasets/../machine-learning-databases/adult/old.adult.names"
                ]
             ]
        ],
        [
            "f9a9220df6bc5d9848bf450fd9ad45b9496503551af387d4a1bbe38ce1f8fc38", #adult.data ⊻ adult.test
            [
             "c53c35ce8a0eb10c12dd4b73830f3c94ae212bb388389d3763bce63e8d6bc684", #Index
             "818481d320861c4b623626ff6fab3426ad93dae4434b7f54ca5a0f357169c362" # adult.names ⊻ old.adult.names
            ]
        ]
    )

    @test length(collect(eachline(datadep"UCI Adult"*"/adult.names"))) == 110


end


@testset "Data.Gov Babynames" begin
    RegisterDataDep(
        "Baby Names",
        """
        Dataset: Baby Names from Social Security Card Applications-National Level Data
        Website: https://catalog.data.gov/dataset/baby-names-from-social-security-card-applications-national-level-data
        License: CC0

        The data (name, year of birth, sex and number) are from a 100 percent sample of Social Security card applications after 1879.
        """,
        ["https://www.ssa.gov/oact/babynames/names.zip","https://catalog.data.gov/harvest/object/f8ab4d49-b6b4-47d8-b1bb-b18187094f35"
        ],
        Any, # Test that there is no warning about checksum. This data is updated annually
        #TODO : Automate this test with new 0.7 test_warn stuff
        ;
        post_fetch_method = [unpack, f->mv(f, "metadata551randstuff.json")]
    )

    @test !any(endswith.(readdir(datadep"Baby Names"), "zip"))
    @test first(eachline(joinpath(datadep"Baby Names", "yob2016.txt")))=="Emma,F,19414"
    @test filemode(joinpath(datadep"Baby Names", "metadata551randstuff.json")) > 0
end

@testset "GitHub repo via API" begin
    # This test set is important because it catching the case where the filename is determined by the headers, not by the URL
    # Also githubs API is finicky about USER-AGENT and stuff

    RegisterDataDep(
        "DataDeps.jl Repo",
        """
        Dataset: The DataDeps.jl Repo.

        It is not normally a good idea to download code using DataDeps.
        But if you are treating that code as Data, e.g. doing a survey of coding practices, it is correct.

        See LICENSE.md for details on what you can do with this.
        """,
        "https://api.github.com/repos/oxinabox/DataDeps.jl/tarball",
        Any; # Does not have a constant checksum, but this is just for testing purposes anyway
        post_fetch_method = unpack)
    @test length(readdir(datadep"DataDeps.jl Repo"))==1
    folder = readdir(datadep"DataDeps.jl Repo")[1]
    @test isdir(joinpath(datadep"DataDeps.jl Repo", folder))

end
