
using DiffFusion
using Test

@testset "Cox-Ingersoll-Ross model tests." begin

    @testset "Model setup." begin
        z0 = 0.01
        chi = 0.05
        theta = 0.03
        sigma = 0.01
        v = [ z0, chi, theta, sigma ]
        p = DiffFusion.flat_parameter("", v)
        #
        m1 = DiffFusion.cox_ingersoll_ross_model("CRD", z0, chi, theta, sigma)
        m2 = DiffFusion.cox_ingersoll_ross_model("CRD", v)
        m3 = DiffFusion.cox_ingersoll_ross_model("CRD", p)
        #
        @test string(m1) == string(m2)
        @test string(m2) == string(m3)
        #
        @test DiffFusion.alias(m1) == "CRD"
        @test DiffFusion.state_alias(m1) == [ "CRD_x" ]
        @test DiffFusion.factor_alias(m1) == [ "CRD_x" ]
        #
        @test DiffFusion.cir_z0(m1) == z0
        @test DiffFusion.cir_chi(m1) == chi
        @test DiffFusion.cir_theta(m1) == theta
        @test DiffFusion.cir_sigma(m1) == sigma
    end
    
    @testset "CIR moments." begin
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        m = DiffFusion.cox_ingersoll_ross_model("CRD", z0, chi, theta, sigma)
        #
        zs = [ 0.01, 0.02, 0.03, 0.04 ]
        T = [ 1.0, 2.0, 5.0, 10.0 ]
        M = [ 
            DiffFusion.cir_moments(m, zs, 0.0, t)
            for t in T
        ]
        Ez = vcat([m[1]' for m in M]...)
        Ez_ref = [
            0.0119033  0.0209516  0.03  0.0390484
            0.0136254  0.0218127  0.03  0.0381873
            0.0178694  0.0239347  0.03  0.0360653
            0.0226424  0.0263212  0.03  0.0336788
        ]
        @test isapprox(Ez, Ez_ref, atol=1.0e-6)
        # display(Ez)
        Vz = vcat([m[2]' for m in M]...)
        Vz = sqrt.(Vz ./ T)
        Vz_ref = [
            0.00698916  0.00954152  0.0115427   0.0132448
            0.00695961  0.00920852  0.0110072   0.0125506
            0.00679309  0.0083387   0.00963959  0.0107847
            0.00638463  0.00722206  0.007972    0.00865722           
        ]
        @test isapprox(Vz, Vz_ref, atol=1.0e-6)
        #display(Vz)
    end

    @testset "Lognormal approximation." begin
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        m = DiffFusion.cox_ingersoll_ross_model("CRD", z0, chi, theta, sigma)
        #
        zs = [ 0.01, 0.02, 0.03, 0.04 ]
        T = [ 1.0, 2.0, 5.0, 10.0 ]
        #
        M = [
            DiffFusion.cir_moments(m, zs, 0.0, t)
            for t in T
        ]
        Ez = vcat([m[1]' for m in M]...)
        Vz = vcat([m[2]' for m in M]...)
        #
        L_ab2 = [
            DiffFusion.cir_lognormal_approximation(m, zs, 0.0, t)
            for t in T
        ]
        a = vcat([ab2[1]' for ab2 in L_ab2]...)
        b2 = vcat([ab2[2]' for ab2 in L_ab2]...)
        @test isapprox(exp.(a+0.5*b2), Ez, atol=1.0e-16)
        @test isapprox(exp.(2.0*(a+0.5*b2)).*(exp.(b2) .- 1.0), Vz, atol=10.e-16)
        #display(a)
        #display(b2)        
    end

    @testset "Simulation functions." begin
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        m = DiffFusion.cox_ingersoll_ross_model("CRD", z0, chi, theta, sigma)
        #
        xs = log.([ 0.01, ] ./ z0)
        X = reshape(xs, (1,:))
        idx = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        p = DiffFusion.simulation_parameters(m, nothing, 1.0, 3.0)
        X = DiffFusion.model_state(X, idx, p)
        #
        (Θ_x, Σ_x) = DiffFusion.func_Theta_Sigma(m, [0.01], 1.0, 3.0)
        #
        Θ = DiffFusion.Theta(m, 1.0, 3.0, X)
        @test Θ==Θ_x
        #
        Σ = DiffFusion.Sigma_T(m, 1.0, 3.0, X)
        @test Σ(1.0)[1,1]==Σ_x[1]
        #
        xs = log.([ 0.01, 0.02, 0.03, 0.04, 0.05 ] ./ z0)
        X = reshape(xs, (1,:))
        idx = DiffFusion.alias_dictionary(DiffFusion.state_alias(m))
        p = DiffFusion.simulation_parameters(m, nothing, 1.0, 3.0)
        X = DiffFusion.model_state(X, idx, p)
        Σ_d = DiffFusion.diagonal_volatility(m, 1.0, 3.0, X)
        (Θ_x, Σ_x) = DiffFusion.func_Theta_Sigma(m, [ 0.01, 0.02, 0.03, 0.04, 0.05 ], 1.0, 3.0)
        @test Σ_d==Σ_x'
        #display(Σ_d)
        #display(Σ_x)
    end

end
