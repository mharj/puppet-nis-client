class nis::client {
	notify {"nis::client":}
	include common::network,nscd
	# Note: common::network loads nis::config for different networks
	$domainname = $nis::config::domainname
	$yp_servers = $nis::config::yp_servers
		
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
		hasrestart => "true",
		enable  => "true",
		require => Package['ypbind'],
		notify	=> Service['nscd'],
	}
	# update domainname and restart ypbind
	exec { 'set_ypdomainname':
		refreshonly => true,
		command     => "ypdomainname ${domainname}",
		path        => [ '/bin','/usr/bin','/sbin','/usr/sbin'],
		notify      => Service['ypbind'],
	}
	# nisdomain file for RedHat based
	if $::osfamily == 'RedHat' {
		file_line { 'set_nisdomain': 
			ensure	=> present,
			path	=> '/etc/sysconfig/network',
			line	=> "NISDOMAIN=${domainname}",
			match	=> '^NISDOMAIN=',
			notify	=> Exec['set_ypdomainname'],
		}
	}
	# nisdomain file for Debian based
	elsif $::osfamily =~ /Suse|Debian/ {
		file { '/etc/defaultdomain':
			ensure  => file,
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			content => "${domainname}\n",
			notify	=> Exec['set_ypdomainname'],
		}
	}
	# setup nsswitch.conf for NIS
	file_line { 'set_nss_passwd': 
		ensure	=> present,
		path	=> '/etc/nsswitch.conf',
		line	=> "passwd:     files nis",
		match	=> '^passwd:',
	}
	file_line { 'set_nss_shadow': 
		ensure	=> present,
		path	=> '/etc/nsswitch.conf',
		line	=> "shadow:     files nis",
		match	=> '^shadow:',
	}
	file_line { 'set_nss_group': 
		ensure	=> present,
		path	=> '/etc/nsswitch.conf',
		line	=> "group:      files nis",
		match	=> '^group:',
	}	
	file_line { 'set_nss_automount': 
		ensure	=> present,
		path	=> '/etc/nsswitch.conf',
		line	=> "automount:  files nis",
		match	=> '^automount:',
	}
	# open tcp wrappers
	file_line { 'rpcbind: ALL': 
		ensure	=> present,
		path	=> '/etc/hosts.allow',
		line	=> "rpcbind: ALL",
		match	=> '^rpcbind:',
	}	
	# fix ypbind dbus
	file { "/etc/sysconfig/ypbind":                                                                                                                                                                                                                                                                                                                            
		content => 'OTHER_YPBIND_OPTS="-no-dbus"',                                                                                                                                                                                                                                                                                                   
		notify  => Service['ypbind']
	}
	
}