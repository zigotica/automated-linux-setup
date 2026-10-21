# No primary-user aliases, greeting, editor setup, or private executable paths.
case $- in
  *i*) ;;
  *) return ;;
esac

PS1='\u@\h \w \$ '
