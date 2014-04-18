# setup lxc
include_recipe "yum-repoforge"

%w(
debootstrap
lxc
lxc-templates
lxc-doc
lxc-libs
).each do |pkg|
  package pkg
end

template "/etc/sysconfig/network-scripts/ifcfg-lxcbr0" do
  source "ifcfg.erb"
  owner "root"
  group "root"
  variables({
    device: "lxcbr0",
    type: "Bridge",
    bootproto: "none",
    target: "10.0.3.1",
    mask: "255.255.255.0",
    onboot: "yes",
  })
  notifies :run, "ifup lxcbr0"
end

directory "/cgroup"
mount "cgroup" do
  fstype "cgroup"
  action [:mount, :enable]
end

#node.default[:sysctl][:params][:net][:ipv4][:ip_forward] = 1
#include_recipe "sysctl"

# create template

template_dir = "#{node[:vnet][:lxc][:basedir]}/#{node[:vnet][:lxc][:template_name}"
template_file = "#{template_dir}.tar.gz"

bash "create_template" do
  not_if { File.exists?(template_file) }

  code <<-EOS
    mkdir -p #{template_dir}

    # centos-release
    cat /etc/yum.repos.d/CentOS-Base.repo |sed s/'$releasever'/6/g > #{template_dir}/etc/yum.repos.d/CentOS-Base.repo

    # install base packages
    yum --installroot=#{template_dir} groupinstall base

    chroot /t

    # create devices
    rm -f /dev/null
    mknod -m 666 /dev/null c 1 3
    mknod -m 666 /dev/zero c 1 5
    mknod -m 666 /dev/urandom c 1 9
    ln -s /dev/urandom /dev/random
    mknod -m 600 /dev/console c 5 1
    mknod -m 660 /dev/tty1 c 4 1
    chown root:tty /dev/tty1
    mkdir -p /dev/shm
    chmod 1777 /dev/shm
    mkdir -p /dev/pts
    chmod 755 /dev/pts

    # copy skel files
    cp -a /etc/skel/. /root/.

    # dns
    cat > /etc/resolv.conf << END
nameserver 8.8.8.8
nameserver 8.8.4.4
    END

    # /etc/hosts
    cat > /etc/hosts << END
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
    END

    # /etc/sysconfig/network
    cat > /etc/sysconfig/network << END
NETWORKING=yes
HOSTNAME=localhost
    END

    # fstab
    cat > /etc/fstab << END
/dev/root               /                       rootfs   defaults        0 0
none                    /dev/shm                tmpfs    nosuid,nodev    0 0
END

    # lxc-sysinit.conf
    cat > /etc/init/lxc-sysinit.conf << END
start on startup
env container
pre-start script
        if [ "x$container" != "xlxc" -a "x$container" != "xlibvirt" ]; then
                stop;
        fi
        telinit 3
        initctl start tty TTY=console
        exit 0;
end script
    END

    # vagrant user
    useradd vagrant
    echo vagrant:vagrant | chpasswd

    #sed "s/Defaults *requiretty/#Defaults    requiretty/" -i /etc/sudoers
    echo "%vagrant>-ALL=(ALL)>NOPASSWD: ALL" >> /etc/sudoers.d/vagrant

    exit

    # configure ssh
    mkdir -p #{template_dir}/home/vagrant/.ssh
    cp -a /vagrant/share/ssh #{template_dir}/home/vagrant/.ssh/
    chown -R vagrant:vagrant #{template_dir}/home/vagrant/.ssh
    chmod 700 #{template_dir}/home/vagrant/.ssh;

    tar cvfz #{template_file} .
  EOS
end

# create vms
node[:vnet][:vms].select { |vm| vm["host"] == node.name }.tap do |vms|
  vms.each do |vm|
    vm_dir = "#{node[:vnet][:lxc][:basedir]}/#{vm[:name]}"

    base "create_rootfs" do
      code <<-EOS
        mkdir #{vm_dir}
        mkdir #{vm_dir}/rootfs

        tar xvfz #{template_file} -C #{vm_dir}/rootfs --numeric-owner
      EOS
    end

    template "#{vm_dir}/config" do
      source "lxc/config.erb"
      mode "0644"
      variables vm: vm
    end

    template "#{vm_dir}/fstab" do
      source "lxc/fstab.erb"
      mode "0644"
      variables vm: vm
    end
  end
end
