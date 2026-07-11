%module deque
%{
#include <deque>
#include <string>
%}
%include "std_string.i"
%include "std_deque.i"

%template(IntDeque)    std::deque<int>;
%template(DoubleDeque) std::deque<double>;
%template(StrDeque)    std::deque<std::string>;
