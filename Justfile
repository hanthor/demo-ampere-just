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

export model_name := env("MODEL_NAME", "deepseek-r1:70b")
export model_source := env("SOURCE", "ollama")
export threads := env("THREADS", `sh -c 'echo $(( $(nproc) / 2 ))'`)
export ngl := env("NGL", "0")
export ramalama_image := env("RAMALAMA_IMAGE", "quay.io/ramalama/vulkan:latest")

demo-llama-server $ramalama_image=ramalama_image $model_source=model_source $model_name=model_name $threads=threads $ngl=ngl:
    #!/usr/bin/env bash
    python3 ramalama-serve-ampere.py --image $ramalama_image --threads $threads --ngl $ngl $model_source://$model_name

demo-deepseekserver:
    just demo-llama-server "ollama" "deepseek-r1:70b" "96"

demo-ai-server $ramalama_image=ramalama_image $threads=threads $ngl=ngl:
    #!/usr/bin/env bash
    python3 demo-ai-server.py --image $ramalama_image --threads $threads --ngl $ngl
