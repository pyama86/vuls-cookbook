
execute 'fetch NVD' do
  cwd node['user']['home']
  command "for i in {#{node['vuls']['go-cve-dictionary']['nvd']['start_year']}..#{node['vuls']['go-cve-dictionary']['nvd']['end_year']}}; do #{node['golang']['command']} run go-cve-dictionary/main.go fetchnvd -years $i; done"
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
