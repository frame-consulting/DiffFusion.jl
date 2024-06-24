using DiffFusion
using Test

using LinearAlgebra


@testset "Separable HJM model methods." begin
    
    struct BasicSeparableHjmModel <: DiffFusion.SeparableHjmModel
        alias::String
        chi::DiffFusion.ParameterTermstructure
        delta::DiffFusion.ParameterTermstructure
    end
    chi = [ 0.01, 0.10, 0.30 ]
    delta = [ 1., 2., 5. ]
    m = BasicSeparableHjmModel("Std", DiffFusion.flat_parameter("Std", chi), DiffFusion.flat_parameter("Std", delta))

    @testset "Model setup." begin
        @test DiffFusion.alias(m) == "Std"
        @test DiffFusion.chi_hjm(m) == [ 0.01, 0.10, 0.30 ]
        @test DiffFusion.benchmark_times(m) == [ 1., 2., 5. ]
    end

    @testset "Basic model function." begin
        @test DiffFusion.H_hjm(chi,1.0,3.0) == [ exp(-0.01*2), exp(-0.10*2), exp(-0.30*2) ]
        @test DiffFusion.G_hjm(chi,1.0,3.0) == [
            (1. - exp(-0.01*2)) / 0.01,
            (1. - exp(-0.10*2)) / 0.10,
            (1. - exp(-0.30*2)) / 0.30]
        @test DiffFusion.H_hjm(chi,1.0,3.0) == DiffFusion.H_hjm(m,1.0,3.0)
        @test DiffFusion.G_hjm(chi,1.0,3.0) == DiffFusion.G_hjm(m,1.0,3.0)
        G = DiffFusion.G_hjm(chi,1.0, [3.0, 5.0])
        @test size(G) == (3,2)
        @test G[:,1] == DiffFusion.G_hjm(chi,1.0,3.0)
        @test G[:,2] == DiffFusion.G_hjm(chi,1.0,5.0)
        @test DiffFusion.G_hjm(chi,1.0, [3.0, 5.0]) == DiffFusion.G_hjm(m,1.0, [3.0, 5.0])
        chi_delta = [
            chi[1]*delta[1] chi[2]*delta[1] chi[3]*delta[1];
            chi[1]*delta[2] chi[2]*delta[2] chi[3]*delta[2];
            chi[1]*delta[3] chi[2]*delta[3] chi[3]*delta[3];
        ]
        @test DiffFusion.benchmark_times_scaling(chi, delta) == inv(exp.(-chi_delta))
        @test DiffFusion.benchmark_times_scaling(chi, delta, DiffFusion.ForwardRateScaling) == inv(exp.(-chi_delta))
        @test DiffFusion.benchmark_times_scaling(chi, delta, DiffFusion.ZeroRateScaling) == inv((1.0 .- exp.(-chi_delta)) ./ chi_delta)
        @test DiffFusion.benchmark_times_scaling(chi, delta, DiffFusion.DiagonalScaling) == Matrix(I, 3, 3)
    end

    @testset "Auxilliary state variable/variance calculation." begin
        # we test against textbook and alternative Quasi-Gaussian implementation
        sigma_f = Diagonal([ 50., 75., 100. ]) * 1e-4
        HHfInv = DiffFusion.benchmark_times_scaling(chi,delta)
        sigmaT = HHfInv * sigma_f
        #
        y0 = zeros(3,3)
        y1 = DiffFusion.func_y(y0,chi,sigmaT,0.0, 1.0)
        chi_i_p_chi_j = [
            chi[1]+chi[1] chi[1]+chi[2] chi[1]+chi[3];
            chi[2]+chi[1] chi[2]+chi[2] chi[2]+chi[3];
            chi[3]+chi[1] chi[3]+chi[2] chi[3]+chi[3];
        ]
        y1_ref = (sigmaT * sigmaT') .* (1. .- exp.(-chi_i_p_chi_j)) ./ chi_i_p_chi_j
        @test isapprox(y1, y1_ref, atol=1.e-16, rtol=0.0)
        # textbook implementation
        y0 = y1
        s = 1.0
        t = 3.0
        y1 = DiffFusion.func_y(y0,chi,sigmaT,s, t)
        y1_ref = Diagonal(DiffFusion.H_hjm(chi,s,t)) * y0 * Diagonal(DiffFusion.H_hjm(chi,s,t)) +
            (sigmaT * sigmaT') .* (1. .- exp.(-chi_i_p_chi_j*(t-s))) ./ chi_i_p_chi_j
        @test isapprox(y1, y1_ref, atol=1.e-16)
        # Quasi-Gaussian evolve implementation
        GPrime_ = DiffFusion.H_hjm(chi,s,t)
        V = sigmaT * transpose(sigmaT)
        b = V ./ chi_i_p_chi_j
        a = y0 - b
        # y1[i,j] = a[i,j] exp{-(chi_i + chi_j)(T-t)} + b[i,j]
        y1_ref = zeros(3,3)
        for i in 1:3
            for j = 1:3
                y1_ref[i,j] = a[i,j] * GPrime_[i] * GPrime_[j] + b[i,j]
            end
        end
        @test isapprox(y1, y1_ref, atol=1.5e-16, rtol=0.0)
    end

    @testset "Theta calculation." begin
        # we test against textbook implementation
        sigma_f = Diagonal([ 50., 75., 100. ]) * 1e-4
        HHfInv = DiffFusion.benchmark_times_scaling(chi,delta)
        sigmaT(u) = HHfInv * sigma_f  # This is a rates volatility without correlation!
        V = sigmaT(0.0) * transpose(sigmaT(0.0))
        alpha(u) = -0.30 * ones(3) * 0.15  # -30% rates-FX correlation and 15% FX vol
        #
        y0 = DiffFusion.func_y(zeros(3,3),chi,sigmaT(0.0),0.0, 1.0)  # at s=1.
        y(u) = DiffFusion.func_y(y0,chi,sigmaT(1.0),1.0, u)
        s = 1.0
        t = 3.0
        #
        theta_x = DiffFusion.func_Theta_x(chi,y,sigmaT,alpha,s,t,nothing)
        theta0 = Diagonal(DiffFusion.H_hjm(chi,s,t)) * y0 * DiffFusion.G_hjm(chi,s,t)
        f_x(u) = Diagonal(DiffFusion.H_hjm(chi,u,t)) * V * DiffFusion.G_hjm(chi,u,t) -
                 Diagonal(DiffFusion.H_hjm(chi,u,t)) * sigmaT(u) * alpha(u)
        theta1 = DiffFusion._vector_integral(f_x, s, t)
        @test isapprox(theta_x, theta0 + theta1, atol=1.e-16, rtol=0.0)
        # Simpson's rule
        theta1_0 = f_x(s)
        theta1_1 = f_x((s+t)/2)
        theta1_2 = f_x(t)
        theta1_Simpson = (theta1_0 + 4*theta1_1 + theta1_2) * (t-s) / 6
        @test isapprox(theta_x, theta0 + theta1_Simpson, atol=6.e-5)
        @test isapprox(theta_x, theta0 + theta1_Simpson, rtol=2.e-2)
        #
        theta_s = DiffFusion.func_Theta_s(chi,y,sigmaT,alpha,s,t,nothing)
        f_s(u) = DiffFusion.G_hjm(chi,u,t)' * reshape(sum(DiffFusion.func_y(y0,chi,sigmaT(u),s,u), dims=2), (3)) -
                 DiffFusion.G_hjm(chi,u,t)' * sigmaT(u) * alpha(u)
        theta_s_ref = DiffFusion._scalar_integral(f_s, s, t)
        @test isapprox(theta_s, theta_s_ref, atol=1.e-16, rtol=0.0)
        # Simpson's rule
        theta_s_0 = f_s(s)
        theta_s_1 = f_s((s+t)/2)
        theta_s_2 = f_s(t)
        theta_s_Simpson = (theta_s_0 + 4*theta_s_1 + theta_s_2) * (t-s) / 6
        @test isapprox(theta_s, theta_s_Simpson, atol=2.e-6)
        @test isapprox(theta_s, theta_s_Simpson, rtol=4.e-3)
        #
        theta_X = DiffFusion.func_Theta(chi,y,sigmaT,alpha,s,t,nothing)
        @test size(theta_X) == (4,)
        @test theta_X[1:end-1] == theta_x
        @test theta_X[end] == theta_s
        #
        theta_x_integrate_y = DiffFusion.func_Theta_x_integrate_y(chi,y,sigmaT,alpha,s,t,nothing)
        @test isapprox(theta_x_integrate_y, theta_x)
    end

    @testset "H calculation." begin
        s = 1.0
        t = 3.0
        H = DiffFusion.func_H_T(chi,s,t)'
        H_ = DiffFusion.H_hjm(chi,s,t)
        G_ = DiffFusion.G_hjm(chi,s,t)
        H_ref = [
            H_[1] 0     0     0;
            0     H_[2] 0     0;
            0     0     H_[3] 0;
            G_[1] G_[2] G_[3] 1;
        ]
        @test H == H_ref
        #
        H_dense = DiffFusion.func_H_T_dense(chi,s,t)'
        @test H_dense == H
    end


    @testset "Sigma_T calculation." begin
        sigma_f = Diagonal([ 50., 75., 100. ]) * 1e-4
        HHfInv = DiffFusion.benchmark_times_scaling(chi,delta)
        sigmaT(u) = HHfInv * sigma_f
        s = 1.0
        t = 3.0
        SigmaT = DiffFusion.func_Sigma_T(chi,sigmaT,s,t)
        SigmaT_0 = SigmaT(s)
        SigmaT_1 = SigmaT((s+t)/2)
        SigmaT_2 = SigmaT(t)
        #
        u = s
        H_ = DiffFusion.H_hjm(chi,u,t)
        G_ = DiffFusion.G_hjm(chi,u,t)
        @test isapprox(SigmaT_0[1:end-1,:], Diagonal(H_) * sigmaT(u), atol=1.e-16)
        @test isapprox(SigmaT_0[end:end,:], G_' * sigmaT(u), atol=1.e-16)
        #
        u = (s + t) / 2
        H_ = DiffFusion.H_hjm(chi,u,t)
        G_ = DiffFusion.G_hjm(chi,u,t)
        @test isapprox(SigmaT_1[1:end-1,:], Diagonal(H_) * sigmaT(u), atol=1.e-16)
        @test isapprox(SigmaT_1[end:end,:], G_' * sigmaT(u), atol=1.e-16)
        #
        u = t
        @test isapprox(SigmaT_2[1:end-1,:], sigmaT(u),  atol=1.e-16)
        @test isapprox(SigmaT_2[end:end,:], zeros(1,3), atol=1.e-16)
    end

end
