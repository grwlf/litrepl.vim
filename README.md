LitREPL
=======

**LitREPL** is a command-line tool and a Vim plugin for [literate
programming](https://en.wikipedia.org/wiki/Literate_programming) in Python,
aimed at providing user-friendly code editing and execution workflows.


~~~~ markdown
Consider a Markdown document.

``` python
print("Hello, World!")
```

Having LitREPL tool and plugin installed, users get :LEval,
:LEvalAsync or other commands to run Python code sections right
in the editor.

``` result
Hello, World!
```

The execution takes place in a background interpreter, tied to the UNIX pipes
residing in the filesystem.
~~~~

<details><summary>Features</summary><p>

* Supported document formats: Markdown [[MD]](./doc/example.md), Latex
  [[TEX]](./doc/example.tex)[[PDF]](./doc/example.pdf).
* Supported Python interpreters: Python, IPython
* Supported modes: Vim, Command-line

</p></details>

<details><summary>Requirements</summary><p>

* POSIX-compatible OS, typically a Linux. The plugin relies on POSIX pipes and
  depends on certain shell commands.
* More or less recent `Vim`
* Python3 with the following libraries: `lark-parser` (Required).
* Command line tools: `GNU socat` (Optional), `ipython` (Optional).

</p></details>

Contents
--------

<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
* [Usage](#usage)
    * [Text formatting](#text-formatting)
    * [Reference](#reference)
        * [Commands](#commands)
        * [Variables and arguments](#variables-and-arguments)
    * [Examples](#examples)
        * [Vim, basic usage](#vim-basic-usage)
        * [Vim, basic keybindings](#vim-basic-keybindings)
        * [Vim, basic keybindings](#vim-basic-keybindings-1)
    * [Vim, shell command in a section](#vim-shell-command-in-a-section)
        * [Shell, basic usage](#shell-basic-usage)
* [Development](#development)
    * [Development shells](#development-shells)
    * [Common workflows](#common-workflows)
    * [Other Nix targets](#other-nix-targets)
* [Gallery](#gallery)
* [Technical details](#technical-details)
* [Limitations](#limitations)
* [Related projects](#related-projects)
* [Third-party issues](#third-party-issues)

<!-- vim-markdown-toc -->

Installation
------------

The repository includes a Python tool and an interface Vim plugin. The Python
part should be installed with `pip install` as usual. The Vim part requires
plugin manager like `Plug` or hand-copying files to a .vim config folder.

The generic installation procedure:

<details><summary>Pip-install and Vim-Plug</summary><p>

Instructions for the Python Pip and [Vim Plug](https://github.com/junegunn/vim-plug):

1. Install the `litrepl` Python package with pip:
   ```sh
   $ pip install --user git+https://github.com/grwlf/litrepl.vim
   $ litrepl --version
   ```
2. Install the Vim plugin by adding the following line between the
   `plug#begin` and `plug#end` lines of your `.vimrc` file:
   ```vim
   Plug 'https://github.com/grwlf/litrepl.vim' , { 'rtp': 'vim' }
   ```
   Note: `rtp` sets the custom vim-plugin source directory of the plugin.

</p></details>

Alternatively, Nix/NixOS users can follow the formalized path:

<details><summary>Nix and vim_configurable</summary><p>

Nix supports
[configurable Vim expressions](https://nixos.wiki/wiki/Vim#System_wide_vim.2Fnvim_configuration).
To enable the Litrepl plugin, just add the `vim-litrepl.vim-litrepl-release` to the
list of Vim packages.

``` nix
let
  vim-litrepl = import <path/to/litrepl.vim> {};
in
vim_configurable.customize {
  name = "vim";
  vimrcConfig.packages.myVimPackage = with pkgs.vimPlugins; {
    start = [
      ...
      vim-litrepl.vim-litrepl-release
      ...
    ];
  };
}
```

Note: `vim-demo` expression from the [default.nix](./default.nix) provides
an example Vim configuration. Use `nix build '.#vim-demo'` to build it and then
`./result/bin/vim-demo` to run the editor.

See the [Development](#development) section for more details.

</p></details>

Usage
-----

### Text formatting

LaTeX:

``` tex
\begin{lcode}
print('Code here!')
\end{lcode}

\begin{lresult}
Code here!
\end{lresult}
```

Markdown:

~~~~ markdown
``` python
print('Code here!')
```

``` result
Code here!
```
~~~~

For more options, see:

* [Formatting Markdown documents](./doc/formatting.md#markdown)
* [Formatting LaTeX documents](./doc/formatting.md#latex)

### Reference

#### Commands

| Vim             | Command line         | Description                          |
|-----------------|----------------------|--------------------------------------|
| `:LStart`       | `litepl start`       | Start the interpreter     |
| `:LStop`        | `litepl stop`        | Stop the interpreter      |
| `:LStatus`      | `litepl status <F`     | Print the daemon status |
| `:LRestart`     | `litrepl restart`    | Restart the interpreter   |
| `:LEval N`      | `lirtepl eval-sections (N\|L:C) <F`   | Run or update section under the cursor and wait until the completion |
| `:LEvalAbove N` | `lirtepl eval-sections '0..(N\|L:C)' <F`| Run sections above and under the cursor and wait until the completion |
| `:LEvalBelow N` | `lirtepl eval-sections '(N\|L:C)..$' <F`| Run sections below and under the cursor and wait until the completion |
| `:LEvalAsync N` | `lirtepl --timeout-initial=0.5 --timeout-continue=0 eval-sections (N\|L:C) <F` | Run section under the cursor and wait a bit before going asynchronous. Also, update the output from the already running section. |
| `:LInterrupt`   | `lirtepl interrupt (N\|L:C) <F`       | Send Ctrl+C signal to the interpreter and get a feedback |
| `:LEvalAll`     | `lirtepl eval-sections '0..$' <F`       | Evaluate all code sections |
|                 | `lirtepl eval-code <P`                  | Evaluate the given Python code |
| `:LTerm`        | `lirtepl repl`       | Open the terminal to the interpreter |
| `:LOpenErr`     | N/A                  | Open the stderr window    |
| `:LVersion`     | `litrepl --version`  | Show version              |

Where

* `F` denotes the document
* `P` denotes the Python code
* `N` denotes the number of code section starting from 0.
* `L:C` denotes line:column of the cursor.


#### Variables and arguments


| Vim setting               | CLI argument         | Description                       |
|---------------------------|----------------------|-----------------------------------|
| `set filetype`            | `--filetype=T`       | Input file type: `latex`\|`markdown` |
| N/A                       | `--interpreter=I`    | The interpreter to use: `python`\|`ipython`\|`auto` (the default) |
| `let g:litrepl_debug=0/1` |  `--debug=1`         | Print debug messages to the stderr |
| `let g:litrepl_errfile="/tmp/litrepl.vim"` |  N/A  | Intermediary file for debug and error messages |
| `let g:litrepl_always_show_stderr=0/1`     |  N/A  | Set to auto-open stderr window after each execution |
| `let g:litrepl_timeout=FLOAT` |  `--timeout-initial=FLOAT` | Timeout to wait for the new executions, in seconds, defaults to inf |
| N/A                           |  `--timeout-continue=FLOAT`| Timeout to wait for executions which are already running, in seconds, defaults to inf |

* `I` is taken into account by the `start` command or by the first call to
  `eval-sections`.

### Examples

#### Vim, basic usage

1. Open Markdown or Latex document in Vim.
2. Type the code and result sections, for example:
    ~~~~ markdown
    ``` python
    print('Code here!')
    ```

    ``` result
    Code here!
    ```
    ~~~~
3. Move the cursor to either of sections.
4. Execute `:LEval` Vim command. The contents of the result section will be
   set to contain the output of the code section.

#### Vim, basic keybindings

The plugin does not define any key bindings, but users could do it by themselves,
for example:

```vim
nnoremap <F5> :LEval<CR>
nnoremap <F6> :LEvalAsync<CR>
```

#### Vim, basic keybindings

The plugin does not define any key bindings, but users could do it by themselves,
for example:

```vim
nnoremap <F5> :LEval<CR>
nnoremap <F6> :LEvalAsync<CR>
```

### Vim, shell command in a section

Thanks to the IPython features, we can use exclamation to run shell commands
directly from Python code sections.

~~~~
``` python
!cowsay "Hi Litrepl"
```

``` result
 ____________ 
< Hi Litrepl >
 ------------ 
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
~~~~

#### Shell, basic usage

To evaluate code section in a document:

```sh
$ cat doc/example.md | litrepl --filetype=markdown --interpreter=ipython \
                               eval-sections 0..$ >output.md
```

To evaluate a Python script:

```sh
$ cat script.py | litrepl --interpreter=ipython eval-code
```

Development
-----------

This project uses [Nix](https://nixos.org/nix) as a primary development
framework. [flake.nix](./flake.nix) handles the source-level Nix dependencies
while the [default.nix](./default.nix) defines the common build targets
including Pypi and Vim packages, demo Vim configurations, development shells,
etc.

### Development shells

The default development shell is defined in the `./default.nix` as a Nix
expression named `shell`. Nix makes sure that all the dependencies are available
inside. To enter this shell, run:

``` sh
$ nix develop
```

Another shell which might be useful is `shell-screencast`. To run it, specify
the full Nix-flake path as follows:

``` sh
$ nix develop '.#shell-screencast'
```

### Common workflows

The top-level [Makefile](./Makefile) encodes typical workflows to be executed
from within the development shell:

``` sh
[LitREPL-develop] $ make help
LitREPL is a macroprocessing Python library for Litrate programming and code execution
Build targets:
help:       Print help
test:       Run the test script (./sh/test.sh)
wheel:      Build Python wheel (the DEFAULT target)
version:    Print the version
upload:     Upload wheel to Pypi.org (./_token.pypi is required)
```

### Other Nix targets

To build individual Nix expressions, run the `nix build '.#NAME'` passing the
name of the expression to build. If succeeded, Nix publishes the last build
results under the `./result` symlink.

``` sh
$ nix build '.#vim-demo'
$ ./result/bin/vim-demo  # Run the pre-configured demo instance of Vim
```

The list of Nix build targets includes:

* `litrepl-release` - Litrepl script and Python lib
* `litrepl-release-pypi` - Litrepl script and Python lib
* `vim-litrepl-release` - Vim with locally built litrepl plugin
* `vim-litrepl-release-pypi` - Vim with litrepl plugin built from PYPI
* `vim-test` - A minimalistic Vim with a single litrepl plugin
* `vim-demo` - Vim configured to use litrepl suitable for recording screencasts
* `vim-plug` - Vim configured to use litrepl via the Plug manager
* `shell-dev` - The development shell
* `shell-screencast` - The shell for recording demonstrations, includes `vim-demo`.

Gallery
-------

Basic usage

<img src="https://github.com/grwlf/litrepl-media/blob/main/demo.gif?raw=true" width="400"/>

Using LitREPL in combination with the [Vimtex](https://github.com/lervag/vimtex)
plugin to edit Latex documents on the fly.


<video controls src="https://user-images.githubusercontent.com/4477729/187065835-3302e93e-6fec-48a0-841d-97986636a347.mp4" muted="true"></video>

Asynchronous code execution

<img src="https://user-images.githubusercontent.com/4477729/190009000-7652d544-a668-4440-933d-799f3410736f.gif" width="510"/>


Technical details
-----------------

The following events should normally happen after users type the `:LitEval1`
command:

1. On the first run, LitREPL starts the Python interpreter in the background.
   Its standard input and output are redirected into UNIX pipes in the current
   directory.
2. LitREPL runs the whole document through the express Markdown/Latex parser
   determining the start/stop positions of code and result sections. The cursor
   position is also available and the code from the right code section can
   reach the interpreter.
3. The process which reads the interpreter's response is forked out of the main
   LitREPL process. The output goes to the temporary file.
4. If the interpreter reports the completion quickly, the output is pasted to
   the resulting document immediately. Otherwise, the temporary results are
   pasted.
5. Re-evaluating sections with temporary results causes LitREPL to update
   these results.

Limitations
-----------

* Formatting: Nested code sections are not supported.
* Formatting: Special symbols in the Python output could invalidate the
  document.
* Interpreter: Extra newline is required after Python function definitions.
* Interpreter: Stdout and stderr are joined together.
* Interpreter: Evaluation of a code section locks the editor.
* Interpreter: Tweaking `os.ps1`/`os.ps2` prompts of the Python interpreter
  could break the session.
* ~~Interpreter: No asynchronous code execution.~~
* ~~Interpreter: Background Python interpreter couldn't be interrupted~~

Related projects
----------------

Edititng:

* https://github.com/lervag/vimtex (LaTeX editing, LaTeX preview)
* https://github.com/shime/vim-livedown (Markdown preview)
* https://github.com/preservim/vim-markdown (Markdown editing)

Code execution:

* Vim-medieval https://github.com/gpanders/vim-medieval
  - Evaluates Markdown code sections
* Pyluatex https://www.ctan.org/pkg/pyluatex
* Magma-nvim https://github.com/dccsillag/magma-nvim
* Codi https://github.com/metakirby5/codi.vim
* Pythontex https://github.com/gpoore/pythontex
  - Evaluates Latex code sections
* Codebraid https://github.com/gpoore/codebraid
* Vim-ipython-cell https://github.com/hanschen/vim-ipython-cell
* Vim-ipython https://github.com/ivanov/vim-ipython
* Jupytext https://github.com/goerz/jupytext.vim
  - Alternative? https://github.com/mwouts/jupytext
* Ipython-vimception https://github.com/ivanov/ipython-vimception

Useful Vim plugins:

* https://github.com/sergei-grechanik/vim-terminal-images (Graphics in vim terminals)

Useful tools:

* https://pandoc.org/

Third-party issues
------------------

* Vim-plug https://github.com/junegunn/vim-plug/issues/1010#issuecomment-1221614232
* Pandoc https://github.com/jgm/pandoc/issues/8598
* Jupytext https://github.com/mwouts/jupytext/issues/220#issuecomment-1418209581
* Vim-LSC https://github.com/natebosch/vim-lsc/issues/469


