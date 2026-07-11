%module unordered_multiset
%{
#include <unordered_set>
#include <string>
%}
%include "std_string.i"
%include "std_unordered_multiset.i"

%template(IntUnorderedMultiset)    std::unordered_multiset<int>;
%template(DoubleUnorderedMultiset) std::unordered_multiset<double>;
%template(StrUnorderedMultiset)    std::unordered_multiset<std::string>;
