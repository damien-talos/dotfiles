BASH_SCRIPTS = $(shell find . -type f -name '*bash*')
ZSH_SCRIPTS = $(shell find . -type f -name '*zsh*')
all: shellcheck

.PHONY: shellcheck
shellcheck: build/shellcheck.target

build/shellcheck.target: $(BASH_SCRIPTS)
	shellcheck $? && touch $@

