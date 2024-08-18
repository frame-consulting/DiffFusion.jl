
"""
    black_scholes_vanilla_price(X, ϕ, S, DF_r, DF_b, ν)

Vanilla option pricing formula for calls and puts.

Notation:
  - X option strike
  - ϕ = 1 (call), -1 (put); option type
  - S underlying spot
  - DF_r = exp(-r T), r is (domestic) risk-free rate
  - DF_b = exp(-b T), b is *cost-of-carry*, i.e. b = r - q (see Haug, sec. 1.2.1)
  - ν = σ √T, σ option volatility, T time to option expiry.
"""
function black_scholes_vanilla_price(X, ϕ, S, DF_r, DF_b, ν)
    N(x) = cdf.(Normal(), x)
    F = S ./ DF_b
    d1 = log.(F ./ X) ./ ν .+ ν ./ 2
    d2 = d1 .- ν
    return DF_r .* ϕ .* (F .* N(ϕ .* d1) .- X .* N(ϕ .* d2))
end


"""
    black_scholes_barrier_price(X, H, K, η, χ, ϕ, S, DF_r, DF_b, σ, T)

Barrier option pricing formulas following Haug, "The Complete Guide to Option Pricing Formulas".

Notation:
  - r is (domestic) risk-free rate
  - b is *cost-of-carry*, see Haug, sec. 1.2.1:
      - b = r - q, where q is a continuous dividend yield,
      - b = r - rf, where rf is a foreign currency rate,
      - b = 0 for options on futures.
  - DF_r = exp(-r T)
  - DF_b = exp(-b T)

  - σ option volatility
  - T time to option expiry
  - ν = σ √T

  - S underlying spot
  - X option strike
  - H option barrier
  - K option rebate

  - η = 1 (down), -1 (up); barrier direction
  - χ = 1 (out), -1 (in); barrier type
  - ϕ = 1 (call), -1 (put); option type

"""
function black_scholes_barrier_price(X, H, K, η, χ, ϕ, S, DF_r, DF_b, σ, T)

    ν = σ * sqrt(T)
    if any(ν .<= 0.0)
        error("Intrinsic value not yet implemented.")
    end

    down = Int(η == 1)
    up = 1 - down
    out = Int(χ == 1)
    in = 1 - out
    
    barrier_hit = down .* (S .< H) + up .* (S .> H)  # OR of disjoint events
    barrier_hit_price = in .* black_scholes_vanilla_price(X, ϕ, S, DF_r, DF_b, ν) # + out * DF_r * K, for rebate at expiry
    
    N(x) = cdf.(Normal(), x)
    # scalar auxiliary variables
    r = -log.(DF_r) ./ T
    b = -log.(DF_b) ./ T
    μ = (b .- (σ.^2)/2)./(σ.^2)
    λ = sqrt.(max.(μ.^2 .+ 2 .* r ./ σ.^2, 0.0))
    α = (1 .+ μ) .* ν

    # common vector-valued input terms
    log_S_X = log.(S ./ X)
    log_S_H = log.(S ./ H)
    log_H_X = log.(H ./ X)
    x1 = log_S_X ./ ν .+ α                # -> A
    x2 = log_S_H ./ ν .+ α                # -> B, E
    y1 = (log_H_X .- log_S_H) ./ ν .+ α   # -> C
    y2 = -log_S_H ./ ν .+ α               # -> D, E
    z  = -log_S_H ./ ν .+ (λ .* ν)        # -> F

    # option component terms; TODO: move to where it is really needed and avoid unnecessary calculations
    A = ϕ .* S .* DF_r./DF_b                       .* N(ϕ .* x1) .- ϕ .* X .* DF_r                  .* N(ϕ .* x1 .- ϕ .* ν)
    B = ϕ .* S .* DF_r./DF_b                       .* N(ϕ .* x2) .- ϕ .* X .* DF_r                  .* N(ϕ .* x2 .- ϕ .* ν)
    C = ϕ .* S .* DF_r./DF_b .* (H./S).^(2*(μ.+1)) .* N(η .* y1) .- ϕ .* X .* DF_r .* (H./S).^(2*μ) .* N(η .* y1 .- η .* ν)
    D = ϕ .* S .* DF_r./DF_b .* (H./S).^(2*(μ.+1)) .* N(η .* y2) .- ϕ .* X .* DF_r .* (H./S).^(2*μ) .* N(η .* y2 .- η .* ν)
    #
    E = K .* DF_r .* (                  N(η .* x2 .- η .* ν) .- (H./S).^(2 .* μ) .* N(η .* y2           .- η .* ν))
    F = K         .* ((H./S).^(μ.+λ) .* N(η .* z)            .+ (H./S).^(μ .- λ) .* N(η .* z  .- 2 .* λ .* η .* ν))

    # if KO rebate is paid at expiry: λ -> μ
    z_T_e = -log_S_H ./ ν .+ (μ .* ν)  # -> F_T_e
    F_T_e = K .* ((H./S).^(2*μ)     .* N(η * z)              .+                     N(η .* z  .- 2 .* μ .* η .* ν))
    
    # For the no-hit case we need to distinguish 16 different cases.
    # We follow the ordering in Haug
    if χ == -1  # in-options
        if ϕ == 1  # call
            if η == 1  # DIC
                if X > H
                    no_hit_price = C
                else
                    no_hit_price = A .- B .+ D
                end
            else  # UIC
                if X > H
                    no_hit_price = A
                else
                    no_hit_price = B .- C .+ D
                end
            end
        else  # put
            if η == 1  # DIP
                if X > H
                    no_hit_price = B .- C .+ D
                else
                    no_hit_price = A
                end
            else  # UIP
                if X > H
                    no_hit_price = A .- B .+ D
                else
                    no_hit_price = C
                end
            end
        end
        # add rebate for in-options (if needed)
        no_hit_price = no_hit_price .+ E
    else  # out-options
        if ϕ == 1  # call
            if η == 1  # DOC
                if X > H
                    no_hit_price = A .- C
                else
                    no_hit_price = B .- D
                end
            else  # UOC
                if X > H
                    no_hit_price = 0 .* S  # beware dimensions
                else
                    no_hit_price = A - B + C - D
                end
            end
        else  # put
            if η == 1  # DOP
                if X > H
                    no_hit_price = A .- B .+ C .- D
                else
                    no_hit_price = 0 .* S  # beware dimensions
                end
            else  # UOP
                if X > H
                    no_hit_price = B .- D
                else
                    no_hit_price = A .- C
                end
            end
        end
        # add rebate (at KO-time) for out-options (if needed)
        no_hit_price = no_hit_price .+ F
    end
    
    return barrier_hit .* barrier_hit_price + (1.0 .- barrier_hit) .* no_hit_price
end

"""
    black_scholes_barrier_price(X, H, K, option_type::String, S, DF_r, DF_b, σ, T)

Barrier option pricing formulas following Haug.

String `option_type` is of the form

    [D|U][O|I][C|P]

"""
function black_scholes_barrier_price(X, H, K, option_type::String, S, DF_r, DF_b, σ, T)
    @assert length(option_type) == 3
    o_type = uppercase(option_type)
    @assert o_type[1] in ('D', 'U')
    @assert o_type[2] in ('O', 'I')
    @assert o_type[3] in ('C', 'P')
    if o_type[1] == 'D'
        η = 1
    else
        η = -1
    end
    if o_type[2] == 'O'
        χ = 1
    else
        χ = -1
    end
    if o_type[3] == 'C'
        ϕ = 1
    else
        ϕ = -1
    end
    return black_scholes_barrier_price(X, H, K, η, χ, ϕ, S, DF_r, DF_b, σ, T)
end
