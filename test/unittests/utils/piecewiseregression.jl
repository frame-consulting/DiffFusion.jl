using DiffFusion
using Random
using Test

@testset "Piecewise regression." begin

    @testset "Partitioning indices" begin
        @test DiffFusion.partition_index([ 2, 1, 3 ], [ 1, 1, 1 ]) == 1
        @test DiffFusion.partition_index([ 2, 1, 3 ], [ 1, 1, 2 ]) == 2
        @test DiffFusion.partition_index([ 2, 1, 3 ], [ 2, 1, 3 ]) == 6
        #
        π = [ 2, 1, 3 ]
        α = [ 1, 1 ]
        Q = [
            0.3 0.2
            0.6 0.8
        ]
        α = [ 1, 1 ]
        @test DiffFusion.sub_index(0.2, π, α, Q) == 1
        @test DiffFusion.sub_index(0.4, π, α, Q) == 2
        @test DiffFusion.sub_index(0.7, π, α, Q) == 3
        α = [ 2, 1 ]
        @test DiffFusion.sub_index(0.15, π, α, Q) == 1
        @test DiffFusion.sub_index(0.25, π, α, Q) == 2
        @test DiffFusion.sub_index(0.75, π, α, Q) == 2
        @test DiffFusion.sub_index(0.85, π, α, Q) == 3
        #
        α = [ 1, 2 ]
        @test_throws AssertionError DiffFusion.sub_index(0.15, π, α, Q)
        α = [ 1, 1 ]
        π = [ 2, 1, 0 ]
        @test_throws AssertionError DiffFusion.sub_index(0.15, π, α, Q)
        π = [ 2, 1, 3 ]
        Q = [
            0.3 0.2 0.1
            0.6 0.8 0.9
        ]
        @test_throws AssertionError DiffFusion.sub_index(0.15, π, α, Q)
        Q = [
            0.3 0.2
            0.6 0.8
            0.7 0.9
        ]
        @test_throws AssertionError DiffFusion.sub_index(0.15, π, α, Q)
        #
        π = [ 2, 1, 3 ]
        Q1 = reshape([ 0.5 ], (1,1))
        Q2 = zeros(0, 2)
        Q3 = [
            0.3 0.2
            0.6 0.8
        ]
        Q_list = [ Q1, Q2, Q3 ]
        @test DiffFusion.multi_index([0.2, 0.2, 0.1], π, Q_list) == [1, 1, 1]
        @test DiffFusion.multi_index([0.2, 0.2, 0.7], π, Q_list) == [1, 1, 3]
        @test DiffFusion.multi_index([0.6, 0.2, 0.7], π, Q_list) == [2, 1, 2]
        @test DiffFusion.multi_index([0.6, 0.2, 0.9], π, Q_list) == [2, 1, 3]
    end
        
    @testset "Branching matrices and partitioning." begin
        Random.seed!(2718281828459045)
        π = [ 2, 1, 3 ]
        C = rand(3, 100)
        # manual partitioning calculation
        Qs = AbstractMatrix[]
        Alpha = zeros(Int, 0, size(C)[2])
        # i = 1
        Q1 = DiffFusion.branching_matrix(π[begin:1], Alpha, C[1,:])
        A1 = [ DiffFusion.sub_index(C[1,j], π[begin:1], Alpha[:,j], Q1) for j=1:size(C)[2] ]
        Alpha = vcat(Alpha, A1')
        push!(Qs, Q1)
        # i = 2
        Q2 = DiffFusion.branching_matrix(π[begin:2], Alpha, C[2,:])
        A2 = [ DiffFusion.sub_index(C[2,j], π[begin:2], Alpha[:,j], Q2) for j=1:size(C)[2] ]
        Alpha = vcat(Alpha, A2')
        push!(Qs, Q2)
        # i = 3
        Q3 = DiffFusion.branching_matrix(π[begin:3], Alpha, C[3,:])
        A3 = [ DiffFusion.sub_index(C[3,j], π[begin:3], Alpha[:,j], Q3) for j=1:size(C)[2] ]
        Alpha = vcat(Alpha, A3')
        push!(Qs, Q3)
        #
        R = [ DiffFusion.partition_index(π, Alpha[:,j]) for j = 1:size(C)[2] ]
        #
        @test size(Q1) == (1,1)
        @test abs(Q1[1,1] - 0.5) < 0.1
        #
        @test Q2 == zeros(Int, 0, 2)
        #
        @test size(Q3) == (2,2)
        if VERSION >= v"1.7"
            @test all(abs.(Q3[1,:] .- 0.33) .< 0.1)
            @test all(abs.(Q3[2,:] .- 0.67) .< 0.1)
        else # relax tolerance for Julia 1.6
            @test all(abs.(Q3[1,:] .- 0.33) .< 0.2)
            @test all(abs.(Q3[2,:] .- 0.67) .< 0.2)
        end
        #
        @test DiffFusion.partitioning(C, π) == (Qs, Alpha, R)
    end

    @testset "Regression setup and prediction." begin
        Random.seed!(2718281828459045)
        # consistency to polynomial regression for trivial partitioning
        f1(x) =   sin(x[1]) + 2.0 * x[1]^2 - 3.0 * cos(x[1] * x[2]) + exp(x[3]^2) - 1.0
        C = rand(3, 20)
        O = [ f1(C[:,j]) for j in 1:size(C)[2] ]
        reg_poly = DiffFusion.polynomial_regression(C, O, 2)
        reg_piec = DiffFusion.piecewise_regression(C, O, 2, [1, 1, 1])
        @test length(reg_piec.regs) == 1
        @test reg_piec.regs[1].V == reg_poly.V
        @test reg_piec.regs[1].beta == reg_poly.beta
        # manual predict
        reg = reg_piec
        Alpha = hcat((DiffFusion.multi_index(C[:,j], reg.π, reg.Qs) for j in 1:size(C)[2])...)
        R = [ DiffFusion.partition_index(reg.π, Alpha[:,j]) for j = 1:size(C)[2] ]
        p = zeros(size(C)[2])
        for r in 1:prod(reg.π)
            p[R .== r] = DiffFusion.predict(reg.regs[r], C[:,R .== r])
        end
        @test DiffFusion.predict(reg_piec, C) == p
        @test DiffFusion.predict(reg_piec, C) == DiffFusion.predict(reg_poly, C)
        # check improved fit by partitioning
        C = rand(3, 100)
        O = [ f1(C[:,j]) for j in 1:size(C)[2] ]
        reg_poly = DiffFusion.polynomial_regression(C, O, 2)
        reg_piec = DiffFusion.piecewise_regression(C, O, 2, [2, 2, 2])
        if VERSION >= v"1.7"
            @test maximum(abs.(DiffFusion.predict(reg_poly, C) - O)) > 0.167
            @test maximum(abs.(DiffFusion.predict(reg_piec, C) - O)) < 0.014
        else # relax tolerance for Julia 1.6
            @test maximum(abs.(DiffFusion.predict(reg_poly, C) - O)) > 0.133
            @test maximum(abs.(DiffFusion.predict(reg_piec, C) - O)) < 0.017
        end
        # more partitioning configs
        @test maximum(abs.(DiffFusion.predict(DiffFusion.piecewise_regression(C, O, 2, [2, 1, 1]), C) - O) ) < 0.12
        @test maximum(abs.(DiffFusion.predict(DiffFusion.piecewise_regression(C, O, 2, [1, 2, 1]), C) - O) ) < 0.11
        @test maximum(abs.(DiffFusion.predict(DiffFusion.piecewise_regression(C, O, 2, [1, 1, 2]), C) - O) ) < 0.14
        @test maximum(abs.(DiffFusion.predict(DiffFusion.piecewise_regression(C, O, 2, [3, 1, 2]), C) - O) ) < 0.04
    end

end