using DiffFusion
using StatsBase
using Test

@testset "Gradient calculation." begin

    @testset "Zero bond calculation" begin
        # reference calculation
        times  = [1.0, 3.0, 6.0, 10.0]
        values = [1.0, 1.0, 1.0,  1.0] .* 1e-2
        yts = DiffFusion.linear_zero_curve("Std", times, values)
        #
        delta = DiffFusion.flat_parameter("Std", [ 1., 7., 15. ])
        chi = DiffFusion.flat_parameter("Std", [ 0.01, 0.10, 0.30 ])
        times =  [ 1., 2., 5., 10. ]
        values = [ 50. 60. 70. 80.;
                   60. 70. 80. 90.;
                   70. 80. 90. 90.] * 1.0e-4
        sigma_f = DiffFusion.backward_flat_volatility("Std",times,values)
        #
        ch = DiffFusion.correlation_holder("Std")
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_2", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_2", "Std_f_3", 0.80)
        DiffFusion.set_correlation!(ch, "Std_f_1", "Std_f_3", 0.50)
        #
        m = DiffFusion.gaussian_hjm_model("Std",delta,chi,sigma_f,ch,nothing)
        #
        SX = DiffFusion.model_state(zeros(4,1) .+ 0.01, m)
        #
        zb = DiffFusion.zero_bonds(yts, m, 1.0, [5.0], SX)[1,1]
        # println(zb)
        
        # argument setup for gradient calculation
        arg_x = vcat(
            [1.0, 1.0, 1.0,  1.0] .* 1e-2,  # yts
            [ 0.01, 0.10, 0.30 ],           # chi
            reshape(
                [ 50. 60. 70. 80.;
                  60. 70. 80. 90.;
                  70. 80. 90. 90.] * 1.0e-4,
                (12,)),                     # sigma_f
            [ 0.80, 0.80, 0.50 ],           # ch
        )
        
        obj_function(arg_x::AbstractVector) = begin
            times_  = [1.0, 3.0, 6.0, 10.0]
            yts_ = DiffFusion.linear_zero_curve("Std", times_, arg_x[1:4])
            #
            delta_ = DiffFusion.flat_parameter("Std", [ 1., 7., 15. ])
            chi_ = DiffFusion.flat_parameter("Std", arg_x[5:7])
            times_ =  [ 1., 2., 5., 10. ]
            sigma_f_ = DiffFusion.backward_flat_volatility("Std", times_, reshape(arg_x[8:19], (3,4)))
            #
            ch_ = DiffFusion.correlation_holder("Std", "<>", typeof(arg_x[20]))
            DiffFusion.set_correlation!(ch_, "Std_f_1", "Std_f_2", arg_x[20])
            DiffFusion.set_correlation!(ch_, "Std_f_2", "Std_f_3", arg_x[21])
            DiffFusion.set_correlation!(ch_, "Std_f_1", "Std_f_3", arg_x[22])
            #
            m_ = DiffFusion.gaussian_hjm_model("Std", delta_, chi_, sigma_f_, ch_, nothing)
            #
            SX_ = DiffFusion.model_state(zeros(4,1) .+ 0.01, m_)
            #
            return DiffFusion.zero_bonds(yts_, m_, 1.0, [5.0], SX_)[1,1]
        end

        @test zb == obj_function(arg_x)

        (v1, g1) = DiffFusion._function_value_and_gradient(obj_function, arg_x, DiffFusion.ForwardDiff)
        (v2, g2) = DiffFusion._function_value_and_gradient(obj_function, arg_x, DiffFusion.Zygote)
        (v3, g3) = DiffFusion._function_value_and_gradient(obj_function, arg_x, DiffFusion.FiniteDifferences)

        @test v1 == zb
        @test v2 == zb
        @test v3 == zb
        
        @test isapprox(g1, g2, atol=1.0e-14)
        @test isapprox(g2, g3, atol=1.0e-10)

        #println(g1)
        #println(g2)
        #println(g3)
    end


    @testset "Regression calibration" begin
        
        f(x, y, a1, a2, b1, b2, ab, c) = a1.*x .+ a2.*x.^2 .+ b1.*y .+ b2.*y.^2 .+ ab.*x.*y .+ c 
        Z = rand(100, 5)

        p = [ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 ]

        obj_function(p) = begin
            O = f(Z[:,1], Z[:,2], p...) + Z[:,3]
            R = DiffFusion.polynomial_regression(Z[:,1:2]', O, 2)
            Y = DiffFusion.predict(R, Z[:,3:4]')
            return mean(Y)
        end

        y = obj_function(p)

        (v1, g1) = DiffFusion._function_value_and_gradient(obj_function, p, DiffFusion.ForwardDiff)
        (v2, g2) = DiffFusion._function_value_and_gradient(obj_function, p, DiffFusion.Zygote)
        (v3, g3) = DiffFusion._function_value_and_gradient(obj_function, p, DiffFusion.FiniteDifferences)

        @test v1 == y
        @test v2 == y
        @test v3 == y
        
        @test isapprox(g1, g2, atol=1.0e-14)
        @test isapprox(g2, g3, atol=1.0e-10)

        #println(y)
        #println(v2)
        #println(g2)

    end


    @testset "AMC payoff" begin
        ch = DiffFusion.correlation_holder("")
        δ = DiffFusion.flat_parameter([ 0., ])
        χ = DiffFusion.flat_parameter([ 0.01, ])

        times = [  1.,  2.,  5., 10. ]
        values = [ 50.,  50.,  50.,  50., ]' * 1.0e-4
        σ = DiffFusion.backward_flat_volatility("", times, values)

        model = DiffFusion.gaussian_hjm_model("md/EUR", δ, χ, σ, ch, nothing)

        # Simulation
        times = 0.0:0.25:10.0
        n_paths = 2^10
        sim = DiffFusion.simple_simulation(
            model,
            ch,
            times,
            n_paths,
            with_progress_bar = true,
            brownian_increments = DiffFusion.sobol_brownian_increments,
        )

        # Path

        yc_estr = DiffFusion.linear_zero_curve(
            "yc/EUR:ESTR",
            [1.0, 3.0, 6.0, 10.0],
            [1.0, 1.0, 1.0,  1.0] .* 1e-2,
        )
        yc_euribor6m = DiffFusion.linear_zero_curve(
            "yc/EUR:EURIBOR6M",
            [1.0, 3.0, 6.0, 10.0],
            [2.0, 2.0, 2.0,  2.0] .* 1e-2,
        )

        ts_list = [
            yc_estr,
            yc_euribor6m,
        ]

        _empty_key = DiffFusion._empty_context_key
        context = DiffFusion.Context(
            "Std",
            DiffFusion.NumeraireEntry("EUR", "md/EUR", Dict(_empty_key => "yc/EUR:ESTR")),
            Dict{String, DiffFusion.RatesEntry}([
                ("EUR", DiffFusion.RatesEntry("EUR", "md/EUR", Dict(
                    _empty_key  => "yc/EUR:ESTR",
                    "ESTR"      => "yc/EUR:ESTR",
                    "EURIBOR6M" => "yc/EUR:EURIBOR6M",
                ))),
            ]),
            Dict{String, DiffFusion.AssetEntry}(),
            Dict{String, DiffFusion.ForwardIndexEntry}(),
            Dict{String, DiffFusion.FutureIndexEntry}(),
            Dict{String, DiffFusion.FixingEntry}(),
        )

        path = DiffFusion.path(sim, ts_list, context, DiffFusion.LinearPathInterpolation)

        L5 = DiffFusion.LiborRate(5.0, 5.0, 10.0, "EUR:EURIBOR6M")
        F0 = DiffFusion.Pay(DiffFusion.Fixed(0.0), 5.0)
        L2 = DiffFusion.LiborRate(2.0, 5.0, 10.0, "EUR:EURIBOR6M")

        A1 = DiffFusion.AmcMax(
            2.0,
            [ L5 ],
            [ F0 ],
            [ L2 ],
            nothing,
            nothing,
            "EUR",
        )

        A2 = DiffFusion.AmcSum(
            2.0,
            [ L5 ],
            [ L2 ],
            nothing,
            nothing,
            "EUR",
        )

        (v1, g1, ts_labels) = DiffFusion.model_price_and_deltas(
            [ A1, A2 ],
            path,
            nothing,
            nothing,
            DiffFusion.ForwardDiff
        )

        (v2, g2, ts_labels) = DiffFusion.model_price_and_deltas(
            [ A1, A2 ],
            path,
            nothing,
            nothing,
            DiffFusion.Zygote
        )

        (v3, g3, ts_labels) = DiffFusion.model_price_and_deltas(
            [ A1, A2 ],
            path,
            nothing,
            nothing,
            DiffFusion.FiniteDifferences
        )

        @test v1 == v2
        @test v2 == v3

        @test isapprox(g1, g2, atol=1.0e-14)
        @test isapprox(g2, g3, atol=1.0e-8)

        #println(v1)
        #println(g2)

    end

end