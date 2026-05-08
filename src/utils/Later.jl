
"""
    later(seconds, f, args)

Delayed call of a function `f` with arguments `arg`.

We use this function to mimic long-running calculations in
down-stream application development and testing.
"""
function later(seconds, f, args)
    sleep(seconds)
    return f(args...)
end

"""
    later(seconds)

Sleep for `seconds` seconds.
"""
function later(seconds)
    return sleep(seconds)
end
