# Debian CLI repository

Scripts for populating custom debian repository of various cool cli tools.

Those mostly do downloading releases from github repositories,
pack them to debian packages and push to the local reprepro
repository managing tool.

Tools required:
```
sudo apt install dpkg fakeroot jq tar unzip reprepro
```
* [Apty](https://www.aptly.info)