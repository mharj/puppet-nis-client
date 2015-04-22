puppet-nis-client
=================

Manifest and template for yp.conf on Linux

Install to modules directory:
```bash
# git clone https://github.com/mharj/puppet-nis-client.git nis
```

Example:
```ruby
class { 'nis::config':
  domainname => 'domainname',
  yp_servers => { 
    'nis_domain1' => ['server1','server2','server3'],
    'nis_domain2' => ['server1','server2','server3'], 
    ..... 
  }
}

include nis::client
```
