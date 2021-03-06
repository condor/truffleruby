# 1.0 RC 2, May 2018

New features:

* We are now compatible with Ruby 2.4.4.

* `object.class` on a Java `Class` object will give you an object on which you
  can call instance methods, rather than static methods which is what you get by
  default.

* The log level can now also be set with `-Dtruffleruby.log=info` or
  `TRUFFLERUBY_LOG=info`.

* `-Xbacktraces.raise` will print Ruby backtraces whenever an exception is
  raised.

* `Java.import name` imports Java classes as top-level constants.

* Coercion of foreign numbers to Ruby numbers now works.

* `to_s` works on all foreign objects and calls the Java `toString`.

* `to_str` will try to `UNBOX` and then re-try `to_str`, in order to provoke
  the unboxing of foreign strings.

Changes:

* The version string now mentions `GraalVM CE` or `EE`.

* The inline JavaScript functionality `-Xinline_js` has been removed.

* Line numbers `< 0`, in the various eval methods, are now warned about, because
  we don't support these at all. Line numbers `> 1` are warned about (at the
  fine level) but the are shimmed by adding blank lines in front to get to the
  correct offset. Line numbers starting at `0` are also warned about at the fine
  level and set to `1` instead.
  
* The `erb` standard library has been patched to stop using a -1 line number.

* `-Xbacktraces.interleave_java` now includes all the trailing Java frames.

* Objects with a `[]` method, except for `Hash`, now do not return anything
  for `KEYS`, to avoid the impression that you could `READ` them. `KEYINFO`
  also returns nothing for these objects, except for `Array` where it returns
  information on indices.

* `String` now returns `false` for `HAS_KEYS`.

* The supported additional functionality module has been renamed from `Truffle`
  to `TruffleRuby`. Anything not documented in
  `doc/user/truffleruby-additions.md` should not be used.
  
* Imprecise wrong gem directory detection was replaced. TruffleRuby newly marks
  its gem directories with a marker file, and warns if you try to use 
  TruffleRuby with a gem directory which is lacking the marker. 

Bug fixes:

* TruffleRuby on SubstrateVM now correctly determines the system timezone.

* `Kernel#require_relative` now coerces the feature argument to a path and
  canonicalizes it before requiring, and it now uses the current directory as
  the directory for a synthetic file name from `#instance_eval`.

# 1.0 RC 1, April 2018

New features:

* The Ruby version has been updated to version 2.3.7.

Security:

* CVE-2018-6914, CVE-2018-8779, CVE-2018-8780, CVE-2018-8777, CVE-2017-17742
  and CVE-2018-8778 have been mitigated.

Changes:

* `RubyTruffleError` has been removed and uses replaced with standard
  exceptions.

* C++ libraries like `libc++` are now not needed if you don't run C++
  extensions. `libc++abi` is now never needed. Documentation updated to make it
  more clear what the minimum requirements for pure Ruby, C extensions, and C++
  extensions separately.

* C extensions are now built by default - `TRUFFLERUBY_CEXT_ENABLED` is assumed
  `true` unless set to `false`.
  
* The `KEYS` interop message now returns an array of Java strings, rather than
  Ruby strings. `KEYS` on an array no longer returns indices.
  
* `HAS_SIZE` now only returns `true` for `Array`.

* A method call on a foreign object that looks like an operator (the method name
  does not begin with a letter) will call `IS_BOXED` on the object and based on
  that will possibly `UNBOX` and convert to Ruby.
  
* Now using the native version of Psych.

* The supported version of LLVM on Oracle Linux has been dropped to 3.8.

* The supported version of Fedora has been dropped to 25, and the supported
  version of LLVM to 3.8, due to LLVM incompatibilities. The instructions for
  installing `libssl` have changed to match.

# 0.33, April 2018

New features:

* The Ruby version has been updated to version 2.3.6.

* Context pre-initialization with TruffleRuby `--native`, which significantly
  improves startup time and loads the `did_you_mean` gem ahead of time.
  
* The default VM is changed to SubstrateVM, where the startup is significantly 
  better. Use `--jvm` option for full JVM VM.
  
* The `Truffle::Interop` module has been replaced with a new `Polyglot` module
  which is designed to use more idiomatic Ruby syntax rather than explicit
  methods. A [new document](doc/user/polyglot.md) describes polyglot programming
  at a higher level.
  
* The `REMOVABLE`, `MODIFIABLE` and `INSERTABLE` Truffle interop key info flags
  have been implemented.

* `equal?` on foreign objects will check if the underlying objects are equal
  if both are Java interop objects.

* `delete` on foreign objects will send `REMOVE`, `size` will send `GET_SIZE`,
  and `keys` will send `KEYS`. `respond_to?(:size)` will send `HAS_SIZE`,
  `respond_to?(:keys)` will send `HAS_KEYS`.

* Added a new Java-interop API similar to the one in the Nashorn JavaScript
  implementation, as also implemented by Graal.js. The `Java.type` method
  returns a Java class object on which you can use normal interop methods. Needs
  the `--jvm` flag to be used.

* Supported and tested versions of LLVM for different platforms have been more
  precisely [documented](doc/user/installing-llvm.md).

Changes:

* Interop semantics of `INVOKE`, `READ`, `WRITE`, `KEYS` and `KEY_INFO` have
  changed significantly, so that `INVOKE` maps to Ruby method calls, `READ`
  calls `[]` or returns (bound) `Method` objects, and `WRITE` calls `[]=`.

Performance:

* `Dir.glob` is much faster and more memory efficient in cases that can reduce
  to direct filename lookups.

* `SecureRandom` now defers loading OpenSSL until it's needed, reducing time to
  load `SecureRandom`.

* `Array#dup` and `Array#shift` have been made constant-time operations by
  sharing the array storage and keeping a starting index.

Bug fixes:

* Interop key-info works with non-string-like names.

Internal changes:

* Changes to the lexer and translator to reduce regular expression calls.

* Some JRuby sources have been updated to 9.1.13.0.

# 0.32, March 2018

New features:

* A new embedded configuration is used when TruffleRuby is used from another
  language or application. This disables features like signals which may
  conflict with the embedding application, and threads which may conflict with
  other languages, and enables features such as the use of polyglot IO streams.

Performance:

* Conversion of ASCII-only Ruby strings to Java strings is now faster.
* Several operations on multi-byte character strings are now faster.
* Native I/O reads are ~22% faster.

Bug fixes:

* The launcher accepts `--native` and similar options in  the `TRUFFLERUBYOPT`
environment variable.

Internal changes:

* The launcher is now part of the TruffleRuby repository, rather than part of
the GraalVM repository.

* `ArrayBuilderNode` now uses `ArrayStrategies` and `ArrayMirrors` to remove
direct knowledge of array storage.

* `RStringPtr` and `RStringPtrEnd` now report as pointers for interop purposes,
fixing several issues with `char *` usage in C extensions.
