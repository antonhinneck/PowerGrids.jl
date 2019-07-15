# Paton's algorithm for deriving a cyclic basis.
# Minimum spanning tree is created in the process.
#-------------------------------------------------

function paton(G::S where S <: AbstractSimpleGraph; initialization = :min, selection = :max)

    g_nv = nv(G)
    g_ne = ne(G)
    adj = G.fadjlist
    print(g_nv, "   ", g_ne)

    level = Array{Int64, 1}(undef, g_nv)
    anc = Array{Int64, 1}(undef, g_nv)

    cycles = Vector{Vector{Int64}}()

    T = Vector{Int64}()
    X = Vector{Int64}()
    z = -1

    # INITIALIZATION
    #---------------
    for i in 1:g_nv
        push!(X, i)
    end

    if initialization == :min
        z = minimum(X)
    elseif initialization == :max
        z = maximum(X)
    elseif initialization == :rnd
        z = rand(1:g_nv)
    end

    push!(T, z)
    level[z] = 1
    anc[z] = 1

    # MAIN ALGORITHM
    #---------------

    if z != -1

        c = 0
        T_X_empty = false
        while !T_X_empty #&& c < 130

            # GENERATE CUT SET OF T AND X
            #----------------------------

            T_X_empty = true
            T_X = Vector{Int64}()
            for i in 1:length(T)
                if T[i] in Set(X)
                    push!(T_X, T[i])
                    T_X_empty = false
                end
            end

            if !T_X_empty

                # SELECT NEXT VERTEX
                #-------------------

                if selection == :min
                    z = minimum(T_X)
                elseif selection == :max
                    z = maximum(T_X)
                else
                    print("\nERROR: SELECTION FAILED.\n")
                end

                for i in 1:length(adj[z])
                    if  adj[z][i] != anc[z]
                        if adj[z][i] in Set(T)
                            cycle = Vector{Int64}()
                            itr = 0
                            push!(cycle, adj[z][i])
                            last_v = z
                            while itr < level[z] + 1 && last_v != adj[z][i]
                                push!(cycle, last_v)
                                last_v = anc[last_v]
                                itr += 1
                            end
                            push!(cycles, cycle)
                        else
                            level[adj[z][i]] = level[z] + 1
                            push!(T, adj[z][i])
                            anc[adj[z][i]] = z
                        end
                    end
                end

                # REMOVE z FROM X
                #----------------

                for i in 1:length(X)
                    if X[i] == z
                        deleteat!(X, i)
                        break
                    end
                end
            end
            c += 1
        end
    else
        print("\nERROR: INITIALIZATION FAILED.\n")
    end
    return cycles, anc, [g_nv, g_ne]
end

# Construct adjacency list (see SimpleGraphs.jl) from minimum spanning tree.
#---------------------------------------------------------------------------

function adjacency_list(anc::Array{I, 1} where I <: Integer)

    nv = length(anc)
    adjacency_list = Array{Vector{Int64}}(undef, nv)

    for i in 1:nv

        adjacency_list[i] = Vector{Int64}()

    end

    # Start form 2 because first
    # entry in spanning tree has no root
    #-----------------------------------
    for i in 2:nv

        push!(adjacency_list[i], anc[i])
        push!(adjacency_list[anc[i]], i)

    end

    return adjacency_list
end

# Construct a line indication vector for a specific power grid, based on
# a minimum spanning tree.
#-----------------------------------------------------------------------

function line_vector(adjl::S where S <: Array{Array{T, 1}} where T <: Integer,
                     pg::S where S <: PowerGrids.PowerGrid)

    nl = length(pg.lines)
    lines = Array{Array{Int64, 1}}(undef, nl)
    lv = Array{Int64, 1}(undef, nl)

    for i in 1:nl

        lines[i] = Array{Int64, 1}(undef, 2)
        lines[i][1] = pg.line_start[pg.lines[i]]
        lines[i][2] = pg.line_end[pg.lines[i]]
        lines[i][2] in Set(adjl[lines[i][1]]) ? lv[i] = 1 : lv[i] = 0

    end

    return lv
end
