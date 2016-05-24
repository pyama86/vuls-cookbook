ruby_block "source_go_env" do
  block do
    ENV['GOPATH'] = "#{node['user']['home']}/go"
    ENV['GOOS'] = 'linux'
    ENV['GOARCH'] = node['golang']['arch']
    ENV['GOROOT'] = node['golang']['root']
  end
  action :run
end

execute 'fetch NVD' do
  cwd node['user']['home']
  command "number=#{node['vuls']['go-cve-dictionary']['nvd']['start_year']};while [ \"$number\" -lt #{node['vuls']['go-cve-dictionary']['nvd']['end_year']} ]; do #{node['golang']['command']} run go-cve-dictionary/main.go fetchnvd -years $number; number=`expr $number + 1`; done"
  creates "#{node['user']['home']}/cve.sqlite3"
end

#execute 'go-cve-dictionary server' do
#  cwd node['user']['home']
#  command "#{node['golang']['command']} run #{node['user']['home']}/go-cve-dictionary/main.go server -dbpath=#{node['user']['home']}/cve.sqlite3 >/dev/null 2>&1 &"
#  creates "#{node['user']['home']}/cve.sqlite3"
#end


template "/etc/init.d/go-cve-dictionary" do
  source 'go-cve-dictionary.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables :vars => {
    'go_root' => node['golang']['root'],
    'go_path' => "#{node['user']['home']}/go",
    'user_home'=> node['user']['home']
  }
end

execute 'go-cve-dictionary server' do
  command "/etc/init.d/go-cve-dictionary start"
end
