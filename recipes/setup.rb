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
  user node['user']['name']
  command "ssh-keygen -t rsa -b 4096 -N '' -f #{node['user']['home']}/.ssh/id_rsa"
  not_if { File.exists?("#{node['user']['home']}/.ssh/id_rsa.pub") }
end

execute 'publish id_rsa.pub' do
  user node['user']['name']
  command "ruby -run -e httpd #{node['user']['home']}/.ssh/id_rsa.pub -p 1414 >/dev/null 2>&1 &"
  only_if { File.exists?("#{node['user']['home']}/.ssh/id_rsa.pub") }
end

template "/etc/profile.d/goenv.sh" do
  source 'goenv.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables :vars => {
    'go_root' => node['golang']['root'],
    'go_path' => "#{node['user']['home']}/go"
  }
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

