
using DiffFusion
using Random
using Test

@testset "Polynomial regression." begin

    @testset "Multi-index and monomials" begin
        V_ref = [
            0  0  0
            1  0  0
            2  0  0
            3  0  0
            0  1  0
            1  1  0
            2  1  0
            0  2  0
            1  2  0
            0  3  0
            0  0  1
            1  0  1
            2  0  1
            0  1  1
            1  1  1
            0  2  1
            0  0  2
            1  0  2
            0  1  2
            0  0  3        
        ]
        M_ref = [
            1.0    1.0    1.0     1.0     1.0
            1.0    2.0    3.0     4.0     5.0
            1.0    4.0    9.0    16.0    25.0
            1.0    8.0   27.0    64.0   125.0
            2.0    4.0    6.0     8.0    10.0
            2.0    8.0   18.0    32.0    50.0
            2.0   16.0   54.0   128.0   250.0
            4.0   16.0   36.0    64.0   100.0
            4.0   32.0  108.0   256.0   500.0
            8.0   64.0  216.0   512.0  1000.0
            3.0    6.0    9.0    12.0    15.0
            3.0   12.0   27.0    48.0    75.0
            3.0   24.0   81.0   192.0   375.0
            6.0   24.0   54.0    96.0   150.0
            6.0   48.0  162.0   384.0   750.0
           12.0   96.0  324.0   768.0  1500.0
            9.0   36.0   81.0   144.0   225.0
            9.0   72.0  243.0   576.0  1125.0
           18.0  144.0  486.0  1152.0  2250.0
           27.0  216.0  729.0  1728.0  3375.0        
        ]
        #
        V = DiffFusion.multi_index(3,4)
        V = Matrix(reduce(hcat, V)')
        @test V == V_ref
        #
        C = (1.0:3.0) * (1:5)'
        M = DiffFusion.monomials(C, V)
        @test M == M_ref
    end

    @testset "Regression test." begin
        Random.seed!(123)
        # exact quadratic fit
        f2(x) = x[1] + 2.0 * x[1]^2 - 3.0 * x[1] * x[2] + x[3]^2 - 1.0
        C = rand(3, 20)
        O = [ f2(C[:,j]) for j in 1:size(C)[2] ]
        reg = DiffFusion.polynomial_regression(C, O, 2)
        P = DiffFusion.predict(reg, C)
        @test isapprox(P, O, atol=5.0e-14)
        # approximate quadratic
        f3(x) = x[1] + 2.0 * x[1]^2 - 3.0 * x[1] * x[2] + x[3]^3 - 1.0
        C = rand(3, 100)
        O = [ f3(C[:,j]) for j in 1:size(C)[2] ]
        reg = DiffFusion.polynomial_regression(C, O, 2)
        P = DiffFusion.predict(reg, C)
        @test maximum(abs.(P - O)) < 0.051
        # exact cubic fit
        reg = DiffFusion.polynomial_regression(C, O, 3)
        P = DiffFusion.predict(reg, C)
        @test isapprox(P, O, atol=5.0e-14)
        # out of sample test
        C1 = rand(3, 100)
        O1 = [ f3(C1[:,j]) for j in 1:size(C1)[2] ]
        P1 = DiffFusion.predict(reg, C1)
        @test isapprox(P1, O1, atol=5.0e-14)
    end
end
