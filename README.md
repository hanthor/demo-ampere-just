#Battle Plan (Roadmap)

## For the Ampere Demo
- [ ] Use `ramalama --dryrun serve` and then strip out the Nvidia stuff for the Ampere Demo Llama Serve Just action
- [ ] Make some "see how fast you can do this" stuff    
    - [ ] `just demo-build-k8s` 
    - [ ] `just demo-build-kernel`
    - [ ] `just demo-build-chromium?`
- [ ] Setup VSCode for Local AI
    - [ ] Install Continue pointed at local Ramalama Quadlet?
    - [ ] if that doesn't work just use ollama


## For Adding Ramalama Just actions to Ublue
- [ ] Make a generic ramalama model picker for `ramalama serve` and `ramalama run` not just Ampere 
- [ ] Can make a fully interactive command builder
    - [ ] ramalama image picker `Intel-GPU`, `Vulkan`, `ROCM`, etc.
    - [ ] model picker
    - [ ] threads
    - [ ] `ngl` - explain what that is `Full CPU`, `Full GPU`, or `both`



#Current Status

- `just demo-llama-serve` - hacked podman command to allow for changeing thread count and model. using Vulkan with all the nvidia args  (to show off the CPU)
- `just demo-ai-server` - An interactive picker for a model and executes `demo-llama-server`
- `just demo-deepseekserver` - running `deepseek`
- `just --choose`

# Local Testing
    do local testing by doing `export SCRIPT_DIR` or doing something like `SCRIPT_DIR=. just demo-benchmark-sysbench`
