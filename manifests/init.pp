# == Class: nis::client
#
# NIS Client configuration
#
# === Parameters
#
# Document parameters here.
#
# domainname => 'domainname'
# yp_servers => { 'nis_domain1' => ['server1','server2','server3'],'nis_domain2'=>['server1','server2','server3'], ..... } 
#
# === Examples
#
#  class { 'nis::client':
#    domainname => 'domainname',
#    yp_servers => { 'nis_domain1' => ['server1','server2','server3'],'nis_domain2'=>['server1','server2','server3'], ..... }
#  }
#

class nis::client ($domainname,$yp_servers) {
        # yp.conf
        case $operatingsystem {
                centos,redhat: { $package = "ypbind" }
                debian,ubuntu: { $package = "nis" }
                default: { fail("Unrecognized operating system for nis client") }
        }
        file { "/etc/yp.conf":
                content => template('nis/yp.conf.erb'),
                notify  => Service['ypbind']
        }
        package {'ypbind':
                name   => $package,
                ensure => present,
        }
        service {'ypbind':
                name => $package ,
                ensure  => running,
                enable  => "true",
                require => Package['ypbind'],
        }
        # update domainname and restart ypbind
        exec { 'ypdomainname':
                command     => "ypdomainname ${domainname}",
                path        => [ '/bin','/usr/bin','/sbin','/usr/sbin'],
                refreshonly => true,
                notify      => Service['ypbind'],
                unless          => 'ypdomainname | grep "${domainname}"',
        }
        # nisdomain file for RedHat based
        if $::osfamily == 'RedHat' {
                exec { 'set_nisdomain':
                        command => "echo NISDOMAIN=${domainname} >> /etc/sysconfig/network",
                        path    => [ '/bin','/usr/bin','/sbin','/usr/sbin'],
                        unless  => 'grep ^NISDOMAIN /etc/sysconfig/network',
                } # set NISDOMAIN if not already configured
                exec { 'change_nisdomain':
                        command => "sed -i 's/^NISDOMAIN.*/NISDOMAIN=${domainname}/' /etc/sysconfig/network",
                        path    => [ '/bin','/usr/bin','/sbin','/usr/sbin'],
                        unless  => "grep ^NISDOMAIN=${domainname} /etc/sysconfig/network",
                        onlyif  => 'grep ^NISDOMAIN /etc/sysconfig/network',
                } # replace NISDOMAIN if different than current
        }
        # nisdomain file for Debian based
        elsif $::osfamily =~ /Suse|Debian/ {
                file { '/etc/defaultdomain':
                        ensure  => file,
                        owner   => 'root',
                        group   => 'root',
                        mode    => '0644',
                        content => "${domainname}\n",
                }
        }
}
