%module algorithms
%{
#include "algorithms.hpp"
%}

%include "std_string.i"
%include "std_vector.i"
%include "std_deque.i"

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

%include "algorithms.hpp"

// --- std::vector<T> -------------------------------------------------------
%template(sort_IntVector)             algokit::sort<std::vector<int>>;
%template(sort_DoubleVector)          algokit::sort<std::vector<double>>;
%template(sort_StrVector)             algokit::sort<std::vector<std::string>>;

%template(stable_sort_IntVector)      algokit::stable_sort<std::vector<int>>;
%template(stable_sort_DoubleVector)   algokit::stable_sort<std::vector<double>>;
%template(stable_sort_StrVector)      algokit::stable_sort<std::vector<std::string>>;

%template(reverse_IntVector)          algokit::reverse<std::vector<int>>;
%template(reverse_DoubleVector)       algokit::reverse<std::vector<double>>;
%template(reverse_StrVector)          algokit::reverse<std::vector<std::string>>;

%template(binary_search_IntVector)    algokit::binary_search<std::vector<int>>;
%template(binary_search_DoubleVector) algokit::binary_search<std::vector<double>>;
%template(binary_search_StrVector)    algokit::binary_search<std::vector<std::string>>;

%template(lower_bound_IntVector)      algokit::lower_bound<std::vector<int>>;
%template(lower_bound_DoubleVector)   algokit::lower_bound<std::vector<double>>;
%template(lower_bound_StrVector)      algokit::lower_bound<std::vector<std::string>>;

%template(upper_bound_IntVector)      algokit::upper_bound<std::vector<int>>;
%template(upper_bound_DoubleVector)   algokit::upper_bound<std::vector<double>>;
%template(upper_bound_StrVector)      algokit::upper_bound<std::vector<std::string>>;

// --- std::deque<T> ---------------------------------------------------------
%template(sort_IntDeque)              algokit::sort<std::deque<int>>;
%template(sort_DoubleDeque)           algokit::sort<std::deque<double>>;
%template(sort_StrDeque)              algokit::sort<std::deque<std::string>>;

%template(stable_sort_IntDeque)       algokit::stable_sort<std::deque<int>>;
%template(stable_sort_DoubleDeque)    algokit::stable_sort<std::deque<double>>;
%template(stable_sort_StrDeque)       algokit::stable_sort<std::deque<std::string>>;

%template(reverse_IntDeque)           algokit::reverse<std::deque<int>>;
%template(reverse_DoubleDeque)        algokit::reverse<std::deque<double>>;
%template(reverse_StrDeque)           algokit::reverse<std::deque<std::string>>;

%template(binary_search_IntDeque)     algokit::binary_search<std::deque<int>>;
%template(binary_search_DoubleDeque)  algokit::binary_search<std::deque<double>>;
%template(binary_search_StrDeque)     algokit::binary_search<std::deque<std::string>>;

%template(lower_bound_IntDeque)       algokit::lower_bound<std::deque<int>>;
%template(lower_bound_DoubleDeque)    algokit::lower_bound<std::deque<double>>;
%template(lower_bound_StrDeque)       algokit::lower_bound<std::deque<std::string>>;

%template(upper_bound_IntDeque)       algokit::upper_bound<std::deque<int>>;
%template(upper_bound_DoubleDeque)    algokit::upper_bound<std::deque<double>>;
%template(upper_bound_StrDeque)       algokit::upper_bound<std::deque<std::string>>;
