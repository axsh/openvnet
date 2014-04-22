FROM centos

RUN yum install -y passwd sudo openssh-server openssh-clients telnet tcpdump bind-utils nc dnsmasq

# ssh
#RUN echo UsePAM no >> /etc/ssh/sshd_config
RUN echo "UseDNS no" >> /etc/ssh/sshd_config
RUN echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
RUN /etc/init.d/sshd start
RUN /etc/init.d/sshd stop
# http://stackoverflow.com/questions/22547939/docker-gitlab-container-ssh-git-login-error
RUN sed -i "s/session *required *pam_loginuid.so/session    optional     pam_loginuid.so/" /etc/pam.d/sshd

# vagrant user
RUN useradd vagrant
RUN echo vagrant:vagrant | chpasswd
ADD ./ssh/vnet_private_key /home/vagrant/.ssh/vnet_private_key
ADD ./ssh/vm_config /home/vagrant/.ssh/config
ADD ./ssh/authorized_keys /home/vagrant/.ssh/authorized_keys
RUN mkdir -p /home/vagrant/.ssh; chown -R vagrant:vagrant /home/vagrant/.ssh; chmod 700 /home/vagrant/.ssh;

# sudo
RUN sed "s/Defaults *requiretty/#Defaults    requiretty/" -i /etc/sudoers
RUN echo "vagrant	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers.d/vagrant

# dnsmasq
RUN echo "NETWORKING=yes" > /etc/sysconfig/network
RUN echo "listen-address=127.0.0.1" >> /etc/dnsmasq.conf
RUN echo "resolv-file=/etc/resolv.dnsmasq.conf" >> /etc/dnsmasq.conf
RUN echo "user=root" >> /etc/dnsmasq.conf
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.dnsmasq.conf
RUN echo "nameserver 8.8.4.4" >> /etc/resolv.dnsmasq.conf

# EXPOSE is not necessary
#EXPOSE 22

CMD /usr/sbin/sshd -D
