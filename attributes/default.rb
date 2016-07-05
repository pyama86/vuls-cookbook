default["setting"]["publish_ssh_pub_key"] = false

default['package']['names'] = %w(wget vim git gcc sqlite)

default['user']['name'] = 'ec2-user'

default['golang']['version'] = '1.6'
default['golang']['arch'] = 'amd64'
default['golang']['root_dir'] = '/usr/local'

default['vuls']['go-cve-dictionary']['path'] = 'github.com/kotakanbe/go-cve-dictionary'
default['vuls']['go-cve-dictionary']['branch'] = 'master'
default['vuls']['go-cve-dictionary']['nvd']['start_year'] = '2013'
default['vuls']['go-cve-dictionary']['nvd']['end_year'] = '2016'

default['vuls']['scanner']['path'] = 'github.com/future-architect/vuls'
default['vuls']['scanner']['branch'] = 'master'
default['vuls']['scanner']['server']['amazon'] = %w()
default['vuls']['scanner']['server']['centos'] = %w()
default['vuls']['scanner']['server']['ubuntu'] = %w()
default['vuls']['scanner']['server']['redhat'] = %w()
