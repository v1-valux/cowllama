# cowllama
Provides a bash interface for local and remotely hosted ollama APIs powered by cowsay

```
 ___________________ 
< Ollama is running >
 ------------------- 
      \
       \   /\⌒⌒⌒⌒⌒/\
        \ {         }
          (°('◞◟') °)
          (         )
          (         )
```

## Usage: ##

1. (optional) create an alias for convenience:

```bash
echo 'alias ollama="/path/to/cowllama.sh"' >> ~/.bashrc
```
2. install `cowsay` on your system:

- Debian: `apt install cowsay`
- Arch: `yay -S cowsay`

..you'll figure it out..

3. copy `cows/llama.cow` from this repository to `/usr/share/cows/`

4. run it as you would normally run ollama, but with additional argument-options:

```
ollama [[OPTIONS] [MODEL] [PROMPT]]

Option:           Description
-L | --local      run ollama commands via localhost / ollama binary
-D | --docker     run ollama commands through local docker container
-R | --remote     run ollama commands via remote API
--health          check the availability of all available APIs
--update-all      pulls all publicly available models via preconfigured API 
                  if no docker-container is provided the default API is 'localhost'

run               equivalent to 'ollama run'
list              equivalent to 'ollama list'
pull              equivalent to 'ollama pull'

health            check availability of the chosen API 
update-all        pulls all publicly available model blobs on the chosen API
```

## Examples: ##

```
# check health of all APIs
ollama --health

# pull "phi3:medium" on remote machine
ollama -R pull phi3:medium

# update all models on remote machine
ollama -R update-all

# run codellama on localhost with optional prompt
ollama -L run codellama [prompt]
```
