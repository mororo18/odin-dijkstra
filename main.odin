package main

import "core:c"
import "core:fmt"
import "core:slice"
import pq "core:container/priority_queue"
import "base:runtime"


AdjMatrix :: struct {
    data: [dynamic]uint,
    rows: uint,
    cols: uint,
}

init_matrix_with_dimensions :: proc(rows: uint, cols: uint, mat: ^AdjMatrix) {
    mat.rows = rows
    mat.cols = cols
    mat.data = make([dynamic]uint, rows * cols)
    for &e in mat.data do e = uint(c.UINT32_MAX)
}

get_matrix_element :: proc(row: uint, col: uint, mat: AdjMatrix) -> uint {
    if !(row < mat.rows) do panic("Out of bounds")
    if !(col < mat.cols) do panic("Out of bounds")
    return mat.data[row * mat.cols + col]
}

set_matrix_element :: proc(element: uint, row: uint, col: uint, mat: ^AdjMatrix) {
    if !(row < mat.rows) do panic("Out of bounds")
    if !(col < mat.cols) do panic("Out of bounds")
    mat.data[row * mat.cols + col] = element
}

print_matrix :: proc(mat: AdjMatrix) {
    for row in 0..<mat.rows {
        offset := row * mat.cols
        fmt.println(mat.data[offset:offset+mat.cols])
    }
}

// Custom Formatter for AdjacencyMatrix
AdjMatrix_Formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
	m := cast(^AdjMatrix)arg.data

    elem_type := type_info_of(typeid_of(type_of(m.data[0])))
    for i in 0..<m.rows {
        row_ptr := &m.data[i * m.cols]
        fmt.fmt_array(fi, row_ptr, int(m.cols), int(size_of(uint)), elem_type, verb)
    }
	return true
}

Graph :: struct {
    mat: AdjMatrix,
    total_vertices: uint,
}

init_graph :: proc(total_vertices: uint, graph: ^Graph) {
    init_matrix_with_dimensions(total_vertices, total_vertices, &graph.mat)
    graph.total_vertices = total_vertices
}

clone_graph :: proc(dest: ^Graph, src: Graph) {
    dest.total_vertices = src.total_vertices

    //AdjMatrix
    dest.mat = src.mat
    dest.mat.data = make(type_of(src.mat.data), len(src.mat.data))
    copy(dest.mat.data[:], src.mat.data[:])
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

init_queue :: proc(pqueue: ^pq.Priority_Queue(uint), weight: []uint) {
    @static in_weight: []uint
    in_weight = weight

    less :: proc(a, b: uint) -> bool {
        if in_weight[a] < in_weight[b] do return true
        else do return false
    }

    swap :: proc(q: []uint, i, j: int) {
        slice.swap(q, i, j)
    }

    pq.init(pqueue, less, swap, len(weight))
}

dijkstra :: proc(graph: Graph, src: uint) -> ([dynamic]uint, [dynamic]Maybe(uint)){
    dist := make([dynamic]uint, graph.total_vertices)
    prev := make([dynamic]Maybe(uint), graph.total_vertices)
    pqueue: pq.Priority_Queue(uint)
    init_queue(&pqueue, dist[:])

    graph_cpy: Graph
    clone_graph(&graph_cpy, graph)

    for v in 0..<graph.total_vertices {
        dist[v] = uint(0xffffffff)
        prev[v] = nil
    }
    dist[src] = 0

    //fmt.println("dist=", dist)

    for v in 0..<graph.total_vertices {
        pq.push(&pqueue, v)
    }

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

    return dist, prev
}

shortest_path :: proc(src: uint, dest: uint, graph: Graph) -> (path: [dynamic]uint) {
    dist, prev := dijkstra(graph, src)
    //fmt.println(dist)
    //fmt.println(prev)

    u: Maybe(uint) = dest
    if prev[dest] != nil {
        path = make([dynamic]uint)
        for u != nil {
            append(&path, u.(uint))
            //fmt.print(u, " ")
            u = prev[u.(uint)]
        }
    }

    return
}

main :: proc() {
    fmt.set_user_formatters(new(map[typeid]fmt.User_Formatter))
	err := fmt.register_user_formatter(type_info_of(AdjMatrix).id, AdjMatrix_Formatter)
	assert(err == .None)

    graph: Graph

    init_graph(5, &graph)
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

    print_matrix(graph.mat)

    spath := shortest_path(0, 4, graph)
    //fmt.println(spath)

    free_all()
}
