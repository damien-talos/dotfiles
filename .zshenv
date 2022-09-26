PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH
export EDITOR=code
export GITHUB_TOKEN=$(cat ~/.github_token)
[ -e ~/.sentry_token ] && . ~/.sentry_token

## LOAD AVA ENVIRONMENT VARS
if [ -f /Users/damien.schoof/workspace/talos/env/ava-vars.sh ]; then
  source /Users/damien.schoof/workspace/talos/env/ava-vars.sh
fi
### END LOAD AVA ENVIRONMENT VARS

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
