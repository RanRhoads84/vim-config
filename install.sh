#!/user/bin bash

rm -rf .git \
cp -r .vim ~/ \
cp .vimrc ~/ \
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow' >> ~/.bashrc \
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow' >> ~/.bashrc
