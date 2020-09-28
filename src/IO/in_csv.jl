CSV_ROOT_PATH = "C:/Users/Anton Hinneck/Documents/Git/pglib2csv/pglib/2020-08-21.19-54-30-275/csv"
CSV_PATH = nothing
CASE_DIR = nothing
CASE_NAME = nothing

function set_csv_path(csv_root_path; subset = :root )

    @assert isdir(csv_root_path) "Directory does not exist."

    global CSV_ROOT_PATH = csv_root_path

    if subset == :root
        global CSV_PATH = csv_root_path
    elseif subset == :api
        @assert isdir( string(csv_root_path, "/api") ) "Directory does not exist."
        global CSV_PATH = string(csv_root_path, "/api")
    elseif subset == :sad
        @assert isdir( string(csv_root_path, "/sad") ) "Directory does not exist."
        global CSV_PATH = string(csv_root_path, "/sad")
    else
        error("Data subset not defined.")
    end
end

function csv_cases(; verbose = false)
    # This function returns all data
    # set names in the directory CSV_PATH.

    if (CSV_PATH == nothing)
        set_csv_path(CSV_ROOT_PATH)
    end

    lst = readdir(CSV_PATH)

    # Remove non-data files
    i = 1
    print("-------------\n")
    while (i <= length(lst))
        if length(lst[i]) >= 10
            if !(lst[i][1:10] == "pglib_opf_")
                deleteat!(lst, i)
                i = i - 1
            end
        else
            deleteat!(lst, i)
            i = i - 1
        end
        i += 1
    end

    # Print data directories to terminal
    if verbose
        for i in 1:length(lst)
            println("[INFO] ", lst[i]," - ", i)
        end
    end

    # Return data directories
    return lst
end

function select_csv_case(id::T where T <: Integer; verbose = false)
    # Function locks a data directory for further use.
    lst = csv_cases(verbose = verbose)
    println(string("Case ",lst[id]," selected."))
    global CASE_DIR = string(CSV_PATH,"/",lst[id])
    global CASE_NAME = lst[id]
end

function select_csv_case(id::T where T <: String; verbose = false)
    # Function locks a data directory for further use.
    lst = csv_cases(verbose = verbose)
    for i in 1:length(lst)
        if lst[i] == id
            break
        end
    end

    println(string("Case ",lst[i]," selected."))
    global CASE_DIR = string(CSV_PATH,"/",lst[i])
    global CASE_NAME = lst[i]
end

function _csv2dataset()

    #@assert CASE_DIR != nothing "A case has not been selected."
    if (CASE_DIR == nothing)
        set_csv_path(CSV_ROOT_PATH)
    end

    params_df = CSV.read(string(CASE_DIR,"/params.csv"))
    bus_df = CSV.read(string(CASE_DIR,"/bus.csv"))
    gen_df = CSV.read(string(CASE_DIR,"/gen.csv"))
    gencost_df = CSV.read(string(CASE_DIR,"/gencost.csv"))
    branch_df = CSV.read(string(CASE_DIR,"/branch.csv"))

    baseMVA = params_df[1, 2]

    is_extended_generator = false
    if size(gen_df, 2) == 21
        is_extended_generator = true
    else
        @assert size(gen_df, 2) == 10 "The table in the file \"gen.csv\" has an unknown format."
    end

    ds_buses = Vector{bus}()
    if is_extended_generator
        ds_generators = Vector{extended_generator}()
    else
        ds_generators = Vector{generator}()
    end

    ds_branches = Vector{branch}()
    if size(gen_df, 1) == size(gencost_df, 1)
        for i in 1:size(gen_df, 1)
            if is_extended_generator
                if (typeof(gen_df[i, 4]) <: Number) && (typeof(gen_df[i, 5]) <: Number)
                    push!(ds_generators, extended_generator(gen_df[i, :]...,
                                            gencost_df[i, :]...))
                else
                    push!(ds_generators, extended_generator(gen_df[i, 1],
                                                                gen_df[i, 2],
                                                                gen_df[i, 3],
                                                                Inf,
                                                                -Inf,
                                                                gen_df[i, 6],
                                                                gen_df[i, 7],
                                                                gen_df[i, 8],
                                                                gen_df[i, 9],
                                                                gen_df[i, 10],
                                                                gen_df[i, 11],
                                                                gen_df[i, 12],
                                                                gen_df[i, 13],
                                                                gen_df[i, 14],
                                                                gen_df[i, 15],
                                                                gen_df[i, 16],
                                                                gen_df[i, 17],
                                                                gen_df[i, 18],
                                                                gen_df[i, 19],
                                                                gen_df[i, 20],
                                                                gen_df[i, 21],
                                                                gencost_df[i, :]...))
                end
            else
                if (typeof(gen_df[i, 4]) <: Number) && (typeof(gen_df[i, 5]) <: Number)
                    push!(ds_generators, generator(gen_df[i, :]...,
                                            gencost_df[i, :]...))
                else
                    push!(ds_generators, generator(gen_df[i, 1],
                                                        gen_df[i, 2],
                                                        gen_df[i, 3],
                                                        Inf,
                                                        -Inf,
                                                        gen_df[i, 6],
                                                        gen_df[i, 7],
                                                        gen_df[i, 8],
                                                        gen_df[i, 9],
                                                        gen_df[i, 10],
                                                        gencost_df[i, :]...))
                end
            end
        end
    else
        print("Generator and Cost Data Mismatch.")
    end

    for i in 1:size(branch_df, 1)
        push!(ds_branches, branch(branch_df[i, :]...))
    end

    for i in 1:size(bus_df, 1)
        push!(ds_buses, bus(bus_df[i, :]...))
    end

    return _dataset(0,
                    CASE_NAME,
                    baseMVA,
                    ds_buses,
                    ds_branches,
                    ds_generators)

end
