# Performance

## Strings

* Comparing strings is computationally expensive because you have to compare two arrays of bytes together to determine equality.
* Don't use Strings as a unique identifier for resources in your game.  You will want to coerce strings to a more an easily compared object (like a number).  This can be done with a hash function.
* Does your string class treat all String buffers as read-only?
* Does it utilize `copy on write` optimizations?  See: [https://en.wikipedia.org/wiki/Copy-on-write](https://en.wikipedia.org/wiki/Copy-on-write).
* Does the String class own the memory associated with the string, or does it just reference memory that it does not own?
* As a rule of thumb, always pass String objects by reference, never by value. (Doing so by value typically incurs string-copying costs.)

#### Interning a String
One technique used at _Naughty Dog_ and on other game engines like the _Unreal_ engine is to transform strings into a `string_id` by hashing the strings.

* If you go with this option, be wary of hash collisions.
* If you have a 32-bit hash code, the hash space is more than 4 billion possible values.
* In cases of a collision, _Naughty Dog_ typically just adds another character to the String before hashing.
* In _The Last of Us Part II_, the _Naughty Dog_ team moved to a 64-bit hashing function.
* _Naughty Dog_ uses a pre-compilation step to identify and hash strings in their source code before compilation.
* Once the character array is hashed, the original character array is usually placed in a global string registry so that it can be retrieved by hash later.

```cpp
static HashTable<StringId, const char*> gStringIdTable;

StringId internString(const char* str)
{
    StringId sid = hashCrc32(str);

    HashTable<StringId, const char*>::iterator it
        = gStringIdTable.find(sid);

    if (it == gStringTable.end())
    {
        gStringTable[sid] = strdup(str);
    }

    return sid;
}
```

#### String ID Classes
Instead of a String class, (and perhaps instead of the global String registry), the _Unreal_ engine wraps a hashed StringId and a pointer to the character array in a tiny class called `FName`.

#### Dropping Strings at finalization
For the `release` version of the game, it is common to stop using the Strings entirely altogether in lieu of the StringIds alone.

For this reason, the global string registry is often stored in "debug" memory (where appropriate) and is conditionally compiled out of the binary.
