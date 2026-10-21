# Interactive shells only.
case $- in
    *i*) ;;
    *) return ;;
esac

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend checkwinsize

# Colors
export RED="$(tput setaf 1)"
export GRN="$(tput setaf 2)"
export YLW="$(tput setaf 3)"
export BLU="$(tput setaf 4)"
export PRL="$(tput setaf 5)"
export ORN="$(tput setaf 130)"
export WHT="$(tput setaf 7)"
export RST="$(tput sgr0)"

# Source optional shell files in the declared order.
shell_files=(.bash_aliases .bash_functions)
for shell_file in "${shell_files[@]}"; do
  if [ -f "$HOME/$shell_file" ]; then
    . "$HOME/$shell_file"
  fi
done
unset shell_file shell_files

# Prompt: purple SSH indicator, white username, yellow hostname, blue directory.
PS1="\[${PRL}\]"'$(__is_ssh)'"\[${WHT}\]"'\u'"\[${RST}\]@\[${YLW}\]"'\h'"\[${RST}\] \[${BLU}\]"'\w'"\[${RST}\]"' \$ '

# Pretty welcome
if command -v figurine >/dev/null 2>&1; then
  fonts=('ANSI Regular' 'DOS Rebel' 'Isometric3')
  figurine -f "${fonts[RANDOM % ${#fonts[@]}]}.flf" "$(hostname)"
  printf '\n\n'
  unset fonts
fi
