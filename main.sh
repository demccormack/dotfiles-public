# Daniel McCormack's customisations
# This file is sourced by bash and zsh


DOTFILES_DIR="$(dirname ${BASH_SOURCE[0]:-$0})"


### ENV VARS ###

export EDITOR=/usr/bin/vim


### UTILITIES ###

alias branch='git branch --show-current'

# Auto-fill Jira issue in commit template
gc() {
    ISSUE=$(branch | grep -oE "$ISSUE_REGEX")
    sed "s,ISSUE,$ISSUE,g" "$DOTFILES_DIR"/.git-commit-template.orig > ~/.git-commit-template
    git commit $@
}

alias fetch='git fetch && git status'

# Push current branch
push() {
    if [[ "$(branch)" ]]
    then
        git push origin "$(branch)" $@
    else
        incolor 1 echo "Not on a branch"
        return 1
    fi
}

alias ll='ls -l'

# Clear the terminal and leave a gap in the scrollback
alias cl='i=0; while [ "$((i++))" -le 20 ]; do echo . ; done; clear'

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

if [[ -f .nvmrc ]]
then
    if ACTIVE_NODE_VERSION=$(node -v | grep "$(cat .nvmrc)")
    then
        incolor 8 echo "Already using correct node $ACTIVE_NODE_VERSION"
    else
        incolor 8 nvm use
    fi
else
    incolor 8 echo "No .nvmrc found"
fi

# Display power status (MacOS)
POWER_STATUS="$(pmset -g batt)"
echo "$POWER_STATUS" | incolor 8 head -n 1
echo "$POWER_STATUS" | tail -n 1 | grep -oE '[0-9]+%.*present' | sed 's/present.*//' | \
    GREP_COLOR='0;31' incolor 8 grep --color=always '^[0-9]%\|[1-3][0-9]%\|discharging\|$'

[[ -d .git ]] && echo "On branch $(incolor 10 echo $(branch))"


