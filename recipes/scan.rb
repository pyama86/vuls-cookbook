template "#{node['user']['home']}/config.toml" do
  source 'config.toml.erb'
  owner node['user']['name']
  group node['user']['name']
  mode '0755'
  variables :servers => {
    'amazon' => { 'user' => 'ec2-user', 'servers' => node['vuls']['scanner']['amazon'] },
    'centos' => { 'user' => 'root', 'servers' => node['vuls']['scanner']['centos'] },
    'ubuntu' => { 'user' => 'ubuntu', 'servers' => node['vuls']['scanner']['ubuntu'] },
    'redhat' => { 'user' => 'root', 'servers' => node['vuls']['scanner']['redhat'] },
  }
end

execute 'vuls prepare' do
  cwd node['user']['home']
  command "#{node['golang']['command']} run #{node['user']['home']}/vuls/main.go prepare"
end

execute 'vuls scan' do
  cwd node['user']['home']
  command "#{node['golang']['command']} run #{node['user']['home']}/vuls/main.go scan"
end

