BASH_SCRIPTS = $(shell find . -type f -name '*bash*')
ZSH_SCRIPTS = $(shell find . -type f -name '*zsh*')

bins :=$(patsubst %,~/%,$(wildcard bin/*))
functions := $(patsubst %,~/%,$(shell find .config/ -type f))

all: shellcheck
install: install_config_files install_bins install_functions

.PHONY: shellcheck
shellcheck: build/shellcheck.target

build/shellcheck.target: $(BASH_SCRIPTS)
	shellcheck $? && touch $@

install_config_files: git_config bash_config zsh_config
git_config: ~/.gitconfig ~/.gitaliases
bash_config: ~/.bashrc ~/.bash-prompt.sh ~/.bash_aliases ~/.talos_aliases
zsh_config: ~/.zshrc ~/.zshenv ~/.zsh_aliases ~/.talos_aliases

install_bins: $(bins)
install_functions: $(functions)

~/% : %
	@if [ ! \( -L "$@" \) ]; then\
		if [ -e "$@" ]; then\
			echo "Backing up existing $@";\
			mv "$@" "$@.bak";\
		fi;\
		echo "Linking $@ to $(abspath $?)";\
		mkdir -p "$(dir $@)" && ln -s $(abspath "$?") "$@";\
	fi
