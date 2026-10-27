output "swarm1_public_ip" {
  description = "Point the DNS A record for your domain at this address."
  value       = google_compute_address.swarm1_public.address
}

output "swarm1_internal_ip" {
  description = "Private address the other nodes use to join the swarm."
  value       = google_compute_address.swarm1_internal.address
}

output "ssh_commands" {
  description = "Commands to open a shell on each node."
  value = {
    for n in local.nodes :
    n => "gcloud compute ssh ${n} --zone=${var.zone} --project=${var.project_id}"
  }
}

output "portainer_tunnel_command" {
  description = "Run on your own computer after deploying the Portainer stack, then open https://localhost:9443."
  value       = "gcloud compute ssh ${local.nodes[length(local.nodes) - 1]} --zone=${var.zone} --project=${var.project_id} -- -L 9443:localhost:9443"
}

output "next_steps" {
  description = "What is still done by hand after apply."
  value       = <<-EOT
    1. Create a DNS A record for your domain pointing at ${google_compute_address.swarm1_public.address}.
    2. SSH to swarm-1 and check the swarm:  sudo docker node ls   (3 managers, db=true label on swarm-1).
    3. Create ~/users.env, ~/tasks.env and the JWT keys on swarm-1 (setup guide, section 6).
    4. Deploy the users, tasks, proxy and portainer stacks (setup guide, sections 7 to 9), or push to main so CI deploys them.
  EOT
}
