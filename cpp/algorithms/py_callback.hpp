#pragma once
// Python.h must be the first include in any translation unit that uses
// it (CPython's own requirement, due to feature-test macros it defines).
#include <Python.h>

#include <exception>
#include <stdexcept>
#include <string>

// A minimal, low-overhead wrapper around a Python callable, used by every
// algorithm that needs a predicate (find_if, remove_if, partition, ...)
// or a generator (generate, generate_n).
//
// SWIG's "directors" feature could do this too, but directors generate a
// full virtual-dispatch C++ class per callback type -- built for
// overriding polymorphic classes, not for "call this one Python function
// per element". That's meaningfully more generated code and compile
// time for a job this small. Talking to the Python C API directly here
// keeps the generated code (and the compile cost) proportional to what
// we actually need.
//
// Every algorithm function that needs a callback takes a plain
// `PyObject*` parameter (which SWIG passes straight through natively --
// no custom typemap needed) and constructs a PyCallable from it locally.

namespace algokit {

// Thrown when the user's Python callable itself raised -- CPython has
// already set the real exception (type, message, traceback) on the
// interpreter at that point. The SWIG %exception handler in
// swig/algorithms.i catches this specifically and re-raises via
// SWIG_fail *without* calling PyErr_SetString again, so the user's
// original exception (a ValueError, a custom exception, whatever it was)
// propagates unchanged instead of being replaced by a generic
// RuntimeError.
class PythonError : public std::exception {
public:
    const char* what() const noexcept override {
        return "algokit_ds: the Python callable raised an exception";
    }
};

class PyCallable {
public:
    explicit PyCallable(PyObject* callable) : callable_(callable) {
        Py_XINCREF(callable_);
    }

    PyCallable(const PyCallable& other) : callable_(other.callable_) {
        Py_XINCREF(callable_);
    }

    PyCallable& operator=(const PyCallable&) = delete;

    ~PyCallable() { Py_XDECREF(callable_); }

    // Predicate call: T -> bool. Used by find_if, count_if, remove_if,
    // replace_if, partition*, is_partitioned, partition_point.
    template <typename T>
    bool test(const T& value) const {
        PyObject* arg = to_python(value);
        PyObject* result = PyObject_CallFunctionObjArgs(callable_, arg, nullptr);
        Py_DECREF(arg);
        if (!result) {
            throw PythonError();
        }
        int truthy = PyObject_IsTrue(result);
        Py_DECREF(result);
        if (truthy < 0) {
            throw PythonError();
        }
        return truthy != 0;
    }

    // Generator call: () -> T. Used by generate, generate_n.
    template <typename T>
    T generate() const {
        PyObject* result = PyObject_CallObject(callable_, nullptr);
        if (!result) {
            throw PythonError();
        }
        T value = from_python<T>(result);
        Py_DECREF(result);
        return value;
    }

private:
    PyObject* callable_;

    static PyObject* to_python(int v) { return PyLong_FromLong(v); }
    static PyObject* to_python(double v) { return PyFloat_FromDouble(v); }
    static PyObject* to_python(const std::string& v) {
        return PyUnicode_FromStringAndSize(v.data(), static_cast<Py_ssize_t>(v.size()));
    }

    template <typename T>
    static T from_python(PyObject* obj);
};

template <>
inline int PyCallable::from_python<int>(PyObject* obj) {
    long v = PyLong_AsLong(obj);
    if (v == -1 && PyErr_Occurred()) {
        throw PythonError();
    }
    return static_cast<int>(v);
}

template <>
inline double PyCallable::from_python<double>(PyObject* obj) {
    double v = PyFloat_AsDouble(obj);
    if (v == -1.0 && PyErr_Occurred()) {
        throw PythonError();
    }
    return v;
}

template <>
inline std::string PyCallable::from_python<std::string>(PyObject* obj) {
    Py_ssize_t len = 0;
    const char* buf = PyUnicode_AsUTF8AndSize(obj, &len);
    if (!buf) {
        throw PythonError();
    }
    return std::string(buf, static_cast<std::size_t>(len));
}

} // namespace algokit
