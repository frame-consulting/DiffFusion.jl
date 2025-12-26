using StatsBase
using Test

@testset "Quasi-Gaussian hybrid model simulation" begin
    
    @info "Run quasi-Gaussian hybrid model simulation."

    ch_one = DiffFusion.correlation_holder("One")
    ch_full = DiffFusion.correlation_holder("Full")
    #
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_2", 0.8)
    DiffFusion.set_correlation!(ch_full, "EUR_f_2", "EUR_f_3", 0.8)
    DiffFusion.set_correlation!(ch_full, "EUR_f_1", "EUR_f_3", 0.5)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "USD_f_2", 0.50)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_1", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_2", -0.30)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "EUR_f_3", -0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_1", -0.20)
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "USD_f_2", -0.20)
    #
    DiffFusion.set_correlation!(ch_full, "USD_f_1", "EUR_f_1", 0.30)
    DiffFusion.set_correlation!(ch_full, "USD_f_2", "EUR_f_2", 0.30)
    #
    DiffFusion.set_correlation!(ch_full, "EUR-USD_x", "SXE50_x", 0.70)

    setup_models(ch) = begin
        sigma_fx = DiffFusion.flat_volatility("EUR-USD", 0.15)
        fx_model = DiffFusion.lognormal_asset_model("EUR-USD", sigma_fx, ch, nothing)
    
        sigma_fx = DiffFusion.flat_volatility("SXE50", 0.10)
        eq_model = DiffFusion.lognormal_asset_model("SXE50", sigma_fx, ch, fx_model)
    
        delta_dom = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi_dom = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
        times_dom =  [ 0. ]
        values_dom = [ 50. 60. 70. ]' * 1.0e-4
        sigma_f_dom = DiffFusion.backward_flat_volatility("USD", times_dom, values_dom)
        hjm_model_dom = DiffFusion.gaussian_hjm_model("USD", delta_dom, chi_dom, sigma_f_dom, ch, nothing)
    
        delta_for = DiffFusion.flat_parameter([ 1., 10. ])
        chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
        times_for =  [ 0. ]
        values_for = [ 80. 90. ]' * 1.0e-4
        sigma_f_for = DiffFusion.backward_flat_volatility("EUR", times_for, values_for)
        hjm_model_for = DiffFusion.gaussian_hjm_model("EUR", delta_for, chi_for, sigma_f_for, ch, fx_model)

        sigma_min = 1.0e-4
        sigma_max = 500. * 1.0e-4
        ou_model = DiffFusion.ornstein_uhlenbeck_model(
            "OU",
            DiffFusion.flat_parameter("", 0.10),   # chi
            DiffFusion.flat_volatility("", 0.20),  # sigma_x
        )

        slope_d_dom = DiffFusion.flat_parameter([ 10., 10., 10. ] .* (-1.e-2) )
        slope_u_dom = DiffFusion.flat_parameter([ 15., 15., 15. ] .* (1.e-2) )
        slope_d_for = DiffFusion.flat_parameter([ 10., 10., ] .* (-1.e-2) )
        slope_u_for = DiffFusion.flat_parameter([ 15., 15., ] .* (1.e-2) )

        qg_model_dom = DiffFusion.quasi_gaussian_model(
            hjm_model_dom, slope_d_dom, slope_u_dom, sigma_min, sigma_max, ou_model, exp
        )
        qg_model_for = DiffFusion.quasi_gaussian_model(
            hjm_model_for, slope_d_for, slope_u_for, sigma_min, sigma_max, ou_model, exp
        )

        return [ qg_model_dom, fx_model, qg_model_for, eq_model, ou_model ]
    end

    @testset "State-dependent simulation, no correlation" begin
        models = setup_models(ch_one)
        m = DiffFusion.diagonal_model("Std", models)

        s_alias = [
            "USD_x_1", "USD_x_2", "USD_x_3", "USD_s",  # 1 .. 4
            "USD_y_1_1", "USD_y_2_1", "USD_y_3_1",     # 5 .. 13
            "USD_y_1_2", "USD_y_2_2", "USD_y_3_2",
            "USD_y_1_3", "USD_y_2_3", "USD_y_3_3", 
            "EUR-USD_x",                               # 14
            "EUR_x_1", "EUR_x_2", "EUR_s",             # 15 .. 17
            "EUR_y_1_1", "EUR_y_2_1",
            "EUR_y_1_2", "EUR_y_2_2",
            "SXE50_x",
            "OU_x",
        ]
        @test DiffFusion.state_alias(m) == s_alias

        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.state_dependent_simulation(m, ch_one, times, n_paths, with_progress_bar = true)
        @test size(sim.X) == (23, 1024, 11)

        # martingale test domestic numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        @test maximum(abs.(one .- 1.0)) < 3.8e-3

        # martingale test for domestic zero bonds
        qg_model = m.models[1]
        obs_times = 0.0:1.0:10
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(obs_times)
            SX = DiffFusion.model_state(sim.X[:,:,k], m)
            x = DiffFusion.state_variable(qg_model, SX)
            s = DiffFusion.integrated_state_variable(qg_model, SX)
            y = DiffFusion.auxiliary_variable(qg_model, SX)
            for dt in dt_
                G = DiffFusion.G_hjm(qg_model.gaussian_model, t, t+dt)
                GyG = [ dot(G, @view(y[:,:,p]), G) for p in 1:n_paths ]'
                one = mean(exp.(-G'*x - 0.5*GyG - s))
                @test abs(one-1.0) < 7.6e-3
                # display(abs(one-1))
            end
        end
        
        # martingale test for fx rate
        one = mean(exp.(sim.X[14,:,:]), dims=1)
        @test maximum(abs.(one .- 1.0)) < 3.2e-2
        
        # martingale test for foreign numeraire - effectively no quanto impact due to zero correlation
        one = mean(exp.(-sim.X[17,:,:] + sim.X[14,:,:]), dims=1)
        @test maximum(abs.(one .- 1.0)) < 2.8e-2

        # martingale test for foreign zero bonds
        qg_model = m.models[3]
        obs_times = 0.0:1.0:10
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(obs_times)
            SX = DiffFusion.model_state(sim.X[:,:,k], m)
            x = DiffFusion.state_variable(qg_model, SX)
            s = DiffFusion.integrated_state_variable(qg_model, SX)
            y = DiffFusion.auxiliary_variable(qg_model, SX)
            fx = sim.X[14:14,:,k]
            for dt in dt_
                G = DiffFusion.G_hjm(qg_model.gaussian_model, t, t+dt)
                GyG = [ dot(G, @view(y[:,:,p]), G) for p in 1:n_paths ]'
                one = mean(exp.(-G'*x - 0.5*GyG - s + fx))
                @test abs(one-1.0) < 2.8e-2
                # display(one)
                # display(abs(one-1))
            end
        end
        
        #display(vec(one))
        #println(maximum(abs.(one .- 1.0)))
    end

    @testset "State-dependent simulation, full correlation" begin
        models = setup_models(ch_full)
        m = DiffFusion.diagonal_model("Std", models)

        s_alias = [
            "USD_x_1", "USD_x_2", "USD_x_3", "USD_s",  # 1 .. 4
            "USD_y_1_1", "USD_y_2_1", "USD_y_3_1",     # 5 .. 13
            "USD_y_1_2", "USD_y_2_2", "USD_y_3_2",
            "USD_y_1_3", "USD_y_2_3", "USD_y_3_3", 
            "EUR-USD_x",                               # 14
            "EUR_x_1", "EUR_x_2", "EUR_s",             # 15 .. 17
            "EUR_y_1_1", "EUR_y_2_1",
            "EUR_y_1_2", "EUR_y_2_2",
            "SXE50_x",
            "OU_x",
        ]
        @test DiffFusion.state_alias(m) == s_alias

        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.state_dependent_simulation(m, ch_full, times, n_paths, with_progress_bar = true)
        @test size(sim.X) == (23, 1024, 11)

        # martingale test domestic numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        @test maximum(abs.(one .- 1.0)) < 4.2e-3

        # martingale test for domestic zero bonds
        qg_model = m.models[1]
        obs_times = 0.0:1.0:10
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(obs_times)
            SX = DiffFusion.model_state(sim.X[:,:,k], m)
            x = DiffFusion.state_variable(qg_model, SX)
            s = DiffFusion.integrated_state_variable(qg_model, SX)
            y = DiffFusion.auxiliary_variable(qg_model, SX)
            for dt in dt_
                G = DiffFusion.G_hjm(qg_model.gaussian_model, t, t+dt)
                GyG = [ dot(G, @view(y[:,:,p]), G) for p in 1:n_paths ]'
                one = mean(exp.(-G'*x - 0.5*GyG - s))
                @test abs(one-1.0) < 8.1e-3
                # display(abs(one-1))
            end
        end
        
        # martingale test for fx rate
        one = mean(exp.(sim.X[14,:,:]), dims=1)
        @test maximum(abs.(one .- 1.0)) < 3.2e-2
        
        # martingale test for foreign numeraire - effectively no quanto impact due to zero correlation
        one = mean(exp.(-sim.X[17,:,:] + sim.X[14,:,:]), dims=1)
        @test maximum(abs.(one .- 1.0)) < 3.6e-2

        # martingale test for foreign zero bonds
        qg_model = m.models[3]
        obs_times = 0.0:1.0:10
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(obs_times)
            SX = DiffFusion.model_state(sim.X[:,:,k], m)
            x = DiffFusion.state_variable(qg_model, SX)
            s = DiffFusion.integrated_state_variable(qg_model, SX)
            y = DiffFusion.auxiliary_variable(qg_model, SX)
            fx = sim.X[14:14,:,k]
            for dt in dt_
                G = DiffFusion.G_hjm(qg_model.gaussian_model, t, t+dt)
                GyG = [ dot(G, @view(y[:,:,p]), G) for p in 1:n_paths ]'
                one = mean(exp.(-G'*x - 0.5*GyG - s + fx))
                @test abs(one-1.0) < 3.6e-2
                # display(one)
                # display(abs(one-1))
            end
        end
        
        #display(vec(one))
        #println(maximum(abs.(one .- 1.0)))
    end
end

