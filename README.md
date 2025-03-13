# AI Model Server Justfile

This Justfile provides recipes for managing AI model servers using ramalama and llama.cpp on an Ampere system.

## Dependencies

- [just](https://github.com/casey/just): A command runner for simplifying tasks.
- [podman](https://podman.io/): A daemonless container engine (or use Docker).
- [ramalama](https://...): A tool for managing AI models.
- [jq](https://stedolan.github.io/jq/): A lightweight and flexible command-line JSON processor.
- [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder (optional, for interactive model selection).

## Setup

1. Install dependencies:
    - Follow the installation instructions for each dependency.
2. Configure ramalama to access your models:
    - Ensure ramalama is set up to manage your AI models correctly.
3. Additional setup instructions:
    - Configure environment variables and other necessary settings.

## Environment Variables

- `model`: Default AI model (e.g., deepseek-r1:70b, llama2:7b, ollama://llama2:7b).
- `threads`: Number of threads for llama.cpp (defaults to nproc / 2).

## Usage

- `just check`: Check Justfile syntax.
- `just fix`: Fix Justfile syntax.
- `just demo-llama-server <model> <threads>`: Start llama-server with the specified model and threads.
- `just demo-deepseekserver`: Quick demo with deepseek-r1:70b.
- `just demo-ai-server`: Interactive model selection and server start.

## Example README.md (partial)

```markdown
# AI Model Server Justfile

This Justfile provides recipes for managing AI model servers using ramalama and llama.cpp on an Ampere system.

## Dependencies

- [just](https://github.com/casey/just): A command runner for simplifying tasks.
- [podman](https://podman.io/): A daemonless container engine (or use Docker).
- [ramalama](https://...): A tool for managing AI models.
- [jq](https://stedolan.github.io/jq/): A lightweight and flexible command-line JSON processor.
- [fzf](https://github.com/junegunn/fzf): A command-line fuzzy finder (optional, for interactive model selection).

## Setup

1. Install dependencies:
    - Follow the installation instructions for each dependency.
2. Configure ramalama to access your models:
    - Ensure ramalama is set up to manage your AI models correctly.
3. Additional setup instructions:
    - Configure environment variables and other necessary settings.

## Usage

- `just check`: Check Justfile syntax.
- `just fix`: Fix Justfile syntax.
- `just demo-llama-server <model> <threads>`: Start llama-server with the specified model and threads.
- `just demo-deepseekserver`: Quick demo with deepseek-r1:70b.
- `just demo-ai-server`: Interactive model selection and server start.
```