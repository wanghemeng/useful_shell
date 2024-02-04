# for clash activate
alias clash='export http_proxy='http://127.0.0.1:7893';export https_proxy='http://127.0.0.1:7893';export all_proxy='sock5:/http://127.0.0.1:7893';export ALL_PROXY='sock5://http://127.0.0.1:7893''

# enable auto complete in bash (no need in oh-my-zsh)
if [[ $- == *i* ]]
then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

# kill by process id
kbp() {
    port=$1
    pids=$(lsof -t -i :$port)
    
    if [ -z "$pids" ]; then
        echo "No processes found using port $port"
        return 0
    fi
    
    for pid in $(echo "$pids"); do
        kill -9 $pid
    done
    
    echo "All processes using port $port have been terminated"
}
