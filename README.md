
# Mongoc.jl

[![License][license-img]](LICENSE)
[![CI][ci-img]][ci-url]
[![appveyor][appveyor-img]][appveyor-url]
[![codecov][codecov-img]][codecov-url]
[![dev][docs-dev-img]][docs-dev-url]
[![stable][docs-stable-img]][docs-stable-url]

[license-img]: https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[ci-img]: https://github.com/felipenoris/Mongoc.jl/workflows/CI/badge.svg
[ci-url]: https://github.com/felipenoris/Mongoc.jl/actions?query=workflow%3ACI
[appveyor-img]: https://img.shields.io/appveyor/ci/felipenoris/mongoc-jl/master.svg?logo=appveyor&label=Windows&style=flat-square
[appveyor-url]: https://ci.appveyor.com/project/felipenoris/mongoc-jl/branch/master
[codecov-img]: https://img.shields.io/codecov/c/github/felipenoris/Mongoc.jl/master.svg?label=codecov&style=flat-square
[codecov-url]: https://codecov.io/github/felipenoris/Mongoc.jl?branch=master
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg?style=flat-square
[docs-dev-url]: https://felipenoris.github.io/Mongoc.jl/dev
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square
[docs-stable-url]: https://felipenoris.github.io/Mongoc.jl/stable

**Mongoc.jl** is a [MongoDB](https://www.mongodb.com/) driver for the Julia Language.

It is implemented as a thin wrapper around [libmongoc](https://mongoc.org/), the official client library for C applications.

Given that [BSON](https://bsonspec.org/) is the document format for MongoDB,
this package also implements a wrapper around [libbson](https://mongoc.org/libbson/current/index.html),
which provides a way to create and manipulate BSON documents.

## Requirements

* MongoDB 3.0 or newer.

* Julia v1.6 or newer.

* Linux, macOS, or Windows.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("Mongoc")
```

## Documentation

The documentation for this package is hosted at https://felipenoris.github.io/Mongoc.jl/stable.

## License

The source code for the package `Mongoc.jl` is licensed under the [MIT License](https://github.com/felipenoris/Mongoc.jl/blob/master/LICENSE).

This repository distributes binary assets built from [mongo-c-driver](https://github.com/mongodb/mongo-c-driver) source code,
which is licensed under [Apache-2.0](https://github.com/mongodb/mongo-c-driver/blob/master/COPYING).
