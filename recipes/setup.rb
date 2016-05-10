#
# Cookbook Name:: vuls
# Recipe:: setup
#
# Copyright 2016, vuls
#
# All rights reserved - Do Not Redistribute
#
#

node['package']['names'].each do |pack|
  package pack
end

execute 'create ssh keys' do
  command "ssh-keygen -t rsa -b 4096 -N '' -f #{node['user']['home']}/.ssh/id_rsa"
end

ruby_block "source_go_env" do
  block do
    ENV['GOPATH'] = "#{node['user']['home']}/go"
    ENV['GOOS'] = 'linux'
    ENV['GOARCH'] = node['golang']['arch']
    ENV['GOROOT'] = node['golang']['root']
  end
  action :run
end

execute 'install golang' do
  command "wget #{node['golang']['src']['url']} -P #{node['user']['home']} &&
           tar xzf #{node['user']['home']}/#{node['golang']['src']['name']} -C #{node['golang']['root_dir']}"
  creates  node['golang']['root']
  notifies :create, "ruby_block[source_go_env]", :immediately
end

directory '/var/log/vuls' do
  owner node['user']['name']
  group node['user']['name']
  mode '0700'
end

git "go-cve-dictionary" do
  destination "#{node['user']['home']}/go-cve-dictionary"
  repository node['vuls']['go-cve-dictionary']['url']
  revision node['vuls']['go-cve-dictionary']['branch']
  user node['user']['name']
  group node['user']['name']
end

node['vuls']['go-cve-dictionary']['imports'].each do |pack|
  execute "install #{pack} for go-cve-dictionary" do
    command "#{node['golang']['command']} get #{pack}"
    creates "#{node['golang']['root']}/src/#{pack}"
  end
end

execute 'fetch NVD' do
  cwd node['user']['home']
  command "for i in {#{node['vuls']['go-cve-dictionary']['nvd']['start_year']}..#{node['vuls']['go-cve-dictionary']['nvd']['end_year']}}; do #{node['golang']['command']} run go-cve-dictionary/main.go fetchnvd -years $i; done"
  creates "#{node['user']['home']}/cve.sqlite3"
end

#service 'go-cve-dictionary server' do
#  service_name 'cve_server'
#  start_command "#{node['golang']['command']} run #{node['user']['home']}/go-cve-dictionary/main.go server -dbpath=#{node['user']['home']}/cve.sqlite3"
#  action [ :start ]
#end


template "/etc/init.d/go-cve-dictionary" do
  source 'go-cve-dictionary.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables :servers => {
    'go_root' => node['golang']['root'],
    'go_path' => "#{node['user']['home']}/go",
    'user_home'=> node['user']['home']
  }
end

execute 'go-cve-dictionary server' do
  command "/etc/init.d/go-cve-dictionary start"
end

git 'vuls scanner' do
  destination "#{node['user']['home']}/vuls"
  repository node['vuls']['scanner']['url']
  revision node['vuls']['scanner']['branch']
  user node['user']['name']
  group node['user']['name']
end

node['vuls']['scanner']['imports'].each do |pack|
  execute "install #{pack} for vuls scanner" do
    command "#{node['golang']['command']} get #{pack}"
    creates "#{node['golang']['root']}/src/#{pack}"
  end
end

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

