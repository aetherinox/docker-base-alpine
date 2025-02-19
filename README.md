<div align="center">
<h6>Docker Image using alpine and s6-overlay</h6>
<h1>💿 Alpine - Base Image 💿</h1>

<br />

This branch `docker/base-alpine` contains the base docker alpine image which is utilized as a base for creating other images such as [TheTvApp](https://git.binaryninja.net/pub_projects/tvapp2). This alpine image is what you will derive your app's Dockerfile from.

 Normal users should not need to modify the files in this repository.
 
</p>

<br />

<img src="https://upload.wikimedia.org/wikipedia/commons/e/e6/Alpine_Linux.svg" width="300">

<br />
<br />

</div>

<br />

---

<br />

- [About](#about)
- [Before Building](#before-building)
  - [LF over CRLF](#lf-over-crlf)
  - [Set `+x / 0755` Permissions](#set-x--0755-permissions)
- [Build `docker/alpine-base` Image](#build-dockeralpine-base-image)
  - [amd64](#amd64)
  - [arm64 / aarch64](#arm64--aarch64)
- [Build `TvApp` Image](#build-tvapp-image)
  - [amd64](#amd64-1)
  - [arm64 / aarch64](#arm64--aarch64-1)
  - [hub.docker.com / ghcr.io / local](#hubdockercom--ghcrio--local)
  - [Image Tags](#image-tags)
- [Using TvApp Image](#using-tvapp-image)
  - [docker run](#docker-run)
  - [docker-compose.yml](#docker-composeyml)
- [Extra Notes](#extra-notes)
  - [Custom Scripts](#custom-scripts)
  - [SSL Certificates](#ssl-certificates)
  - [Access Shell / Bash](#access-shell--bash)
  - [Logs](#logs)



<br />

---

<br />

## About
The files contained within this branch `docker/alpine-base` are utilized as a foundation. This base image only provides us with a docker image which has alpine linux, Nginx, a few critical packages, and the **[s6-overlay](https://github.com/just-containers/s6-overlay)** plugin.

This branch `docker/alpine-base` does **NOT** contain any applications. For our example, we will use the application **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)**.

<br />

To build a docker image using this base and the actual app you want to release (TheTVApp), you need two different docker images:
- **Step 1**: Build **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image **(this repo)**
  - When being build, the alpine-base `Dockerfile` will grab and install the files from the branch **[docker/core](https://github.com/Aetherinox/docker-base-alpine/tree/docker/core)**
- **Step 2**: Build **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** image
- **Step 3**: Release the docker image built from **Step 2** to Github's **Ghcr.io** or **hub.docker.com**

<br />

> [!WARNING]
> You should NOT need to modify any of the files within this branch `docker/alpine-base` unless you absolutely know what you are doing.

<br />

When you build this **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image, the `Dockerfile` and `Dockerfile.aarch64` files will request files from another branch we host, which is the **[docker/core](https://github.com/Aetherinox/docker-base-alpine/tree/docker/core)** branch.

```bash
ADD --chmod=755 "https://raw.githubusercontent.com/Aetherinox/docker-base-alpine/docker/core/docker-images.${MODS_VERSION}" "/docker-images"
ADD --chmod=755 "https://raw.githubusercontent.com/Aetherinox/docker-base-alpine/docker/core/package-install.${PKG_INST_VERSION}" "/etc/s6-overlay/s6-rc.d/init-mods-package-install/run"
ADD --chmod=755 "https://raw.githubusercontent.com/Aetherinox/docker-base-alpine/docker/core/aetherxown.${AETHERXOWN_VERSION}" "/usr/bin/aetherxown"
```

<br />

`aetherxown` is vital and must be included in the base image you build. It is what controls the **USER : GROUP** permissions that will be handled within your docker image. 

For this reason, there are a few requirements you can read about below in the section **[Before Building](#before-building)**.

<br />

---

<br >

## Before Building

Prior to building the ****[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)**** and **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** docker images, you **must** ensure the following conditions are met. If the below tasks are not performed, your docker container will throw the following errors when started:

- `Failed to open apk database: Permission denied`
- `s6-rc: warning: unable to start service init-adduser: command exited 127`
- `unable to exec /etc/s6-overlay/s6-rc.d/init-envfile/run: Permission denied`
- `/etc/s6-overlay/s6-rc.d/init-adduser/run: line 34: aetherxown: command not found`
- `/etc/s6-overlay/s6-rc.d/init-adduser/run: /usr/bin/aetherxown: cannot execute: required file not found`

<br />

### LF over CRLF

You cannot utilize Windows' `Carriage Return Line Feed`. All files must be converted to Unix' `Line Feed`.  This can be done with **[Visual Studio Code](https://code.visualstudio.com/)**. OR; you can run the Linux terminal command `dos2unix` to convert these files.

For the branches **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** and **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)**, you can use the following recursive commands:

<br />

> [!CAUTION]
> Be careful using the command to change **ALL** files. You should **NOT** change the files in your `.git` folder, otherwise you will corrupt your git indexes.
>
> If you accidentally run dos2unix on your `.git` folder, do NOT push anything to git. Pull a new copy from the repo.

<br />

```shell
# Change ALL files
find ./ -type f | grep -Ev '.git|*.jpg|*.jpeg|*.png' | xargs dos2unix --

# Change run / binaries
find ./ -type f -name 'run' | xargs dos2unix --
```

<br />

For the branch **[docker/core](https://github.com/Aetherinox/docker-base-alpine/tree/docker/core)**, you can use the following commands:

```shell
dos2unix docker-images.v3
dos2unix aetherxown.v1
dos2unix package-install.v1
dos2unix with-contenv.v1
```

<br />

### Set `+x / 0755` Permissions
The files contained within this repo **MUST** have `chmod 755` /  `+x` executable permissions. If you are using our Github workflow sample **[deploy-docker-github.yml](https://github.com/Aetherinox/docker-base-alpine/blob/workflows/samples/deploy-docker-github.yml)**, this is done automatically. If you are building the images manually; you need to do this. Ensure those files have the correct permissions prior to building the Alpine base docker image.

If you are building the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** or **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** images, you must ensure the files in those branches have the proper permissions. All of the executable files are named `run`:

```shell
find ./ -name 'run' -exec chmod +x {} \;
```

<br />

If you want to set the permissions manually, run the following:

```shell
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-adduser/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-crontab-config/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-custom-files/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-envfile/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-folders/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-keygen/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-migrations/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-nginx/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-permissions/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-php/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-samples/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/init-version-checks/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/svc-cron/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/svc-nginx/run
sudo chmod +x /root/etc/s6-overlay/s6-rc.d/svc-php-fpm/run
```

<br />

For the branch **[docker/core](https://github.com/Aetherinox/docker-base-alpine/tree/docker/core)**, there are a few files to change. The ending version number may change, but the commands to change the permissions are as follows:

```shell
sudo chmod +x docker-images.v3
sudo chmod +x aetherxown.v1
sudo chmod +x package-install.v1
sudo chmod +x with-contenv.v1
```

<br />

---

<br />

## Build `docker/alpine-base` Image

In order to use the files in this repo `docker/alpine-base`, clone the branch:

```shell
git clone -b docker/alpine-base https://github.com/Aetherinox/docker-base-alpine.git .
```

<br />

Once cloned, you can now make whatever adjustments you deem fit. Once your edits are done, you will need to build the base image:

### amd64

```shell ignore
# Build alpine-base amd64
docker build --build-arg VERSION=3.20 --build-arg BUILD_DATE=20250218 -t alpine-base:latest -t alpine-base:3.20-amd64 -f Dockerfile .
```

<br />

### arm64 / aarch64

```shell
# Build alpine-base arm64
docker build --build-arg VERSION=3.20 --build-arg BUILD_DATE=20250218 -t alpine-base:3.20-arm64 -f Dockerfile.aarch64 .
```

<br />

The flow of the process is outlined below:

```mermaid
%%{init: { 'themeVariables': { 'fontSize': '10px' }}}%%
flowchart TB

subgraph GRAPH_TVAPP ["Build thetvapp:latest"]
    direction TB
    obj_step10["`&gt; git clone https://git.binaryninja.net/pub_projects/tvapp2.git`"]
    obj_step11["`**Dockerfile
     Dockerfile.aarch64**`"]
    obj_step12["`&gt; docker build &bsol;
    --build-arg VERSION=1.0.0 &bsol;
    --build-arg BUILD_DATE=20250218 &bsol;
    -t tvapp:latest &bsol;
    -t tvapp:1.0.0-amd64 &bsol;
    -f Dockerfile . &bsol;`"]
    obj_step13["`Download **alpine-base** from branch **docker/alpine-base**`"]
    obj_step14["`New Image: **thetvapp:latest**`"]

    style obj_step10 text-align:center,stroke-width:1px,stroke:#555
    style obj_step11 text-align:left,stroke-width:1px,stroke:#555
    style obj_step12 text-align:left,stroke-width:1px,stroke:#555
    style obj_step13 text-align:left,stroke-width:1px,stroke:#555
end

style GRAPH_TVAPP text-align:center,stroke-width:1px,stroke:transparent,fill:transparent

subgraph GRAPH_ALPINE["Build alpine-base:latest Image"]
direction TB
    obj_step20["`&gt; git clone -b docker/alpine-base github.com/Aetherinox/docker-base-alpine.git`"]
    obj_step21["`**Dockerfile
     Dockerfile.aarch64**`"]
    obj_step22["`&gt; docker build &bsol;
    --build-arg VERSION=3.20 &bsol;
    --build-arg BUILD_DATE=20250218 &bsol;
    -t docker-alpine-base:latest &bsol;
    -t docker-alpine-base:3.20-amd64 &bsol;
    -f Dockerfile . &bsol;`"]
    obj_step23["`Download files from branch **docker/core**`"]
    obj_step24["`New Image: **alpine-base:latest**`"]

    style obj_step20 text-align:center,stroke-width:1px,stroke:#555
    style obj_step21 text-align:left,stroke-width:1px,stroke:#555
    style obj_step22 text-align:left,stroke-width:1px,stroke:#555
    style obj_step23 text-align:left,stroke-width:1px,stroke:#555
end

style GRAPH_ALPINE text-align:center,stroke-width:1px,stroke:transparent,fill:transparent

GRAPH_TVAPP --> obj_step10 --> obj_step11 --> obj_step12 --> obj_step13 --> obj_step14
GRAPH_ALPINE --> obj_step20 --> obj_step21 --> obj_step22 --> obj_step23 --> obj_step24
```

<br />

Once the base alpine image is built, you can now build the actual docker version of your app (such as [iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)).

<br />

---

<br />

## Build `TvApp` Image

After the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image is built, you can now use that docker image as a base to build the **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** image. Navigate to the repo and open the files:

- `Dockerfile`
- `Dockerfile.aarch64`

<br />

Next, specify the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image which will be used as the foundation of the **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** image:

```dockerfile
FROM ghcr.io/Aetherinox/alpine-base:3.20-amd64
```

After you have completed configuring the **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** `Dockerfile`, you can now build the image. Remember to build an image for both `amd64` and `aarch64`.

<br />

For the argument `VERSION`; specify the current release of your app ([iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)) which will be contained within the docker image. It should be in the format of `YYYYMMDD`:

<br />

### amd64

```shell
# Build tvapp amd64
docker build --build-arg VERSION=1.0.0 --build-arg BUILD_DATE=20250218 -t thetvapp:latest -t thetvapp:1.0.0 -t thetvapp:1.0.0-amd64 -f Dockerfile .
```

<br />

### arm64 / aarch64

```shell
# Build tvapp arm64
docker build --build-arg VERSION=1.0.0 --build-arg BUILD_DATE=20250218 -t thetvapp:1.0.0-arm64 -f Dockerfile.aarch64 .
```

<br />

### hub.docker.com / ghcr.io / local
After you have your **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** image built, you can either upload the image to a public repository such as:

- hub.docker.com (Docker Hub)
- ghcr.io (Github)

After it is uploaded, you can use the `docker run` command, or create a `docker-compose.yml`, and call the docker image to be used. 

This is discussed in the section **[Using TvApp Image](#using-tvapp-image)** below.

<br />

### Image Tags
When building your images with the commands provided above, ensure you create two sets of tags:

| Architecture | Dockerfile | Tags |
| --- | --- | --- |
| `amd64` | `Dockerfile` | `thetvapp:latest` <br /> `thetvapp:1.0.0` <br /> `thetvapp:1.0.0-amd64` |
| `arm64` | `Dockerfile.aarch64` | `thetvapp:1.0.0-arm64` |

<br />

the `amd64` arch gets a few extra tags because it should be the default image people clone. 

<br />

---

<br />

## Using TvApp Image

To use the new **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** image, you can either call it with the `docker run` command, or create a new `docker-compose.yml` and specify the image:

<br />

### docker run

If you want to use your new program docker image in the `docker run` command, execute the following:

```shell
docker run -d --restart=unless-stopped -p 443:443 --name tvapp -v ${PWD}/tvapp:/config ghcr.io/iflip721/tvapp:latest
```

<br />

### docker-compose.yml

If you'd much rather use a `docker-compose.yml` file and call your application image that way, create a new folder somewhere:

```shell
mkdir -p /home/docker/tvapp
```

Then create a new `docker-compose.yml` file and add the following:

```shell
sudo nano /home/docker/tvapp/docker-compose.yml
```

```yml
services:
    tvapp:
        container_name: tvapp
        image: ghcr.io/iflip721/tvapp:latest        # Github image
      # image: iflip721/tvapp:latest                # Dockerhub image
        restart: unless-stopped
        volumes:
            - ./tvapp:/config
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=Etc/UTC
```

<br />

Once the `docker-compose.yml` is set up, you can now start your application container:

```shell
cd /home/docker/tvapp/
docker compose up -d
```

<br />

Your app (such as TvApp) should now be running as a container. You can access it by opening your browser and going to:

```shell
http://container-ip
https://container-ip
```

<br />

---

<br />

## Extra Notes

The following are other things to take into consideration when creating the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** and **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** images:

<br />

### Custom Scripts

The `docker/alpine-base` and `tvapp` images support the ability of adding custom scripts that will be ran when the container is started. To create / add a new custom script to the container, you need to create a new folder in the container source files `/root` folder

```shell
mkdir -p /root/custom-cont-init.d/
```

<br />

Within this new folder, add your custom script:

```shell
nano /root/custom-cont-init.d/my_customs_script
```

<br />

```bash
#!/bin/bash

echo "**** INSTALLING BASH ****"
apk add --no-cache bash
```

<br />

When you create the docker image, this new script will automatically be loaded. You can also do this via the `docker-compose.yml` file by mounting a new volume:

```yml
services:
    tvapp:
        volumes:
            - ./tvapp:/config
            - ./custom-scripts:/custom-cont-init.d:ro
```

<br />

> [!NOTE]
> if using compose, we recommend mounting them **read-only** (`:ro`) so that container processes cannot write to the location.

> [!WARNING]
> The folder `/root/custom-cont-init.d` **MUST** be owned by `root`. If this is not the case, this folder will be renamed and a new empty folder will be created. This is to prevent remote code execution by putting scripts in the aforesaid folder.

<br />

The **[iflip721/tvapp2](https://git.binaryninja.net/pub_projects/tvapp2)** image already contains a custom script called `/root/custom-cont-init.d/plugins`. Do **NOT** edit this script. It is what automatically downloads the official application plugins and adds them to the container.

<br />
<br />

### SSL Certificates

This docker image automatically generates an SSL certificate when the nginx server is brought online. 

<br />

You may opt to either use the generated self-signed certificate, or you can add your own. If you decide to use your own self-signed certificate, ensure you have mounted the `/config` volume in your `docker-compose.yml`:

```yml
services:
    tvapp:
        container_name: tvapp
        image: ghcr.io/iflip721/tvapp:latest        # Github image
      # image: iflip721/tvapp:latest                # Dockerhub image
        restart: unless-stopped
        volumes:
            - ./tvapp:/config
```

<br />

Then navigate to the newly mounted folder and add your `📄 cert.crt` and `🔑 cert.key` files to the `📁 /tvapp/keys/*` folder.

<br />

> [!NOTE]
> If you are generating your own certificate and key, we recommend a minimum of:
> - RSA: `2048 bits`
> - ECC: `256 bits`
> - ECDSA: `P-384 or P-521`

<br />
<br />

### Access Shell / Bash
You can access the docker container's shell by running:

```shell
docker exec -it tvapp ash
```

<br />
<br />

### Logs

This image spits out detailed information about its current progress. You can either use `docker logs` or a 3rd party app such as [Portainer](https://portainer.io/) to view the logs.

<br />

```shell
 Migrations   : Started
 Migrations   : 01-nginx-site-confs-default › Skipped
 Migrations   : Complete
──────────────────────────────────────────────────────────────────────────────────────────
                               Alpine by Aetherinox                               
──────────────────────────────────────────────────────────────────────────────────────────
  Get started with some of the links below:

        Official Repo           https://github.com/Aetherinox/docker-base-alpine

  If you are making this container available on a public-facing domain,
  please consider using Traefik and Authentik to protect this container from
  outside access.

        User:Group              1000:1000
        (Ports) HTTP/HTTPS      80/443
──────────────────────────────────────────────────────────────────────────────────────────

 SSL          : Using existing keys found in /config/keys
 Loader       : Custom files found, loading them ...
 Loader       : Executing ...
 Loader       : Checking tvapp-plugins
 Loader       : tvapp-plugins already installed in /config/www/plugins; skipping
 Loader       : plugins: Exited 0
 Core         : Completed loading container
```

<br />

---

<br />

<!-- BADGE > GENERAL -->
  [general-npmjs-uri]: https://npmjs.com
  [general-nodejs-uri]: https://nodejs.org
  [general-npmtrends-uri]: http://npmtrends.com/Aetherinox

<!-- BADGE > VERSION > GITHUB -->
  [github-version-img]: https://img.shields.io/github/v/tag/Aetherinox/docker-base-alpine?logo=GitHub&label=Version&color=ba5225
  [github-version-uri]: https://github.com/Aetherinox/docker-base-alpine/releases

<!-- BADGE > VERSION > GITHUB (For the Badge) -->
  [github-version-ftb-img]: https://img.shields.io/github/v/tag/Aetherinox/docker-base-alpine?style=for-the-badge&logo=github&logoColor=FFFFFF&logoSize=34&label=%20&color=ba5225
  [github-version-ftb-uri]: https://github.com/Aetherinox/docker-base-alpine/releases

<!-- BADGE > VERSION > NPMJS -->
  [npm-version-img]: https://img.shields.io/npm/v/Aetherinox?logo=npm&label=Version&color=ba5225
  [npm-version-uri]: https://npmjs.com/package/Aetherinox

<!-- BADGE > VERSION > PYPI -->
  [pypi-version-img]: https://img.shields.io/pypi/v/Aetherinox
  [pypi-version-uri]: https://pypi.org/project/Aetherinox/

<!-- BADGE > LICENSE > MIT -->
  [license-mit-img]: https://img.shields.io/badge/MIT-FFF?logo=creativecommons&logoColor=FFFFFF&label=License&color=9d29a0
  [license-mit-uri]: https://github.com/Aetherinox/docker-base-alpine/blob/main/LICENSE

<!-- BADGE > GITHUB > DOWNLOAD COUNT -->
  [github-downloads-img]: https://img.shields.io/github/downloads/Aetherinox/docker-base-alpine/total?logo=github&logoColor=FFFFFF&label=Downloads&color=376892
  [github-downloads-uri]: https://github.com/Aetherinox/docker-base-alpine/releases

<!-- BADGE > NPMJS > DOWNLOAD COUNT -->
  [npmjs-downloads-img]: https://img.shields.io/npm/dw/%40Aetherinox%2Fdocker-base-alpine?logo=npm&&label=Downloads&color=376892
  [npmjs-downloads-uri]: https://npmjs.com/package/Aetherinox

<!-- BADGE > GITHUB > DOWNLOAD SIZE -->
  [github-size-img]: https://img.shields.io/github/repo-size/Aetherinox/docker-base-alpine?logo=github&label=Size&color=59702a
  [github-size-uri]: https://github.com/Aetherinox/docker-base-alpine/releases

<!-- BADGE > NPMJS > DOWNLOAD SIZE -->
  [npmjs-size-img]: https://img.shields.io/npm/unpacked-size/Aetherinox/latest?logo=npm&label=Size&color=59702a
  [npmjs-size-uri]: https://npmjs.com/package/Aetherinox

<!-- BADGE > CODECOV > COVERAGE -->
  [codecov-coverage-img]: https://img.shields.io/codecov/c/github/Aetherinox/docker-base-alpine?token=MPAVASGIOG&logo=codecov&logoColor=FFFFFF&label=Coverage&color=354b9e
  [codecov-coverage-uri]: https://codecov.io/github/Aetherinox/docker-base-alpine

<!-- BADGE > ALL CONTRIBUTORS -->
  [contribs-all-img]: https://img.shields.io/github/all-contributors/Aetherinox/docker-base-alpine?logo=contributorcovenant&color=de1f6f&label=contributors
  [contribs-all-uri]: https://github.com/all-contributors/all-contributors

<!-- BADGE > GITHUB > BUILD > NPM -->
  [github-build-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/docker-base-alpine/deploy-docker.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-uri]: https://github.com/Aetherinox/docker-base-alpine/actions/workflows/deploy-docker.yml

<!-- BADGE > GITHUB > BUILD > Pypi -->
  [github-build-pypi-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/docker-base-alpine/release-pypi.yml?logo=github&logoColor=FFFFFF&label=Build&color=%23278b30
  [github-build-pypi-uri]: https://github.com/Aetherinox/docker-base-alpine/actions/workflows/pypi-release.yml

<!-- BADGE > GITHUB > TESTS -->
  [github-tests-img]: https://img.shields.io/github/actions/workflow/status/Aetherinox/docker-base-alpine/npm-tests.yml?logo=github&label=Tests&color=2c6488
  [github-tests-uri]: https://github.com/Aetherinox/docker-base-alpine/actions/workflows/npm-tests.yml

<!-- BADGE > GITHUB > COMMIT -->
  [github-commit-img]: https://img.shields.io/github/last-commit/Aetherinox/docker-base-alpine?logo=conventionalcommits&logoColor=FFFFFF&label=Last%20Commit&color=313131
  [github-commit-uri]: https://github.com/Aetherinox/docker-base-alpine/commits/main/

<!-- BADGE > DOCKER HUB > VERSION -->
  [dockerhub-version-img]: https://img.shields.io/docker/v/Aetherinox/docker-base-alpine/latest?logo=docker&logoColor=FFFFFF&label=Docker%20Version&color=ba5225
  [dockerhub-version-uri]: https://hub.docker.com/repository/docker/Aetherinox/docker-base-alpine/general
