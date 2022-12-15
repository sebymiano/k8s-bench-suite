#!/bin/bash

IP=$1
PORT=$2
TYPE=$3

tmux set remain-on-exit on

echo "Creating tmux panes..."
for j in {0..17}
do
    tmux split-window -v -p 80 -t ${j}
    tmux select-layout -t ${j} tiled
done

echo "Configuring fds in tmux panes..."
for j in {1..17}
do
    tmux send-keys -t ${j} "./set_fd.sh" Enter
    tmux send-keys -t ${j} "cd ./locust_worker_${j}/" Enter
    sleep 0.1
done

echo "Testing the locust master in tmux pane 1..."
tmux send-keys -t 1 "locust --version && echo \"Run Knative's locust master\"" Enter

sleep 0.1

echo "Testing locust workers in each tmux pane..."
for j in {2..17}
do
    tmux send-keys -t ${j} "locust --version && echo \"Run locust worker in pane ${j}\"" Enter
    sleep 0.1
done

# tmux kill-pane -t 0

######
echo "Run the locust master in tmux pane 1..."
echo "Run locust master"
if [ $TYPE == "25k" ]; then
    tmux send-keys -t 1 "locust -u 25000 -r 500 -t 3m --csv kn --csv-full-history -f locustfile.py --headless  -H http://${IP}:${PORT} --master --expect-workers=16" Enter
else
    tmux send-keys -t 1 "locust -u 5000 -r 200 -t 3m --csv kn --csv-full-history -f locustfile.py --headless  -H http://${IP}:${PORT} --master --expect-workers=16" Enter
fi

sleep 0.1

echo "Run locust workers in each tmux pane..."
for j in {2..17}
do
    echo "Run locust worker"
    tmux send-keys -t ${j} "locust -f locustfile.py --worker" Enter
done

sleep 0.1