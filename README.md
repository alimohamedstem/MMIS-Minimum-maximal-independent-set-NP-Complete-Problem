# Heuristic MMIS Finder

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Language: Julia](https://img.shields.io/badge/language-Julia-9558B2.svg)
![Status: Research](https://img.shields.io/badge/status-research-red.svg)

This repository contains the Julia implementation of a novel heuristic and greedy algorithm for solving the **Minimum Maximal Independent Set (MMIS)** problem in complex graphs. The approach leverages community detection via label propagation to break down large graphs into smaller, manageable subproblems, delivering highly competitive results on benchmark datasets.

## 📖 Overview

The Minimum Maximal Independent Set (MMIS) is a classic NP-complete problem in graph theory with wide-ranging applications, from network analysis to scheduling. This project tackles the problem by partitioning a complex graph into distinct communities. By solving the MMIS for each smaller community and then intelligently merging the results, the algorithm can efficiently approximate the MMIS for the entire graph.

The core methodology is a multi-step process:
1.  **Community Detection**: Uses a label propagation algorithm to partition the graph into communities with the highest possible modularity score.
2.  **Local MMIS Calculation**: A greedy algorithm finds the MMIS for each partitioned community.
3.  **Conflict Graph Merging**: A meta-graph is constructed where each node represents a local MMIS. The DSATUR graph coloring algorithm resolves conflicts between them.
4.  **Final Set Combination**: The colored sets are merged to produce the final independent sets for the entire graph.

## ⚙️ How It Works

The algorithm is implemented as a sequence of four main functions, each handling a critical part of the process.

### 1. Modularity Score Calculation (`get_score`)
To ensure an optimal community structure, we first need a way to measure its quality. This algorithm uses the **modularity score (Qmod)**, which evaluates how densely connected the nodes within a community are compared to nodes outside it. A higher score signifies a better partition.

```Input: Graph 'g', node labels 'node_info'
Output: Modularity score Q
```

### 2. Label Propagation
The algorithm uses label propagation to find the best community structure. This is an iterative process where each node adopts the label most common among its neighbors. The process continues until no node can improve the global modularity score by changing its label.

```
Input: Graph 'g'
Output: Final node labels representing the community structure
```

### 3. MMIS Calculation in Communities (`My_technique`)
With the graph partitioned, a greedy algorithm finds the independent sets for each community. It iterates through the nodes, adding a node to the `current_set` and blocking all its neighbors. This ensures no two adjacent nodes are in the same set. The process repeats until all nodes in the community are processed.

```
Input: A community subgraph 'g', 'community_nodes'
Output: A collection of disjoint independent sets for the community
```

### 4. Merging MMIS Sets (DSATUR)
This is the final step where local results are combined.
1.  A **meta-graph** is built where each node represents an MMIS from a community. An edge connects two nodes if their corresponding sets have a conflicting edge in the original graph.
2.  The **DSATUR graph coloring algorithm** is applied to this meta-graph. Conflicting sets are guaranteed to receive different colors.
3.  Finally, all MMIS sets that share the same color are merged into larger, non-conflicting independent sets for the whole graph.

## 🚀 Getting Started

The code is written in **Julia**. You will need to have a Julia environment set up. The `Graphs.jl` package is a primary dependency.

### Installation

1.  Install Julia from the [official website](https://julialang.org/downloads/).
2.  Open the Julia REPL and install the necessary packages:
    ```julia
    using Pkg
    Pkg.add("Graphs")
    Pkg.add("SimpleWeightedGraphs") # If your graph is weighted
    ```

### Usage

The complete code is composed of the functions found in the paper's appendix. To run the full algorithm, you would integrate and execute them in sequence. Below is a conceptual `main.jl` file showing how to use the functions.

```julia
# main.jl

# --- Paste the implementation of all functions here ---
# 1. get_score (Listing 1)
# 2. Label propagation algorithm (Listing 2)
# 3. My_technique (Listing 3)
# 4. Community detection and MIS merging logic (Listing 4)
# 5. build_sets_graph, dsatur_color, etc. (pages 18-19)

using Graphs

function main()
    # 1. Create your graph
    # Example: A simple graph
    g = SimpleGraph(7)
    add_edge!(g, 1, 2); add_edge!(g, 1, 4)
    add_edge!(g, 2, 5); add_edge!(g, 2, 7)
    add_edge!(g, 3, 4) # Node 3 is only connected to 4
    add_edge!(g, 4, 6); add_edge!(g, 4, 7)
    add_edge!(g, 5, 6); add_edge!(g, 5, 7)

    # Note: The provided code assumes a `node_info` structure that holds labels
    # and neighbors. You may need to adapt this part based on the label
    # propagation output. For this example, we'll skip label propagation
    # and run `My_technique` on the whole graph.

    println("Running MMIS calculation on the entire graph...")
    all_nodes = vertices(g)
    final_sets = My_technique(g, all_nodes)

    println("Final MMIS Sets:")
    for (i, s) in enumerate(final_sets)
        println("Set $i: ", s)
    end
end

main()

# Expected Output (will vary based on sorting, but an example):
# Running MMIS calculation on the entire graph...
# Final MMIS Sets:
# Set 1:
# Set 2:
# Set 3:
# Set 4:

# To run the full community-based algorithm, you would first run
# the label propagation to get communities, then apply the logic
# from Listing 4 to process each community and merge the results.
```

## 📊 Experimental Results

The algorithm was validated against standard benchmark graphs from the **DIMACS Challenge** and **Tepper School of Business (COLOR02)**. The results were highly competitive and often matched the best-known chromatic numbers (which correspond to MMIS).

Here is a sample of the results:

| Graph Name          | Vertices | Edges   | Best Known (BK) | Algorithm Result |
| ------------------- | -------- | ------- | --------------- | ---------------- |
| `zeroin.i.1.col`    | 211      | 4100    | 49              | **49**           |
| `fpsol2.i.3.col`    | 425      | 8688    | 30              | **30**           |
| `miles750.col`      | 128      | 2113    | 31              | 32               |
| `queen8_12.col`     | 96       | 1368    | 12              | 13               |
| `flat300_28_0`      | 300      | 21695   | 28              | **28**           |
| `myciel6.col`       | 95       | 755     | 7               | **7**            |
| `dsjc1000.1.col`    | 1000     | 49629   | ~21-86          | **23**           |

As shown, the algorithm successfully finds the optimal solution for many graphs and produces near-optimal results for others.
