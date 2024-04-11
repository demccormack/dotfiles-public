# Daniel McCormack's customisations
# This file is sourced by bash and zsh

set -u

DOTFILES_DIR="$(dirname ${BASH_SOURCE[0]:-$0})"


### VIM SETUP ###

set -o vi
export EDITOR=/usr/bin/vim
ln -snf "$DOTFILES_DIR/.vimrc" ~/.vimrc

# From https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key
export GPG_TTY=$(tty)

### UTILITIES ###

! [[ "$(uname)" == "Linux" ]] || DOCKER_AS=sudo
alias docker="${DOCKER_AS:-} docker"

alias reload="source ~/.zshrc"

# Delete all Docker containers/images
alias delcontainers="${DOCKER_AS:-} docker ps -a | tail +2 | awk '{print \$1}' | xargs ${DOCKER_AS:-} docker rm"
alias delimages="${DOCKER_AS:-} docker images | tail +2 | awk '{print \$3}' | xargs ${DOCKER_AS:-} docker rmi"

# List the processes blocking a port (or pass --kill to kill them)
port() {
    PORT=$(sed 's/[[:space:]]*--kill[[:space:]]*//' <<< "$@")
    if grep -q '\-\-kill' <<< "$@"
    then
        lsof -n -i :"$PORT" | grep LISTEN | awk '{print $2}' | xargs kill -9
    else
        lsof -n -i :"$PORT" | grep LISTEN
    fi
}

# Stash any local changes, then begin an interactive rebase for the last n commits.
# n is the first argument. Any additional arguments will be apended to the rebase command.
rebase() {
    git stash && git rebase -i "HEAD~$1" ${@:2}
}

alias branch='incolor 10 git branch --show-current'

# Auto-fill Jira issue in commit template
gc() {
    if [[ "${ISSUE_REGEX:-}" ]] && ! grep -q '\-\-amend' <<< "$@"
    then
        ISSUE=$(git branch --show-current | grep -oE "$ISSUE_REGEX")
        sed "s,ISSUE,$ISSUE,g" "$DOTFILES_DIR"/.git-commit-template.orig > ~/.git-commit-template
    fi
    git commit $@
}

alias fetch='git fetch && git status'
alias nohook='git -c core.hooksPath=/dev/null'

# Push current branch
push() {
    CURRENT_BRANCH=$(git branch --show-current)
    if [[ "$CURRENT_BRANCH" ]]
    then
        git push origin "$CURRENT_BRANCH" $@
        echo
        incolor 3 echo 'Have you run the tests?'
    else
        incolor 1 echo "Not on a branch"
        return 1
    fi
}

# Rollback specific ActiveRecord migration without changing any of the ones in-between
# For local use only
rollback() {
    bundle exec rake db:migrate:down VERSION="$1"
}

generate() {
    bundle exec rails generate $@
    bundle exec rake rubocop:autoformat
}

alias ll='ls -l'

! [[ "$(uname)" == "Darwin" ]] || alias sha256sum='shasum -a 256'

# Retry a command until it succeeds, or 10 tries if session not interactive
retry() {
	RETRY_COUNT=0
    MAX_RETRIES=10
	while ! $@
	do
		((++RETRY_COUNT))
        if [[ "$TERM" == dumb ]] && [[ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]]
        then
            echo "Failed $RETRY_COUNT times, aborting!"
            return 1
        fi
		echo "Failed $RETRY_COUNT times, retrying..."
		sleep 0.5 # to allow keyboard interrupts
	done
	echo Done
}

# Leave a gap in the terminal scrollback
alias cl='i=0; while [ "$((i++))" -le 20 ]; do echo; done'

# Show a side-by-side diff easily
vdiff() {
    diff -y <(fold -s -w72 "$1") <(fold -s -w72 "$2") -W 200 ${@:3}
}

# Run a commnd and show the output in the specified color
incolor() {
    if [[ "$@" ]] 
    then
        echo "$(tput setaf $1)$(${@:2})$(tput sgr0)"
    else
        for (( i = 0; i < 17; i++ ))
        do
            echo "$(tput setaf $i)This is color ${i}$(tput sgr0)"
        done
    fi
}


### PROMPT ###

# Use correct node version
if [[ "$TERM" != dumb ]] && [[ -f .nvmrc ]]
then
    if ACTIVE_NODE_VERSION=$(node -v | grep "$(cat .nvmrc)")
    then
        incolor 8 echo "Already using correct node $ACTIVE_NODE_VERSION"
    else
        nvm use
    fi
fi
