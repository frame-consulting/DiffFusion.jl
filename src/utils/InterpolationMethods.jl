
"""
Specify names for available interpolation methods.
"""
const interpolation_methods = Dict{String, Function}(
    "LINEAR" => (x,y) -> linear_interpolation(x, y, extrapolation_bc = Line()),
    "CUBIC" => (x,y) -> extrapolate(
        interpolate(x, y, FiniteDifferenceMonotonicInterpolation()),
        Line(),
    ),
    "AKIMA" => (x,y) -> extrapolate(
        interpolate(x, y, AkimaMonotonicInterpolation()),
        Line(),
    ),
    "FRITSCHCARLSON" => (x,y) -> extrapolate(
        interpolate(x, y, FritschCarlsonMonotonicInterpolation()),
        Line(),
    ),
    "FRITSCHBUTLAND" => (x,y) -> extrapolate(
        interpolate(x, y, FritschButlandMonotonicInterpolation()),
        Line(),
    ),
    "STEFFEN" => (x,y) -> extrapolate(
        interpolate(x, y, SteffenMonotonicInterpolation()),
        Line(),
    ),
)
