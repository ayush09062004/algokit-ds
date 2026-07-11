%module unordered_map
%{
#include <unordered_map>
#include <string>
%}
%include "std_string.i"
%include "std_unordered_map.i"

%template(IntIntUnorderedMap)    std::unordered_map<int, int>;
%template(IntDoubleUnorderedMap) std::unordered_map<int, double>;
%template(StrIntUnorderedMap)    std::unordered_map<std::string, int>;
%template(StrStrUnorderedMap)    std::unordered_map<std::string, std::string>;
