# Tgrep

Tgrep queries ctags files.


## Usage

```
$ tgrep -h
$ tgrep 'TAG_REGULAR_EXPRESSION' tagfile
```

If *tagfile* is omitted tgrep searches for a file named `tags` from the
current directory down to root directory.


## Caveats

* It's slow for large tagfiles.
* Some features behave badly with non-C/C++ code.
