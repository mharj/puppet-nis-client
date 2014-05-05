puppet-nis-client
=================

Manifest and template for yp.conf on Linux

Example:
```ruby
class { 'nis::client':
  domainname => 'domainname',
  yp_servers => { 
    'nis_domain1' => ['server1','server2','server3'],
    'nis_domain2' => ['server1','server2','server3'], 
    ..... 
  }
}
```
