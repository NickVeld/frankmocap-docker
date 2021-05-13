# Docker image for [FrankMocap](https://github.com/facebookresearch/frankmocap)

The page of the image on Dockerhub: https://hub.docker.com/r/nickveld/frankmocap-env

## Preparation

### Packages
In case the usage of this image
you can skip `conda` setup, installing packages using `apt-get`, `conda` and `pip`
listed in the installation guide from the repository of `frankmocap`.

### Optional: Building

There is no need to rebuild image but in case of rebuilding
you need to place `requirements.txt` from the `docs` directory of the repository of `frankmocap` next to the Dockerfile

Also, you can download supplementary files (the details below) into the image using the following command:
```
ARG INSTALLATION_PATH="TYPE THE PATH HERE"

WORKDIR ${INSTALLATION_PATH}
COPY scripts scripts
# `find | xargs sed` line is aimed to reduce the number of `wget` progress updates
# because each update causes new line in the `docker build` output
RUN find scripts -name '*.sh' -type f | xargs sed -i 's/wget/wget --progress=dot:giga /g' \
  && sh scripts/install_frankmocap.sh \
  && rm -r scripts
```

### Optional: Building `freegult`

If you want to build `freegult` you can you the following lines as a starter for Dockerfile:
```
RUN apt-get update \
  && apt-get install -y cmake unzip libx11-dev libxi-dev \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp
RUN wget https://sourceforge.net/code-snapshots/svn/f/fr/freeglut/code/freeglut-code-r1865-tags-FG_3_2_1.zip \
  && unzip freeglut-code-r*-tags-FG_*.zip \
  && cd freeglut-code-r*-tags-FG_* \
  && cmake . \
  && make \
  && cd .. \
  && rm -r freeglut-code-r*-tags-FG_*
```

For other versions:
1. See https://sourceforge.net/p/freeglut/code/HEAD/tree/tags/
2. Select the version and enter into its folder
3. Click on "Download Snapshot"
4. Cancel the downloading and copy the direct link
5. Replace the URL argument of `wget` with the obtained link

Although, I am not successed with the building because
```
/tmp/freeglut-code-r1865-tags-FG_3_2_1/include/GL/freeglut_std.h:144:13: fatal error: GL/glu.h: No such file or directory
    include <GL/glu.h>
            ^~~~~~~~~~
```

I assume that somewhere in the files for CMake `libGL` library linking is missing.

### Optional: `pytorch3d`
If you need the prebuilt image with `pytorch3d`
replace `nickveld/frankmocap-env` (the image name) with `nickveld/frankmocap-env:pytorch3d`.
In case building add the build argument `PIP_AUX_PKGS=pytorch3d`. (Example: `docker build --build-arg PIP_AUX_PKGS=pytorch3d`)

### Supplementary files and packages from `git`

The installation scripts from the repository of `frankmocap` is not good for the usage with the docker environments.
Thus I have slightly modificated them, see this
[pull request](https://github.com/facebookresearch/frankmocap/pull/108)
or [this branch](https://github.com/NickVeld/frankmocap/tree/download-and-setup-apart).
The docker image and this instruction assume that you have the same content of the `scripts` directory.

After you cloned the repository of `frankmocap` and applied the changes to the files inside the `scripts` directory,
change your working directory to the root of the repository (the directory with `scripts`, `LICENSE`, ...).
You can run `sh scripts/install_frankmocap.sh` either in the host system
or in the docker container (see the "Usage" section).

### SMPL/SMPLX models

Follow the minisection "Setting SMPL/SMPL-X Models"
in [the original installation guide](https://github.com/facebookresearch/frankmocap/blob/master/docs/INSTALL.md).

### Filesystem tree validation

After running `sh scripts/install_frankmocap.sh` and downloading the SMPL/SMPLX models compare your filesystem tree under the root of the repository with the tree in the section "Folder hierarchy"
in [the original installation guide](https://github.com/facebookresearch/frankmocap/blob/master/docs/INSTALL.md#folder-hierarchy).
In Unix-like systems (including the system inside the docker container) the `tree` command can assist you.

## Usage

Basic run command is simple (assuming that your working directory
is the root of the repository (the directory with `scripts`, `LICENSE`, ...):

`docker run -it --rm -v $(pwd):/opt/app -w /opt/app nickveld/frankmocap-env`

Note that the path after `-v $(pwd):` and the path after `-w` are the same, and **it is important**!

If you have not run `sh scripts/install_frankmocap.sh` but intend to do it in the docker,
see the subsection "Troubleshooting" below in order to get details regarding it.

### Running without a display

If you want to run a demo from `frankmocap` you need most likely to use `xvfb-run`
that allows to run the demo without a display.
But `exec xvfb-run` does not work properly somewhy
(`exec "$@"` is a traditional way to execute the provided docker command).
For example, we need to run the following command: `python -m demo.demofrankmocap YOUR_ARGS`.
One way is the folowing one:
```
user@host_system:/path/to/frankmocap$ docker run -it --rm -v $(pwd):/opt/app -w /opt/app nickveld/frankmocap-env
root@docker_container:/opt/app$ xvfb-run -a python -m demo.demofrankmocap YOUR_ARGS
```

But also a one line way is implemented (using the special environment variable `USE_XVFB` set with `-e USE_XVFB=1`):
```
user@host_system:/path/to/frankmocap$ docker run -it --rm -v $(pwd):/opt/app -w /opt/app -e USE_XVFB=1 nickveld/frankmocap-env python -m demo.demofrankmocap YOUR_ARGS
```

The image is based on `pytorch/pytorch:1.6.0-cuda10.1-cudnn7-runtime`
which, in turn, is based on `nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04` .
Thus, refer to their documentation in order to enable GPU in the container and learn other advanced options. 

### Troubleshooting

* After the run I see "The setup routine is needed, but the setup script is not located..."
  * Check that the path between `-v` and `:` points to the repository root (`$(pwd)` means "the current directory")
  * Check that the path after `-v $(pwd):` and the path after `-w` are the same
* After the run I see "python: can't open file 'setup.py': \[Errno 2\] No such file or directory"
  * If you have not run `sh scripts/install_frankmocap.sh` you must run it just after you see the error message.
    (Or run it on the host system as described in the subsection "Supplementary files and packages from `git`")
  * Check the filesystem tree as described in the subsection "Filesystem tree validation"
* After a demo from `frankmocap` execution finishes I see `Segmentation fault` and get exit code 139
  * I do not know how to fix it. I only have figured out that there is a problem with `opengl` renderer (or its compatibility with `xvfb-run`). You can just switch to another renderer and the message disappears.
