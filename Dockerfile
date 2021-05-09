# Copyright 2021 Nikolay Veld
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Build args: PIP_AUX_PKGS

FROM pytorch/pytorch:1.6.0-cuda10.1-cudnn7-runtime
MAINTAINER https://github.com/NickVeld
LABEL maintainer="https://github.com/NickVeld"

# In addition to the packages mentioned in the installation guide of the app
# (ffmpeg, libosmesa6-dev), the following packages are needed in fact.
#
# git and wget are needed only for downloading supplementary materials
# so you can remove them in case you have the materials and mount them by yourself.
#
# The link creation (ln -s) is needed because otherwise the used compliation flags -lGL and -lGLU do not work
RUN apt-get update \
   && apt-get install -y \
    build-essential \
    ffmpeg \
    libosmesa6-dev \
    libglu1-mesa \
    xvfb \
    git \
    wget \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/lib/x86_64-linux-gnu/libGL.so.1 /usr/lib/x86_64-linux-gnu/libGL.so \
  && ln -s /usr/lib/x86_64-linux-gnu/libGLU.so.1 /usr/lib/x86_64-linux-gnu/libGLU.so

# Official detecron2 installation
RUN python -m pip install detectron2 -f \
    https://dl.fbaipublicfiles.com/detectron2/wheels/cu101/torch1.6/index.html

# Python requirements installation
COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt \
  && rm /tmp/requirements.txt

# In order to install "pytorch3d" using "pip" set PIP_AUX_PKGS to "pytorch3d"
ARG PIP_AUX_PKGS=""
RUN [ -z "${PIP_AUX_PKGS}" ] || pip install ${PIP_AUX_PKGS}

COPY start.sh /start.sh

ENTRYPOINT ["/start.sh"]
CMD ["/bin/bash"]