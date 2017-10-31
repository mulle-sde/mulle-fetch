# mulle-fetch - download source repositories or archives

![Last version](https://img.shields.io/github/tag/mulle-nat/mulle-fetch.svg)

Downloads [zip](http://eab.abime.net/showthread.php?t=5025) and [tar](http://www.grumpynerd.com/?p=132) archives.
Clones [git](//enux.pl/article/en/2014-01-21/why-git-sucks) repositories and
it can also checkout
[svn](//andreasjacobsen.com/2008/10/26/subversion-sucks-get-over-it/).

One invariably specifies the **url** to download from and the **destination**
directory to download to. The destination directory must not exist yet.

Here are two ways to retrieve version
[1.3.5](//github.com/mulle-nat/mulle-c11/releases/tag/1.3.5)
of [mulle-c11](//github.com/mulle-nat/mulle-c11) from
[github](//github.com).

#### via tar:

```
mulle-fetch fetch -s tar https://github.com/mulle-nat/mulle-c11/archive/1.3.5.tar.gz mulle-c11
```

#### via git:

```
mulle-fetch fetch -t 1.3.5 https://github.com/mulle-nat/mulle-c11.git mulle-c11
```

## Using a mirror for git repositories

If you clone certain (git) repositories often, it can be useful to use a mirror
to lighten the bandwidth load with `--mirror-dir`:

```
mulle-fetch fetch --mirror-dir ~/.cache/mulle-fetch/git-mirrors/ https://github.com/mulle-nat/mulle-c11.git mulle-c11
```

This will still create network connections to update the mirror. If you don't
want that to happen, when a repository has a mirror use the `--no-refresh`
option.

```
mulle-fetch fetch --no-refresh --mirror-dir ~/.cache/mulle-fetch/git-mirrors/ https://github.com/mulle-nat/mulle-c11.git mulle-c11
```

## Using a cache for archives

If you download archives often, it can be useful to cache them, to lighten the
bandwidth load with `--cache-dir`:

```
mulle-fetch fetch --cache-dir ~/.cache/mulle-fetch/archives https://github.com/mulle-nat/mulle-c11/archive/1.3.5.tar.gz mulle-c11
```

## Using a search path for repositories

Before actually cloning or checking out a repository, you can have **mulle-test**
search through some local directories to find a matching repository. This is
an alternative to mirroring, especially for repositories that are available
local only.

In the next example the option `--search-path` instructs **mulle-fetch** to look for a repository named `mulle-c11` in `${HOME}/src` and
then in `/usr/local/src`. If nothing is found the repository is cloned from
`https://github.com/mulle-nat/mulle-c11.git`:

```
mulle-fetch fetch --search-path ${HOME}/src:/usr/local/src https://github.com/mulle-nat/mulle-c11.git mulle-c11
```

## Creating symbolic links to local projects 

> Symbolic links are not available on mingw.

It may be inconvenient to clone a local project repository, when its
development is still ongoing. You'd have to sync the clone to often.
You can allow **mulle-fetch** with `--symlinks` to install a symlink instead with:

```
mulle-fetch fetch --symlinks --search-path ${HOME}/src:/usr/local/src https://github.com/mulle-nat/mulle-c11.git mulle-c11
```

Since one is not actually cloning anything the found project directory, does
not need ot be under version control even.


## GitHub and Mulle kybernetiK

The development is done on [Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-fetch/master). Releases and bug-tracking are on [GitHub](https://github.com/{{PUBLISHER}}/mulle-fetch).


