#!/usr/bin/env bash

# Generic
alias ..='cd ..'
alias ...='cd ../..'
alias reload='source ~/.bash_profile'
alias fuck='sudo $(history -p \!\!)'
alias mv='mv -i'
alias ls='ls -A --color=auto'
alias ll='ls -lAshN --color=auto'
alias v="$VISUAL"

# Git
alias gs="git status -s"
alias gst="git status"
alias gsh="git stash save --keep-index --include-untracked"
alias gl="git log --pretty=format:'%Cgreen%h%Creset -%Creset %s%C(yellow)%d %Cblue(%aN, %cr)%Creset' --abbrev-commit --date=iso --first-parent"
alias gla="git log --pretty=format:'%Cgreen%h%Creset -%Creset %s%C(yellow)%d %Cblue(%aN, %cr)%Creset' --abbrev-commit --date=relative"
alias glg="git log --graph --pretty=format:'%Cgreen%h%Creset -%Creset %s%C(yellow)%d %Cblue(%aN, %cr)%Creset' --abbrev-commit --date=relative"
alias gall="git add ."
alias gco="git commit -m"
alias gra="git remote add"
alias gback="git reset --soft HEAD~1 && git reset HEAD ."
alias grall="git clean -df ." # removes all untracked files
alias gam="git commit -am"
alias gpoh="git push origin HEAD"
alias gb="git branch"
alias gcd="git checkout develop"

