#!/bin/sh

cat vscode-extensions.txt | xargs -t -n 1 code --install-extension
