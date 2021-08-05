# Engine File Systems

Games need to be capable of loading all types of media, from texture bitmaps, to mesh data, to audio clips, game world layouts, etc.

To do this, most games have some kind of abstraction from loading data from the local file system.

Many engines will implement their own file system API to _wrap_ the native API to shield the engine from the underlying low-level details of reading from a file using the operating system.

## File System APIs
A File System (FS) API must support the following features:
* Manipulate file names and paths
* Open, close, read, and write to files
* Scan contents of a directory.
* Async file I/O requests (for streaming)

### FS Differences
* UNIX uses / as a delimiter for its paths.
* Windows uses \ as a delimiter, but recent versions can allows both.
* Mac OS X uses / as a delimiter, since it is based on BSD UNIX. Older versions of Mac uses the colon :.
* Some FS have a case-sensitive filepaths, e.g., UNIX.
* Some FS have case-insensitive filepaths, e.g., Windows.
* UNIX does not support volumes as separate directory hierarchies.
    * Local disk drives, network drives are _mounted_ so that they appear to be subtrees under root.
* Windows does support volumes as separate directory hierarchies.  A disk drive can be specified by letter, e.g., `C:`.   A mount can happen with a letter like a local disk or can be referenced via a volume specifier consisting of two backslashes followed by the remote computer name and the name of a shared directory or resource on that machine.
* Some FS use text after the last `.` to indicate a file's extension.  Others don't care about extensions.
* FS have their own rules for what characters are allowed in a filepath.
* FS may have one or more "current working directories."  Windows has multiple CWDs, one for each volume.

### Search paths
Some engines emulate the `PATH` environment variable by having a string value with a delimiter that indicates the path along which the engine will look for a particular file.

However, doing this at runtime is a little silly.  We should know _exactly_ where all the files are at compile time.

### File I/O
Every file I/O requires data blocks known as `buffer`s to serve as the source or destination of the bytes passing between teh program and the file on disk.

When the API is `buffered`, the API handles the buffer for you.  When the API is `unbuffered`, you have to handle the data buffers yourself.

In C, a `buffered` file I/O are referred to as `stream` I/O because it helps make files on disk just look like a stream of bytes.
