#
# Cookbook Name:: vuls
# Recipe:: setup
#
# Copyright 2016, vuls
#
# All rights reserved - Do Not Redistribute
#
#

# set vars
user_home = "/home/#{node['user']['name']}"
go_root = "#{node['golang']['root_dir']}/go"
go_path = "#{user_home}/go"
go_bin = "#{go_path}/bin"
go_cmd = "#{go_root}/bin/go"
go_src_name = "go#{node['golang']['version']}.linux-#{node['golang']['arch']}.tar.gz"
go_src_url = "https://storage.googleapis.com/golang/#{go_src_name}"
go_cve_dictionary_abs_path = "#{go_path}/src/#{node['vuls']['go-cve-dictionary']['path']}"
scanner_abs_path = "#{go_path}/src/#{node['vuls']['scanner']['path']}"

node['package']['names'].each do |pack|
  package pack
end

execute 'create ssh keys' do
  user node['user']['name']
  command "ssh-keygen -t rsa -b 4096 -N '' -f #{user_home}/.ssh/id_rsa"
  not_if { File.exists?("#{user_home}/.ssh/id_rsa.pub") && ["setting"]["publish_ssh_pub_key"] }
end

execute 'publish id_rsa.pub' do
  user node['user']['name']
  command "ruby -run -e httpd #{user_home}/.ssh/id_rsa.pub -p 1414 >/dev/null 2>&1 &"
  only_if { File.exists?("#{user_home}/.ssh/id_rsa.pub") && node["setting"]["publish_ssh_pub_key"] }
end

template "/etc/profile.d/goenv.sh" do
  source 'goenv.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables :vars => {
    'go_root' => go_root,
    'go_path' => go_path
  }
end

ruby_block "source_go_env" do
  block do
    ENV['GOPATH'] = go_path
    ENV['GOOS'] = 'linux'
    ENV['GOARCH'] = node['golang']['arch']
    ENV['GOROOT'] = go_root
    ENV['GO15VENDOREXPERIMENT'] = "1"
  end
  action :run
end

execute 'install golang' do
  command "wget #{go_src_url} -P #{user_home} &&
           tar xzf #{user_home}/#{go_src_name} -C #{node['golang']['root_dir']}"
  creates  go_root
  notifies :create, "ruby_block[source_go_env]", :immediately
end

directory "#{user_home}/go" do
  owner node['user']['name']
  group node['user']['name']
  mode '0755'
end

directory '/var/log/vuls' do
  owner node['user']['name']
  group node['user']['name']
  mode '0700'
end

execute "install glide" do
  command "GOPATH=#{go_path} && #{go_cmd} get github.com/Masterminds/glide"
  user node['user']['name']
end

execute "git clone go-cve-dictionary" do
  command "git clone http://#{node['vuls']["go-cve-dictionary"]['path']} -b #{node['vuls']['go-cve-dictionary']['branch']} #{go_cve_dictionary_abs_path}"
  user node['user']['name']
  group node['user']['name']
end

execute "glide install" do
  cwd go_cve_dictionary_abs_path
  command "PATH=$PATH:#{go_root}/bin:#{go_path}/bin &&
          GOPATH=#{go_path} GOROOT=#{go_root} #{go_bin}/glide install"
  user node['user']['name']
end

execute "build go-cve-dictionary" do
  cwd go_cve_dictionary_abs_path
  command "GOPATH=#{go_path} GOROOT=#{go_root} #{go_cmd} build"
  user node['user']['name']
end

execute "git clone scanner" do
  command "git clone http://#{node['vuls']["scanner"]['path']} -b #{node['vuls']['scanner']['branch']} #{go_cve_dictionary_abs_path}"
  user node['user']['name']
  group node['user']['name']
end

execute "glide install" do
  cwd scanner_abs_path
  command "PATH=$PATH:#{go_root}/bin:#{go_path}/bin &&
          GOPATH=#{go_path} GOROOT=#{go_root} #{go_bin}/glide install"
  user node['user']['name']
end

execute "build scanner" do
  cwd scanner_abs_path
  command "GOPATH=#{go_path} GOROOT=#{go_root} #{go_cmd} build"
  user node['user']['name']
end

execute 'fetch NVD' do
  cwd user_home
  command "number=#{node['vuls']['go-cve-dictionary']['nvd']['start_year']};while [ \"$number\" -lt #{node['vuls']['go-cve-dictionary']['nvd']['end_year']} ]; do #{go_cve_dictionary_abs_path}/go-cve-dictionary fetchnvd -years $number; number=`expr $number + 1`; done"
  user node['user']['name']
  creates "#{user_home}/cve.sqlite3"
end
