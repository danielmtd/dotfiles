#!/usr/bin/env bash
# RUN_AS: user
# 03-dotfiles.sh — optional zsh / kitty / git / yazi / vim dotfile setup
#
# Run as your normal user (NOT sudo). Idempotent — re-running just refreshes.

set -euo pipefail

[ "$EUID" -ne 0 ] || { echo "do NOT run this with sudo — run as your user"; exit 1; }

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
say()  { echo "${BLUE}==>${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*" >&2; }

# Backup helper: rename existing file with timestamp before overwriting
backup() {
  local f="$1"
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    cp "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"
  fi
}

# ---- zsh --------------------------------------------------------------------
say "Setting up zsh..."

ZSHRC="$HOME/.zshrc"
backup "$ZSHRC"

cat > "$ZSHRC" <<'EOF'
# ~/.zshrc — managed by 03-dotfiles.sh

# ---- history ----
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE INC_APPEND_HISTORY

# ---- options ----
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PROMPT_SUBST INTERACTIVE_COMMENTS

# ---- completion ----
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ''

# ---- key bindings ----
bindkey '^R' history-incremental-search-backward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# ---- plugins (Debian's apt-installed paths) ----
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ---- aliases ----
alias ll='ls -l --color=auto'
alias la='ls -la --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'
alias gp='git pull'
alias glog='git log --oneline --graph --decorate'
alias gpu='prime-run'
alias update='sudo apt update && sudo apt full-upgrade'

# Use bat instead of cat if installed (Debian names it batcat)
if command -v batcat >/dev/null; then
  alias cat='batcat --paging=never'
fi

# ---- PATH additions ----
export PATH="$HOME/.local/bin:$PATH"

# ---- editor ----
export EDITOR="vim"
export VISUAL="$EDITOR"

# ---- prompt (simple, fast — replace with starship if you want fancy) ----
# Format: user@host cwd (git-branch?) $
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f$(__git_ps1 " %F{magenta}(%s)%f")
$ '

# Lightweight git branch in prompt
__git_ps1() {
  local b
  b=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  [ -n "$b" ] && printf "$1" "$b"
}

# ---- starship if installed (overrides PROMPT) ----
command -v starship >/dev/null && eval "$(starship init zsh)"

# ---- zoxide (smarter cd) ----
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
eval "$(zoxide init zsh --cmd cd)"

# ---- direnv hook ----
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ---- nvs (Node Version Switcher) ----
export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"

# ---- fzf integration (Debian path) ----
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
  source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
  source /usr/share/doc/fzf/examples/completion.zsh
EOF

ok "~/.zshrc written"

# ---- starship (optional) ----------------------------------------------------
if ! command -v starship >/dev/null 2>&1; then
  say "Installing starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes >/dev/null
  ok "starship installed"
fi

mkdir -p ~/.config
cat > ~/.config/starship.toml <<'EOF'
# starship.toml — minimal, fast
add_newline = false

[character]
success_symbol = "[❯](bold green)"
error_symbol   = "[❯](bold red)"

[directory]
truncation_length = 4
truncation_symbol = "…/"
EOF
ok "starship configured"

# ---- kitty ------------------------------------------------------------------
say "Configuring kitty..."
mkdir -p ~/.config/kitty
backup ~/.config/kitty/kitty.conf
cat > ~/.config/kitty/kitty.conf <<'EOF'
# kitty config — minimal, dark theme, JetBrainsMono

font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.0

cursor_shape         beam
cursor_blink_interval 0.5

scrollback_lines 10000
enable_audio_bell no
window_padding_width 6
background_opacity 0.95

# Sane copy/paste
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard

# Catppuccin Mocha colors
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8

cursor #f5e0dc
EOF
ok "kitty configured"

# ---- git --------------------------------------------------------------------
say "Configuring git basics..."

# Only set if not already set (don't clobber existing identity)
if ! git config --global user.email >/dev/null; then
  read -rp "git user.name (display name): " gname
  read -rp "git user.email: " gemail
  git config --global user.name "$gname"
  git config --global user.email "$gemail"
fi

git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global core.editor vim
ok "git configured"

# ---- yazi (file manager) ----------------------------------------------------
say "Configuring yazi..."
mkdir -p ~/.config/yazi
backup ~/.config/yazi/yazi.toml
cat > ~/.config/yazi/yazi.toml <<'EOF'
[manager]
show_hidden    = true
sort_by        = "natural"
sort_sensitive = false
sort_dir_first = true
EOF
ok "yazi configured"

# ---- vim (sane defaults) ---------------------------------------------------
say "Configuring vim..."
backup ~/.vimrc
cat > ~/.vimrc <<'EOF'
" ~/.vimrc — sane defaults

" ---- behavior ----
set nocompatible
filetype plugin indent on
syntax on
set encoding=utf-8
set fileencoding=utf-8
set hidden                  " allow background buffers
set autoread                " reload files changed outside vim
set backspace=indent,eol,start

" ---- indentation ----
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent

" ---- search ----
set incsearch
set hlsearch
set ignorecase
set smartcase

" ---- ui ----
set number                  " line numbers
set relativenumber          " relative line numbers (great for navigation)
set cursorline              " highlight current line
set ruler
set showcmd
set showmatch               " match brackets
set scrolloff=5             " keep 5 lines visible above/below cursor
set sidescrolloff=8
set wildmenu                " better tab completion
set wildmode=longest:full,full
set laststatus=2            " always show status line
set mouse=a                 " mouse works in all modes

" ---- colors ----
set background=dark
try
  colorscheme habamax       " ships with vim 9+; falls back if missing
catch
  colorscheme desert
endtry

" ---- backups & swap ----
set noswapfile
set nobackup
set undofile
set undodir=~/.vim/undo
silent !mkdir -p ~/.vim/undo

" ---- keybinds ----
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>e :Explore<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Stay in visual mode after indent
vnoremap < <gv
vnoremap > >gv

" Wayland clipboard via wl-clipboard
if executable('wl-copy')
  " Visual mode: copy selected text (any lines/columns) to clipboard
  vnoremap <silent> <C-c> :<C-u>call system('wl-copy', GetVisualSelection())<CR>
  vnoremap <silent> "+y   :<C-u>call system('wl-copy', GetVisualSelection())<CR>

  " Normal mode: yyy or "+yy etc still works through this helper too
  nnoremap <silent> <leader>Y :call system('wl-copy', join(getline(1,'$'), "\n"))<CR>

  " Helper: returns the visual selection as a string, preserving newlines
  function! GetVisualSelection()
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end,   col_end]   = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
      return ''
    endif
    " Trim columns for character-wise selection
    if visualmode() ==# 'v'
      let lines[-1] = lines[-1][: col_end - (&selection == 'inclusive' ? 1 : 2)]
      let lines[0]  = lines[0][col_start - 1:]
    endif
    return join(lines, "\n")
  endfunction
endif

EOF
ok "vim configured"

# ---- system-wide editor default --------------------------------------------
# Set vim as the default for `update-alternatives` so things like
# `git commit` outside our shell, sudoedit, etc. all use vim.
if [ "$EUID" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    say "Setting vim as system-default editor (needs sudo)..."
    sudo update-alternatives --set editor /usr/bin/vim.basic 2>/dev/null \
      || sudo update-alternatives --set editor /usr/bin/vim 2>/dev/null \
      || warn "couldn't set vim as system editor — try manually:"
    [ -n "${SUDO_USER:-}" ] || ok "vim set as system-wide default editor"
  fi
fi

# ---- summary ----------------------------------------------------------------
echo
ok "=== dotfiles.sh complete ==="
echo
cat <<EOF
Configured:
  ${BLUE}~/.zshrc${NC}                  — zsh with autosuggestions, syntax highlighting
  ${BLUE}~/.config/starship.toml${NC}   — minimal starship prompt
  ${BLUE}~/.config/kitty/kitty.conf${NC} — dark theme, JetBrainsMono
  ${BLUE}~/.config/yazi/yazi.toml${NC}  — file manager defaults
  ${BLUE}~/.vimrc${NC}                  — sane vim defaults (relative line numbers,
                                space leader, sensible search, color scheme)
  ${BLUE}~/.gitconfig${NC}              — your name/email + sensible defaults
  ${BLUE}EDITOR=vim${NC}                — system-wide editor (git, sudoedit, etc.)

Open a new terminal (or run ${YELLOW}exec zsh${NC}) to use the new shell config.

Existing files were backed up with .bak.<timestamp> suffix if they existed.
EOF
