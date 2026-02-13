using DiffFusion
using Test

@testset "Methods for simulation-based implied vols." begin

    @info "Run implied_swaption_volatility.jl..."

    @testset "1F Gaussian model implied volatilities." begin

        serialised_example = DiffFusion.Examples.load("g3_1factor_flat")
        example = DiffFusion.Examples.build(serialised_example)
        example["config/simulation"]["n_paths"] = 2^13

        path = DiffFusion.Examples.path!(example)
        expiry_time = 2.0
        fixed_times = [ 2.0, 3.0, 4.0, 5.0 ]
        fixed_weights = [ 1.0, 1.0, 1.0 ]
        disc_key = "USD:SOFR"
        relative_strikes = [ -200.0, -100.0, -50.0, 0.0, 50.0, 100.0, 200.0 ] * 1e-4
        vols = DiffFusion.implied_swaption_volatilities(
            path,
            expiry_time,
            fixed_times,
            fixed_weights,
            disc_key,
            relative_strikes,
        )

        vols_ref = [
            0.006860516606132516,
            0.00704798192799966,
            0.007096794124866358,
            0.007163007937014269,
            0.0072216158597455,
            0.0072881006102977295,
            0.007428443760527222,
        ]
        @test isapprox(vols, vols, atol=1.0e-14)

        # alternative methods
        vols_1 = DiffFusion.implied_swaption_volatilities(
            path.sim,
            path.ts_dict["yc/USD:SOFR"],
            expiry_time,
            fixed_times,
            fixed_weights,
            relative_strikes,
        )
        @test vols_1 == vols

    end

    @testset "3F Gaussian model implied volatilities." begin

        serialised_example = DiffFusion.Examples.load("g3_3factor_real_world")
        example = DiffFusion.Examples.build(serialised_example)
        example["config/simulation"]["n_paths"] = 2^13

        path = DiffFusion.Examples.path!(example)
        expiry_time = 2.0
        fixed_times = [ 2.0, 3.0, 4.0, 5.0 ]
        fixed_weights = [ 1.0, 1.0, 1.0 ]
        disc_key = "EUR:ESTR"
        relative_strikes = [ -200.0, -100.0, -50.0, 0.0, 50.0, 100.0, 200.0 ] * 1e-4
        vols = DiffFusion.implied_swaption_volatilities(
            path,
            expiry_time,
            fixed_times,
            fixed_weights,
            disc_key,
            relative_strikes,
        )

        vols_ref = [
            0.008333955168774032,
            0.008404279757708442,
            0.00843744535461749,
            0.008449346557001223,
            0.008431340494923457,
            0.008422858717000726,
            0.008358806047859917,
        ]
        @test isapprox(vols, vols, atol=1.0e-14)

    end

    @testset "1F Quasi-Gaussian model implied volatilities." begin
        ch = DiffFusion.correlation_holder("Std")
        delta = DiffFusion.flat_parameter([ 1.,])
        chi = DiffFusion.flat_parameter([ 0.01,])
        sigma_f = DiffFusion.flat_volatility("EUR", 0.0050)
        quanto_model = nothing
        gaussian_model = DiffFusion.gaussian_hjm_model("EUR", delta, chi, sigma_f, ch, nothing)

        sigma_min = 1.0e-4
        sigma_max = 500. * 1.0e-4

        slope_d = DiffFusion.flat_parameter("Std", 0.25)
        slope_u = DiffFusion.flat_parameter("Std", 0.25)
        volatility_model = nothing
        volatility_function = nothing

        qg_model = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )

        #
        sim_times = 0.0:0.25:2.0
        n_paths = 2^13
        #
        sim = DiffFusion.quasi_gaussian_simulation(
            qg_model, ch, sim_times, n_paths, with_progress_bar = true, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        
        ctx = DiffFusion.simple_context("Std", ["EUR",])
        ts_list = [
            DiffFusion.flat_forward("EUR", 0.03)
        ]
        path = DiffFusion.path(sim, ts_list, ctx)

        expiry_time = 2.0
        fixed_times = [ 2.0, 3.0, 4.0, 5.0 ]
        fixed_weights = [ 1.0, 1.0, 1.0 ]
        disc_key = "EUR"
        relative_strikes = [ -200.0, -100.0, -50.0, 0.0, 50.0, 100.0, 200.0 ] * 1e-4
        vols = DiffFusion.implied_swaption_volatilities(
            path,
            expiry_time,
            fixed_times,
            fixed_weights,
            disc_key,
            relative_strikes,
        )
        # display(vols)

        vols_ref = [
            0.006955503258638896,
            0.006232424402828255,
            0.005831601615205481,
            0.005608048939146989,
            0.005815151102168668,
            0.006224471521744841,
            0.007062832134847158,
        ]
        @test isapprox(vols, vols, atol=1.0e-14)

    end

    @testset "3F Quasi-Gaussian model implied volatilities." begin

        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_2", 0.8)
        DiffFusion.set_correlation!(ch, "EUR_f_2", "EUR_f_3", 0.8)
        DiffFusion.set_correlation!(ch, "EUR_f_1", "EUR_f_3", 0.5)
        #
        delta = DiffFusion.flat_parameter([ 1., 7., 15. ])
        chi = DiffFusion.flat_parameter([ 0.01, 0.10, 0.30 ])
        times =  [ 1., 2., 5., 10. ]
        values = [ 50. 60. 70. 80.;
                   60. 70. 80. 90.;
                   70. 80. 90. 90.] * 1.0e-4 * 1.0
        sigma_f = DiffFusion.backward_flat_volatility("EUR", times, values)
        quanto_model = nothing

        gaussian_model = DiffFusion.gaussian_hjm_model("EUR", delta, chi, sigma_f, ch, nothing, DiffFusion.ForwardRateScaling)

        #
        slope_d_vals = [
            10. 10. 10. 10.;
            10. 10. 10. 10.;
            10. 10. 10. 10.
        ] * 1.0e-2 * (-1.0)
        #
        slope_u_vals = [
            10. 10. 10. 10.;
            10. 10. 10. 10.;
            10. 10. 10. 10.
        ] * 1.0e-2 * (1.0)
        #
        sigma_min = 1.0e-4
        sigma_max = 500. * 1.0e-4

        slope_d = DiffFusion.backward_flat_parameter("Std", times, slope_d_vals)
        slope_u = DiffFusion.backward_flat_parameter("Std", times, slope_u_vals)
        volatility_model = nothing
        volatility_function = nothing
        #
        qg_model = DiffFusion.quasi_gaussian_model(
            gaussian_model, slope_d, slope_u, sigma_min, sigma_max,
            volatility_model, volatility_function,
        )

        #
        sim_times = 0.0:0.25:2.0
        n_paths = 2^13
        #
        sim = DiffFusion.quasi_gaussian_simulation(
            qg_model, ch, sim_times, n_paths, with_progress_bar = true, # brownian_increments = DiffFusion.sobol_brownian_increments
        )
        
        ctx = DiffFusion.simple_context("Std", ["EUR",])
        ts_list = [
            DiffFusion.flat_forward("EUR", 0.03)
        ]
        path = DiffFusion.path(sim, ts_list, ctx)

        expiry_time = 2.0
        fixed_times = [ 0.0, 1.0, 2.0, 3.0 ] .+ expiry_time
        fixed_weights = [ 1.0, 1.0, 1.0 ]
        disc_key = "EUR"
        relative_strikes = [ -200.0, -100.0, -50.0, 0.0, 50.0, 100.0, 200.0 ] * 1e-4
        vols = DiffFusion.implied_swaption_volatilities(
            path,
            expiry_time,
            fixed_times,
            fixed_weights,
            disc_key,
            relative_strikes,
        )
        # display(vols)

        vols_ref = [
            0.005411808886445246,
            0.005770159408628805,
            0.006021651205788282,
            0.0062680545581249554,
            0.006500929957360227,
            0.00676790064304691,
            0.007409744254174504,
        ]
        @test isapprox(vols, vols, atol=1.0e-14)

    end

end
