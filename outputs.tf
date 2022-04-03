output "manager_ip" {
  description = "Swarm Manager IP"
  value = "${aws_instance.manager.public_ip}"
}

output "workers_ip" {
  description = "Swarm Worker IP"
  value = "${aws_instance.worker.*.public_ip}"
  
}