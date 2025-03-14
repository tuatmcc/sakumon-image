FROM python:3.11.11-bookworm AS python_base
FROM pypy:bookworm

COPY --from=python_base /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python_base /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=python_base /usr/local/include/python3.11 /usr/local/include/python3.11
COPY --from=python_base /usr/local/lib/libpython3.11.so.1.0 /usr/local/lib/

RUN ldconfig
ENV PATH="/usr/local/bin:$PATH"

ENV LANG=C.UTF-8
ENV LANGUAGE=en_US:
ENV TZ=Asia/Tokyo

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 諸々のインストール
#
# C++ の環境を整える
# gmpy2 用に gmp, mpfr, mpc をインストールする
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN apt-get update -qq \
 && apt-get install -qq \
    zsh time tree git curl nano vim ca-certificates \
    nodejs npm rustc \
    libgmp-dev libmpfr-dev libmpc-dev \
 && apt-get install -qq software-properties-common python3-launchpadlib \
 && add-apt-repository ppa:ubuntu-toolchain-r/test \
 && apt-get update -qq \
 && apt-get install -qq gcc-12 g++-12 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100 \
 && update-alternatives --config gcc \
 && update-alternatives --config g++ \
 && rm -rf /var/lib/apt/lists/*

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Zsh をいい感じにする
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
COPY zshrc /root/.zshrc


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# プロンプトの見た目をいい感じにする
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes \
 && echo "eval \"\$(starship init zsh)\"" >> /root/.zshrc


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# シェルを zsh にする
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN chsh -s /bin/zsh


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# npm (textlint & Task)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN npm i -g textlint \
    textlint-rule-preset-ja-technical-writing \
    textlint-rule-preset-ja-spacing \
    textlint-filter-rule-comments \
    textlint-filter-rule-allowlist \
    @go-task/cli


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ac-library のインストール
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN git clone https://github.com/atcoder/ac-library.git /lib/ac-library
RUN git clone https://github.com/MikeMirzayanov/testlib /lib/testlib
ENV CPLUS_INCLUDE_PATH="/lib/ac-library:/lib/testlib:$CPLUS_INCLUDE_PATH"


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AtCoder の環境に存在するパッケージをインストールする
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WORKDIR /tmp
COPY requirements-cpython.txt /tmp/requirements-cpython.txt
RUN python3 -m pip install --no-cache-dir --upgrade pip \
&& python3 -m pip install --no-cache-dir -r requirements-cpython.txt

RUN apt-get update -qq \
 && apt-get install -qq gfortran libopenblas-dev liblapack-dev pkg-config libgeos-dev

COPY requirements-pypy.txt /tmp/requirements-pypy.txt
RUN pypy3 -m pip install --no-cache-dir --upgrade pip \
&& pypy3 -m pip install --no-cache-dir cython \
&& pypy3 -m pip install --no-cache-dir --config-settings --confirm-license= --verbose -r requirements-pypy.txt


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 作問用のパッケージをインストールする
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN python3 -m pip install --no-cache-dir rime statements-manager beautifulsoup4


#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 不要なパッケージファイルを削除する
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RUN rm -rf /var/lib/apt/lists/* \
 && apt-get clean

CMD /bin/zsh -c "cd /root/app && exec /bin/zsh"
