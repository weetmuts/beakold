
_beakconfigs()
{
  local cur=${COMP_WORDS[COMP_CWORD]}
  local names=$(cd ~/.beak; echo *.cfg | sed 's/.cfg//g')
  COMPREPLY=( $( compgen -W "$names" -- $cur ) )
  return 0
}

_beakremotes()
{
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}

  local remotes=$(grep remote= ~/.beak/${prev}.cfg | sed 's/remote=//')
  COMPREPLY=( $( compgen -W "$remotes" -- $cur ) )
  return 0
}

_beak()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}
    local prevprev=${COMP_WORDS[COMP_CWORD-2]}

    case "$prev" in
        push) _beakconfigs ;;
        mount) _beakconfigs ;;
        umount) _beakconfigs ;;
    esac

    case "$prevprev" in
        push) _beakremotes ;;
        mount) _beakremotes ;;
        umount) _beakremotes ;;
    esac
    
    if [ -z "$COMPREPLY" ]
    then
        COMPREPLY=( $(compgen -W "config mount push status umount" -- $cur) )
    fi
}
complete -F _beak beak
