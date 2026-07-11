%module vector
%{
#include <vector>
#include <string>
%}
%include "std_string.i"
%include "std_vector.i"

%template(IntVector)    std::vector<int>;
%template(DoubleVector) std::vector<double>;
%template(StrVector)    std::vector<std::string>;
