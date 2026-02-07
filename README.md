# aura-scripts

Parallel agent launcher for Aura multi-agent workflows. Launches Claude agents in tmux sessions with role-based instructions.

## Usage

```bash
# Launch 3 reviewers
./launch-parallel.py --role reviewer -n 3 --prompt "Review the plan..."

# Launch supervisor
./launch-parallel.py --role supervisor -n 1 --prompt "Coordinate tasks..."

# Launch workers with task distribution
./launch-parallel.py --role worker -n 3 \
    --task-id impl-001 --task-id impl-002 --task-id impl-003 \
    --prompt "Implement the assigned task"
```

## Requirements

- Python 3.10+ (stdlib only, no dependencies)
- tmux
- Claude CLI (`claude`)
