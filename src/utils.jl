function string_to_symbol_array(string_array)
# This function converts an Array{String, 1}
# into an Array{Symbol, 1}.

    out = Array{Symbol, 1}()

    for i in 1:length(string_array)

        push!(out, Symbol(string_array[i]))

    end

    return  out
end

function to_df(raw_data)
# This function takes 2 Arrays
# and constructs a DataFrame.

    if typeof(raw_data) <: Tuple
        df = DataFrame(raw_data[1], raw_data[2])
    end
    return df

end

function datasets()
# This function returns all data
# file names in the directory "datasets".

    # Read file names
    cd((@__DIR__))
    cd("datasets")
    itr = walkdir(pwd(), topdown = false, follow_symlinks = false)
    datasets = first(itr)[3]

    # Remove non-data files
    i = 1
    print("-------------\n")
    while (i <= length(datasets))
        if !(datasets[i][(length(datasets[i]) - 4):length(datasets[i])] == ".xlsx")
            deleteat!(datasets, i)
            i = i - 1
        end
        i += 1
    end

    # Return data files
    return datasets
end
