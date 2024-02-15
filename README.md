# Setup

```sh
make install
```

will install symlinks to most of the dotfiles in this repo, and backup any existing files.

## Cool stuff

Some of the most useful / coolest commands here:

- [review](#review)
- [git-continue](#git-continue)
- [git-abort](#git-abort)
- [rmdir](#rmdir)

### [review](bin/review)

One step command to checkout a git pull request locally, and open it in VSCode.

Very useful for reviewing larger PRs, since opening it in VSCode means that you can review the code with full IDE
support - hover stuff to see the inferred types, jump to definition, etc.

### [git-continue](bin/git-continue)

A single command to "continue" a git operation.

This command checks which operation is currently in progress, and runs the appropriate `continue` command.

Handles `rebase`, `merge`, `cherry-pick` and `revert`.

_See also [git-abort](#git-abort)._

### [git-abort](bin/git-abort)

A single command to "abort" a git operation.

This command checks which operation is currently in progress, and runs the appropriate `abort` command.

Handles `rebase`, `merge`, `cherry-pick` and `revert`.

_See also [git-continue](#git-continue)._

### [rmdir](bin/rmdir.sh)

"Instantly" remove an entire directory, no matter how large that directory is.

Works by first moving the directory to a temp location, then deleting the directory from that temporary location in the
background.

Very useful for removing e.g. large `node_modules` directories - no need to wait for the entire delete to finish, you
can just run `rmdir node_modules` and then immediately start a new `yarn install`.

The script is named `rmdir.sh`, but I've aliased that script to `rmdir` so that I don't break any other commands.
