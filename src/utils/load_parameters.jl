using DelimitedFiles

function checkregionorder(model::Model, regions, file)
    regionaliases = Dict{AbstractString, Vector{AbstractString}}("EU" => [],
                                                                 "USA" => ["US"],
                                                                 "OECD" => ["OT"],
                                                                 "Africa" => ["AF"],
                                                                 "China" => ["CA"],
                                                                 "SEAsia" => ["IA"],
                                                                 "LatAmerica" => ["LA"],
                                                                 "USSR" => ["EE"])

    for ii in 1:length(regions)
        region_keys = Mimi.dim_keys(model.md, :region)
        if region_keys[ii] != regions[ii] && !in(regions[ii], regionaliases[region_keys[ii]])
            error("Region indices in $file do not match expectations: $(region_keys[ii]) <> $(regions[ii]).")
        end
    end
end

function checktimeorder(model::Model, times, file)
    for ii in 1:length(times)
        if Mimi.time_labels(model)[ii] != times[ii]
            error("Time indices in $file do not match expectations: $(Mimi.time_labels(model)[ii]) <> $(times[ii]).")
        end
    end
end

function readpagedata(model::Union{Model, Nothing}, filepath::AbstractString)
    # Handle relative paths
    if filepath[1] ∉ ['.', '/'] && !isfile(filepath)
        filepath = joinpath(@__DIR__, "..", "..", filepath)
    end

    content = readlines(filepath)

    firstline = chomp(content[1])
    if firstline == "# Index: region"
        data = readdlm(filepath, ',', header=true, comments=true)

        if model != nothing
            # Check that regions are in the right order
            checkregionorder(model, data[1][:, 1], basename(filepath))
        end

        return convert(Vector{Float64},vec(data[1][:, 2]))
    elseif firstline == "# Index: time"
        data = readdlm(filepath, ',', header=true, comments=true)

        if model != nothing
            # Check that the times are in the right order
            checktimeorder(model, data[1][:, 1], basename(filepath))
        end

        return convert(Vector{Float64}, vec(data[1][:, 2]))
    elseif firstline == "# Index: time, region"
        data = readdlm(filepath, ',', header=true, comments = true)

        if model != nothing
            # Check that both dimension match
            checktimeorder(model, data[1][:, 1], basename(filepath))
            checkregionorder(model, data[2][2:end], basename(filepath))
        end

        return convert(Array{Float64}, data[1][:, 2:end])
    else
        error("Unknown header in parameter file $filepath.")
    end
end

function load_parameters(model::Model)
    parameters = Dict{Any, Any}()

    parameter_directory = joinpath(dirname(@__FILE__), "..", "..", "data")
    for file in filter(q->splitext(q)[2]==".csv", readdir(parameter_directory))
        parametername = splitext(file)[1]
        filepath = joinpath(parameter_directory, file)

        parameters[parametername] = readpagedata(model, filepath)
    end
    return parameters
end

# define a function to reset the master parameters
function reset_masterparameters()
    global modelspec_master = "RegionBayes" # "RegionBayes" (default), "Region", "Burke" or "PAGE09"
    global scen_master = "NDCs"             # "NDCs" (default), tbd
    global ge_master = 0.0                  # 0.0 (default), any other Float between 0 and 1
    global equiw_master = "Yes"             # "Yes" (default), "No", "DFC"
    global gdploss_master = "Excl"          # "Excl" (default), "Incl"
    global permafr_master = "Yes"           # "Yes" (default), "No"
    global gedisc_master = "No"             # "No" (default), "Yes", "Only" (feeds only discontinuity impacts into growth rate)

    "All master parameters reset to defaults"
end
