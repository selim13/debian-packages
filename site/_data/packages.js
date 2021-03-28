const fetch = require('node-fetch');
const semver = require('semver');

function sortNames(a, b) {
  var nameA = a.name.toUpperCase();
  var nameB = b.name.toUpperCase();
  if (nameA < nameB) {
    return -1;
  }
  if (nameA > nameB) {
    return 1;
  }

  return 0;
}

async function packages() {
  const api = 'http://localhost:8081/api/repos/deb-cli/packages?format=details';
  const res = await fetch(api);
  const body = await res.text();
  const repoRaw = JSON.parse(body);

  // sort packages by their version, newest go first
  repo = repoRaw
    .sort((a, b) => semver.compareBuild(a.Version, b.Version, true))
    .reverse();

  let packages = {};
  repo.forEach((repoPackage) => {
    console.log(repoPackage.Version);
    if (!(repoPackage.Package in packages)) {
      const package = {
        name: repoPackage.Package,
        version: repoPackage.Version,
        description: (repoPackage.Description || '').trim(),
        archs: [repoPackage.Architecture],
        homepage: repoPackage.Homepage || '',
      };

      packages[package.name] = package;
    } else {
      // get other architectures but only for current version
      const package = packages[repoPackage.Package];
      if (!semver.lt(repoPackage.Version, package.version)) {
        if (!package.archs.includes(repoPackage.Architecture)) {
          package.archs.push(repoPackage.Architecture);
        }
      }
    }
  });

  return Object.values(packages).sort(sortNames);
}

module.exports = packages;
