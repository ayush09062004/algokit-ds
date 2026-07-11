%module unordered_set
%{
#include <unordered_set>
#include <string>
%}
%include "std_string.i"
%include "std_unordered_set.i"

%template(IntUnorderedSet)    std::unordered_set<int>;
%template(DoubleUnorderedSet) std::unordered_set<double>;
%template(StrUnorderedSet)    std::unordered_set<std::string>;
