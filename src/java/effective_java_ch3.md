# Methods Common to All Objects

Each of `Object`'s nonfinal methods have a _general contract_ that should be upheld since they are meant to be overridden.  These nonfinal methods include::
* `equals`
* `hashCode`
* `toString`
* `clone`
* `finalize` (but you shouldn't even use this one. avoid finalizers and cleaners.)

## Obey the general contract when overriding `equals`

First, don't even override `equals` if any of the following apply:
1. Each instance of the class is inherently unique (like an enum)
1. There is no need for the class to provide a "logical equality" test.  For example, two differnet instances of a `Point` object that have the same `x` and `y` value would be "logically equal".
1. A superclass has already overriden equals and the superclass behavior is appropriate for your subclass.
1. The class is `private` or `package-private`, and you are certain that its `equals` method will never be invoked.
