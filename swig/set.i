%module set
%{
#include <set>
#include <string>
%}
%include "std_string.i"
%include "std_set.i"

%template(IntSet)    std::set<int>;
%template(DoubleSet) std::set<double>;
%template(StrSet)    std::set<std::string>;
