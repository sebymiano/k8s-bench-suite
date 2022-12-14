#/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt update && sudo apt install -y python3-pip

# Install dependencies
sudo python3 -m pip install -r ${DIR}/load-generator/requirements.txt --user

# Install Locust
sudo python3 -m pip install locust --user

if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "The path is correctly set"
else
    # export the locust path to locust
    echo export PATH="$HOME/.local/bin:$PATH" >> ~/.bashrc
    source ~/.bashrc
fi

echo "Installation of Locust is done. Please do source ~/.bashrc before using it!"