#!/bin/bash
# /home/hargathor/dev/clarus-proxy/benchmarking/docker_install_requirements.sh
# Copyright (c) 2017 hargathor <3949704+hargathor@users.noreply.github.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# File              : /home/hargathor/dev/clarus-proxy/benchmarking/docker_install_requirements.sh
# Author            : hargathor <3949704+hargathor@users.noreply.github.com>
# Date              : 18.12.2017
# Last Modified Date: 18.12.2017
# Last Modified By  : hargathor <3949704+hargathor@users.noreply.github.com>
alias ll="ls -la --color=auto"
export PERL_MM_USE_DEFAULT=1
apt update && apt upgrade -- assume-yes && apt install --assume-yes python3 postgresql-client libcrypt-rijndael-perl libcrypt-cbc-perl gawk sysstat rrdtool gnuplot build-essential libssl-dev
cpan install Crypt::OpenSSL::AES 
cpan install Date::Calc
apt install --assume-yes curl && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && apt install --assume-yes git-lfs && git-lfs install && git-lfs pull
