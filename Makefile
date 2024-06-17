BASH_SCRIPTS = $(shell find . -type f -name '*bash*')
ZSH_SCRIPTS = $(shell find . -type f -name '*zsh*')

bins :=$(patsubst %,~/%,$(filter-out bin/template.sh,$(wildcard bin/*)))
functions := $(patsubst %,~/%,$(shell find .config -type f -o -type l))

all: shellcheck
install: install_config_files install_bins install_functions

.PHONY: shellcheck
shellcheck: build/shellcheck.target

build/shellcheck.target: $(BASH_SCRIPTS)
	shellcheck $? && touch $@

git_config: ~/.gitconfig ~/.gitaliases
bash_config: ~/.bashrc ~/.bash-prompt.sh ~/.bash_aliases ~/.talos_aliases
zsh_config: ~/.zshrc ~/.zshenv ~/.zprofile ~/.zsh_aliases ~/.talos_aliases
x_config: ~/.xprofile
launch_agents: ~/Library/LaunchAgents/com.user.loginscript.plist

install_config_files: git_config bash_config zsh_config x_config launch_agents

install_bins: $(bins)
install_functions: $(functions)

~/% : %
	@if [ ! \( -L "$@" \) ]; then\
		if [ -e "$@" ]; then\
			echo "Backing up existing $@";\
			mv "$@" "$@.bak";\
		fi;\
		echo "Linking $@ to $(abspath "$?")";\
		mkdir -p "$(dir "$@")" && ln -s $(abspath "$?") "$@";\
	elif [ "$(shell readlink -f \"$@\")" != "$(abspath "$?")" ]; then \
		echo "Linking $@ to $(abspath "$?")";\
		echo " - Removing current link pointing to $(shell readlink -f "$@")";\
		mv "$@" "$@.bak"; \
		mkdir -p "$(dir "$@")" && ln -s $(abspath "$?") "$@";\
	fi
