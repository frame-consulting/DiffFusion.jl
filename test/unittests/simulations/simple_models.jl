
using DiffFusion
using SparseArrays
using StatsBase
using Test

@testset "SimpleModel simulation" begin

    include("../test_tolerances.jl")
    abs_tol = test_tolerances["simulations/simple_models.jl"]
    @info "Run simulation test with tolerance abs_tol=" * string(abs_tol) * "."

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
        sigma_f_dom = DiffFusion.backward_flat_volatility("USD",times_dom,values_dom)
        hjm_model_dom = DiffFusion.gaussian_hjm_model("USD",delta_dom,chi_dom,sigma_f_dom,ch,nothing)
    
        delta_for = DiffFusion.flat_parameter([ 1., 10. ])
        chi_for = DiffFusion.flat_parameter([ 0.01, 0.15 ])
        times_for =  [ 0. ]
        values_for = [ 80. 90. ]' * 1.0e-4
        sigma_f_for = DiffFusion.backward_flat_volatility("EUR",times_for,values_for)
        hjm_model_for = DiffFusion.gaussian_hjm_model("EUR",delta_for,chi_for,sigma_f_for,ch,fx_model)

        return [ hjm_model_dom, fx_model, hjm_model_for, eq_model ]
    end

    @testset "Simple simulation, no correlation" begin
        models = setup_models(ch_one)
        m = DiffFusion.simple_model("Std", models)
        full_state_alias = [
            "USD_x_1", "USD_x_2", "USD_x_3", "USD_s",  # 1 ... 4
            "EUR-USD_x",                               # 5
            "EUR_x_1", "EUR_x_2", "EUR_s",             # 6 ... 8
            "SXE50_x",                                 # 9
        ]
        @test DiffFusion.state_alias(m) == full_state_alias
        times = 0.0:2.0:10.0
        n_paths = 2^13
        sim = DiffFusion.simple_simulation(m, ch_one, times, n_paths, with_progress_bar = false)
        # println(size(sim.X))
        @test size(sim.X) == (9,8192,6)
        # martingale test domestic numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 1.000074124385906,  atol=abs_tol)
        @test isapprox(one[3], 1.000117511339956,  atol=abs_tol)
        @test isapprox(one[4], 1.0002124517141107, atol=abs_tol)
        @test isapprox(one[5], 1.0006167705643887, atol=abs_tol)
        @test isapprox(one[6], 1.0004471131886592, atol=abs_tol)
        #
        # martingale test for domestic zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(models[1], t, t+dt)
                y = DiffFusion.func_y(models[1], t)
                x = sim.X[1:3,:,k]
                s = sim.X[4:4,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s))
                # println(abs(one-1))
                @test isapprox(one, 1.0, atol=4.3e-3)
            end
        end
        # martingale test for fx rate
        one = mean(exp.(sim.X[5,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9994159450453675, atol=abs_tol)
        @test isapprox(one[3], 0.9989116056873114, atol=abs_tol)
        @test isapprox(one[4], 0.9986757418538581, atol=abs_tol)
        @test isapprox(one[5], 0.9977927081254931, atol=abs_tol)
        @test isapprox(one[6], 0.9967224122451686, atol=abs_tol)
        #
        # martingale test for foreign numeraire - effectively no quanto impact due to zero correlation
        one = mean(exp.(-sim.X[8,:,:] + sim.X[5,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9991827395906183, atol=abs_tol)
        @test isapprox(one[3], 0.9984419400807558, atol=abs_tol)
        @test isapprox(one[4], 0.9979564966194745, atol=abs_tol)
        @test isapprox(one[5], 0.9968802858212116, atol=abs_tol)
        @test isapprox(one[6], 0.9956927821419111, atol=abs_tol)
        #
        # martingale test for foreign zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(models[3], t, t+dt)
                y = DiffFusion.func_y(models[3], t)
                x = sim.X[6:7,:,k]
                s = sim.X[8:8,:,k]
                fx = sim.X[5:5,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s + fx))
                # println(abs(one-1))
                @test isapprox(one, 1.0, atol=7.9e-3)
            end
        end
        #
        # martingale test for foreign equity
        one = mean(exp.(sim.X[9,:,:] + sim.X[5,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9993874194203978, atol=abs_tol)
        @test isapprox(one[3], 0.9973114567580126, atol=abs_tol)
        @test isapprox(one[4], 0.9974130364132837, atol=abs_tol)
        @test isapprox(one[5], 0.9993085827312518, atol=abs_tol)
        @test isapprox(one[6], 0.9992173330301211, atol=abs_tol)
    end


    @testset "Simple simulation, full correlation" begin
        models = setup_models(ch_full)
        m = DiffFusion.simple_model("Std", models)
        full_state_alias = [
            "USD_x_1", "USD_x_2", "USD_x_3", "USD_s",  # 1 ... 4
            "EUR-USD_x",                               # 5
            "EUR_x_1", "EUR_x_2", "EUR_s",             # 6 ... 8
            "SXE50_x",                                 # 9
        ]
        @test DiffFusion.state_alias(m) == full_state_alias
        times = 0.0:2.0:10.0
        n_paths = 2^13
        sim = DiffFusion.simple_simulation(m, ch_full, times, n_paths, with_progress_bar = false)
        # println(size(sim.X))
        @test isnothing(sim.dZ)
        @test size(sim.X) == (9,8192,6)
        # martingale test domestic numeraire
        one = mean(exp.(-sim.X[4,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 1.0000518810953414, atol=abs_tol)
        @test isapprox(one[3], 1.0000972102091612, atol=abs_tol)
        @test isapprox(one[4], 1.0002542603911526, atol=abs_tol)
        @test isapprox(one[5], 1.0005518649082878, atol=abs_tol)
        @test isapprox(one[6], 1.0002827258273377, atol=abs_tol)
        #
        # martingale test for domestic zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(models[1], t, t+dt)
                y = DiffFusion.func_y(models[1], t)
                x = sim.X[1:3,:,k]
                s = sim.X[4:4,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s))
                # println(abs(one-1))
                @test isapprox(one, 1.0, atol=3.5e-3)
            end
        end
        # martingale test for fx rate
        one = mean(exp.(sim.X[5,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9997168869387103, atol=abs_tol)
        @test isapprox(one[3], 0.9996821790938175, atol=abs_tol)
        @test isapprox(one[4], 0.9995771790608567, atol=abs_tol)
        @test isapprox(one[5], 0.9981347470531878, atol=abs_tol)
        @test isapprox(one[6], 0.9959371944761019, atol=abs_tol)
        #
        # martingale test for foreign numeraire
        one = mean(exp.(-sim.X[8,:,:] + sim.X[5,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9997397411755645, atol=abs_tol)
        @test isapprox(one[3], 0.9998509371487277, atol=abs_tol)
        @test isapprox(one[4], 0.999748796991814,  atol=abs_tol)
        @test isapprox(one[5], 0.9982686259703222, atol=abs_tol)
        @test isapprox(one[6], 0.9962259507484493, atol=abs_tol)
        #
        # martingale test for foreign zero bonds
        dt_ = [ 0.0, 1.0, 2.0, 5.0, 10.0 ]
        for (k, t) in enumerate(sim.times)
            for dt in dt_
                G = DiffFusion.G_hjm(models[3], t, t+dt)
                y = DiffFusion.func_y(models[3], t)
                x = sim.X[6:7,:,k]
                s = sim.X[8:8,:,k]
                fx = sim.X[5:5,:,k]
                one = mean(exp.(-G'*x .- 0.5*G'*y*G - s + fx))
                # println(abs(one-1))
                @test isapprox(one, 1.0, atol=4.8e-3)
            end
        end
        #
        # martingale test for foreign equity
        one = mean(exp.(sim.X[9,:,:] + sim.X[5,:,:]), dims=1)
        # [ println(abs(o)) for o in one ]
        @test one[1] == 1.0
        @test isapprox(one[2], 0.9991296495267097, atol=abs_tol)
        @test isapprox(one[3], 0.9978222843629395, atol=abs_tol)
        @test isapprox(one[4], 0.9967937694265642, atol=abs_tol)
        @test isapprox(one[5], 0.9976008565308596, atol=abs_tol)
        @test isapprox(one[6], 0.9947929666530295, atol=abs_tol)
        #
        # store Brownian increments
        sim_w_dZ = DiffFusion.simple_simulation(m, ch_full, times, n_paths,
            with_progress_bar = false, store_brownian_increments = true)
        @test !isnothing(sim_w_dZ.dZ)
        @test size(sim_w_dZ.dZ) == (9,8192,5)
        @test sim_w_dZ.X == sim.X
    end

end