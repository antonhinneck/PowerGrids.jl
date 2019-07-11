include("C:/Users/Anton Hinneck/.julia/packages/GraphVisualization/src/GraphVisualization.jl")
include("C:/Users/Anton Hinneck/.julia/packages/PowerGrids/src/PowerGrids.jl")
using LightGraphs: ne, nv, AbstractSimpleGraph

#grid = PowerGrids.readDataset(PowerGrids.datasets()[5]) # 14 busses
#grid = PowerGrids.readDataset(PowerGrids.datasets()[36]) # 588 busses
grid = PowerGrids.readDataset(PowerGrids.datasets()[2]) # 118 busses
PowerGrids.datasets()
graph = PowerGrids.toGraph(grid)

function decomposition(G::S where S <: AbstractSimpleGraph; n_cluster = 4, initialization = :rnd)

    g_nv = nv(G)
    print(g_nv)
    g_ne = ne(G)
    adj = G.fadjlist

    # Initialize Clusters
    #--------------------
    clusters = Vector{Array{Bool, 1}}()
    for i in 1:length(clusters)
        clusters[i] = Array{Bool,1}(g_nv)
    end

    init_v = -1
    if initialization == :rnd
        init_v = rand(1:g_nv)
    end

end

function dfs_wrapper(G::S where S <: AbstractSimpleGraph; initialization = :rnd, cycl_limit = 1000)

    g_nv = nv(G)
    g_ne = ne(G)
    adj = G.fadjlist

    n_cycls = 0

    init_visited = Array{Bool}(undef, g_nv)
    for i in 1:g_nv
        init_visited .= false
    end

    cycles = Vector{Vector{Int64}}()

    init_v = -1

    if initialization == :rnd
    # Select initial vertex
    #----------------------
        init_v = rand(1:g_nv)
    end

    if init_v != -1

        function dfs_recursive(visited::Array{Bool}, trace::Array{Int64}, v_precc; status = :search)

            v = trace[length(trace)]
            lt = length(trace)

            if !visited[v]
                visited[v] = true
                for i in 1:length(adj[v])
                    if adj[v][i] != v_precc && n_cycls < cycl_limit
                        dfs_recursive(visited, [trace..., adj[v][i]], v)
                        #dfs_recursive([visited...], [trace..., adj[v][i]], v)
                    end
                end
            else

                cycle = Vector{Int64}()
                cycle_found = false
                idx = lt

                for i in 1:lt
                    if trace[i] == v && i < idx
                        idx = i
                        cycle_found = true
                    end
                end

                if cycle_found
                    push!(cycles, [trace[i] for i in idx:lt])
                    n_cycls += 1
                end

                if status == :search
                    for i in 1:length(adj[v])
                        if visited[adj[v][i]] && adj != v
                            dfs_recursive([visited...], [trace..., adj[v][i]], v, status = :termination)
                        end
                    end
                end
            end
        end

        dfs_recursive(init_visited, [init_v], init_v)
    else
        print("\nDFS ERROR: INITIALIZATION FAILED.\n")
    end

    return cycles
end

function paton(G::S where S <: AbstractSimpleGraph; initialization = :min, selection = :max)

    g_nv = nv(G)
    g_ne = ne(G)
    adj = G.fadjlist

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
    level[z] = 0
    anc[z] = 0

    # MAIN ALGORITHM
    #---------------

    if z != -1

        c = 0
        T_X_empty = false
        while !T_X_empty && c < 100

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
    return cycles
end

#cycles = dfs_wrapper(graph.Graph, cycl_limit = 1000000)
t1 = time()
cycles = paton(graph.Graph)
print("RUN TIME: ", time() - t1)
#GraphVisualization.plot(graph, [400,400])
