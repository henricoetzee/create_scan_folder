# create_scan_folder
Script to create a scan folder and share it on the network.

WARNING

This program will make changes to your PC.
Please read through this text so that you understand what
this program changes so that you can undo the changes if anything goes wrong.

This program requires powershell to be installed on the PC.

This program comes with no warrenty.

These are the things that this program will do:

1. A new folder will be created on your pc.

2. A new user may be created on this pc.
   Please don't create a new username that already exists.

3. A new share will be created with the name "scans".
   The specified user will be given full access to this share.

4. The current connected network profile will be changed to Private.

5. "Network discovery" and "File and printer sharing" will be enabled for the Private network profile.
