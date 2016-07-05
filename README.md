Vuls Cookbook
===================

# Description

This is a chef cookbook for vuls.

Use this and you can get the vuls scanner environment.

Ofcourse, you can use this in Opsworks(AWS).

Detail actions in this is below.


- setup.rb
  1. Install wget vim git gcc sqlite
  2. Create a ssh key pair(option)
  3. Publish the ssh public key(option)
  4. Install golang(default varsion:1.6)
  5. Install glide
  6. Clone go-cve-dictionary
  7. Install packages for go-cve-dictionary
  8. Build go-cve-dictionary
  9. Clone vuls
  10. Install packages for vuls
  11. Build vuls
  12. Fetch CVD by go-cve-dictionary
- scan.rb
  1. Create config.toml
  2. Execute vuls prepare
  3. Execute vuls scan

# Dependency

- chef 12

# Configure

Please Configure '/attributes/default.rb'. See below.

```
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
```

# Usage

- Use chef
  - Install chef
  - Clone this repository
  - Execute chef
- Use Opsworks
  - Setup Opsworks
  - Add this repository to the layer setting
  - Run instance

# Use With CloudFormation

You can use this cookbook with [cloudformation](https://github.com/sadayuki-matsuno/vuls-cf).

# Author

Sadayuki Matsuno
