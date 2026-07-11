%module multiset
%{
#include <set>
#include <string>
%}
%include "std_string.i"
%include "std_multiset.i"

%template(IntMultiset)    std::multiset<int>;
%template(DoubleMultiset) std::multiset<double>;
%template(StrMultiset)    std::multiset<std::string>;
