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
    ENV['GO15VENDOREXPERIMENT'] = 1
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

execute "install glide" do
  command "go get github.com/Masterminds/glide"
end

['go-cve-dictionary', 'scanner'].each do |repo|
  git repo do
    destination node['vuls'][repo]['abs_path']
    repository node['vuls'][repo]['url']
    revision node['vuls'][repo]['branch']
    user node['user']['name']
    group node['user']['name']
  end
  
  execute "install package for #{repo}" do
    cwd node['vuls'][repo]['abs_path']
    command "glide install && go build"
  end
end

execute 'fetch NVD' do
  cwd node['user']['home']
  command "number=#{node['vuls']['go-cve-dictionary']['nvd']['start_year']};while [ \"$number\" -lt #{node['vuls']['go-cve-dictionary']['nvd']['end_year']} ]; do #{node['vuls']['go-cve-dictionary']['abs_path']}/go-cve-dictionary fetchnvd -years $number; number=`expr $number + 1`; done"
  creates "#{node['user']['home']}/cve.sqlite3"
end
