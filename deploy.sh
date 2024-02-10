#!/bin/bash

backup()
{
    local new_name=$1.$RANDOM$RANDOM
    set -x
    [ -f $1 ] && mv $1 $new_name -f
    set +x
}

rm -f /usr/bin/starship
cp starship /usr/bin/starship
backup ~/.zshrc
backup ~/.config/starship.toml
cp .zshrc ~/.zshrc
cp starship.toml ~/.config/starship.toml

