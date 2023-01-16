using KeywordStrings
using Test

@testset "KeywordStrings.jl" begin
    
    # string remains literal on construction
    @test kw"abcd" === "abcd"

    # simple interpolation works with various types
    @test kw"abcd$x" % (; x = 0) === "abcd0"
    @test kw"abcd$x" % Dict(:x => 0) === "abcd0"
    @test kw"abcd$x" % pairs(Dict(:x => 0)) === "abcd0"
    @test kw"abcd$value" % Some(0) === "abcd0"

    # test local variable interpolation works on construction
    let x = 0
        @test kw"abcd$x$!" === "abcd0"
    end

    # test composition and precedence works
    @test (kw"$x" * kw"$y") % (; x=0, y=1) === "01"
    @test kw"$x" % (; x=0) * kw"$y" % (; y=1) === "01"
    @test kw"$x$y" % (; x = 0, y = 1) === "01"
    @test kw"$x$y" % (; x = 0) % (; y = 1) === "01"

    # cannot convert to string before finalizing all formatting
    @test_throws KeywordStrings.KeywordStringsError string(kw"$undefinedvar")

end
