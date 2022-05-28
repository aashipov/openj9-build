### Eclipse OpenJ9 JDK from source ###

#### Host requirements ####

x86_64 Linux with docker, user with UID 10001, a member of GID 10001 and docker groups, enough disk space in ```${HOME}``` to store openJDK source and build files

[Windows host](win.txt)

#### How-to ####

##### Linux #####

Build OpenJ9 version 17 in Debian 9 container ```bash builder.bash debian 17```

##### Windows #####

In cygwin terminal run ```bash entrypoint8.bash```, ```bash entrypoint9plus.bash 11``` or ```bash entrypoint9plus.bash 17```

#### Troubleshooting ####

#### License ####

Perl "Artistic License"
