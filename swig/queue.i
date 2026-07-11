%module queue
%{
#include <queue>
#include <deque>
#include <string>
%}
%include "std_string.i"
%include "std/std_queue.i"

%template(IntQueue)    std::queue<int>;
%template(DoubleQueue) std::queue<double>;
%template(StrQueue)    std::queue<std::string>;
