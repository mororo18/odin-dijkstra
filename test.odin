package main

import "core:testing"
import "core:slice"
import "core:fmt"

@(test)
dijkstra_test_a :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(6, &graph, context.allocator) == nil)

    //     (0)--1--(1)--2--(2)
    //      |           /
    //      4          3
    //      |         /
    //     (3)       (4)   (5) isolated

    set_edge(1, 0, 1, &graph)
    set_edge(4, 0, 3, &graph)
    set_edge(2, 1, 2, &graph)
    set_edge(3, 2, 4, &graph)

    path, err := shortest_path(0, 5, graph)
    testing.expect(t, path == nil)

    free_all()
}

@(test)
dijkstra_test_b :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(7, &graph, context.allocator) == nil)

    //         (0)
    //       /  |  \
    //     2    4    1
    //   /      |      \
    // (1)--1--(2)--3--(3)
    //   \           /
    //    2         5
    //      \     /
    //        (4)
    //         |
    //         7
    //        (5)--6--(6)

    set_edge(2, 0, 1, &graph)
    set_edge(4, 0, 2, &graph)
    set_edge(1, 0, 3, &graph)
    set_edge(1, 1, 2, &graph)
    set_edge(3, 2, 3, &graph)
    set_edge(2, 1, 4, &graph)
    set_edge(5, 3, 4, &graph)
    set_edge(7, 4, 5, &graph)
    set_edge(6, 5, 6, &graph)

    path := shortest_path(0, 6, graph) or_else nil
    testing.expect(t, slice.simple_equal([]uint{0, 1, 4, 5, 6}, path[:]))

    free_all()
}

@(test)
dijkstra_test_c :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(8, &graph, context.allocator) == nil)

    // (0)--1--(1)--1--(2)
    //  |       |       |
    //  2       2       2
    //  |       |       |
    // (7)--1--(6)--1--(5)
    //          \
    //           3
    //           \
    //           (3)--1--(4)

    set_edge(1, 0, 1, &graph)
    set_edge(1, 1, 2, &graph)
    set_edge(2, 0, 7, &graph)
    set_edge(2, 1, 6, &graph)
    set_edge(2, 2, 5, &graph)
    set_edge(1, 7, 6, &graph)
    set_edge(1, 6, 5, &graph)
    set_edge(3, 6, 3, &graph)
    set_edge(1, 3, 4, &graph)

    path := shortest_path(0, 7, graph) or_else nil
    testing.expect(t, slice.simple_equal([]uint{0, 7}, path[:]))
    free_all()
}

@(test)
find_patht_test_a :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(3, &graph, context.allocator) == nil)

    // Graph:
    // 0 --(1)-- 1 --(1)-- 2

    set_edge(1, 0, 1, &graph)
    set_edge(1, 1, 2, &graph)

    path := find_path(0, 2, graph) or_else nil
    testing.expect(t, slice.simple_equal([]uint{0, 1, 2}, path[:]))

    free_all()
}

@(test)
find_path_test_b :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(5, &graph, context.allocator) == nil)

    // Graph:
    // 0 --(10)-- 1 --(10)-- 2
    //  \                    /
    //   --(1)--- 3 --(1)--- 4

    set_edge(10, 0, 1, &graph)
    set_edge(10, 1, 2, &graph)
    set_edge(1, 0, 3, &graph)
    set_edge(1, 3, 4, &graph)
    set_edge(1, 4, 2, &graph)

    h := proc(n: uint) -> uint {
        return 0
    }

    path := find_path(0, 2, graph) or_else nil
    testing.expect(t, slice.simple_equal([]uint{0, 3, 4, 2}, path[:]))

    free_all()
}

@(test)
find_path_test_c :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(4, &graph, context.allocator) == nil)

    // Graph:
    // 0 --(1)-- 1 --(5)-- 3
    //  \                 /
    //   --(2)-- 2 --(1)--

    set_edge(1, 0, 1, &graph)
    set_edge(2, 0, 2, &graph)
    set_edge(5, 1, 3, &graph)
    set_edge(1, 2, 3, &graph)

    h := proc(n: uint) -> uint {
        if n == 1 do return 5
        if n == 2 do return 1
        if n == 3 do return 0
        return 0
    }

    path := find_path(0, 3, graph) or_else nil
    testing.expect(t, slice.simple_equal([]uint{0, 2, 3}, path[:]))

    free_all()
}

@(test)
find_path_test_d :: proc(t: ^testing.T) {
    graph: Graph
    testing.expect(t, init_graph(4, &graph, context.allocator) == nil)

    // Graph:
    // 0 -- 1    2 -- 3

    set_edge(1, 0, 1, &graph)
    set_edge(1, 2, 3, &graph)

    path, _ := find_path(0, 3, graph)
    testing.expect(t, path == nil)

    free_all()
}


