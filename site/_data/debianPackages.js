const { readFile } = require('fs/promises');
const { createReadStream } = require('fs');
const { parse, ParagraphStream } = require('debian-control');

async function readRelease(repoPath, distr) {
  const releasePath = `${repoPath}/dists/${distr}/Release`;

  const releaseBuf = await readFile(releasePath);
  const releaseData = await releaseBuf.toString('utf8');
  return parse(releaseData);
}

function repoToSitePackage(repoPackage) {
  let description = repoPackage.Description || '';
  if (typeof description === 'object') {
    description = description.join('<br>\n');
  }

  return {
    name: repoPackage.Package,
    version: repoPackage.Version,
    description: description.trim(),
    archs: [
      {
        name: repoPackage.Architecture,
        file: repoPackage.Filename,
      },
    ],
    homepage: repoPackage.Homepage || '',
  };
}

function readArchPackages(repoPath, distr, component, arch, packages = {}) {
  packages = { ...packages };
  const packagesPath = `${repoPath}/dists/${distr}/${component}/binary-${arch}/Packages`;

  return new Promise((accept, reject) => {
    const readStream = createReadStream(packagesPath);
    const paragraphStream = new ParagraphStream(packagesPath);
    readStream.pipe(paragraphStream);
    paragraphStream.on('data', (line) => {
      const repoPackage = parse(line.toString('utf8'));

      if (!(repoPackage.Package in packages)) {
        packages[repoPackage.Package] = repoToSitePackage(repoPackage);
        return;
      }

      const package = packages[repoPackage.Package];
      if (repoPackage.Version === package.version) {
        const archExists = package.archs.some(
          (arch) => arch.name === repoPackage.Architecture
        );
        if (archExists) return;

        package.archs = [
          ...package.archs,
          {
            name: repoPackage.Architecture,
            file: repoPackage.Filename,
          },
        ];

        return;
      }
    });

    paragraphStream.on('end', () => {
      console.log('finish', packagesPath);
      accept(packages);
    });
  });
}

async function debianPackages() {
  const repoPath = process.env.REPO_PATH;
  const distr = process.env.REPO_CODENAME;

  if (!repoPath || !distr) {
    throw new Error(
      'REPO_PATH or REPO_CODENAME environment variables are not set'
    );
  }

  const release = await readRelease(repoPath, distr);
  const components = release.Components.split(' ');
  const archs = release.Architectures.split(' ');

  let packages = {};
  for (component of components) {
    for (arch of archs) {
      packages = await readArchPackages(
        repoPath,
        distr,
        component,
        arch,
        packages
      );
    }
  }

  let arr = Object.values(packages);
  arr.sort((a, b) => {
    const nameA = a.name.toUpperCase();
    const nameB = b.name.toUpperCase();

    return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
  });

  return arr;
}

module.exports = debianPackages;
