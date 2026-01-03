
"""
This file defines methods to serialise and de-serialise data structures.

We serialise an object into an ordered dictionary of the general form

    typename : TypeName
    constructor : function_name
    field_name_1 : field_value_1
    ...
    field_name_n : field_value_n

Dictionary keys are strings, dictionary values are strings, numbers o
ordered dictionaries of component structures.

We utilise multiple dispatch to specify serialisation recursively.
"""

"""
A regular expression to match the type name with type parameters.

We match, e.g.,
 - DiffFusion.ZeroCurve,
 - DiffFusion.ZeroCurve{Float64},
 - Array{Float64, 3}
"""
const _type_pattern = r"\A(DiffFusion\.|)([A-Za-z]+)(\{.+\})?\Z"


"""
    _type_name_long(o::Any)

Return type name as string with "DiffFusion....".
"""
function _type_name_long(o::Any)
    s = string(typeof(o))
    m = match(_type_pattern, s)
    @assert !isnothing(m) && length(m) == 3
    return m[1] * m[2]
end

"""
    _type_name_short(o::Any)

Return type name as string without "DiffFusion....".
"""
function _type_name_short(o::Any)
    s = string(typeof(o))
    m = match(_type_pattern, s)
    @assert !isnothing(m) && length(m) == 3
    return m[2]
end

"""
    serialise_struct(o::Any)

Create a dictionary from an arbitrary struct object
"""
function serialise_struct(o::Any)
    @assert isstructtype(typeof(o))
    d = OrderedDict{String, Any}()
    d["typename"] = _type_name_long(o)
    d["constructor"] = _type_name_short(o)
    for name in propertynames(o)
        d[string(name)] = serialise(getfield(o, name))
    end
    return d
end

"Identifyiers used to specify a reference for serialisation."
const _serialise_key_references = ("{", "}")

"""
    serialise_key(alias::String)

Serialise an alias as a key.

This is required to capture object dependencies for de-serialisation. 
"""
function serialise_key(alias::String)
    return _serialise_key_references[1] * alias * _serialise_key_references[2]
    # return alias
end


"""
    serialise(o::Any)

Serialise an arbitrary object.
"""
function serialise(o::Any)
    if !isstructtype(typeof(o))
        error("Method serialise needs to be implemented for non-struct type.")
    end
    return serialise_struct(o)
end

"""
    serialise(o::Future)

Serialise a Future object from a `remotecall(...)`.

This operation is blocking. We require that the result is calculated such that
it actually can be serialised.
"""
serialise(o::Future) = serialise(fetch(o))

"""
    serialise(o::Nothing)

Serialise Nothing.
"""
serialise(o::Nothing) = string(o)

"""
    serialise(o::AbstractString)

Serialise String.
"""
serialise(o::AbstractString) = string(o)

"""
    serialise(o::Integer)

Serialise Integer.
"""
serialise(o::Integer) = Int(o)

"""
    serialise(o::ModelValue)

Serialise Float.
"""
serialise(o::ModelValue) = Float64(o)

"""
    serialise(o::Function)

Serialise a Function object.

Note, the result is not directly de-serialisable. Set key/value in dictionary.
"""
serialise(o::Function) = serialise_key(string(o))

"""
    serialise(o::AbstractDict)

Serialise dictionaries.
"""
function serialise(o::AbstractDict)
    d = OrderedDict{String, Any}()
    for key in keys(o)
        d[string(key)] = serialise(o[key])
    end
    return d
end



"""
    deserialise(o::String, d::Union{AbstractDict, Nothing} = nothing)

De-serialise strings.

We incorporate some logic to handle external references.

We allow that the repository disctionary `d` contains remote call
`Futures`. However, we want to ensure that the method returns actual
objects. Thus, we `fetch` any `Future` within this method.
"""
function deserialise(o::String, d::Union{AbstractDict, Nothing} = nothing)
    if o == "nothing"
        return nothing
    end
    n_first = length(_serialise_key_references[1])
    n_last = length(_serialise_key_references[2])
    if (length(o) >= n_first + n_last) &&
        (first(o, n_first) == _serialise_key_references[1]) &&
        (last(o, n_last) == _serialise_key_references[2])
        # we found a key
        dict_key = o[begin+n_first:end-n_last]
        @assert !isnothing(d)
        @assert haskey(d, dict_key)
        obj = d[dict_key]
        if isa(obj, Future)
            return fetch(obj)
        end
        return obj
    end
    return o
end

"""
    deserialise(o::Number, d::Union{AbstractDict, Nothing} = nothing)

De-serialise numbers.
"""
deserialise(o::Number, d::Union{AbstractDict, Nothing} = nothing) = o


"""
    deserialise(o::AbstractDict, d::Union{AbstractDict, Nothing} = nothing)

De-serialise dictionary.
"""
function deserialise(o::AbstractDict, d::Union{AbstractDict, Nothing} = nothing)
    if haskey(o, "typename")
        return deserialise_object(o, d)
    end
    return Dict(((key, deserialise(o[key], d)) for key in keys(o)))
end


"""
    deserialise_object(o::OrderedDict, d::Union{AbstractDict, Nothing} = nothing)

De-serialise objects.

Caution, this method bares the potential risk of code injection.
"""
function deserialise_object(o::OrderedDict, d::Union{AbstractDict, Nothing} = nothing)
    @assert haskey(o, "typename")
    @assert haskey(o, "constructor")
    func_name = o["constructor"]
    @assert isa(func_name, AbstractString)
    @assert func_name in _eligible_func_names
    #
    func = eval(Meta.parse(func_name))
    arg_dict = OrderedDict(o)
    delete!(arg_dict, "typename")
    delete!(arg_dict, "constructor")
    kwargs = ()
    if haskey(arg_dict, "kwargs")
        kwarg_dict = arg_dict["kwargs"]
        @assert isa(kwarg_dict, AbstractDict)
        symbols = (Symbol(key) for key in keys(kwarg_dict))
        kwargs = ( s => deserialise(v, d) for (s,v) in zip(symbols, values(kwarg_dict)) )
        delete!(arg_dict, "kwargs")
    end
    args = ( deserialise(arg_dict[key], d) for key in keys(arg_dict) )
    obj = func(args...; kwargs...)
    #
    type_name_full = o["typename"]  # should be DiffFusion.[some type]
    @assert !isnothing(match(_type_pattern, type_name_full))
    obj_type = eval(Meta.parse(type_name_full))
    @assert isa(obj, obj_type)
    #
    return obj
end

"""
    deserialise_from_list(dict_list::AbstractVector)

De-serialise a list of objects and capture references.
"""
function deserialise_from_list(dict_list::AbstractVector)
    obj_dict = OrderedDict{String, Any}()
    for d in dict_list
        obj = deserialise(d, obj_dict)
        @assert hasproperty(obj, :alias) || haskey(obj, "alias")
        if hasproperty(obj, :alias)
            obj_dict[obj.alias] = obj
        else
            obj_dict[obj["alias"]] = obj
        end
    end
    return obj_dict
end
