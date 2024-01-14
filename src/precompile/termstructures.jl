
# yield term structures

ts = flat_forward(0.03); alias(ts); ts(0.0)
ts = zero_curve([0.0, 1.0,], [1.0, 1.0,]); alias(ts); ts(0.0)
ts = zero_curve([0.0, 1.0,], [1.0, 1.0,], "LINEAR"); alias(ts); ts(0.0)
ts = linear_zero_curve([0.0, 1.0,], [1.0, 1.0,]); alias(ts); ts(0.0)

# parameter term structures

flat_parameter(0.0)

ts = backward_flat_parameter("", [0.0, 1.0,], [1.0, 1.0,]); alias(ts); ts(0.0)
ts = forward_flat_parameter("", [0.0, 1.0,], [1.0, 1.0,]); alias(ts); ts(0.0)

# volatility term structures

flat_volatility(0.0)

ts = backward_flat_volatility("", [0.0, 1.0,], [1.0, 1.0,]); alias(ts); ts(0.0)

# credit spread term structures

ts = flat_spread_curve(0.0); alias(ts); ts(0.0)
ts = survival_curve("", [0.0, 1.0,], [1.0, 1.0,]); alias(ts); ts(0.0)

# correlation term structure

ch = correlation_holder("")
set_correlation!(ch, "A", "B", 0.50)
ch = correlation_holder("", ch.correlations)
ch("A", "B")
ch(["A"], ["B"])
ch(["A", "B"])
