<div align="center">
<h6>Docker Image using alpine and s6-overlay</h6>
<h1>💿 Alpine - Base Image 💿</h1>

<br />

This branch `docker/base-alpine` contains the base docker alpine image which is utilized as a base for creating other images such as **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)**. This alpine image is what you will derive your app's Dockerfile from.

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
  - [Using docker buildx](#using-docker-buildx)
    - [Save Local Image](#save-local-image)
    - [Upload to Registry](#upload-to-registry)
  - [Upload to hub.docker.com / ghcr.io / local](#upload-to-hubdockercom--ghcrio--local)
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

This branch `docker/alpine-base` does **NOT** contain any applications. For our example, we will use the application **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)**.

<br />

To build a docker image using this base and the actual app you want to release (TVApp2), you need two different docker images:
- **Step 1**: Build **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image **(this repo)**
  - When being build, the alpine-base `Dockerfile` will grab and install the files from the branch **[docker/core](https://github.com/Aetherinox/docker-base-alpine/tree/docker/core)**
- **Step 2**: Build **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** image
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

Prior to building the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** and **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** docker images, you **must** ensure the following conditions are met. If the below tasks are not performed, your docker container will throw the following errors when started:

- `Failed to open apk database: Permission denied`
- `s6-rc: warning: unable to start service init-adduser: command exited 127`
- `unable to exec /etc/s6-overlay/s6-rc.d/init-envfile/run: Permission denied`
- `/etc/s6-overlay/s6-rc.d/init-adduser/run: line 34: aetherxown: command not found`
- `/etc/s6-overlay/s6-rc.d/init-adduser/run: /usr/bin/aetherxown: cannot execute: required file not found`

<br />

### LF over CRLF

You cannot utilize Windows' `Carriage Return Line Feed`. All files must be converted to Unix' `Line Feed`.  This can be done with **[Visual Studio Code](https://code.visualstudio.com/)**. OR; you can run the Linux terminal command `dos2unix` to convert these files.

For the branches **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** and **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)**, you can use the following recursive commands:

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

If you are building the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** or **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** images, you must ensure the files in those branches have the proper permissions. All of the executable files are named `run`:

```shell
find ./ -name 'run' -exec chmod +x {} \;
```

<br />

If you want to set the permissions manually, run the following:

```shell
sudo chmod +x ./root/etc/s6-overlay/s6-rc.d/init-adduser/run \
  ./root/etc/s6-overlay/s6-rc.d/init-crontab-config/run \
  ./root/etc/s6-overlay/s6-rc.d/init-custom-files/run \
  ./root/etc/s6-overlay/s6-rc.d/init-envfile/run \
  ./root/etc/s6-overlay/s6-rc.d/init-folders/run \
  ./root/etc/s6-overlay/s6-rc.d/init-keygen/run \
  ./root/etc/s6-overlay/s6-rc.d/init-migrations/run \
  ./root/etc/s6-overlay/s6-rc.d/init-permissions/run \
  ./root/etc/s6-overlay/s6-rc.d/init-samples/run \
  ./root/etc/s6-overlay/s6-rc.d/init-version-checks/run \
  ./root/etc/s6-overlay/s6-rc.d/svc-cron/run \
  ./root/etc/s6-overlay/s6-rc.d/svc-php-fpm/run \
  ./root/etc/s6-overlay/s6-rc.d/svc-nginx/run \
  ./root/etc/s6-overlay/s6-rc.d/init-php/run \
  ./root/etc/s6-overlay/s6-rc.d/init-nginx/run
```

<br />

For the branch **[docker/core](https://github.com/Aetherinox/docker-base-alpine/tree/docker/core)**, there are a few files to change. The ending version number may change, but the commands to change the permissions are as follows:

```shell
sudo chmod +x docker-images.v3 \
  chmod +x aetherxown.v1 \
  chmod +x package-install.v1 \
  chmod +x with-contenv.v1
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

Once cloned, you can now make whatever adjustments you deem fit. Once your edits are done, you will need to build the base image. If you built the image locally, make sure you remove the line `--pull` from the commands below:

### amd64

```shell
# alpine-base - amd64: using docker buildx
docker buildx build \
  --build-arg ARCH=x86_64 \
  --build-arg VERSION=3.21 \
  --build-arg BUILDDATE=20250226 \
  --tag aetherinox/alpine-base:latest \
  --tag aetherinox/alpine-base:3.21-amd64 \
  --tag aetherinox/alpine-base:3.2 \
  --tag aetherinox/alpine-base:3 \
  --file Dockerfile \
  --platform linux/amd64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --output type=docker \
  --no-cache \
  --pull \
  .

# alpine-base - amd64: using docker build
docker build \
  --network=host \
  --build-arg ARCH=x86_64 \
  --build-arg VERSION=3.21 \
  --build-arg BUILDDATE=20250226 \
  --tag aetherinox/alpine-base:latest \
  --tag aetherinox/alpine-base:3.21-amd64 \
  --tag aetherinox/alpine-base:3.2 \
  --tag aetherinox/alpine-base:3 \
  --file Dockerfile \
  --platform linux/amd64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --builder default \
  --output type=docker \
  --no-cache \
  --pull \
  .
```

<br />

### arm64 / aarch64

```shell
# alpine-base - arm64: using docker buildx
docker buildx build \
  --build-arg ARCH=aarch64 \
  --build-arg VERSION=3.21 \
  --build-arg BUILDDATE=20250226 \
  --tag aetherinox/alpine-base:3.21-arm64 \
  --file Dockerfile \
  --platform linux/arm64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --output type=docker \
  --no-cache \
  --pull \
  .

# alpine-base - arm64: using docker build
docker build \
  --network=host \
  --build-arg ARCH=aarch64 \
  --build-arg VERSION=3.21 \
  --build-arg BUILDDATE=20250226 \
  --file Dockerfile \
  --platform linux/arm64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --tag aetherinox/alpine-base:3.21-arm64 \
  --builder default \
  --output type=docker \
  --no-cache \
  --pull \
  .
```

<br />

If you need to get the digest for both images so that you can merge the two into a single manifest and release, obtain the digests by using:

```shell
$ docker images --all --no-trunc | grep aetherinox

aetherinox/alpine-base       3.21-arm64       sha256:6bbe08af5b1dbe396168feec13d01ff99e2232ca29c783ef3cd6ff18e74529b2   22 seconds ago       38.8MB
aetherinox/alpine-base       3.21-amd64       sha256:fd9c44373af2915fe805ff93179ce56160cb90bd25830f764694dbc8c6341816   About a minute ago   27.2MB
```

<br />

To merge the manifest / images and push a single multi-platform release, run:

```shell
docker buildx imagetools create \
  -t aetherinox/alpine-base:3.21 \
  sha256:6bbe08af5b1dbe396168feec13d01ff99e2232ca29c783ef3cd6ff18e74529b2 \ 
  sha256:fd9c44373af2915fe805ff93179ce56160cb90bd25830f764694dbc8c6341816
```

<br />

<br />

The flow of the process is outlined below:

```mermaid
%%{init: { 'themeVariables': { 'fontSize': '10px' }}}%%
flowchart TB

subgraph GRAPH_TVAPP ["Build tvapp2:latest"]
    direction TB
    obj_step10["`&gt; git clone github.com/Aetherinox/tvapp2.git`"]
    obj_step11["`**Dockerfile
     Dockerfile.aarch64**`"]
    obj_step12["`&gt; docker build &bsol;
    --build-arg VERSION=1.0.0 &bsol;
    --build-arg BUILDDATE=20250220 &bsol;
    -t tvapp2:latest &bsol;
    -t tvapp2:1.0.0-amd64 &bsol;
    -f Dockerfile . &bsol;`"]
    obj_step13["`Download **alpine-base** from branch **docker/alpine-base**`"]
    obj_step14["`New Image: **tvapp2:latest**`"]

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
    --build-arg BUILDDATE=20250220 &bsol;
    -t docker-alpine-base:latest &bsol;
    -t docker-alpine-base:3.21-amd64 &bsol;
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

Once the base alpine image is built, you can now build the actual docker version of your app (such as **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)**.

<br />

---

<br />

## Build `TvApp` Image

After the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image is built, you can now use that docker image as a base to build the **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** image. Navigate to the repo and open the files:

- `Dockerfile`
- `Dockerfile.aarch64`

<br />

Next, specify the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** image which will be used as the foundation of the **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** image:

```dockerfile
FROM ghcr.io/Aetherinox/alpine-base:3.21-amd64
```

After you have completed configuring the **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** `Dockerfile`, you can now build the image. Remember to build an image for both `amd64` and `aarch64`.

<br />

For the argument `VERSION`; specify the current release of your app (**[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)**) which will be contained within the docker image. It should be in the format of `YYYYMMDD`:

<br />

### amd64

```shell
# tvapp2 - amd64: using docker buildx
docker buildx build \
  --build-arg ARCH=amd64 \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILDDATE=20250227 \
  --tag aetherinox/tvapp2:latest \
  --tag aetherinox/tvapp2:1.0.0-amd64 \
  --file Dockerfile \
  --platform linux/amd64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --output type=docker \
  --no-cache \
  --pull \
  .

# tvapp2 - amd64: using docker build
docker build \
  --network=host \
  --build-arg ARCH=amd64 \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILDDATE=20250227 \
  --file Dockerfile \
  --platform linux/amd64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --tag aetherinox/tvapp2:1.0.0-amd64 \
  --builder default \
  --output type=docker \
  --no-cache \
  --pull \
  .
```

<br />

### arm64 / aarch64

```shell
# tvapp2 - arm64: using docker buildx
docker buildx build \
  --build-arg ARCH=arm64 \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILDDATE=20250226 \
  --tag aetherinox/tvapp2:1.0.0-arm64 \
  --file Dockerfile \
  --platform linux/arm64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --output type=docker \
  --no-cache \
  --pull \
  .

# tvapp2 - arm64: using docker build
docker build \
  --network=host \
  --build-arg ARCH=arm64 \
  --build-arg VERSION=1.0.0 \
  --build-arg BUILDDATE=20250226 \
  --file Dockerfile \
  --platform linux/arm64 \
  --attest type=provenance,disabled=true \
  --attest type=sbom,disabled=true \
  --tag aetherinox/tvapp2:1.0.0-arm64 \
  --builder default \
  --output type=docker \
  --no-cache \
  --pull \
  .
```

<br />

### Using docker buildx
This section explains how to build your application's docker image using `docker buildx` instead of `docker build`. It is useful when generating your app's image for multiple platforms.

<br />

All of the needed Docker files already exist in the repository. To get started, clone the repo to a folder
```shell ignore
mkdir docker-alpine-base && cd docker-alpine-base
git clone https://github.com/Aetherinox/docker-base-alpine.git ./
```

<br />

Once the image files are downloaded, create a new container for **buildx**

```shell ignore
docker buildx create --driver docker-container --name container --bootstrap --use
```

<br />

**Optional**:  If you first need to remove the container because you created it previously, run the command:

```shell ignore
docker buildx rm container
```

<br />

Next, create your new docker image. Two different commands are provided below:
- Method to save docker image locally
- Push docker image to registry

<br />

#### Save Local Image
The command below will save a local copy of your application's docker image, which can be immediately used, or seen using `docker ps`

```shell
docker buildx build --no-cache --pull --build-arg VERSION=1.0.0 --build-arg BUILDDATE=02-18-25 -t tvapp2:latest -t tvapp2:1.0.0 --platform=linux/amd64 --output type=docker --output type=docker .
```

<br />

#### Upload to Registry
The command below will push your application's new docker image to a registry. Before you can push the image, ensure you are signed into Docker CLI. Open your Linux terminal and see if you are already signed in:

```shell ignore
docker info | grep Username
```

<br />

If nothing is printed; then you are not signed in. Initiate the web login:

```shell ignore
docker login
```

<br />

Some text will appear on-screen, copy the code, open your browser, and go to https://login.docker.com/activate

```console
USING WEB BASED LOGIN
To sign in with credentials on the command line, use 'docker login -u <username>'

Your one-time device confirmation code is: XXXX-XXXX
Press ENTER to open your browser or submit your device code here: https://login.docker.com/activate

Waiting for authentication in the browser…
```

<br />

Once you are finished in your browser, you can return to your Linux terminal, and it should bring you back to where you can type a command. You can now verify again if you are signed in:

```shell ignore
docker info | grep Username
```

You should see:

```console
 Username: YourUsername
```

<br />

Now you are ready to build your application's docker image, run the command:

```shell
docker buildx build --no-cache --pull --build-arg VERSION=1.0.0 --build-arg BUILDDATE=02-18-25 -t tvapp2:latest -t tvapp2:1.0.0 --platform=linux/amd64 --provenance=true --sbom=true --builder=container --push .
```

<br />

### Upload to hub.docker.com / ghcr.io / local
After you have your **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** image built, you can either upload the image to a public repository such as:

- hub.docker.com (Docker Hub)
- ghcr.io (Github)

After it is uploaded, you can use the `docker run` command, or create a `docker-compose.yml`, and call the docker image to be used.  This is discussed in the section **[Using TVApp2 Image](#using-tvapp-image)** below.

<br />

### Image Tags
When building your images with the commands provided above, ensure you create two sets of tags:

| Architecture | Dockerfile | Tags |
| --- | --- | --- |
| `amd64` | `Dockerfile` | `tvapp2:latest` <br /> `tvapp2:1.0.0` <br /> `tvapp2:1.0.0-amd64` |
| `arm64` | `Dockerfile.aarch64` | `tvapp2:1.0.0-arm64` |

<br />

the `amd64` arch gets a few extra tags because it should be the default image people clone. 

<br />

---

<br />

## Using TvApp Image

To use the new **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** image, you can either call it with the `docker run` command, or create a new `docker-compose.yml` and specify the image:

<br />

### docker run

If you want to use your new program docker image in the `docker run` command, execute the following:

```shell
docker run -d --restart=unless-stopped -p 4124:4124 --name tvapp2 -v ${PWD}/tvapp2:/config ghcr.io/aetherinox/tvapp2:latest
```

<br />

### docker-compose.yml

If you'd much rather use a `docker-compose.yml` file and call your application image that way, create a new folder somewhere:

```shell
mkdir -p /home/docker/tvapp2
```

Then create a new `docker-compose.yml` file and add the following:

```shell
sudo nano /home/docker/tvapp2/docker-compose.yml
```

```yml
services:
    tvapp2:
        container_name: tvapp2
        image: ghcr.io/Aetherinox/tvapp2:latest         # Github image hosted by Aetherinox
      # image: ghcr.io/iflip721/tvapp2:latest           # Github image hosted by iflip721
      # image: iflip721/tvapp2:latest                   # Dockerhub image
        restart: unless-stopped
        volumes:
            - ./tvapp2:/config
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=Etc/UTC
```

<br />

Once the `docker-compose.yml` is set up, you can now start your application container:

```shell
cd /home/docker/tvapp2/
docker compose up -d
```

<br />

Your app (such as TvApp) should now be running as a container. You can access it by opening your browser and going to:

```shell
http://container-ip:4124
https://container-ip:4124
```

<br />

---

<br />

## Extra Notes

The following are other things to take into consideration when creating the **[docker/alpine-base](https://github.com/Aetherinox/docker-base-alpine/tree/docker/alpine-base)** and **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** images:

<br />

### Custom Scripts

The `docker/alpine-base` and `TVApp2` images support the ability of adding custom scripts that will be ran when the container is started. To create / add a new custom script to the container, you need to create a new folder in the container source files `/root` folder

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
    tvapp2:
        volumes:
            - ./tvapp2:/config
            - ./custom-scripts:/custom-cont-init.d:ro
```

<br />

> [!NOTE]
> if using compose, we recommend mounting them **read-only** (`:ro`) so that container processes cannot write to the location.

> [!WARNING]
> The folder `/root/custom-cont-init.d` **MUST** be owned by `root`. If this is not the case, this folder will be renamed and a new empty folder will be created. This is to prevent remote code execution by putting scripts in the aforesaid folder.

<br />

The **[aetherinox/tvapp2](https://github.com/Aetherinox/tvapp2)** image already contains a custom script called `/root/custom-cont-init.d/plugins`. Do **NOT** edit this script. It is what automatically downloads the official application plugins and adds them to the container.

<br />
<br />

### SSL Certificates

This docker image automatically generates an SSL certificate when the nginx server is brought online. 

<br />

You may opt to either use the generated self-signed certificate, or you can add your own. If you decide to use your own self-signed certificate, ensure you have mounted the `/config` volume in your `docker-compose.yml`:

```yml
services:
    tvapp2:
        container_name: tvapp2
        image: ghcr.io/Aetherinox/tvapp2:latest         # Github image hosted by Aetherinox
      # image: ghcr.io/iflip721/tvapp2:latest           # Github image hosted by iflip721
      # image: iflip721/tvapp2:latest                   # Dockerhub image
        restart: unless-stopped
        volumes:
            - ./tvapp2:/config
```

<br />

Then navigate to the newly mounted folder and add your `📄 cert.crt` and `🔑 cert.key` files to the `📁 /tvapp2/keys/*` folder.

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
docker exec -it tvapp2 ash
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
 Loader       : Checking tvapp2-plugins
 Loader       : tvapp2-plugins already installed in /config/www/plugins; skipping
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
