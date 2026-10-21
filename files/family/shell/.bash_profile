# Keep this account independent of the primary user's shell configuration.
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# Start the family desktop only after an interactive local text-console login.
# No SSH startup and no autologin: the user still types "family" at the prompt.
if [[ $- == *i* && -z ${DISPLAY:-} && -z ${SSH_CONNECTION:-} ]]; then
  case "$(tty)" in
    /dev/tty[1-6]) exec startx ;;
  esac
fi
