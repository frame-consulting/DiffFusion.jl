
using DiffFusion
using StatsBase
using Test

@testset "Diagonal model simulation" begin

    if !@isdefined(TestModels)
        include("../../test_models.jl")
    end


    @testset "State-independent DiagonalModel simulation" begin
        times = 0.0:2.0:10.0
        n_paths = 2^10
        #
        model1 = TestModels.hybrid_model_one
        ch = TestModels.ch_one
        model2 = DiffFusion.diagonal_model("Std", [m for m in model1.models])
        sim1 = DiffFusion.simple_simulation(model1, ch, times, n_paths, with_progress_bar = false)
        sim2 = DiffFusion.diagonal_simulation(model2, ch, times, n_paths, with_progress_bar = false)
        @test isapprox(sim1.X, sim2.X, atol=1.0e-14 )
        #
        model1 = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        model2 = DiffFusion.diagonal_model("Std", [m for m in model1.models])
        sim1 = DiffFusion.simple_simulation(model1, ch, times, n_paths, with_progress_bar = false)
        sim2 = DiffFusion.diagonal_simulation(model2, ch, times, n_paths, with_progress_bar = false)
        @test isapprox(sim1.X, sim2.X, atol=1.0e-14 )
        #
        model1 = TestModels.hybrid_model_full
        ch = TestModels.ch_full
        model2 = DiffFusion.diagonal_model("Std", [model1])
        sim1 = DiffFusion.simple_simulation(model1, ch, times, n_paths, with_progress_bar = false)
        sim2 = DiffFusion.diagonal_simulation(model2, ch, times, n_paths, with_progress_bar = false)
        @test isapprox(sim1.X, sim2.X, atol=1.0e-14 )
        #display(sim1.X - sim2.X)
    end

    @testset "State-dependent DiagonalModel simulation" begin
        times = 0.0:0.25:5.0
        n_paths = 2^10
        #
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        cir_model_1 = DiffFusion.cox_ingersoll_ross_model("CRD1", z0, chi, theta, sigma)
        cir_model_2 = DiffFusion.cox_ingersoll_ross_model("CRD2", z0 + 0.01, chi, theta + 0.01, sigma)
        cir_model_3 = DiffFusion.cox_ingersoll_ross_model("CRD3", z0 + 0.02, chi, theta + 0.02, sigma)
        m = DiffFusion.diagonal_model("Std", [ cir_model_1, cir_model_2, cir_model_3 ])
        #
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "CRD1_x", "CRD2_x", 0.30)
        DiffFusion.set_correlation!(ch, "CRD2_x", "CRD3_x", 0.40)
        DiffFusion.set_correlation!(ch, "CRD1_x", "CRD3_x", 0.50)
        brownian_increments(seed) = begin
            f(n_states, n_paths, n_times) = DiffFusion.pseudo_brownian_increments(n_states, n_paths, n_times,seed)
            return f
        end
        sim = DiffFusion.diagonal_simulation(m, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(63685089)
        )
        sim1 = DiffFusion.diagonal_simulation(cir_model_1, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(28747716)
        )
        sim2 = DiffFusion.diagonal_simulation(cir_model_2, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(27177619)
        )
        sim3 = DiffFusion.diagonal_simulation(cir_model_3, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(9805674)
        )
        #
        m = mean(sim.X, dims=2)
        m1 = mean(sim1.X, dims=2)
        m2 = mean(sim2.X, dims=2)
        m3 = mean(sim3.X, dims=2)
        m = reshape(m, (3,length(times)))
        m123 = vcat(
            reshape(m1, (1,length(times))),
            reshape(m2, (1,length(times))),
            reshape(m3, (1,length(times))),
        )
        #display(maximum(abs.(m123 - m)))
        @test maximum(abs.(m123 - m)) < 0.075  # that's a rather weak test, but we have convergence
        #
        s = std(sim.X, dims=2)
        s1 = std(sim1.X, dims=2)
        s2 = std(sim2.X, dims=2)
        s3 = std(sim3.X, dims=2)
        s = reshape(s, (3,length(times))) ./ (sqrt.(times') .+ 1.0e-16)
        s123 = vcat(
            reshape(s1, (1,length(times))),
            reshape(s2, (1,length(times))),
            reshape(s3, (1,length(times))),
        )
        s123 = s123  ./ (sqrt.(times') .+ 1.0e-16)
        @test maximum(abs.(s123 - s)) < 0.035  # that's a rather weak test, but we have convergence
        #display(s')
        #display(s123')
        #display(maximum(abs.(s123 - s)))
    end


    @testset "Mixed DiagonalModel simulation" begin
        times = 0.0:0.25:5.0
        n_paths = 2^10
        #
        z0 = 0.01
        chi = 0.1
        theta = 0.03
        sigma = 0.07
        cir_model_1 = DiffFusion.cox_ingersoll_ross_model("CRD1", z0, chi, theta, sigma)
        cir_model_2 = DiffFusion.cox_ingersoll_ross_model("CRD2", z0 + 0.01, chi, theta + 0.01, sigma)
        cir_model_3 = DiffFusion.cox_ingersoll_ross_model("CRD3", z0 + 0.02, chi, theta + 0.02, sigma)
        #
        hyb_models = [ m for m in TestModels.hybrid_model_full.models ]
        all_models = vcat(hyb_models, [ cir_model_1, cir_model_2, cir_model_3 ])
        m_ful = DiffFusion.diagonal_model("Std", all_models)
        m_hyb = TestModels.hybrid_model_full
        m_crd =  DiffFusion.diagonal_model("Std", [ cir_model_1, cir_model_2, cir_model_3 ])
        #
        ch = TestModels.ch_full
        DiffFusion.set_correlation!(ch, "CRD1_x", "CRD2_x", 0.30)
        DiffFusion.set_correlation!(ch, "CRD2_x", "CRD3_x", 0.40)
        DiffFusion.set_correlation!(ch, "CRD1_x", "CRD3_x", 0.50)
        brownian_increments(seed) = begin
            f(n_states, n_paths, n_times) = DiffFusion.pseudo_brownian_increments(n_states, n_paths, n_times,seed)
            return f
        end
        sim_ful = DiffFusion.diagonal_simulation(m_ful, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(63685089)
        )
        sim_hyb = DiffFusion.simple_simulation(m_hyb, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(28747716)
        )
        sim_crd = DiffFusion.diagonal_simulation(m_crd, ch, times, n_paths, with_progress_bar = false,
            brownian_increments = brownian_increments(27177619)
        )
        #
        m_ful = mean(sim_ful.X, dims=2)
        m_hyb = mean(sim_hyb.X, dims=2)
        m_crd = mean(sim_crd.X, dims=2)
        m_ful = reshape(m_ful, (12,length(times)))
        m_ref = vcat(
            reshape(m_hyb, (9,length(times))),
            reshape(m_crd, (3,length(times))),
        )
        @test maximum(abs.(m_ful - m_ref)) < 0.07
        #display(maximum(abs.(m_ful - m_ref)))
        #
        s_ful = std(sim_ful.X, dims=2)
        s_hyb = std(sim_hyb.X, dims=2)
        s_crd = std(sim_crd.X, dims=2)
        s_ful = reshape(s_ful, (12,length(times))) ./ (sqrt.(times') .+ 1.0e-16)
        s_ref = vcat(
            reshape(s_hyb, (9,length(times))),
            reshape(s_crd, (3,length(times))),
        ) ./ (sqrt.(times') .+ 1.0e-16)
        @test maximum(abs.(s_ful - s_ref)) < 0.05
        # display(maximum(abs.(s_ful - s_ref)))
    end


    @testset "Hybrid CEV model regression." begin
        ch = TestModels.ch_full
        model = TestModels.hybrid_model_full
        #
        cev_model = DiffFusion.cev_asset_model(
            model.models[2].alias,
            model.models[2].sigma_x,
            DiffFusion.flat_parameter(0.0),
            model.models[2].correlation_holder,
            nothing,
        )
        hjm_model_for = DiffFusion.gaussian_hjm_model(
            model.models[3].alias,
            model.models[3].delta,
            model.models[3].chi,
            model.models[3].sigma_T.sigma_f,
            model.models[3].correlation_holder,
            cev_model,
        )
        eq_model = DiffFusion.lognormal_asset_model(
            model.models[4].alias,
            model.models[4].sigma_x,
            model.models[4].correlation_holder,
            cev_model,
        )
        model_cev = DiffFusion.diagonal_model("Std", [model.models[1], cev_model, hjm_model_for, eq_model])
        #
        times = 0.0:2.0:10.0
        n_paths = 2^3
        #
        sim1 = DiffFusion.simple_simulation(model, ch, times, n_paths, with_progress_bar = false)
        sim2 = DiffFusion.diagonal_simulation(model_cev, ch, times, n_paths, with_progress_bar = false)
        @test isapprox(sim1.X, sim2.X, atol=1.0e-15)
        #
        #display(sim1.X)
        #display(sim2.X)
    end

    @testset "Hybrid CEV model martingale test." begin
        include("../test_tolerances.jl")
        abs_tol = test_tolerances["simulations/diagonal_model.jl"]
        @info "Run simulation test with tolerance abs_tol=" * string(abs_tol) * "."

        ch = TestModels.ch_full
        model = TestModels.hybrid_model_full
        #
        cev_model = DiffFusion.cev_asset_model(
            model.models[2].alias,
            model.models[2].sigma_x,
            # DiffFusion.flat_parameter(0.0),
            DiffFusion.flat_parameter(-0.25),
            model.models[2].correlation_holder,
            nothing,
        )
        hjm_model_for = DiffFusion.gaussian_hjm_model(
            model.models[3].alias,
            model.models[3].delta,
            model.models[3].chi,
            model.models[3].sigma_T.sigma_f,
            model.models[3].correlation_holder,
            cev_model,
        )
        eq_model = DiffFusion.lognormal_asset_model(
            model.models[4].alias,
            model.models[4].sigma_x,
            model.models[4].correlation_holder,
            cev_model,
        )
        model_cev = DiffFusion.diagonal_model("Std", [model.models[1], cev_model, hjm_model_for, eq_model])
        models = model_cev.models
        #
        times = 0.0:1.0:10.0
        n_paths = 2^10
        #
        sim = DiffFusion.diagonal_simulation(model_cev, ch, times, n_paths, with_progress_bar = false)
        # domestic numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)[1,:]
        @test isapprox(one, ones(11), atol=5.0e-3)
        # display(one .- 1)
        # domestic zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(models[1], t, t+dt)
                y = DiffFusion.func_y(models[1], t)
                x = sim.X[1:3,:,k]
                s = sim.X[4:4,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s))
                # println(maximum(abs(one-1)))
                @test isapprox(one, 1.0, atol=abs_tol)
            end
        end
        # fx rate
        one = mean(exp.(sim.X[5,:,:]), dims=1)[1,:]
        @test isapprox(one, ones(11), atol=4.0e-2)
        # display(one .- 1)
        # foreign numeraire
        one = mean(exp.(-sim.X[8,:,:] + sim.X[5,:,:]), dims=1)[1,:]
        @test isapprox(one, ones(11), atol=3.3e-2)
        # display(one .- 1)
        # foreign zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(models[3], t, t+dt)
                y = DiffFusion.func_y(models[3], t)
                x = sim.X[6:7,:,k]
                s = sim.X[8:8,:,k]
                fx = sim.X[5:5,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s + fx))
                # println(maximum(abs(one-1)))
                @test isapprox(one, 1.0, atol=2.5e-2)
            end
        end
        # foreign equity
        one = mean(exp.(sim.X[9,:,:] + sim.X[5,:,:]), dims=1)[1,:]
        # display(one .- 1)
        @test isapprox(one, ones(11), atol=5.0e-2)
    end

end
