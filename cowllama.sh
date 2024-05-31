#!/bin/bash

###################
# OLLAMA SETTINGS #
###################

# Available ollama commands (leave empty to disable)
OLLAMA_CONTAINER="ollama"
OLLAMA_BINARY="ollama"

# Available URLs for APIs (leave empty to disable)
OLLAMA_LOCAL_URL="http://localhost:11434"
OLLAMA_DOCKER_URL="http://localhost:11434"
OLLAMA_REMOTE_URL="https://ollama.example.com"

###################
# COWSAY SETTINGS #
###################

# Eyes and tongue of the llama
COWFILE="llama"
EYE="°"
TONGUE="U "

###############################
# DON'T CHANGE ANYTHING BELOW #
###############################

VARGS=($@)
ARGLENGTH=${#VARGS[@]}
VENG=$1
VCMD=$2
VMODEL=$3
VPROMPT="${VARGS[@]:3:$ARGLENGTH}"

# take binary into account, but
if [[ "$OLLAMA_BINARY" != "" ]]; then
    OLLAMA=$OLLAMA_BINARY
    VENGINE="Local"
fi

# default to docker if possible
if [[ "$OLLAMA_CONTAINER" != "" ]]; then
    OLLAMA_DOCKER="docker exec -it $OLLAMA_CONTAINER ollama"
    OLLAMA=$OLLAMA_DOCKER
    VENGINE="Docker"
fi


health() {
    case $VENGINE in
        Local|Remote|Docker)
            echo -e "\nChecking ollama API ..\n";
            sleep 0.5
            # check if api available
            curl $OLLAMA_API/ -I -s 2>&1 >/dev/null && (
                curl $OLLAMA_API/ -s | cowsay -W 60 -e "$EYE" -f $COWFILE
            ) || (
                # if not
                echo "API not available" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "\nAPI: $VENGINE";
            ;;

        *)
            echo -e "\nChecking ollama API .."
            sleep 0.5
            echo -e "DOCKER \t $(curl $OLLAMA_DOCKER_URL/ -s -I &> /dev/null && echo 'Healthy' || echo 'Not Available')";
            echo -e "LOCAL \t $(curl $OLLAMA_LOCAL_URL/ -s -I &> /dev/null && echo 'Healthy' || echo 'Not Available')";
            echo -e "REMOTE \t $(curl $OLLAMA_REMOTE_URL/ -I &> /dev/null && echo 'Healthy' || echo 'Not Available')";
            ;;
        esac
}

run() {
    case $VENGINE in
        Local) 
            # check if ollama is available
            $OLLAMA_BINARY -v 2>&1 >/dev/null && (
                # if true
                $OLLAMA_BINARY run $VMODEL $VPROMPT
            ) || (
                # if not
                echo "ollama not installed locally" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "\nAPI: $VENGINE";
            ;;

        Remote)
            # check if api available
            curl $OLLAMA_API/ -I -s 2>&1 >/dev/null && (
                # if true
                curl $OLLAMA_API/v1/chat/completions -s -d '{
                    "model": "'$VMODEL'",
                    "stream": false,
                    "messages": [{
                        "role": "user",
                        "content": "'"${VPROMPT//\"/\\\"}"'"
                    }]
                }' | jq -r '.choices[0].message.content' | cowsay -W 60 -e "$EYE" -f $COWFILE
            ) || (
                # if not
                echo "Ollama not available" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "\nAPI: $VENGINE";
            ;;

        Docker)
            # check if container available
            $OLLAMA_DOCKER -v 2>&1 >/dev/null && (
                # if true
                $OLLAMA_DOCKER run "$VMODEL" "$VPROMPT"
            ) || (
                # if not
                echo "Ollama not available" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "\nAPI: $VENGINE";
            ;;
    esac
}

list() {
    # check if api available
    curl $OLLAMA_API/ -I -s 2>&1 >/dev/null && (
        # if true
        echo -e "\nAvailable models:\n";
        curl $OLLAMA_API/api/tags -s | jq -r '.models|=sort_by(.name)|.models[].name'
    ) || (
        # if not
        echo "Ollama not available" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
    );
    echo -e "\nAPI: $VENGINE";
}

pull() {
    # check if api available
    curl $OLLAMA_API/ -I -s 2>&1 >/dev/null && (
        # if true
        echo -e "\nPulling $VMODEL ..";
        curl -fsSL -d '{"model": "'$VMODEL'" }' $OLLAMA_API/api/pull |
            jq -r '.status' |
            sed -u 'i\\o033[2K' |
            stdbuf -o0 tr '\n' '\r';
            echo
    ) || (
        # if not
        echo "Ollama not available" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
    )
    echo -e "\nAPI: $VENGINE";
}

update_all() {
    # check if api available
    curl $OLLAMA_API/ -I -s 2>&1 >/dev/null && (
        #if true
        # countdown
        countdown=5;
        echo -e "Time to Update all $VENGINE models .." | cowthink -e "$EYE" -f $COWFILE;
        echo
        while [ $countdown -gt 0 ]; do
            echo -ne "         Updating in $countdown\033[0K\r"
            sleep 1;
            : $((countdown--))
        done
        echo -e "\n"
        # update all models
        curl $OLLAMA_API/api/tags -s | jq -r '.models[].name' | tail -n +2 | awk '{print $1}' | while read -r _model; do
            echo -e "\nPulling $_model ..";
            curl -fsSL -d '{"model": "'$_model'" }' $OLLAMA_API/api/pull |
                jq -rS '.status' |
                sed -u 'i\\o033[2K' |
                stdbuf -o0 tr '\n' '\r' && 
                echo
        done
    ) || (
        # if not
        echo "Ollama not available" | cowthink -W 60 -e "+" -T "$TONGUE" -f $COWFILE 2>/dev/null
    );
    echo -e "\nAPI: $VENGINE";
}

native() {
    echo
    $OLLAMA "$@"
    echo -e "\nAPI: $VENGINE";
    
}

case $VENG in
    --local|-L) VENGINE="Local";
        OLLAMA_API=$OLLAMA_LOCAL_URL;
        ;;
    --docker|-D) VENGINE="Docker";
        OLLAMA_API=$OLLAMA_DOCKER_URL;
        ;;
    --remote|-R) VENGINE="Remote";
        OLLAMA_API=$OLLAMA_REMOTE_URL;
        ;;
    --health) VENGINE="";
        health;
        ;;
    --update-all) update_all;
        ;;
    *) native "$@";
        ;;
esac
shift

case $VCMD in
    health) health;
        ;;
    run) run;
        ;;
    list) list;
        ;;
    pull) pull;
        ;;
    update-all) update_all;
        ;;
esac
