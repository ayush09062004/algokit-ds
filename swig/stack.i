%module stack
%{
#include <stack>
#include <deque>
#include <string>
%}
%include "std_string.i"
%include "std/std_stack.i"

%template(IntStack)    std::stack<int>;
%template(DoubleStack) std::stack<double>;
%template(StrStack)    std::stack<std::string>;
