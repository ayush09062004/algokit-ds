%module multimap
%{
#include <map>
#include <string>
%}
%include "std_string.i"
%include "std_multimap.i"

%template(IntIntMultimap)    std::multimap<int, int>;
%template(IntDoubleMultimap) std::multimap<int, double>;
%template(StrIntMultimap)    std::multimap<std::string, int>;
%template(StrStrMultimap)    std::multimap<std::string, std::string>;
