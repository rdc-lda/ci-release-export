# How to set up an SFTP server on CentOS

These steps walk you through the process of setting up an SFTP server on CentOS for the secure transfer of files for specialized file transfer-only users.

## What you'll need

CentOS 7 already has everything you need, out of the box. What you must have, however, is access to an account with admin rights. Once you've procured that access, it's time to make this work.

## Generic settings

~~~bash
# Set base SFTP dir
export BASE_SFTP_DIR=/var/data/sftp
export SFTP_USER=user123
~~~

## SFTP Directory

The first thing we must do is create a directory that will house our FTP data. Open up a terminal window, su to the root user (type su and then, when prompted, type the root user password), and then issue the following two commands:

~~~bash
# Create the base SFTP directory
$ sudo mkdir -p $BASE_SFTP_DIR
$ sudo chmod 701 $BASE_SFTP_DIR
~~~

## Create the SFTP group and user

Now we're going to create a special group for SFTP users. This is done with the following command:

~~~bash
# Create the group the user(s) should be part of
$ sudo groupadd sftp_users
~~~

Now we're going to create a special user that doesn't have regular login privileges, but does belong to our newly created sftp_users group. What you call that user is up to you. The command for this is:

~~~bash
# Create the SFTP user
$ sudo useradd -g sftp_users -d /upload -s /sbin/nologin $SFTP_USER
~~~

Next, give the new user a password. This password will be the password the new users use to log in with the sftp command. To set up the password, issue the command:

~~~bash
# Set password for SFTP user
$ sudo passwd $SFTP_USER
~~~

## Create the new user SFTP directory

Now we're going to create an upload directory, specific to the new user, and then give the directory the proper permissions. This is handled with the following commands:

~~~bash
# Create the homedir and upload of the new user
$ sudo mkdir -p $BASE_SFTP_DIR/$SFTP_USER/upload

# Set permissions
$ sudo chown -R root:sftp_users $BASE_SFTP_DIR/$SFTP_USER
$ sudo chown -R $SFTP_USER:sftp_users $BASE_SFTP_DIR/$SFTP_USER/upload
~~~

## Configure sshd

Open up the SSH daemon configuration file `/etc/ssh/sshd_config` and at the bottom of that file, add the following -- you need to replace the directory `/var/data/sftp` if you have set a different initial value in the first section.

~~~text
# Enable password authentication for this group enforcing SFTP
Match Group sftp_users
   PasswordAuthentication yes
   ChrootDirectory /var/data/sftp/%u
   ForceCommand internal-sftp
~~~

Save and close that file. Restart SSH with the command:

~~~bash
# Restart deamon (possibly with sudo)
$ sudo systemctl restart sshd
~~~

## Logging in

You're all set to log in. From another machine on your network that has SSH installed, open up a terminal window and issue the command:

~~~bash
sftp USERNAME@SERVER_IP
~~~

Where `USERNAME` is the name of our new user and `SERVER_IP` is the IP address of our SFTP server. You will be prompted for `USERNAME`'s password. Once you successfully authenticate, you will be greeted with the sftp prompt.
