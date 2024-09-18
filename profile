export SUTOOLS=true

export PATH=$PATH:$HOME/.sutools/bin

export $(grep -v '^#' $HOME/etc/env/.env | xargs)
