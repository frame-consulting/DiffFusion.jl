
"A list of example models and instrument specifications."
examples = [
    "g3_1factor_flat",
    "g3_1factor_ts",
    "g3_3factor_ts",
    "g3_3factor_real_world",
]

"""
    load(name::String)

Return a list of dictionaries representing a DiffFusion example.

Example details can be modified by changing the dictionary entries.
"""
function load(name::String)
    file_name = joinpath(_yaml_path, name * ".yaml")
    dict_list = YAML.load_file(file_name; dicttype=OrderedDict{String,Any})
    return dict_list
end


"""
    build(dict_list::Vector{OrderedDict{String, Any}})

Return a dictionary of objects and configurations representing a
DiffFusion example.

The resulting dictionary is supposed to be queried and amended by
methods operating on examples.
"""
function build(dict_list::Vector{OrderedDict{String, Any}})
    example = DiffFusion.deserialise_from_list(dict_list)
    return example
end

"""
Return the first object of a given type from an example dictionary.
"""
function get_object(example::OrderedDict{String,Any}, obj_type)
    for value in values(example)
        if isa(value, obj_type)
            return value
        end
    end
    error("Example does not contain " * string(obj_type) * ".")
end

