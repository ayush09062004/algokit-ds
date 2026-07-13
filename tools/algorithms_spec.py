"""Declarative spec for every algorithm exposed by algokit_ds.algorithms.

Each entry in ALGORITHMS says which algokit::<name><Container> template to
instantiate, for which containers ("vector", "deque") and element types
("int", "double", "str"). That's genuinely all SWIG needs: %template
syntax doesn't encode a function's parameter list, only its template
parameter (the container type) -- the actual argument shapes (a value, a
predicate, a second container, ...) live entirely in
cpp/algorithms/algorithms.hpp and never need to be repeated here.

To add a new algorithm:
  1. Add one function to cpp/algorithms/algorithms.hpp.
  2. Add one line to ALGORITHMS below.
  3. Run `python3 tools/generate_algorithms_swig.py` and commit the
     resulting swig/algorithms.i diff.
  4. Add one entry to python/algokit_ds/algorithms/_algorithms.py.
"""

ALL_CONTAINERS = ("vector", "deque")
ALL_TYPES = ("int", "double", "str")
NUMERIC_TYPES = ("int", "double")

# (algorithm_name, containers, types)
ALGORITHMS = [
    # -- original v1.0.0 algorithms, regenerated here too so the whole
    #    file comes from one source of truth -------------------------------
    ("sort", ALL_CONTAINERS, ALL_TYPES),
    ("stable_sort", ALL_CONTAINERS, ALL_TYPES),
    ("reverse", ALL_CONTAINERS, ALL_TYPES),
    ("binary_search", ALL_CONTAINERS, ALL_TYPES),
    ("lower_bound", ALL_CONTAINERS, ALL_TYPES),
    ("upper_bound", ALL_CONTAINERS, ALL_TYPES),

    # -- searching ----------------------------------------------------------
    ("find", ALL_CONTAINERS, ALL_TYPES),
    ("find_if", ALL_CONTAINERS, ALL_TYPES),
    ("count", ALL_CONTAINERS, ALL_TYPES),
    ("count_if", ALL_CONTAINERS, ALL_TYPES),

    # -- min / max ------------------------------------------------------
    ("min_element", ALL_CONTAINERS, ALL_TYPES),
    ("max_element", ALL_CONTAINERS, ALL_TYPES),
    ("minmax_element", ALL_CONTAINERS, ALL_TYPES),

    # -- modification ---------------------------------------------------
    ("replace", ALL_CONTAINERS, ALL_TYPES),
    ("replace_if", ALL_CONTAINERS, ALL_TYPES),
    ("remove", ALL_CONTAINERS, ALL_TYPES),
    ("remove_if", ALL_CONTAINERS, ALL_TYPES),
    ("unique", ALL_CONTAINERS, ALL_TYPES),
    ("unique_copy", ALL_CONTAINERS, ALL_TYPES),
    ("fill", ALL_CONTAINERS, ALL_TYPES),
    ("fill_n", ALL_CONTAINERS, ALL_TYPES),
    ("generate", ALL_CONTAINERS, ALL_TYPES),
    ("generate_n", ALL_CONTAINERS, ALL_TYPES),
    ("swap_ranges", ALL_CONTAINERS, ALL_TYPES),

    # -- reordering -------------------------------------------------------
    ("rotate", ALL_CONTAINERS, ALL_TYPES),
    ("rotate_copy", ALL_CONTAINERS, ALL_TYPES),
    ("shuffle", ALL_CONTAINERS, ALL_TYPES),
    # random_shuffle intentionally omitted: removed from the standard in
    # C++20 and deprecated before that -- std::shuffle above is its
    # replacement and already covers the need.

    # -- partitioning -----------------------------------------------------
    ("partition", ALL_CONTAINERS, ALL_TYPES),
    ("stable_partition", ALL_CONTAINERS, ALL_TYPES),
    ("partition_copy", ALL_CONTAINERS, ALL_TYPES),
    ("is_partitioned", ALL_CONTAINERS, ALL_TYPES),
    ("partition_point", ALL_CONTAINERS, ALL_TYPES),

    # -- merging (ranges must already be sorted ascending) -----------------
    ("merge", ALL_CONTAINERS, ALL_TYPES),
    ("inplace_merge", ALL_CONTAINERS, ALL_TYPES),

    # -- set algorithms (ranges must already be sorted ascending) ----------
    ("set_union", ALL_CONTAINERS, ALL_TYPES),
    ("set_intersection", ALL_CONTAINERS, ALL_TYPES),
    ("set_difference", ALL_CONTAINERS, ALL_TYPES),
    ("set_symmetric_difference", ALL_CONTAINERS, ALL_TYPES),
    ("includes", ALL_CONTAINERS, ALL_TYPES),

    # -- heap ---------------------------------------------------------------
    ("make_heap", ALL_CONTAINERS, ALL_TYPES),
    ("push_heap", ALL_CONTAINERS, ALL_TYPES),
    ("pop_heap", ALL_CONTAINERS, ALL_TYPES),
    ("sort_heap", ALL_CONTAINERS, ALL_TYPES),
    ("is_heap", ALL_CONTAINERS, ALL_TYPES),
    ("is_heap_until", ALL_CONTAINERS, ALL_TYPES),

    # -- permutation --------------------------------------------------------
    ("next_permutation", ALL_CONTAINERS, ALL_TYPES),
    ("prev_permutation", ALL_CONTAINERS, ALL_TYPES),
    ("is_permutation", ALL_CONTAINERS, ALL_TYPES),

    # -- numeric (<numeric>) -------------------------------------------------
    ("accumulate", ALL_CONTAINERS, ALL_TYPES),
    ("adjacent_difference", ALL_CONTAINERS, NUMERIC_TYPES),  # needs operator-
    ("partial_sum", ALL_CONTAINERS, ALL_TYPES),
    ("inner_product", ALL_CONTAINERS, NUMERIC_TYPES),  # needs operator*
    ("iota", ALL_CONTAINERS, NUMERIC_TYPES),  # std::string has no operator++
]

# Algorithms whose C++ signature returns std::pair<Container, Container>
# instead of a scalar or a single Container -- these need one extra
# %template for the pair type itself before they can be wrapped.
PAIR_CONTAINER_RETURNING = {"partition_copy"}

CONTAINER_TYPE_NAMES = {
    ("vector", "int"): ("std::vector<int>", "IntVector"),
    ("vector", "double"): ("std::vector<double>", "DoubleVector"),
    ("vector", "str"): ("std::vector<std::string>", "StrVector"),
    ("deque", "int"): ("std::deque<int>", "IntDeque"),
    ("deque", "double"): ("std::deque<double>", "DoubleDeque"),
    ("deque", "str"): ("std::deque<std::string>", "StrDeque"),
}
