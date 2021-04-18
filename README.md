# Debian CLI repository

Scripts for populating custom debian repository of various cool cli tools.

Those mostly do downloading releases from github repositories,
pack them to debian packages and push to the local [Apty](https://www.aptly.info)
repository managing tool.

Tools required:
```
sudo apt install dpkg fakeroot jq tar unzip
```
* [Apty](https://www.aptly.info)