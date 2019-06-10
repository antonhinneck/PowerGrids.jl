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

    vertices = 0
    for i in 1:length(PG.busses)

        # Add level 1 nodes
        #------------------
        add_vertex!(graph)
        vertices += 1
        top_level_vertex = vertices
        push!(VertexLabels, vertices => string(PG.busses[i]))
        push!(VertexTypes, vertices => 1)

        for j in 1:length(PG.generators_at_bus[PG.busses[i]])
            #print(top_level_vertex," - ")
            # Add level 2 nodes
            #------------------
            add_vertex!(graph)
            vertices += 1
            push!(VertexLabels, vertices => string("gen: ", PG.generators_at_bus[i][j]))
            push!(VertexTypes, vertices => 2)

            # Add level 2 edges
            #------------------
            current_edge = Tuple([top_level_vertex, vertices])
            print(current_edge," - ")
            add_edge!(graph, current_edge...)
            push!(EdgeLabels, current_edge => string("e: ",current_edge[1]," - ",current_edge[2]))
            push!(EdgeTypes, current_edge => 2)

        end
    end

    for i in 1:length(PG.lines)

        # Add level 1 edges
        #------------------
        current_edge = Tuple([PG.line_start[PG.lines[i]], PG.line_end[PG.lines[i]]])
        add_edge!(graph, current_edge...)
        push!(EdgeLabels, current_edge => string("e: ",current_edge[1]," - ",current_edge[2]))
        push!(EdgeTypes, current_edge => 1)

    end

    return GraphVisualization.AnnotatedSimpleGraph(graph,
                                                    VertexLabels,
                                                    VertexTypes,
                                                    VertexTypeLabels,
                                                    EdgeLabels,
                                                    EdgeTypes,
                                                    EdgeTypeLabels)

end
