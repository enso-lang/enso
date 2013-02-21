EnsoSync

About
=====
EnsoSync is a file synchronization tool for multiple file systems that have network connectivity. A centralized host is responsible for keeping the master copy up-to-date.

Language
========
EnsoSync's structured domain description language is based on ??? (at some point we will base it on PADS).
It also uses a security language as well as a web UI language.

Tool
====
cd to /src directory in Enso

To run the host:
ruby -I . applications/EnsoSync/code/esynchost.rb <master dir>
where <master dir> is path of the master file directory in the host

To run the client:
ruby -I . applications/EnsoSync/code/esync.rb [-d] <user> <host address> <local dir>
where -d flag indicates daemon mode
      <user> is name to log in as
      <host address> indicates where the host is located (eg IP address)
      <local dir> is the directory to be synchronized

Sample
======
The sample can be run using the scripts from the /src directory:
1. test-setup.sh <dir>
    Copies sample files to a new directory called <dir>
2. test-host.sh <dir>
    Starts a host on <dir>/server, listening on port 20000
3. test-client.sh <dir>
    Starts a client on <dir>/client in daemon mode and attempt to connect to a server at 127.1.0.1:20000 as "Alice".
In the sample's authorization file, "Alice" is given full access while "Bob" is only allowed to modify but not create files and directories.

