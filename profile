[ "$SUTOOLS" = true ] && return

export SUTOOLS=true
export PATH=$PATH:$HOME/.sutools/bin

if [ -f $HOME/etc/env/.env ]; then
  export $(grep -v '^#' $HOME/etc/env/.env | xargs)
fi
