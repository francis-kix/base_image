# start dropbear sshd; host keys are generated on first connection (-R)
mkdir -p /etc/dropbear /root/.ssh

job sshd /usr/bin/dropbear -REFms -p 22
