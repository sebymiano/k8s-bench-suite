#!/bin/bash

ansible-playbook -i hosts cilium-test-25k.yaml
sleep 10

ansible-playbook -i hosts calico-test-25k.yaml
sleep 10

ansible-playbook -i hosts polykube-test-25k.yaml
sleep 10

ansible-playbook -i hosts morpheus-full-test-25k.yaml
sleep 10

ansible-playbook -i hosts morpheus-only-router-test-25k.yaml
sleep 10