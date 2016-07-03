user_home = "/home/#{node['user']['name']}"
go_root = "#{node['golang']['root_dir']}/go"
scanner_abs_path = "#{go_root}/src/#{node['vuls']['scanner']['path']}"
has_server = false


ruby_block "source_go_env" do
  block do
    ENV['GOPATH'] = "#{node['user']['home']}/go"
    ENV['GOOS'] = 'linux'
    ENV['GOARCH'] = node['golang']['arch']
    ENV['GOROOT'] = go_root
  end
  action :run
end

node['vuls']['scanner']['server'].each do |os, servers|
  has_server = true unless servers.empty?
end

template "#{user_home}/config.toml" do
  source 'config.toml.erb'
  owner node['user']['name']
  group node['user']['name']
  mode '0755'
  variables :servers => {
    'amazon' => { 'user' => 'ec2-user', 'servers' => node['vuls']['scanner']['server']['amazon'] },
    'centos' => { 'user' => 'centos', 'servers' => node['vuls']['scanner']['server']['centos'] },
    'ubuntu' => { 'user' => 'ubuntu', 'servers' => node['vuls']['scanner']['server']['ubuntu'] },
    'redhat' => { 'user' => 'root', 'servers' => node['vuls']['scanner']['server']['redhat'] },
  }
  only_if { has_server }
end

execute 'vuls prepare' do
  user node['user']['name']
  cwd user_home
  command "#{scanner_abs_path}/vuls prepare"
  only_if { has_server }
end

execute 'vuls scan' do
  user node['user']['name']
  cwd user_home
  command "#{scanner_abs_path}/vuls scan"
  only_if { has_server }
end
