package main

import "core:c"
import "core:fmt"
import "core:slice"
import "core:mem"
import pq "core:container/priority_queue"
import "base:runtime"

MainError :: union {
    runtime.Allocator_Error,
}

AdjMatrix :: struct {
    data: [dynamic]uint,
    rows: uint,
    cols: uint,
}

@(require_results)
init_matrix_with_dimensions :: proc(rows: uint, cols: uint, mat: ^AdjMatrix, allocator: mem.Allocator) -> (err: MainError) {
    mat.rows = rows
    mat.cols = cols
    mat.data = make([dynamic]uint, rows * cols, allocator) or_return
    for &e in mat.data do e = uint(c.UINT32_MAX)
    return
}

in_matrix_bounds :: proc(row: uint, col: uint, mat: AdjMatrix) -> bool {
    return row < mat.rows && col < mat.cols
}

get_matrix_element :: proc(row: uint, col: uint, mat: AdjMatrix) -> uint {
    assert(in_matrix_bounds(row, col, mat), "Out of bounds")
    return mat.data[row * mat.cols + col]
}

set_matrix_element :: proc(element: uint, row: uint, col: uint, mat: ^AdjMatrix) {
    assert(in_matrix_bounds(row, col, mat^), "Out of bounds")
    mat.data[row * mat.cols + col] = element
}

print_matrix :: proc(mat: AdjMatrix) {
    for row in 0..<mat.rows {
        offset := row * mat.cols
        fmt.println(mat.data[offset:offset+mat.cols])
    }
}

Graph :: struct {
    mat: AdjMatrix,
    total_vertices: uint,
}

@(require_results)
init_graph :: proc(total_vertices: uint, graph: ^Graph, allocator: mem.Allocator) -> MainError {
    init_matrix_with_dimensions(total_vertices, total_vertices, &graph.mat, allocator) or_return
    graph.total_vertices = total_vertices
    return nil
}

destroy_graph :: proc(graph: Graph) {
    delete(graph.mat.data)
}

@(require_results)
clone_graph :: proc(dest: ^Graph, src: Graph, allocator: mem.Allocator) -> (err: MainError) {
    dest.total_vertices = src.total_vertices

    //AdjMatrix
    dest.mat = src.mat
    dest.mat.data = make(type_of(src.mat.data), len(src.mat.data), allocator) or_return
    copy(dest.mat.data[:], src.mat.data[:])
    return
}

get_edge :: proc(u: uint, v: uint, graph: Graph) -> uint {
    assert(get_matrix_element(u, v, graph.mat) == get_matrix_element(v, u, graph.mat))
    return get_matrix_element(u, v, graph.mat)
}

set_edge :: proc(edge: uint, u: uint, v: uint, graph: ^Graph) {
    set_matrix_element(edge, u, v, &graph.mat)
    set_matrix_element(edge, v, u, &graph.mat)
}

remove_edge :: proc(u: uint, v: uint, graph: ^Graph) {
    set_edge(uint(c.UINT32_MAX), u, v, graph)
}

edge_exists :: proc(u: uint, v: uint, graph: Graph) -> bool{
    return get_edge(u, v, graph) != uint(c.UINT32_MAX)
}

@(require_results)
init_queue :: proc(pqueue: ^pq.Priority_Queue(uint), weight: []uint, allocator: mem.Allocator) -> (err: MainError) {
    @static in_weight: []uint
    in_weight = weight
    less :: proc(a, b: uint) -> bool { return in_weight[a] < in_weight[b] }
    // NOTE: pq.init() doesnt return errors so we need to allocate the memory ourselves
    queue := make([dynamic]uint, allocator) or_return
    pq.init_from_dynamic_array(pqueue, queue, less, pq.default_swap_proc(uint))
    return
}

dijkstra :: proc(src: uint, dest: uint, graph: Graph, allocator: mem.Allocator) -> (path: [dynamic]uint, err: MainError) {
    prev := make([dynamic]Maybe(uint), graph.total_vertices, allocator) or_return
    dist := make([dynamic]uint, graph.total_vertices, allocator) or_return
    pqueue: pq.Priority_Queue(uint)
    init_queue(&pqueue, dist[:], allocator) or_return

    graph_cpy: Graph
    clone_graph(&graph_cpy, graph, allocator) or_return

    for v in 0..<graph.total_vertices {
        dist[v] = uint(c.UINT32_MAX)
        prev[v] = nil
    }
    dist[src] = 0

    for v in 0..<graph.total_vertices do pq.push(&pqueue, v)

    for pq.len(pqueue) > 0 {
        u := pq.pop(&pqueue)

        for v in 0..<graph_cpy.total_vertices {
            if v == u do continue
            // If 'v' is neighbor of 'u'
            if edge_exists(u, v, graph_cpy) {
                path_len := dist[u] + get_edge(u, v, graph_cpy)
                if path_len < dist[v] {
                    dist[v] = path_len
                    prev[v] = u
                }
            }

            // Remove edge from graph_cpy
            remove_edge(u, v, &graph_cpy)
        }

        // fix the the heap ordering
        pq.fix(&pqueue, 0)
    }

    path = reconstruct_path(src, dest, prev[:])
    return
}

reconstruct_path :: proc( origin: uint, dest: uint, predecessor: []Maybe(uint)) -> (path: [dynamic]uint) {
    current: Maybe(uint) = dest
    if predecessor[dest] != nil {
        // NOTE: This dynamic array needs to use the default allocator
        path = make([dynamic]uint)
        for current != nil {
            append(&path, current.(uint))
            if current.(uint) == origin do return
            current = predecessor[current.(uint)]
        }

        if len(path) > 0 && path[len(path)-1] != origin {
            delete(path)
            return
        }
    }

    return
}

@(require_results)
init_arena_with_capacity :: proc(arena: ^mem.Arena, capacity: uint) -> MainError {
    total_bytes := int(capacity)
    data := mem.alloc_bytes(total_bytes) or_return
    mem.arena_init(arena, data)
    return nil
}

shortest_path :: proc(src: uint, dest: uint, graph: Graph) -> (path: [dynamic]uint, err: MainError) {
    arena: mem.Arena
    arena_cap := size_of(uint) * (graph.total_vertices * graph.total_vertices) * 10
    init_arena_with_capacity(&arena, arena_cap) or_return
    defer delete(arena.data)

    // The returned dynamic array (path) is allocated using the default context.allocator
    path = dijkstra(src, dest, graph, mem.arena_allocator(&arena)) or_return
    slice.reverse(path[:])
    return
}

default_heuristic :: proc(uint) -> uint { return 0 }

find_path :: proc(
    src: uint, 
    dest: uint, 
    graph: Graph, 
    heuristic := default_heuristic
) -> (path: [dynamic]uint, err: MainError) {

    arena: mem.Arena
    init_arena_with_capacity(&arena, size_of(uint) * graph.total_vertices * 10) or_return
    defer delete(arena.data)

    // This return dynamic array is allocated using the default context.allocator
    path = a_star(src, dest, default_heuristic, graph, mem.arena_allocator(&arena)) or_return
    slice.reverse(path[:])
    return
}

a_star :: proc(
    origin: uint,
    dest: uint,
    h: proc(uint) -> uint,
    graph: Graph,
    allocator: mem.Allocator
) -> (path: [dynamic]uint, err: MainError) {

    g_score := make([dynamic]uint, graph.total_vertices, allocator) or_return
    f_score := make([dynamic]uint, graph.total_vertices, allocator) or_return
    discovered := make([dynamic]bool, graph.total_vertices, allocator) or_return
    prev := make([dynamic]Maybe(uint), graph.total_vertices, allocator) or_return

    discovered_nodes: pq.Priority_Queue(uint)
    init_queue(&discovered_nodes, f_score[:], allocator) or_return

    for v in 0..<graph.total_vertices {
        g_score[v] = uint(c.UINT32_MAX)
        f_score[v] = uint(c.UINT32_MAX)
        prev[v] = nil
    }

    // Add origin to discovered nodes
    pq.push(&discovered_nodes, origin)
    g_score[origin] = 0
    f_score[origin] = h(origin)
    discovered[origin] = true

    for pq.len(discovered_nodes) > 0 {
        current := pq.pop(&discovered_nodes)

        if current == dest {
            path = reconstruct_path(origin, dest, prev[:])
            return
        }

        // For each neighbor
        for v in 0..<graph.total_vertices {
            // If 'v' is neighbor of 'current'
            if edge_exists(current, v, graph) && v != current {
                neighbor_g_score := g_score[current] + get_edge(current, v, graph)

                if neighbor_g_score < g_score[v] {
                    g_score[v] = neighbor_g_score
                    f_score[v] = neighbor_g_score + h(v)
                    prev[v] = current

                    if !discovered[v] {
                        discovered[v] = true
                        pq.push(&discovered_nodes, v)
                    }
                }
            }
        }
    }

    return
}

main :: proc() {
    graph: Graph

    err := init_graph(5, &graph, context.allocator)
    defer destroy_graph(graph)
    if err != nil do fmt.eprintln(err)

    set_edge(0, 0, 1, &graph)
    set_edge(2, 0, 2, &graph)
    set_edge(3, 1, 2, &graph)
    set_edge(1, 1, 3, &graph)
    set_edge(4, 2, 4, &graph)
    set_edge(2, 3, 4, &graph)
    //
    //         (0)
    //         / \
    //       0/   \2
    //       /     \
    //     (1)---3--(2)
    //      |       |
    //     1|       |4
    //      |       |
    //     (3)---2--(4)
    //

    disj_path := shortest_path(0, 4, graph) or_else nil
    path := find_path(0, 4, graph) or_else nil
    fmt.println(disj_path)
    fmt.println(path)

    delete(disj_path)
    delete(path)
}
