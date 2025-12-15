" Vim Keybinds, Spacebar is the leaderkey!
let mapleader=" "

" Open netrw (File explorer) with <leader>cd
nnoremap <leader>cd :Ex<CR>

" Make current file executable
nnoremap <leader>x :!chmod +x %<CR>

" Reload vimrc (adjust path as needed)
nnoremap <leader>rl :source ~/.vimrc<CR>

" Source current file
nnoremap <leader><leader> :so<CR>
