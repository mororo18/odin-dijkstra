package main

import "core:testing"

@(test)
test_a :: proc(^testing.T) {
    graph: Graph
    init_graph(6, &graph)

    //     (0)--1--(1)--2--(2)
    //      |           /
    //      4          3
    //      |         /
    //     (3)       (4)   (5) isolated

    set_edge(1, 0, 1, &graph)
    set_edge(4, 0, 3, &graph)
    set_edge(2, 1, 2, &graph)
    set_edge(3, 2, 4, &graph)

    free_all()
}

@(test)
test_b :: proc(^testing.T) {
    graph: Graph
    init_graph(7, &graph)

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

    free_all()
}

@(test)
test_c :: proc(^testing.T) {
    graph: Graph
    init_graph(8, &graph)

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

    free_all()
}
