if status is-interactive
    # Commands to run in interactive sessions can go here
    eval (ssh-agent -c) > /dev/null
    ssh-add ~/.ssh/github 2>/dev/null
end

zoxide init fish | source
starship init fish | source
fish_add_path /home/pumetu/.pixi/bin
pixi completion --shell fish | source
