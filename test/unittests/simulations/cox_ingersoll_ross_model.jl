
using DiffFusion
using StatsBase
using Test

@testset "Credit model simulation." begin

    @testset "Single model simulation." begin
        z0 = 0.01
        chi = 0.05
        theta = 0.03
        sigma = 0.07
        cir_model = DiffFusion.cox_ingersoll_ross_model("CRD", z0, chi, theta, sigma)
        #
        ch = DiffFusion.correlation_holder("Std")
        times = 0.0:1.0:10.0
        n_paths = 2^10
        sim = DiffFusion.diagonal_simulation(cir_model, ch, times, n_paths,
            with_progress_bar = false,
            brownian_increments = DiffFusion.sobol_brownian_increments,
            )
        #display(size(sim.X))
        z = z0 * exp.(sim.X)
        Ez = vec(mean(z, dims = 2))
        Σz = vec(std(z, dims = 2)) ./ max.(sqrt.(times), 1.0e-8)
        #display(Ez)
        #display(Σz)
        #
        M = [
            DiffFusion.cir_moments(cir_model, z0, 0.0, t)
            for t in times
        ]
        Ez_ref = [ m[1] for m in M ]
        Σz_ref = [ sqrt(m[2]) for m in M ] ./ max.(sqrt.(times), 1.0e-8)
        @test isapprox(Ez, Ez_ref, atol=1.0e-8, rtol=1.0e-3)
        @test isapprox(Σz, Σz_ref, atol=1.0e-8, rtol=1.2e-2)
        #display(Ez ./ Ez_ref .- 1.0)        
        #display(Σz ./ Σz_ref .- 1.0)
        #display(Σz * 1.e4)
    end

end
