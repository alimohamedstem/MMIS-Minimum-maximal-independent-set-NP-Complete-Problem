function get_score(g, node_info, node_color_indices)
    m = sum(Graphs.weights(g)) / 2
    n = nv(g)
    degrees = [sum(Graphs.weights(g)[i, :]) for i in 1:n]
    Q = 0.0

    for i in 1:n
        for j in 1:n
            if i != j && node_info[i].label == node_info[j].label
                A_ij = Graphs.weights(g)[i, j]
                k_i = degrees[i]
                k_j = degrees[j]
                Q += A_ij - (k_i * k_j) / (2 * m)
            end
        end
    end

    return Q / (2 * m)
end