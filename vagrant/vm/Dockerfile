FROM centos

RUN yum install -y passwd sudo openssh-server openssh-clients telnet tcpdump bind-utils nc

RUN sed -ri \
  -e 's/UsePAM yes/#UsePAM yes/g' \
  -e 's/#UsePAM no/UsePAM no/g' \
  -e 's/#UseDNS yes/UseDNS no/g' \
  /etc/ssh/sshd_config
RUN /etc/init.d/sshd start
RUN /etc/init.d/sshd stop

RUN useradd vagrant
RUN echo vagrant:vagrant | chpasswd
ADD ./ssh /home/vagrant/.ssh/
RUN mkdir -p /home/vagrant/.ssh; chown -R vagrant:vagrant /home/vagrant/.ssh; chmod 700 /home/vagrant/.ssh;
RUN echo "vagrant	ALL=(ALL)	ALL" >> /etc/sudoers.d/vagrant

# EXPOSE is not necessary
#EXPOSE 22

CMD /usr/sbin/sshd -D
