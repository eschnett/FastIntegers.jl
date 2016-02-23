using FastIntegers
using Base.Test

for T in (Int, UInt)
    f1,f2 = map(T, T <: Unsigned ? (1,3) : (-1,+1))
    for x in (f1*42, f2*42)

        @test fast_pos(x) === +x
        @test fast_neg(x) === -x
        @test fast_abs(x) === abs(x)

        for y in (f1*13, f2*13)

            @test fast_add(x, y) === x + y
            @test fast_sub(x, y) === x - y
            @test fast_mul(x, y) === x * y
            @test fast_div(x, y) === x ÷ y
            @test fast_rem(x, y) === x % y
            @test fast_fld(x, y) === fld(x, y)
            @test fast_mod(x, y) === mod(x, y)
            @test fast_cld(x, y) === cld(x, y)

        end
    end
end

@test fast_abs(typemin(Int)) === typemin(Int)
