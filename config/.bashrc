

# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

alias btw='echo i use hyprland btw'

if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
  . "/nix/store/v0rja6r917ch0fhy7aghr12lp43jl5ya-bash-completion-2.17.0/etc/profile.d/bash_completion.sh"
fi

