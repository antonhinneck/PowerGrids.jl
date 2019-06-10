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

    EdgeLabels = Dict{Tuple{I where I <: Integer, I where I <: Integer}, String}()
    EdgeTypes = Dict{Tuple{I where I <: Integer, I where I <: Integer}, I where I <: Integer}()
    # 1: Power Line
    # 2: Connection (Generator - Bus)
    EdgeTypeLabels = Dict{I where I <: Integer, String}()

    vertices = 0
    for i in 1:length(PG.busses)

        # Add level 1 nodes
        #------------------
        add_vertex!(graph)
        vertices += 1
        push!(VertexLabels, vertices => string(PG.busses[i]))
        push!(VertexTypes, vertices => 1)
        push!(VertexTypeLabels, vertices => "bus")

        for j in 1:length(PG.generators_at_bus[i])

            # Add level 2 nodes
            #------------------
            add_vertex!(graph)
            vertices += 1
            push!(VertexLabels, vertices => string("gen: ", PG.generators_at_bus[i][j]))
            push!(VertexTypes, vertices => 2)
            push!(VertexTypeLabels, vertices => "generator")

            # Add level 2 edges
            #------------------
            current_edge = Tuple([i,j])
            add_edge!(graph, current_edge...)
            push!(EdgeLabels, current_edge => string("e: "current_edge[1]," - ",current_edge[2]))
            push!(EdgeTypes, current_edge => 2)
            push!(EdgeTypeLabels, current_edge => "connection")

        end
    end

    for i in 1:length(PG.lines)

        # Add level 1 edges
        #------------------
        current_edge = Tuple([PG.line_start[lines[i]], PG.line_end[lines[i]]])
        add_edge!(graph, current_edge...)
        push!(EdgeLabels, current_edge => string("e: "current_edge[1]," - ",current_edge[2]))
        push!(EdgeTypes, current_edge => 1)
        push!(EdgeTypeLabels, current_edge => "power_line")

    end

    for i in 1:length(generator)

    return GraphVisualization.AnnotatedSimpleGraph(graph,
                                                    VertexLabels,
                                                    VertexTypes,
                                                    VertexTypeLabels,
                                                    EdgeLabels,
                                                    EdgeTypes,
                                                    EdgeTypeLabels)

end
