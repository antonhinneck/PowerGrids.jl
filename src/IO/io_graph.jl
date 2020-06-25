# Functions to convert the data sets into a LightGraphs object.
#--------------------------------------------------------------
function toGraph(PG::PowerGrid)

    graph = SimpleGraph()

    VertexLabels = Dict{I where I <: Integer, String}()
    VertexTypes = Dict{I where I <: Integer, I where I <: Integer}()
    # 1: Bus
    # 2: Generator
    # 3: Demand
    VertexTypeLabels = Dict{I where I <: Integer, String}()
    push!(VertexTypeLabels, 1 => "bus")
    push!(VertexTypeLabels, 2 => "generator")
    push!(VertexTypeLabels, 3 => "demand")

    EdgeLabels = Dict{Tuple{I where I <: Integer, I where I <: Integer}, String}()
    EdgeTypes = Dict{Tuple{I where I <: Integer, I where I <: Integer}, I where I <: Integer}()
    # 1: Power Line
    # 2: Connection (Generator - Bus)
    EdgeTypeLabels = Dict{I where I <: Integer, String}()
    push!(EdgeTypeLabels, 1 => "power_line")
    push!(EdgeTypeLabels, 2 => "connnection")
    rev_map_vertices = Dict{I where I <: Integer, I where I <: Integer}()

    for i in 1:length(PG.buses)

        # Add level 1 nodes
        #------------------
        add_vertex!(graph)
        push!(VertexLabels, i => string(PG.buses[i]))
        push!(VertexTypes, i => 1)
        push!(rev_map_vertices, PG.buses[i] => i)
        #top_level_vertex = vertices

        #=
        for j in 1:length(PG.generators_at_bus[PG.buses[i]])
            # print(top_level_vertex," - ")
            # Add level 2 nodes
            #------------------
            add_vertex!(graph)
            vertices += 1
            push!(VertexLabels, vertices => string("gen: ", PG.generators_at_bus[PG.buses[i]][j]))
            push!(VertexTypes, vertices => 2)

            # Add level 2 edges
            #------------------
            current_edge = Tuple([top_level_vertex, vertices])
            add_edge!(graph, current_edge...)
            push!(EdgeLabels, current_edge => string("e: ",current_edge[1]," - ",current_edge[2]))
            push!(EdgeTypes, current_edge => 2)

        end
        =#
    end

    for i in 1:length(PG.lines)

        # Add level 1 edges
        #------------------
        current_edge = Tuple([rev_map_vertices[PG.line_start[i]], rev_map_vertices[PG.line_end[PG.lines[i]]]])
        add_edge!(graph, current_edge...)
        push!(EdgeLabels, current_edge => string("e: ",current_edge[1]," - ",current_edge[2]))
        push!(EdgeTypes, current_edge => 1)

    end

    # return GraphVisualization.AnnotatedSimpleGraph(graph,
    #                                                 VertexLabels,
    #                                                 VertexTypes,
    #                                                 VertexTypeLabels,
    #                                                 EdgeLabels,
    #                                                 EdgeTypes,
    #                                                 EdgeTypeLabels)
    return graph

end
