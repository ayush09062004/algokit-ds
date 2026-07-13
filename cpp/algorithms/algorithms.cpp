// Explicit instantiations of the algokit:: algorithm templates for every
// container/type combination currently supported. This keeps the actual
// template bodies out of algorithms.hpp's callers (SWIG's generated
// wrap.cxx just declares + calls these, it doesn't need to re-instantiate
// them), and gives future contributors one obvious place to add a line
// when a new container/type combination gets support.
//
// Deliberately covers only the original v1.0.0 six -- see the note at
// the top of algorithms.hpp for why algorithms added afterward rely on
// implicit instantiation instead of being added here too.

#include "algorithms.hpp"

#include <deque>
#include <string>
#include <vector>

namespace algokit {

#define ALGOKIT_INSTANTIATE(Container, T)                                    \
    template void sort(Container<T>&);                                      \
    template void stable_sort(Container<T>&);                               \
    template void reverse(Container<T>&);                                   \
    template bool binary_search(const Container<T>&, const T&);             \
    template Container<T>::difference_type lower_bound(const Container<T>&, const T&); \
    template Container<T>::difference_type upper_bound(const Container<T>&, const T&);

ALGOKIT_INSTANTIATE(std::vector, int)
ALGOKIT_INSTANTIATE(std::vector, double)
ALGOKIT_INSTANTIATE(std::vector, std::string)

ALGOKIT_INSTANTIATE(std::deque, int)
ALGOKIT_INSTANTIATE(std::deque, double)
ALGOKIT_INSTANTIATE(std::deque, std::string)

#undef ALGOKIT_INSTANTIATE

} // namespace algokit
