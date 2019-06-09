# Functions to convert the data sets into a LightGraphs object.
#--------------------------------------------------------------
function toGraph(PG::PowerGrid)

    graph = SimpleGraph()

    VertexLabels = Dict{I where I <: Integer, String}()
    VertexTypes = Dict{I where I <: Integer, I where I <: Integer}()
    VertexTypeLabels = Dict{I where I <: Integer, String}()

    vertices = 0
    for i in 1:length(PG.busses)

        add_vertex!(graph)
        vertices += 1
        push!(VertexLabels, vertices => string(PG.busses[i]))

        for j in 1:length(PG.generators_at_bus[i])

            add_vertex!(graph)
            vertices += 1
            push!(VertexLabels, vertices => string(PG.busses[i]))

        end
    end

    EdgeLabels = Dict{Tuple{I where I <: Integer, I where I <: Integer}, String}()
    EdgeTypes = Dict{Tuple{I where I <: Integer, I where I <: Integer}, I where I <: Integer}()
    EdgeTypeLabels = Dict{I where I <: Integer, String}()

    return GraphVisualization.AnnotatedSimpleGraph(graph,
                                                    VertexLabels,
                                                    VertexTypes,
                                                    VertexTypeLabels,
                                                    EdgeLabels,
                                                    EdgeTypes,
                                                    EdgeTypeLabels)

end
