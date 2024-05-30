#!/bin/bash

###################
# OLLAMA SETTINGS #
###################

# Available ollama commands (leave empty to disable)
OLLAMA_CONTAINER="ollama"
OLLAMA_BINARY="ollama"

# Available URLs for APIs (leave empty to disable)
OLLAMA_LOCAL_URL="http://localhost:11434"
OLLAMA_DOCKER_URL="http://host.docker.internal:11434"
OLLAMA_REMOTE_URL="https://ollama.example.com"

###################
# COWSAY SETTINGS #
###################

# Eyes and tongue of the llama
COWFILE="llama"
EYE="⦿"
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

if [[ "$OLLAMA_CONTAINER" == "" ]]; then
    VENGINE="Local"
    OLLAMA=$OLLAMA_LOCAL
else
    VENGINE="Docker"
    OLLAMA="docker exec -it $OLLAMA_CONTAINER ollama"
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
                echo "API not available" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "\n(Engine: $VENGINE)";
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
                echo "ollama not installed locally" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "(Engine: $VENGINE)";
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
                echo "API not available" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "\n(Engine: $VENGINE)";
            ;;

        Docker)
            # check if container available
            $OLLAMA_DOCKER -v 2>&1 >/dev/null && (
                # if true
                $OLLAMA run "$VMODEL" "$VPROMPT"
            ) || (
                # if not
                echo "API not available" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
            );
            echo -e "(Engine: $VENGINE)";
            ;;
    esac
}

list() {
    echo -e "\nAvailable models:\n";
    # check if api available
    curl $OLLAMA_API/ -I -s 2>&1 >/dev/null && (
        # if true
        curl $OLLAMA_API/api/tags -s | jq -r '.models[].name'
    ) || (
        # if not
        echo "API not available" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
    );
    echo -e "\n(Engine: $VENGINE)";
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
        echo "API not available" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
    )
    echo -e "\n(Engine: $VENGINE)";
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
        echo "API not available" | cowthink -W 60 -e "X" -T "$TONGUE" -f $COWFILE 2>/dev/null
    );
    echo -e "\n(Engine: $VENGINE)";
}

case $VENG in
    --local|-L) VENGINE="Local";
        OLLAMA="ollama"
        OLLAMA_API=$OLLAMA_LOCAL_URL;
        ;;
    --docker|-D) VENGINE="Docker";
        OLLAMA="docker exec -it ollama ollama"
        OLLAMA_API=$OLLAMA_DOCKER_URL;
        ;;
    --remote|-R) VENGINE="Remote";
        OLLAMA_API=$OLLAMA_REMOTE_URL;
        ;;
    --health) health;
        ;;
    --update-all) update_all;
        ;;
    *) echo
        $OLLAMA "$@"
        echo -e "\n(Engine: $VENGINE)"
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
