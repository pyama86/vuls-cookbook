has_server = false
node['vuls']['scanner']['server'].each do |os, servers|
  has_server = true unless servers.empty?
end

template "#{node['user']['home']}/config.toml" do
  source 'config.toml.erb'
  owner node['user']['name']
  group node['user']['name']
  mode '0755'
  variables :servers => {
    'amazon' => { 'user' => 'ec2-user', 'servers' => node['vuls']['scanner']['server']['amazon'] },
    'centos' => { 'user' => 'root', 'servers' => node['vuls']['scanner']['server']['centos'] },
    'ubuntu' => { 'user' => 'ubuntu', 'servers' => node['vuls']['scanner']['server']['ubuntu'] },
    'redhat' => { 'user' => 'root', 'servers' => node['vuls']['scanner']['server']['redhat'] },
  }
  only_if { has_server }
end

execute 'vuls prepare' do
  user node['user']['name']
  cwd node['user']['home']
  command "#{node['golang']['command']} run #{node['user']['home']}/vuls/main.go prepare"
  only_if { has_server }
end

execute 'vuls scan' do
  user node['user']['name']
  cwd node['user']['home']
  command "#{node['golang']['command']} run #{node['user']['home']}/vuls/main.go scan"
  only_if { has_server }
end
