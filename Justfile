[group('Just')]
check:
    #!/usr/bin/bash
    echo "Checking syntax: Justfile"
    find . -type f -name "*.just" | while read -r file; do
    echo "Checking syntax: $file"
    just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

[group('Just')]
fix:
    #!/usr/bin/bash
    echo "Fixing syntax: Justfile"
    find . -type f -name "*.just" | while read -r file; do
    echo "Fixing syntax: $file"
    just --unstable --fmt -f $file
    done
    echo "Fixing syntax: Justfile"
    just --unstable --fmt -f Justfile || { echo "Error: Failed to fix Justfile syntax."; exit 1; }

export model := env("model", "deepseek-r1:70b")
export threads := env("threads", `sh -c 'echo $(( $(nproc) / 2 ))'`)

demo-llama-server $source $model_name $threads:
    #!/usr/bin/env bash
    echo "Starting llama-server with source: ${source}, model: ${model_name}, threads: ${threads}"
    echo "Server will be available at http://bluefin.taile821f.ts.net:8080"
    sleep 2
    podman run --rm -i --label ai.ramalama --name ramalama_okQhesH2uf \
    --env=HOME=/tmp --init --security-opt=label=disable --cap-drop=all \
    --security-opt=no-new-privileges --label ai.ramalama.model=${model_name} \
    --label ai.ramalama.engine=podman --label ai.ramalama.runtime=llama.cpp \
    --label ai.ramalama.port=8080 --label ai.ramalama.command=serve --pull=newer \
    -t --env LLAMA_ARG_THREADS=${threads} -p 8080:8080 --device /dev/dri \
    --mount=type=bind,src=$HOME/.local/share/ramalama/models/ollama/${model_name},destination=/mnt/models/model.file,ro \
    quay.io/ramalama/ramalama:latest \ 
    llama-server --port 8080 -m /mnt/models/model.file -c 2048 --temp 0.8 -ngl 0 --host 0.0.0.0 || { \
    echo "Error: Failed to start llama-server. Check podman logs for 'ramalama_okQhesH2uf'." \
    exit 1 \
    }
    echo "llama-server started successfully in podman container 'ramalama_okQhesH2uf'."

demo-deepseekserver:
    just demo-llama-server "ollama" "deepseek-r1:70b" "96"

demo-ai-server:
    #!/usr/bin/env python3

    import subprocess
    import json
    import os

    def demo_ai_server():
        """Interactively select an AI model and start llama-server."""

        try:
            # Get the list of models in JSON format using ramalama
            process = subprocess.run(["ramalama", "list", "--json"], capture_output=True, text=True, check=True)
            models_json_str = process.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error: Failed to get model list from 'ramalama list --json'.")
            print(f"Return code: {e.returncode}")
            print(f"Stdout: {e.stdout}")
            print(f"Stderr: {e.stderr}")
            print("Please check ramalama installation and model setup.")
            return 1
        except FileNotFoundError:
            print("Error: 'ramalama' command not found. Please ensure ramalama CLI is installed and in your PATH.")
            return 1

        if not models_json_str:
            print("No models found by ramalama. Please add models using 'ramalama pull ...'.")
            return 1

        try:
            models_json = json.loads(models_json_str)
        except json.JSONDecodeError as e:
            print("Error: Failed to parse JSON output from 'ramalama list --json'.")
            print(f"JSONDecodeError: {e}")
            print("Output from ramalama list --json was:")
            print(models_json_str)
            return 1

        if not models_json:
            print("No models found by ramalama (after JSON parsing). Please add models using 'ramalama pull ...'.")
            return 1

        model_array = []
        for item in models_json:
            model_name_full = item.get("name")
            if not model_name_full:
                print("Error: Model entry missing 'name' field in ramalama list output.")
                return 1

            source = "ollama"  # Default source
            model_name = model_name_full

            if model_name_full.startswith("huggingface://"):
                source = "huggingface"
                model_name = model_name_full[len("huggingface://"):]
            elif model_name_full.startswith("ollama://"):
                source = "ollama"
                model_name = model_name_full[len("ollama://"):]
            elif model_name_full.startswith("oci://"):
                source = "oci"
                model_name = model_name_full[len("oci://"):]

            model_array.append({"source": source, "model_name": model_name, "original_name": model_name_full})

        if not model_array:
            print("No valid models found with recognized source prefixes (huggingface://, ollama://, oci://) or default source.")
            return 1

        selected_original_name = None
        if subprocess.run(["command", "-v", "fzf"], capture_output=True).returncode == 0:
            # Use fzf for interactive selection
            print("Using fzf for interactive model selection.")
            display_models = "\n".join([model["original_name"] for model in model_array])
            try:
                fzf_process = subprocess.run(["fzf", "--height", "40%", "--border", "--ansi", "--prompt", "Select a model: "],
                                            input=display_models, capture_output=True, text=True, check=True)
                selected_original_name = fzf_process.stdout.strip()
            except subprocess.CalledProcessError as e:
                if e.returncode == 130: # fzf returns 130 when user exits with Ctrl+C
                    print("No model selected using fzf.")
                    return 1
                else:
                    print(f"Error running fzf: Return code: {e.returncode}, Stderr: {e.stderr}")
                    # Fallback to list selection instead of exiting, if fzf fails for other reasons.
                    print("Falling back to simple list selection due to fzf error.")
                    selected_original_name = None # Ensure fallback happens
            except FileNotFoundError:
                print("Error: fzf command not found, but command -v fzf succeeded earlier. This is unexpected.")
                print("Falling back to simple list selection.")
                selected_original_name = None # Ensure fallback happens


        if not selected_original_name:
            # Fallback to simple numbered list selection
            print("fzf not found or failed. Falling back to simple list selection.")
            print("Available models:")
            for index, model in enumerate(model_array):
                print(f"{index + 1}) {model['original_name']}")

            while True:
                try:
                    selected_index = int(input(f"Select model number (1-{len(model_array)}): "))
                    if 1 <= selected_index <= len(model_array):
                        selected_original_name = model_array[selected_index - 1]["original_name"]
                        break
                    else:
                        print("Invalid selection number. Please try again.")
                except ValueError:
                    print("Invalid input. Please enter a number.")

            if not selected_original_name:
                print("No model selected.")
                return 1

        selected_source = None
        selected_model = None
        for model in model_array:
            if model["original_name"] == selected_original_name:
                selected_source = model["source"]
                selected_model = model["model_name"]
                break

        if not selected_source or not selected_model:
            print("Error: Could not find selected model details in parsed model array.")
            return 1

        threads = os.environ.get("threads")
        if not threads:
            try:
                nproc_output = subprocess.run(["nproc"], capture_output=True, text=True, check=True).stdout.strip()
                num_cores = int(nproc_output)
                threads = str(num_cores // 2)
            except (subprocess.CalledProcessError, ValueError, FileNotFoundError):
                threads = "4" # Default threads if nproc fails

        print(f"Starting llama-server with source: {selected_source}, model: {selected_model}, threads: {threads}")

        try:
            subprocess.run(["just", "demo-llama-server", selected_source, selected_model, threads], check=True)
            print(f"Started llama-server with source: {selected_source}, model: {selected_model}.")
        except subprocess.CalledProcessError as e:
            print(f"Error: Failed to start llama-server using 'just demo-llama-server'.")
            print(f"Return code: {e.returncode}")
            print(f"Stdout: {e.stdout}")
            print(f"Stderr: {e.stderr}")
            print("Please check the error messages and podman logs (if applicable).")
            return 1
        except FileNotFoundError:
            print("Error: 'just' command not found. Please ensure just is installed and in your PATH.")
            return 1

        return 0 # Success

    if __name__ == "__main__":
        exit(demo_ai_server())