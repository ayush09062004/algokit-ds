%module map
%{
#include <map>
#include <string>
%}
%include "std_string.i"
%include "std_map.i"

%template(IntIntMap)    std::map<int, int>;
%template(IntDoubleMap) std::map<int, double>;
%template(StrIntMap)    std::map<std::string, int>;
%template(StrStrMap)    std::map<std::string, std::string>;
