# Ownership

Rust designers chose to not call references "pointers", because they come with special semantic meanings and restrictions.

There are two kinds of reference:

* Shared reference: `&`
* Mutable reference: `&mut`

There are two rules that all references must follow:

* A reference cannot outlive its referent.
* A mutable reference cannot be *aliased*.

## What is "aliasing"?

Variables, References, and Pointers *alias* if they refer to overlapping regions of memory.

> This definition may change (may become tighter) as Rust devs hone the definition further.

Alias analysis allows the compiler to perform useful/powerful optimizations.

## Lifetimes

Lifetimes are named regions of code that a reference must be valid for.  Regions may be fairly complex, since they correspond to execution paths (which may branch).  It's possible to invalidate a reference as long as it's reinitialized before it's used again.

Each `let` statement implicitly introduces a scope.
