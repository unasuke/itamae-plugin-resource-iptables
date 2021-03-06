require 'itamae/plugin/resource/iptables'

iptables_flush 'flush' do
end

iptables_policy 'INPUT' do
  action :drop
end

iptables_policy 'OUTPUT' do
  action :accept
end

iptables_policy 'FORWARD' do
  action :drop
end

iptables_rule 'accept loopback' do
  action :accept
  chain 'INPUT'
  in_interface 'lo'
end

iptables_rule 'accept ping' do
  action :accept
  chain 'INPUT'
  protocol 'icmp'
end

iptables_rule 'accept related,established' do
  action :accept
  chain 'INPUT'
  state %w[RELATED ESTABLISHED]
end

iptables_rule 'accept from local' do
  action :accept
  chain 'INPUT'
  source '192.168.10.0/24'
end

iptables_chain 'SSH_LOGGING' do
end

iptables_rule 'chain ssh' do
  action :create
  chain 'INPUT'
  protocol 'tcp'
  dport 22
  state %w[NEW]
  jump 'SSH_LOGGING'
end

iptables_rule 'log ssh' do
  action :log
  chain 'SSH_LOGGING'
  log_prefix '[ssh] '
  log_level 'info'
end

iptables_rule 'accept ssh' do
  action :accept
  chain 'SSH_LOGGING'
end

iptables_save '/etc/iptables/iptables.rules' do
end

service 'iptables.service' do
  action [:enable, :start]
end
