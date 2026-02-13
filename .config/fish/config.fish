if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Dotfiles Bare Alias
alias config "/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME"
alias xcopy "xsel -selection clipboard --input"
alias xpaste "xsel -selection clipboard --output"
