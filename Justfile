# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

export model := env("model", "deepseek-r1:70b")
export threads := env("threads", `nproc / 2`)

demo-deepseekserver:
    just llama-server "deepseek-r1:70b" "96"

demo-llama-server $model $threads:
    #!/usr/bin/env bash
    echo "Server will be available at http://bluefin.taile821f.ts.net:8080/"
    sleep 2
    podman run --rm -i --label ai.ramalama --name ramalama_okQhesH2uf \
    --env=HOME=/tmp --init --security-opt=label=disable --cap-drop=all \
    --security-opt=no-new-privileges --label ai.ramalama.model=${model} \
    --label ai.ramalama.engine=podman --label ai.ramalama.runtime=llama.cpp \
    --label ai.ramalama.port=8080 --label ai.ramalama.command=serve --pull=newer \
    -t --env LLAMA_ARG_THREADS=${threads} -p 8080:8080 --device /dev/dri \
    --mount=type=bind,src=/var/home/adalovelace/.local/share/ramalama/models/ollama/${model},destination=/mnt/models/model.file,ro \
    quay.io/ramalama/ramalama:latest llama-server \
    --port 8080 -m /mnt/models/model.file -c 2048 --temp 0.8 -ngl 0 --host 0.0.0.0

demo-ai-server:
    #!/usr/bin/env bash

    # Get the list of models and extract the names
    models=$(ramalama list --json | jq -r '.[].name')

    # Check if any models were found
    if [[ -z "$models" ]]; then
      echo "No models found."
      exit 1
    fi

    # Create an array of models with source prefixes
    model_array=()
    while read -r model; do
      if [[ "$model" =~ ^(huggingface://|ollama://|oci://)(.*)$ ]]; then
        source="${BASH_REMATCH[1]//:\/\//}"
        model_name="${BASH_REMATCH[2]}"
        model_array+=("$source" "$model_name")
      fi
    done <<< "$models"

    # Check if the array is empty (no valid models found)
    if [[ ${#model_array[@]} -eq 0 ]]; then
      echo "No valid models found."
      exit 1
    fi

    # Display models for selection (using fzf)
    display_models=""
    for ((i = 0; i < ${#model_array[@]}; i += 2)); do
      display_models+="${model_array[i]}:${model_array[i+1]}\n"
    done

    # Use fzf to select a single line
    selected=$(echo "$display_models" | fzf --height 40% --border --ansi --prompt="Select a model: " --select-1)

    # Check if a model was selected
    if [[ -z "$selected" ]]; then
      echo "No model selected."
      exit 1
    fi

    # Extract source and model name from the selected string
    if [[ "$selected" =~ ^([^:]+):(.*)$ ]]; then
      selected_source="${BASH_REMATCH[1]}"
      selected_model="${BASH_REMATCH[2]}"
    else
      echo "Invalid selection format."
      exit 1
    fi

    # Run the just llama-server command with the selected model
    just demo-llama-server "$selected_source" "$selected_model" "64"

    echo "Started llama-server with source: $selected_source, model: $selected_model"
