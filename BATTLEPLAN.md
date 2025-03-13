#Battle Plan (Roadmap)

## For the Ampere Demo
- [] Use `ramalama --dryrun serve` and then strip out the Nvidia stuff for the Ampere Demo Llama Serve Just action
- [] Make some "see how fast you can do this" stuff    
    - [] `just demo-build-k8s` 
    - [] `just demo-build-kernel`
    - [] `just demo-build-chromium?`


## For Adding Ramalama Just actions to Ublue
- [] Make a generic ramalama model picker for `ramalama serve` and `ramalama run` not just Ampere 
- [] Can make a fully interactive command builder
    - [] ramalama image picker `Intel-GPU`, `Vulkan`, `ROCM`, etc.
    - [] model picker
    - [] threads
    - [] `ngl` - explain what that is `Full CPU`, `Full GPU`, or `both`
