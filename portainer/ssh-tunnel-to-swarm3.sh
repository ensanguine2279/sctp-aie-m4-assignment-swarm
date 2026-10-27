#!/bin/bash
#
# SSH tunnel to swarm-3 for Portainer access on localhost:9443
gcloud compute ssh swarm-3 --zone=asia-southeast1-b -- -L 9443:localhost:9443