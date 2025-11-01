include("plot_graph.jl")
include("scoring.jl")
using Makie.Colors
using Random
using StatsBase
using Colors
using Graphs
using SimpleWeightedGraphs
using IterTools
using BenchmarkTools

mutable struct NodeInfo
    label::Int
    neighbors::Vector{Int}
end

# MIS scoring function (Important)🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴
function My_technique(g, community_nodes)
    remaining_nodes = sort(community_nodes)
    all_sets = []

    while !isempty(remaining_nodes)
        current_set = []
        blocked = Set{Int}()

        for node in remaining_nodes
            if node ∉ blocked
                push!(current_set, node)
                for nbr in neighbors(g, node)
                    if nbr in remaining_nodes
                        push!(blocked, nbr)
                    end
                end
            end
        end

        push!(all_sets, current_set)
        remaining_nodes = setdiff(remaining_nodes, current_set)
    end

    return all_sets
end

function our_algorithm(g, node_info)
    shuffled_nodes = shuffle(1:nv(g))
    current_colors = [node_info[k].label for k in 1:nv(g)]
    current_score = get_score(g, node_info, current_colors)
    changes_made = 0

    for n in shuffled_nodes
        score_changes = Dict{Int,Float64}()  # Changed to Float64 for score values

        for nbr in node_info[n].neighbors
            temp_node_info = deepcopy(node_info)
            temp_node_info[n].label = node_info[nbr].label
            temp_colors = [temp_node_info[k].label for k in 1:nv(g)]
            score_changes[node_info[nbr].label] = get_score(g, temp_node_info, temp_colors) - current_score
        end

        if !isempty(score_changes)
            max_change = maximum(values(score_changes))
            if max_change > 0
                keys_at_max = [key for (key, value) in score_changes if value == max_change]
                best_label = rand(keys_at_max)
                old_label = node_info[n].label
                node_info[n].label = best_label
                changes_made += 1
                println("Node $n: $old_label -> $best_label (score change: $max_change)")
                current_colors = [node_info[k].label for k in 1:nv(g)]
                current_score = get_score(g, node_info, current_colors)
            end
        end
    end
    println("Total changes made: $changes_made")
end

function label_propagation(g, node_info)
    label_changed = true
    max_runs = 1
    run = 0
    while label_changed && run < max_runs
        run += 1

        label_changed = false
        shuffled_nodes = shuffle(1:nv(g))

        for u in shuffled_nodes
            original_label = node_info[u].label
            current_colors = [node_info[k].label for k in 1:nv(g)]
            current_score = get_score(g, node_info, current_colors)

            score_changes = Dict{Int,Float64}()

            for v in node_info[u].neighbors
                temp_label = node_info[v].label

                w = Graphs.weights(g)[u, v]

                node_info[u].label = temp_label
                temp_colors = [node_info[k].label for k in 1:nv(g)]
                new_score = get_score(g, node_info, temp_colors)

                score_changes[temp_label] = w * (new_score - current_score)
            end

            node_info[u].label = original_label

            if !isempty(score_changes)
                max_change = maximum(values(score_changes))
                if max_change > 0
                    best_labels = [label for (label, score) in score_changes if score == max_change]
                    node_info[u].label = rand(best_labels)
                    label_changed = true
                end
            end
        end

        current_labels = [node_info[k].label for k in 1:nv(g)]
        current_final_score = get_score(g, node_info, current_labels)
        most_common_node = mode(current_labels)

        for k in 1:nv(g)
            node_info[k].label = most_common_node
        end

        new_colors = [node_info[k].label for k in 1:nv(g)]
        new_score = get_score(g, node_info, new_colors)

        if new_score > current_final_score
            label_changed = true
        else
            for k in 1:nv(g)
                node_info[k].label = current_labels[k]
            end
        end
    end

    communities = Dict{Int,Vector{Int}}()
    for (node, info) in node_info
        push!(get!(communities, info.label, Int[]), node)
    end

    println("Smaller communities:")

    MIS_results = Dict{Int,Vector{Vector{Int}}}()

    for (label, nodes) in sort(collect(communities), by=x -> x[1])
        sorted_nodes = sort(nodes)
        println("Community $label: ", sorted_nodes)

        MIS_sets = My_technique(g, sorted_nodes)
        MIS_results[label] = MIS_sets

        for (i, s) in enumerate(MIS_sets)
            println("MIS Set $i: ", s)
        end
    end
    all_communities = collect(keys(MIS_results))

    working_sets = [set for cid in all_communities for set in MIS_results[cid] if !isempty(set)]

    function build_sets_graph(sets::Vector{Vector{Int}}, g)
        n = length(sets)
        sets_g = SimpleGraph(n)
        for i in 1:n, j in (i+1):n
            if any(has_edge(g, u, v) for u in sets[i], v in sets[j])
                add_edge!(sets_g, i, j)
            end
        end
        return sets_g
    end

    function dsatur_color(g::SimpleGraph)
        n = nv(g)
        if n == 0
            return Int[]
        end

        colors = zeros(Int, n)
        neigh_colors = [Set{Int}() for _ in 1:n]
        degrees = degree(g)

        function pick_vertex()
            best = 0
            best_deg = -1
            idx = 0
            for v in 1:n
                if colors[v] == 0
                    sat = length(neigh_colors[v])
                    if sat > best || (sat == best && degrees[v] > best_deg)
                        best = sat
                        best_deg = degrees[v]
                        idx = v
                    end
                end
            end
            return idx
        end

        while true
            v = pick_vertex()
            v == 0 && break

            used = neigh_colors[v]
            c = 1
            while c in used
                c += 1
            end
            colors[v] = c

            for u in neighbors(g, v)
                if colors[u] == 0
                    push!(neigh_colors[u], c)
                end
            end
        end

        return colors
    end

    function merge_sets_by_coloring(sets::Vector{Vector{Int}}, g)
        sets_g = build_sets_graph(sets, g)
        col = dsatur_color(sets_g)
        K = maximum(col, init=0)
        K == 0 && return Vector{Vector{Int}}()

        merged = [Int[] for _ in 1:K]
        for i in 1:length(sets)
            k = col[i]
            append!(merged[k], sets[i])
        end

        return merged
    end

    working_sets = merge_sets_by_coloring(working_sets, g)

    println("Final MIS (Maximum Independent Sets):")
    for (idx, s) in enumerate(working_sets)
        println("Set $idx: $s")
    end


end

function main(filename="graph05.txt")
    println("Step 1: Reading edge list...")
    edge_list = read_edges(filename)

    println("Step 2: Building graph...")
    g = build_graph(edge_list)

    println("Step 3: Initializing node info...")
    node_info = Dict{Int,NodeInfo}()
    for n in 1:nv(g)
        node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
    end

    println("Step 4: Running label propagation...")
    label_propagation(g, node_info)

    println("Step 5: Preparing colors and plotting...")
    palette_size = 16
    color_palette = Makie.distinguishable_colors(palette_size)

    labels = unique([node.label for node in values(node_info)])
    label_to_color_index = Dict(labels[i] => mod1(i, palette_size) for i in eachindex(labels))
    node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
    node_colors = [color_palette[i] for i in node_color_indices]
    node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]

    println("Step 6: Launching interactive plot...")
    interactive_plot_graph(g, node_info, node_colors, node_text_colors, node_color_indices, color_palette, label_to_color_index)
    println("All steps completed!")
end
main()