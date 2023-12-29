
"""
    struct Numeraire <: Leaf
        obs_time::ModelTime
        curve_key::String
    end

The price of our numeraire asset price *N(t)* at observation time *t*.

Typically, this coincides with the bank account price in numeraire
(i.e. domestic) currency.
"""
struct Numeraire <: Leaf
    obs_time::ModelTime
    curve_key::String
end

"""
    at(p::Numeraire, path::AbstractPath)

Derive the numeraire price at a given path.
"""
at(p::Numeraire, path::AbstractPath) = numeraire(path, p.obs_time, p.curve_key)

"""
    string(p::Numeraire)

Formatted (and shortened) output for Numeraire payoff.
"""
string(p::Numeraire) = @sprintf("N(%s, %.2f)", p.curve_key, p.obs_time)


"""
    struct BankAccount <: Leaf
        obs_time::ModelTime
        key::String
    end

The price of a continuous compounded bank account *B(t)* at observation
time *t* and with unit notional at inception.
"""
struct BankAccount <: Leaf
    obs_time::ModelTime
    key::String
end

"""
    at(p::BankAccount, path::AbstractPath)

Derive the bank account price at a given path.
"""
at(p::BankAccount, path::AbstractPath) = bank_account(path, p.obs_time, p.key)

"""
    string(p::BankAccount)

Formatted (and shortened) output for BankAccount payoff.
"""
string(p::BankAccount) = @sprintf("B(%s, %.2f)", p.key, p.obs_time)


"""
    struct ZeroBond <: Leaf
        obs_time::ModelTime
        maturity_time::ModelTime
        key::String
    end

The price of a zero coupon bond *P(t,T)* with observation time *t* and
bond maturity time *T*.
"""
struct ZeroBond <: Leaf
    obs_time::ModelTime
    maturity_time::ModelTime
    key::String
end

"""
    at(p::ZeroBond, path::AbstractPath)

Derive the zero bond price at a given path.
"""
at(p::ZeroBond, path::AbstractPath) = zero_bond(path, p.obs_time, p.maturity_time, p.key)

"""
    string(p::ZeroBond)

Formatted (and shortened) output for ZeroBond payoff.
"""
string(p::ZeroBond) = @sprintf("P(%s, %.2f, %.2f)", p.key, p.obs_time, p.maturity_time)


"""
    struct Asset <: Leaf
        obs_time::ModelTime
        key::String
    end

The price of a tradeable asset *S(t)* at observation time *t*.

A tradeable asset is typically an FX rate, equity/index price or spot
inflation index.
"""
struct Asset <: Leaf
    obs_time::ModelTime
    key::String
end

"""
    at(p::Asset, path::AbstractPath)

Derive the asset price at a given path.
"""
at(p::Asset, path::AbstractPath) = asset(path, p.obs_time, p.key)

"""
    string(p::Asset)

Formatted (and shortened) output for Asset payoff.
"""
string(p::Asset) = @sprintf("S(%s, %.2f)", p.key, p.obs_time)


"""
    struct ForwardAsset <: Leaf
        obs_time::ModelTime
        maturity_time::ModelTime
        key::String
    end

The forward price *E_t[S(T)]* of a tradeable asset *S* at observation
time *t* and with maturity time *T*. Expectation is calculated in
T-forward measure.
"""
struct ForwardAsset <: Leaf
    obs_time::ModelTime
    maturity_time::ModelTime
    key::String
end

"""
    at(p::ForwardAsset, path::AbstractPath)

Derive the asset price at a given path.
"""
at(p::ForwardAsset, path::AbstractPath) = forward_asset(path, p.obs_time, p.maturity_time, p.key)

"""
    string(p::ForwardAsset)

Formatted (and shortened) output for ForwardAsset payoff.
"""
string(p::ForwardAsset) = @sprintf("S(%s, %.2f, %.2f)", p.key, p.obs_time, p.maturity_time)


"""
    struct Fixing <: Leaf
        obs_time::ModelTime
        key::String
    end

The value of an index fixing *Idx(t)* at observation time *t*.

The value is obtained from a term structure linked to the path.
"""
struct Fixing <: Leaf
    obs_time::ModelTime
    key::String
end

"""
    at(p::Fixing, path::AbstractPath)

Derive the fixing value at a given path.
"""
at(p::Fixing, path::AbstractPath) = fixing(path, p.obs_time, p.key)

"""
    string(p::Fixing)

Formatted (and shortened) output for Fixing payoff.
"""
string(p::Fixing) = @sprintf("Idx(%s, %.2f)", p.key, p.obs_time)


"""
    struct Fixed <: Leaf
        value::ModelValue
    end

A deterministic quantity.
"""
struct Fixed <: Leaf
    value::ModelValue
end

"""
    obs_time(p::Fixed)

Observation time for Fixed payoffs is zero because they are
deterministic.
"""
obs_time(p::Fixed) = 0.0

"""
    at(p::Fixed, path::AbstractPath)

Return the deterministic value broadcasted to the length of the path.
"""
at(p::Fixed, path::AbstractPath) = p.value * ones(length(path))

"""
    string(p::Fixed)

Formatted (and shortened) output for deterministic payoff.
"""
string(p::Fixed) = @sprintf("%.4f", p.value)


"""
    struct ScalarValue <: Leaf
        value::ModelValue
    end

A scalar deterministic quantity.
"""
struct ScalarValue <: Leaf
    value::ModelValue
end

"""
    obs_time(p::ScalarValue)

Observation time for ScalarValue payoffs is zero because they are
deterministic.
"""
obs_time(p::ScalarValue) = 0.0

"""
    at(p::ScalarValue, path::AbstractPath)

Return the deterministic scalar value.

This aims at avoiding some unnecessary allocations.
"""
at(p::ScalarValue, path::AbstractPath) = p.value

"""
    string(p::ScalarValue)

Formatted (and shortened) output for deterministic payoff.
"""
string(p::ScalarValue) = @sprintf("%.4f", p.value)

