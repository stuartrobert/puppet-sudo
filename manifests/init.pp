# Class: sudo
#
# This module manages sudo
#
# Parameters:
#   [*ensure*]
#     Ensure if present or absent.
#     Default: present
#
#   [*package*]
#     Name of the package.
#     Only set this, if your platform is not supported or you know,
#     what you're doing.
#     Default: auto-set, platform specific
#
#   [*package_ensure*]
#     Allows you to ensure a particular version of a package
#     Default: present / lastest for RHEL < 5.5
#
#   [*package_source*]
#     Where to find the package.  Only set this on AIX (required) and
#     Solaris (required) or if your platform is not supported or you
#     know, what you're doing.
#
#     The default for aix is the perzl sudo package. For solaris 10 we
#     use the official www.sudo.ws binary package.
#
#     Default: AIX: perzl.org
#              Solaris: www.sudo.ws
#
#   [*package_admin_file*]
#     Where to find a Solaris 10 package admin file for
#     an unattended installation. We do not supply a default file, so
#     this has to be staged separately
#
#     Only set this on Solaris 10 (required)
#     Default: /var/sadm/install/admin/puppet
#
#   [*secure_path*]
#     The secure_path variable in sudoers. The new default is secure, where the old is not.
#     The old default is: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin
#     Default: /sbin:/usr/sbin:/bin:/usr/bin
#
#   [*purge*]
#     Whether or not to purge sudoers.d directory
#     Default: true
#
#   [*purge_ignore*]
#     Files to exclude from purging in sudoers.d directory
#     Default: undef
#
#   [*suffix*]
#     Adds a custom suffix to all files created in sudoers.d directory.
#
#   [*config_file*]
#     Main configuration file.
#     Only set this, if your platform is not supported or you know,
#     what you're doing.
#     Default: auto-set, platform specific
#
#   [*config_dir*]
#     Main directory containing sudo snippets, imported via
#     includedir stanza in sudoers file
#     Default: auto-set, platform specific
#
#   [*extra_include_dirs*]
#     Array of additional directories containing sudo snippets
#     Default: undef
#
#   [*content*]
#     Alternate content file location
#     Only set this, if your platform is not supported or you know,
#     what you're doing.
#     Default: auto-set, platform specific
#
#   [*ldap_enable*]
#     Enable ldap support on the package
#     Default: false
#
#   [*delete_on_error*]
#     True if you want that the configuration is deleted on an error
#     during a complete visudo -c run. If false it will just return
#     an error and will add a comment to the sudoers configuration so
#     that the resource will be checked at the following run.
#     Default: true
#
#   [*validate_single*]
#     Do a validate on the "single" file in the sudoers.d directory.
#     If the validate fail the file will not be saved or changed
#     if a file already exist.
#     Default: false
#
#   [*wheel_config*]
#     How to configure the wheel group in /etc/sudoers
#     Options are either not to configure it it, configure it prompting for password,
#     or configuring it without password prompt.
#     Default: 'absent' (don't configure it at all)
#
#   [*use_sudoreplay*]
#     Boolean to enable the usage of sudoreplay.
#     Default: false
#
#   [*sudoreplay_discard*]
#     Array of additional command to discard in sudo log.
#     Default: undef
#
#   [*configs*]
#     A hash of sudo::conf's
#     Default: {}
#
# Actions:
#   Installs sudo package and checks the state of sudoers file and
#   sudoers.d directory.
#
# Requires:
#   Nothing
#
# Sample Usage:
#   class { 'sudo': }
#
# [Remember: No empty lines between comments and class definition]
class sudo (
  Boolean                                   $enable              = true,
  Optional[String]                          $package             = $sudo::params::package,
  Optional[String]                          $package_ldap        = $sudo::params::package_ldap,
  String                                    $package_ensure      = $sudo::params::package_ensure,
  Optional[String]                          $package_source      = $sudo::params::package_source,
  Optional[String]                          $package_admin_file  = $sudo::params::package_admin_file,
  Optional[String]                          $secure_path         = $sudo::params::secure_path,
  Boolean                                   $purge               = true,
  Optional[Variant[String, Array[String]]]  $purge_ignore        = undef,
  Optional[String]                          $suffix              = undef,
  String                                    $config_file         = $sudo::params::config_file,
  Boolean                                   $config_file_replace = true,
  String                                    $config_file_mode    = $sudo::params::config_file_mode,
  String                                    $config_dir          = $sudo::params::config_dir,
  String                                    $config_dir_mode     = $sudo::params::config_dir_mode,
  Optional[Array[String]]                   $extra_include_dirs  = undef,
  String                                    $content             = $sudo::params::content,
  Boolean                                   $ldap_enable         = false,
  Boolean                                   $delete_on_error     = true,
  Boolean                                   $validate_single     = false,
  Boolean                                   $config_dir_keepme   = $sudo::params::config_dir_keepme,
  Boolean                                   $use_sudoreplay      = false,
  Enum['absent','password','nopassword']    $wheel_config        = 'absent',
  Optional[Array[String]]                   $sudoreplay_discard  = undef,
  Hash                                      $configs             = {},
) inherits sudo::params {
  case $enable {
    true: {
      $dir_ensure  = 'directory'
      $file_ensure = 'present'
    }
    false: {
      $dir_ensure  = 'absent'
      $file_ensure = 'absent'
    }
    default: { fail('no $enable is set') }
  }

  case $ldap_enable {
    true: {
      if $package_ldap == undef {
        fail('on your os ldap support for sudo is not yet supported')
      }
      $package_real = $package_ldap
    }
    false: {
      $package_real = $package
    }
    default: { fail('no $ldap_enable is set') }
  }
  if $package_real {
    class { 'sudo::package':
      package            => $package_real,
      package_ensure     => $package_ensure,
      package_source     => $package_source,
      package_admin_file => $package_admin_file,
      ldap_enable        => $ldap_enable,
      before             => [
        File[$config_file],
        File[$config_dir],
      ],
    }
  }

  file { $config_file:
    ensure  => $file_ensure,
    owner   => 'root',
    group   => $sudo::params::config_file_group,
    mode    => $config_file_mode,
    replace => $config_file_replace,
    content => template($content),
  }

  file { $config_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => $sudo::params::config_file_group,
    mode    => $config_dir_mode,
    recurse => $purge,
    purge   => $purge,
    ignore  => $purge_ignore,
  }

  if $config_dir_keepme {
    file { "${config_dir}/.keep-me":
      ensure => file,
      owner  => 'root',
      group  => $sudo::params::config_file_group,
    }
  }

  $configs.each |$config_name, $config| {
    sudo::conf { $config_name:
      * => $config,
    }
  }
}
