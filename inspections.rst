Experiments with Bazel queries and aspects to inspect targets
============================================================= 

- Exploring targets

  .. code-block:: bash

    bazel query //tools/sphinx/codelinks/...

- Find all ``codelinks_analyse`` rule type

  .. code-block:: bash

    bazel query 'kind(codelinks_analyse, //...)'

- Print out the source files of ``codelinks_analyse`` target in ``//projects/acdc/ac``

  .. code-block:: bash

    bazel build //projects/acdc/ac:codelinks_analyse --aspects print.bzl%print_aspect

- print out the source files of all ``codelinks_analyse`` targets used in the repo

  .. code-block:: bash

    bazel build $(bazel query "kind(codelinks_analyse, //...)") --aspects //:print.bzl%print_aspect

- Find all targets that depends on file ``projects/acdc/ac:src/ac.c``

  .. code-block:: bash

    bazel query "rdeps(//..., //projects/acdc/ac:src/ac.c)"

- Find which targets of a specific kind depend on a certain file
  
  .. code-block:: bash
    
    bazel query "kind(codelinks_analyse, rdeps(//..., //projects/acdc/ac:codelinks.toml))"
