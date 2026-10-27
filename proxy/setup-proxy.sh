gcloud compute scp stack-proxy.yml Caddyfile swarm-1:~ --zone=asia-southeast1-b
gcloud compute ssh swarm-1 --zone=asia-southeast1-b
sudo docker network ls | grep -E "users-network|tasks-network"
sudo docker stack deploy -c stack-proxy.yml proxy
sudo docker service logs proxy_caddy --tail 40

curl -i https://sctp-aie-m4-apigw.work.gd/api/tasks/1     # 401 JSON from the tasks API, over HTTPS
curl -i http://sctp-aie-m4-apigw.work.gd/                 # redirects to https
curl -i https://sctp-aie-m4-apigw.work.gd/actuator/health # 404, blocked at the proxy