%module algorithms
%{
#include "algorithms.hpp"
%}

%include "exception.i"
%include "std_string.i"
%include "std_vector.i"
%include "std_deque.i"
%include "std_pair.i"

// Without this, an exception thrown from inside a wrapped function
// surfaces as an uncaught C++ exception, which calls std::terminate()
// and crashes the entire process instead of raising a normal Python
// exception. This applies to every wrapped function in the module.
//
// algokit::PythonError is caught *first* and specifically: it means a
// user-supplied predicate/generator callback itself raised, and CPython
// has already set that original exception (type, message, traceback) on
// the interpreter. SWIG_fail there returns NULL without calling
// PyErr_SetString again, so the user's own exception propagates
// unchanged -- it is not replaced by a generic RuntimeError.
%exception {
    try {
        $action
    } catch (const algokit::PythonError&) {
        SWIG_fail;
    } catch (const std::out_of_range& e) {
        SWIG_exception(SWIG_IndexError, e.what());
    } catch (const std::invalid_argument& e) {
        SWIG_exception(SWIG_ValueError, e.what());
    } catch (const std::exception& e) {
        SWIG_exception(SWIG_RuntimeError, e.what());
    }
}

// Re-declare the exact same C++ types the vector/deque modules already
// wrap. This does NOT create a second incompatible type: SWIG's runtime
// type table is keyed by the actual C++ type signature (e.g.
// "std::vector<int> *") and shared globally across every SWIG module
// loaded in the same process, so a Vector's underlying object -- created
// by the separately-compiled `vector` module -- is still recognized here
// and passed by reference, not copied. (We avoid %import "vector.i" on
// purpose: SWIG's generated cross-module `import vector` statement is a
// bare top-level import that breaks once vector.py lives inside a
// package like algokit_ds._swig instead of being importable as a
// top-level module.)
%template(IntVector)    std::vector<int>;
%template(DoubleVector) std::vector<double>;
%template(StrVector)    std::vector<std::string>;

%template(IntDeque)    std::deque<int>;
%template(DoubleDeque) std::deque<double>;
%template(StrDeque)    std::deque<std::string>;

// A single shared (index, index) pair type, reused by every algorithm
// that returns two positions (currently just minmax_element) regardless
// of which container/type it was called on -- these are plain longs, not
// container-typed, so there is exactly one of these for the whole module.
%template(LongPair) std::pair<long, long>;

// PyCallable (py_callback.hpp) is an internal implementation detail used
// to bridge predicate/generator callbacks back into Python. It is never
// used as a parameter type directly -- every function that needs a
// callback takes a plain PyObject* (which SWIG passes straight through
// natively, no typemap required) and constructs a PyCallable from it
// internally. %ignore just keeps SWIG from also generating a spurious
// wrapper class for PyCallable itself when it's pulled in transitively
// while parsing algorithms.hpp.
%ignore algokit::PyCallable;

%include "algorithms.hpp"

// --- pair-of-container return types ---
%template(PairIntVector) std::pair<std::vector<int>, std::vector<int>>;
%template(PairDoubleVector) std::pair<std::vector<double>, std::vector<double>>;
%template(PairStrVector) std::pair<std::vector<std::string>, std::vector<std::string>>;
%template(PairIntDeque) std::pair<std::deque<int>, std::deque<int>>;
%template(PairDoubleDeque) std::pair<std::deque<double>, std::deque<double>>;
%template(PairStrDeque) std::pair<std::deque<std::string>, std::deque<std::string>>;

// --- sort ---
%template(sort_IntVector) algokit::sort<std::vector<int>>;
%template(sort_DoubleVector) algokit::sort<std::vector<double>>;
%template(sort_StrVector) algokit::sort<std::vector<std::string>>;
%template(sort_IntDeque) algokit::sort<std::deque<int>>;
%template(sort_DoubleDeque) algokit::sort<std::deque<double>>;
%template(sort_StrDeque) algokit::sort<std::deque<std::string>>;

// --- stable_sort ---
%template(stable_sort_IntVector) algokit::stable_sort<std::vector<int>>;
%template(stable_sort_DoubleVector) algokit::stable_sort<std::vector<double>>;
%template(stable_sort_StrVector) algokit::stable_sort<std::vector<std::string>>;
%template(stable_sort_IntDeque) algokit::stable_sort<std::deque<int>>;
%template(stable_sort_DoubleDeque) algokit::stable_sort<std::deque<double>>;
%template(stable_sort_StrDeque) algokit::stable_sort<std::deque<std::string>>;

// --- reverse ---
%template(reverse_IntVector) algokit::reverse<std::vector<int>>;
%template(reverse_DoubleVector) algokit::reverse<std::vector<double>>;
%template(reverse_StrVector) algokit::reverse<std::vector<std::string>>;
%template(reverse_IntDeque) algokit::reverse<std::deque<int>>;
%template(reverse_DoubleDeque) algokit::reverse<std::deque<double>>;
%template(reverse_StrDeque) algokit::reverse<std::deque<std::string>>;

// --- binary_search ---
%template(binary_search_IntVector) algokit::binary_search<std::vector<int>>;
%template(binary_search_DoubleVector) algokit::binary_search<std::vector<double>>;
%template(binary_search_StrVector) algokit::binary_search<std::vector<std::string>>;
%template(binary_search_IntDeque) algokit::binary_search<std::deque<int>>;
%template(binary_search_DoubleDeque) algokit::binary_search<std::deque<double>>;
%template(binary_search_StrDeque) algokit::binary_search<std::deque<std::string>>;

// --- lower_bound ---
%template(lower_bound_IntVector) algokit::lower_bound<std::vector<int>>;
%template(lower_bound_DoubleVector) algokit::lower_bound<std::vector<double>>;
%template(lower_bound_StrVector) algokit::lower_bound<std::vector<std::string>>;
%template(lower_bound_IntDeque) algokit::lower_bound<std::deque<int>>;
%template(lower_bound_DoubleDeque) algokit::lower_bound<std::deque<double>>;
%template(lower_bound_StrDeque) algokit::lower_bound<std::deque<std::string>>;

// --- upper_bound ---
%template(upper_bound_IntVector) algokit::upper_bound<std::vector<int>>;
%template(upper_bound_DoubleVector) algokit::upper_bound<std::vector<double>>;
%template(upper_bound_StrVector) algokit::upper_bound<std::vector<std::string>>;
%template(upper_bound_IntDeque) algokit::upper_bound<std::deque<int>>;
%template(upper_bound_DoubleDeque) algokit::upper_bound<std::deque<double>>;
%template(upper_bound_StrDeque) algokit::upper_bound<std::deque<std::string>>;

// --- find ---
%template(find_IntVector) algokit::find<std::vector<int>>;
%template(find_DoubleVector) algokit::find<std::vector<double>>;
%template(find_StrVector) algokit::find<std::vector<std::string>>;
%template(find_IntDeque) algokit::find<std::deque<int>>;
%template(find_DoubleDeque) algokit::find<std::deque<double>>;
%template(find_StrDeque) algokit::find<std::deque<std::string>>;

// --- find_if ---
%template(find_if_IntVector) algokit::find_if<std::vector<int>>;
%template(find_if_DoubleVector) algokit::find_if<std::vector<double>>;
%template(find_if_StrVector) algokit::find_if<std::vector<std::string>>;
%template(find_if_IntDeque) algokit::find_if<std::deque<int>>;
%template(find_if_DoubleDeque) algokit::find_if<std::deque<double>>;
%template(find_if_StrDeque) algokit::find_if<std::deque<std::string>>;

// --- count ---
%template(count_IntVector) algokit::count<std::vector<int>>;
%template(count_DoubleVector) algokit::count<std::vector<double>>;
%template(count_StrVector) algokit::count<std::vector<std::string>>;
%template(count_IntDeque) algokit::count<std::deque<int>>;
%template(count_DoubleDeque) algokit::count<std::deque<double>>;
%template(count_StrDeque) algokit::count<std::deque<std::string>>;

// --- count_if ---
%template(count_if_IntVector) algokit::count_if<std::vector<int>>;
%template(count_if_DoubleVector) algokit::count_if<std::vector<double>>;
%template(count_if_StrVector) algokit::count_if<std::vector<std::string>>;
%template(count_if_IntDeque) algokit::count_if<std::deque<int>>;
%template(count_if_DoubleDeque) algokit::count_if<std::deque<double>>;
%template(count_if_StrDeque) algokit::count_if<std::deque<std::string>>;

// --- min_element ---
%template(min_element_IntVector) algokit::min_element<std::vector<int>>;
%template(min_element_DoubleVector) algokit::min_element<std::vector<double>>;
%template(min_element_StrVector) algokit::min_element<std::vector<std::string>>;
%template(min_element_IntDeque) algokit::min_element<std::deque<int>>;
%template(min_element_DoubleDeque) algokit::min_element<std::deque<double>>;
%template(min_element_StrDeque) algokit::min_element<std::deque<std::string>>;

// --- max_element ---
%template(max_element_IntVector) algokit::max_element<std::vector<int>>;
%template(max_element_DoubleVector) algokit::max_element<std::vector<double>>;
%template(max_element_StrVector) algokit::max_element<std::vector<std::string>>;
%template(max_element_IntDeque) algokit::max_element<std::deque<int>>;
%template(max_element_DoubleDeque) algokit::max_element<std::deque<double>>;
%template(max_element_StrDeque) algokit::max_element<std::deque<std::string>>;

// --- minmax_element ---
%template(minmax_element_IntVector) algokit::minmax_element<std::vector<int>>;
%template(minmax_element_DoubleVector) algokit::minmax_element<std::vector<double>>;
%template(minmax_element_StrVector) algokit::minmax_element<std::vector<std::string>>;
%template(minmax_element_IntDeque) algokit::minmax_element<std::deque<int>>;
%template(minmax_element_DoubleDeque) algokit::minmax_element<std::deque<double>>;
%template(minmax_element_StrDeque) algokit::minmax_element<std::deque<std::string>>;

// --- replace ---
%template(replace_IntVector) algokit::replace<std::vector<int>>;
%template(replace_DoubleVector) algokit::replace<std::vector<double>>;
%template(replace_StrVector) algokit::replace<std::vector<std::string>>;
%template(replace_IntDeque) algokit::replace<std::deque<int>>;
%template(replace_DoubleDeque) algokit::replace<std::deque<double>>;
%template(replace_StrDeque) algokit::replace<std::deque<std::string>>;

// --- replace_if ---
%template(replace_if_IntVector) algokit::replace_if<std::vector<int>>;
%template(replace_if_DoubleVector) algokit::replace_if<std::vector<double>>;
%template(replace_if_StrVector) algokit::replace_if<std::vector<std::string>>;
%template(replace_if_IntDeque) algokit::replace_if<std::deque<int>>;
%template(replace_if_DoubleDeque) algokit::replace_if<std::deque<double>>;
%template(replace_if_StrDeque) algokit::replace_if<std::deque<std::string>>;

// --- remove ---
%template(remove_IntVector) algokit::remove<std::vector<int>>;
%template(remove_DoubleVector) algokit::remove<std::vector<double>>;
%template(remove_StrVector) algokit::remove<std::vector<std::string>>;
%template(remove_IntDeque) algokit::remove<std::deque<int>>;
%template(remove_DoubleDeque) algokit::remove<std::deque<double>>;
%template(remove_StrDeque) algokit::remove<std::deque<std::string>>;

// --- remove_if ---
%template(remove_if_IntVector) algokit::remove_if<std::vector<int>>;
%template(remove_if_DoubleVector) algokit::remove_if<std::vector<double>>;
%template(remove_if_StrVector) algokit::remove_if<std::vector<std::string>>;
%template(remove_if_IntDeque) algokit::remove_if<std::deque<int>>;
%template(remove_if_DoubleDeque) algokit::remove_if<std::deque<double>>;
%template(remove_if_StrDeque) algokit::remove_if<std::deque<std::string>>;

// --- unique ---
%template(unique_IntVector) algokit::unique<std::vector<int>>;
%template(unique_DoubleVector) algokit::unique<std::vector<double>>;
%template(unique_StrVector) algokit::unique<std::vector<std::string>>;
%template(unique_IntDeque) algokit::unique<std::deque<int>>;
%template(unique_DoubleDeque) algokit::unique<std::deque<double>>;
%template(unique_StrDeque) algokit::unique<std::deque<std::string>>;

// --- unique_copy ---
%template(unique_copy_IntVector) algokit::unique_copy<std::vector<int>>;
%template(unique_copy_DoubleVector) algokit::unique_copy<std::vector<double>>;
%template(unique_copy_StrVector) algokit::unique_copy<std::vector<std::string>>;
%template(unique_copy_IntDeque) algokit::unique_copy<std::deque<int>>;
%template(unique_copy_DoubleDeque) algokit::unique_copy<std::deque<double>>;
%template(unique_copy_StrDeque) algokit::unique_copy<std::deque<std::string>>;

// --- fill ---
%template(fill_IntVector) algokit::fill<std::vector<int>>;
%template(fill_DoubleVector) algokit::fill<std::vector<double>>;
%template(fill_StrVector) algokit::fill<std::vector<std::string>>;
%template(fill_IntDeque) algokit::fill<std::deque<int>>;
%template(fill_DoubleDeque) algokit::fill<std::deque<double>>;
%template(fill_StrDeque) algokit::fill<std::deque<std::string>>;

// --- fill_n ---
%template(fill_n_IntVector) algokit::fill_n<std::vector<int>>;
%template(fill_n_DoubleVector) algokit::fill_n<std::vector<double>>;
%template(fill_n_StrVector) algokit::fill_n<std::vector<std::string>>;
%template(fill_n_IntDeque) algokit::fill_n<std::deque<int>>;
%template(fill_n_DoubleDeque) algokit::fill_n<std::deque<double>>;
%template(fill_n_StrDeque) algokit::fill_n<std::deque<std::string>>;

// --- generate ---
%template(generate_IntVector) algokit::generate<std::vector<int>>;
%template(generate_DoubleVector) algokit::generate<std::vector<double>>;
%template(generate_StrVector) algokit::generate<std::vector<std::string>>;
%template(generate_IntDeque) algokit::generate<std::deque<int>>;
%template(generate_DoubleDeque) algokit::generate<std::deque<double>>;
%template(generate_StrDeque) algokit::generate<std::deque<std::string>>;

// --- generate_n ---
%template(generate_n_IntVector) algokit::generate_n<std::vector<int>>;
%template(generate_n_DoubleVector) algokit::generate_n<std::vector<double>>;
%template(generate_n_StrVector) algokit::generate_n<std::vector<std::string>>;
%template(generate_n_IntDeque) algokit::generate_n<std::deque<int>>;
%template(generate_n_DoubleDeque) algokit::generate_n<std::deque<double>>;
%template(generate_n_StrDeque) algokit::generate_n<std::deque<std::string>>;

// --- swap_ranges ---
%template(swap_ranges_IntVector) algokit::swap_ranges<std::vector<int>>;
%template(swap_ranges_DoubleVector) algokit::swap_ranges<std::vector<double>>;
%template(swap_ranges_StrVector) algokit::swap_ranges<std::vector<std::string>>;
%template(swap_ranges_IntDeque) algokit::swap_ranges<std::deque<int>>;
%template(swap_ranges_DoubleDeque) algokit::swap_ranges<std::deque<double>>;
%template(swap_ranges_StrDeque) algokit::swap_ranges<std::deque<std::string>>;

// --- rotate ---
%template(rotate_IntVector) algokit::rotate<std::vector<int>>;
%template(rotate_DoubleVector) algokit::rotate<std::vector<double>>;
%template(rotate_StrVector) algokit::rotate<std::vector<std::string>>;
%template(rotate_IntDeque) algokit::rotate<std::deque<int>>;
%template(rotate_DoubleDeque) algokit::rotate<std::deque<double>>;
%template(rotate_StrDeque) algokit::rotate<std::deque<std::string>>;

// --- rotate_copy ---
%template(rotate_copy_IntVector) algokit::rotate_copy<std::vector<int>>;
%template(rotate_copy_DoubleVector) algokit::rotate_copy<std::vector<double>>;
%template(rotate_copy_StrVector) algokit::rotate_copy<std::vector<std::string>>;
%template(rotate_copy_IntDeque) algokit::rotate_copy<std::deque<int>>;
%template(rotate_copy_DoubleDeque) algokit::rotate_copy<std::deque<double>>;
%template(rotate_copy_StrDeque) algokit::rotate_copy<std::deque<std::string>>;

// --- shuffle ---
%template(shuffle_IntVector) algokit::shuffle<std::vector<int>>;
%template(shuffle_DoubleVector) algokit::shuffle<std::vector<double>>;
%template(shuffle_StrVector) algokit::shuffle<std::vector<std::string>>;
%template(shuffle_IntDeque) algokit::shuffle<std::deque<int>>;
%template(shuffle_DoubleDeque) algokit::shuffle<std::deque<double>>;
%template(shuffle_StrDeque) algokit::shuffle<std::deque<std::string>>;

// --- partition ---
%template(partition_IntVector) algokit::partition<std::vector<int>>;
%template(partition_DoubleVector) algokit::partition<std::vector<double>>;
%template(partition_StrVector) algokit::partition<std::vector<std::string>>;
%template(partition_IntDeque) algokit::partition<std::deque<int>>;
%template(partition_DoubleDeque) algokit::partition<std::deque<double>>;
%template(partition_StrDeque) algokit::partition<std::deque<std::string>>;

// --- stable_partition ---
%template(stable_partition_IntVector) algokit::stable_partition<std::vector<int>>;
%template(stable_partition_DoubleVector) algokit::stable_partition<std::vector<double>>;
%template(stable_partition_StrVector) algokit::stable_partition<std::vector<std::string>>;
%template(stable_partition_IntDeque) algokit::stable_partition<std::deque<int>>;
%template(stable_partition_DoubleDeque) algokit::stable_partition<std::deque<double>>;
%template(stable_partition_StrDeque) algokit::stable_partition<std::deque<std::string>>;

// --- partition_copy ---
%template(partition_copy_IntVector) algokit::partition_copy<std::vector<int>>;
%template(partition_copy_DoubleVector) algokit::partition_copy<std::vector<double>>;
%template(partition_copy_StrVector) algokit::partition_copy<std::vector<std::string>>;
%template(partition_copy_IntDeque) algokit::partition_copy<std::deque<int>>;
%template(partition_copy_DoubleDeque) algokit::partition_copy<std::deque<double>>;
%template(partition_copy_StrDeque) algokit::partition_copy<std::deque<std::string>>;

// --- is_partitioned ---
%template(is_partitioned_IntVector) algokit::is_partitioned<std::vector<int>>;
%template(is_partitioned_DoubleVector) algokit::is_partitioned<std::vector<double>>;
%template(is_partitioned_StrVector) algokit::is_partitioned<std::vector<std::string>>;
%template(is_partitioned_IntDeque) algokit::is_partitioned<std::deque<int>>;
%template(is_partitioned_DoubleDeque) algokit::is_partitioned<std::deque<double>>;
%template(is_partitioned_StrDeque) algokit::is_partitioned<std::deque<std::string>>;

// --- partition_point ---
%template(partition_point_IntVector) algokit::partition_point<std::vector<int>>;
%template(partition_point_DoubleVector) algokit::partition_point<std::vector<double>>;
%template(partition_point_StrVector) algokit::partition_point<std::vector<std::string>>;
%template(partition_point_IntDeque) algokit::partition_point<std::deque<int>>;
%template(partition_point_DoubleDeque) algokit::partition_point<std::deque<double>>;
%template(partition_point_StrDeque) algokit::partition_point<std::deque<std::string>>;

// --- merge ---
%template(merge_IntVector) algokit::merge<std::vector<int>>;
%template(merge_DoubleVector) algokit::merge<std::vector<double>>;
%template(merge_StrVector) algokit::merge<std::vector<std::string>>;
%template(merge_IntDeque) algokit::merge<std::deque<int>>;
%template(merge_DoubleDeque) algokit::merge<std::deque<double>>;
%template(merge_StrDeque) algokit::merge<std::deque<std::string>>;

// --- inplace_merge ---
%template(inplace_merge_IntVector) algokit::inplace_merge<std::vector<int>>;
%template(inplace_merge_DoubleVector) algokit::inplace_merge<std::vector<double>>;
%template(inplace_merge_StrVector) algokit::inplace_merge<std::vector<std::string>>;
%template(inplace_merge_IntDeque) algokit::inplace_merge<std::deque<int>>;
%template(inplace_merge_DoubleDeque) algokit::inplace_merge<std::deque<double>>;
%template(inplace_merge_StrDeque) algokit::inplace_merge<std::deque<std::string>>;

// --- set_union ---
%template(set_union_IntVector) algokit::set_union<std::vector<int>>;
%template(set_union_DoubleVector) algokit::set_union<std::vector<double>>;
%template(set_union_StrVector) algokit::set_union<std::vector<std::string>>;
%template(set_union_IntDeque) algokit::set_union<std::deque<int>>;
%template(set_union_DoubleDeque) algokit::set_union<std::deque<double>>;
%template(set_union_StrDeque) algokit::set_union<std::deque<std::string>>;

// --- set_intersection ---
%template(set_intersection_IntVector) algokit::set_intersection<std::vector<int>>;
%template(set_intersection_DoubleVector) algokit::set_intersection<std::vector<double>>;
%template(set_intersection_StrVector) algokit::set_intersection<std::vector<std::string>>;
%template(set_intersection_IntDeque) algokit::set_intersection<std::deque<int>>;
%template(set_intersection_DoubleDeque) algokit::set_intersection<std::deque<double>>;
%template(set_intersection_StrDeque) algokit::set_intersection<std::deque<std::string>>;

// --- set_difference ---
%template(set_difference_IntVector) algokit::set_difference<std::vector<int>>;
%template(set_difference_DoubleVector) algokit::set_difference<std::vector<double>>;
%template(set_difference_StrVector) algokit::set_difference<std::vector<std::string>>;
%template(set_difference_IntDeque) algokit::set_difference<std::deque<int>>;
%template(set_difference_DoubleDeque) algokit::set_difference<std::deque<double>>;
%template(set_difference_StrDeque) algokit::set_difference<std::deque<std::string>>;

// --- set_symmetric_difference ---
%template(set_symmetric_difference_IntVector) algokit::set_symmetric_difference<std::vector<int>>;
%template(set_symmetric_difference_DoubleVector) algokit::set_symmetric_difference<std::vector<double>>;
%template(set_symmetric_difference_StrVector) algokit::set_symmetric_difference<std::vector<std::string>>;
%template(set_symmetric_difference_IntDeque) algokit::set_symmetric_difference<std::deque<int>>;
%template(set_symmetric_difference_DoubleDeque) algokit::set_symmetric_difference<std::deque<double>>;
%template(set_symmetric_difference_StrDeque) algokit::set_symmetric_difference<std::deque<std::string>>;

// --- includes ---
%template(includes_IntVector) algokit::includes<std::vector<int>>;
%template(includes_DoubleVector) algokit::includes<std::vector<double>>;
%template(includes_StrVector) algokit::includes<std::vector<std::string>>;
%template(includes_IntDeque) algokit::includes<std::deque<int>>;
%template(includes_DoubleDeque) algokit::includes<std::deque<double>>;
%template(includes_StrDeque) algokit::includes<std::deque<std::string>>;

// --- make_heap ---
%template(make_heap_IntVector) algokit::make_heap<std::vector<int>>;
%template(make_heap_DoubleVector) algokit::make_heap<std::vector<double>>;
%template(make_heap_StrVector) algokit::make_heap<std::vector<std::string>>;
%template(make_heap_IntDeque) algokit::make_heap<std::deque<int>>;
%template(make_heap_DoubleDeque) algokit::make_heap<std::deque<double>>;
%template(make_heap_StrDeque) algokit::make_heap<std::deque<std::string>>;

// --- push_heap ---
%template(push_heap_IntVector) algokit::push_heap<std::vector<int>>;
%template(push_heap_DoubleVector) algokit::push_heap<std::vector<double>>;
%template(push_heap_StrVector) algokit::push_heap<std::vector<std::string>>;
%template(push_heap_IntDeque) algokit::push_heap<std::deque<int>>;
%template(push_heap_DoubleDeque) algokit::push_heap<std::deque<double>>;
%template(push_heap_StrDeque) algokit::push_heap<std::deque<std::string>>;

// --- pop_heap ---
%template(pop_heap_IntVector) algokit::pop_heap<std::vector<int>>;
%template(pop_heap_DoubleVector) algokit::pop_heap<std::vector<double>>;
%template(pop_heap_StrVector) algokit::pop_heap<std::vector<std::string>>;
%template(pop_heap_IntDeque) algokit::pop_heap<std::deque<int>>;
%template(pop_heap_DoubleDeque) algokit::pop_heap<std::deque<double>>;
%template(pop_heap_StrDeque) algokit::pop_heap<std::deque<std::string>>;

// --- sort_heap ---
%template(sort_heap_IntVector) algokit::sort_heap<std::vector<int>>;
%template(sort_heap_DoubleVector) algokit::sort_heap<std::vector<double>>;
%template(sort_heap_StrVector) algokit::sort_heap<std::vector<std::string>>;
%template(sort_heap_IntDeque) algokit::sort_heap<std::deque<int>>;
%template(sort_heap_DoubleDeque) algokit::sort_heap<std::deque<double>>;
%template(sort_heap_StrDeque) algokit::sort_heap<std::deque<std::string>>;

// --- is_heap ---
%template(is_heap_IntVector) algokit::is_heap<std::vector<int>>;
%template(is_heap_DoubleVector) algokit::is_heap<std::vector<double>>;
%template(is_heap_StrVector) algokit::is_heap<std::vector<std::string>>;
%template(is_heap_IntDeque) algokit::is_heap<std::deque<int>>;
%template(is_heap_DoubleDeque) algokit::is_heap<std::deque<double>>;
%template(is_heap_StrDeque) algokit::is_heap<std::deque<std::string>>;

// --- is_heap_until ---
%template(is_heap_until_IntVector) algokit::is_heap_until<std::vector<int>>;
%template(is_heap_until_DoubleVector) algokit::is_heap_until<std::vector<double>>;
%template(is_heap_until_StrVector) algokit::is_heap_until<std::vector<std::string>>;
%template(is_heap_until_IntDeque) algokit::is_heap_until<std::deque<int>>;
%template(is_heap_until_DoubleDeque) algokit::is_heap_until<std::deque<double>>;
%template(is_heap_until_StrDeque) algokit::is_heap_until<std::deque<std::string>>;

// --- next_permutation ---
%template(next_permutation_IntVector) algokit::next_permutation<std::vector<int>>;
%template(next_permutation_DoubleVector) algokit::next_permutation<std::vector<double>>;
%template(next_permutation_StrVector) algokit::next_permutation<std::vector<std::string>>;
%template(next_permutation_IntDeque) algokit::next_permutation<std::deque<int>>;
%template(next_permutation_DoubleDeque) algokit::next_permutation<std::deque<double>>;
%template(next_permutation_StrDeque) algokit::next_permutation<std::deque<std::string>>;

// --- prev_permutation ---
%template(prev_permutation_IntVector) algokit::prev_permutation<std::vector<int>>;
%template(prev_permutation_DoubleVector) algokit::prev_permutation<std::vector<double>>;
%template(prev_permutation_StrVector) algokit::prev_permutation<std::vector<std::string>>;
%template(prev_permutation_IntDeque) algokit::prev_permutation<std::deque<int>>;
%template(prev_permutation_DoubleDeque) algokit::prev_permutation<std::deque<double>>;
%template(prev_permutation_StrDeque) algokit::prev_permutation<std::deque<std::string>>;

// --- is_permutation ---
%template(is_permutation_IntVector) algokit::is_permutation<std::vector<int>>;
%template(is_permutation_DoubleVector) algokit::is_permutation<std::vector<double>>;
%template(is_permutation_StrVector) algokit::is_permutation<std::vector<std::string>>;
%template(is_permutation_IntDeque) algokit::is_permutation<std::deque<int>>;
%template(is_permutation_DoubleDeque) algokit::is_permutation<std::deque<double>>;
%template(is_permutation_StrDeque) algokit::is_permutation<std::deque<std::string>>;

// --- accumulate ---
%template(accumulate_IntVector) algokit::accumulate<std::vector<int>>;
%template(accumulate_DoubleVector) algokit::accumulate<std::vector<double>>;
%template(accumulate_StrVector) algokit::accumulate<std::vector<std::string>>;
%template(accumulate_IntDeque) algokit::accumulate<std::deque<int>>;
%template(accumulate_DoubleDeque) algokit::accumulate<std::deque<double>>;
%template(accumulate_StrDeque) algokit::accumulate<std::deque<std::string>>;

// --- adjacent_difference ---
%template(adjacent_difference_IntVector) algokit::adjacent_difference<std::vector<int>>;
%template(adjacent_difference_DoubleVector) algokit::adjacent_difference<std::vector<double>>;
%template(adjacent_difference_IntDeque) algokit::adjacent_difference<std::deque<int>>;
%template(adjacent_difference_DoubleDeque) algokit::adjacent_difference<std::deque<double>>;

// --- partial_sum ---
%template(partial_sum_IntVector) algokit::partial_sum<std::vector<int>>;
%template(partial_sum_DoubleVector) algokit::partial_sum<std::vector<double>>;
%template(partial_sum_StrVector) algokit::partial_sum<std::vector<std::string>>;
%template(partial_sum_IntDeque) algokit::partial_sum<std::deque<int>>;
%template(partial_sum_DoubleDeque) algokit::partial_sum<std::deque<double>>;
%template(partial_sum_StrDeque) algokit::partial_sum<std::deque<std::string>>;

// --- inner_product ---
%template(inner_product_IntVector) algokit::inner_product<std::vector<int>>;
%template(inner_product_DoubleVector) algokit::inner_product<std::vector<double>>;
%template(inner_product_IntDeque) algokit::inner_product<std::deque<int>>;
%template(inner_product_DoubleDeque) algokit::inner_product<std::deque<double>>;

// --- iota ---
%template(iota_IntVector) algokit::iota<std::vector<int>>;
%template(iota_DoubleVector) algokit::iota<std::vector<double>>;
%template(iota_IntDeque) algokit::iota<std::deque<int>>;
%template(iota_DoubleDeque) algokit::iota<std::deque<double>>;

