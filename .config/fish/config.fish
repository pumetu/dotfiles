if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_add_path ~/.local/bin                                          # nvim etc.

if test -f /usr/local/Modules/init/fish
    source /usr/local/Modules/init/fish
end
zoxide init fish | source
starship init fish | source

function interactive
    set -l numgpu 1
    if set -q argv[1]; set numgpu $argv[1]; end
    set -l numcpu (math "max($numgpu * 8, 8)")
    if set -q argv[2]; set numcpu $argv[2]; end
    set -l memgb (math "$numcpu * 16")
    if set -q argv[3]; set memgb $argv[3]; end
    if command -q srun
        set -l gpuflags
        if test $numgpu -gt 0
            set gpuflags --gres=gpu:$numgpu
        end
        srun $gpuflags \
             --cpus-per-task=$numcpu \
             --mem={$memgb}G \
             --pty bash
    else if command -q qsub
        set -l select select=1:ncpus=$numcpu:mem={$memgb}gb
        if test $numgpu -gt 0
            set select select=1:ngpus=$numgpu:ncpus=$numcpu:mem={$memgb}gb
        end
        qsub -I -l $select
    else
        echo "No scheduler found (neither srun nor qsub in PATH)" >&2
        return 1
    end
end

if module avail -t cuda/12.9 2>&1 | grep -q cuda/12.9
    ml cuda/12.9
end

set -gx ENROOT_DATA_PATH /raid/$USER/enroot-data

cd /mnt/weka/aisg/simfoni_spoke/pume

alias github-ssh 'eval (ssh-agent -c) && ssh-add ~/.ssh/github'
