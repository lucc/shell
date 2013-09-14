#!/bin/sh

MACVIM_DIR=$HOME/macvim

download () {
  if [ -d $MACVIM_DIR/.git ]; then
    cd $MACVIM_DIR
    git pull
  else
    cd
    git checkout https://github.com/b4winckler/macvim.git $MACVIM_DIR
  fi
}

python_setenv () {
    LDFLAGS="$LDFLAGS -L."
    LDFLAGS="$LDFLAGS -L/usr/local/opt/python3/Frameworks/Python.framework/Versions/3.3/lib/python3.3/config-3.3m"
    LDFLAGS="$LDFLAGS -F/usr/local/opt/python3/Frameworks"
    LDFLAGS="$LDFLAGS -L/usr/local/opt/python/Frameworks/Python.framework/Versions/2.7/lib/python2.7/config"
    LDFLAGS="$LDFLAGS -F/usr/local/opt/python/Frameworks"
    LDFLAGS="$LDFLAGS -L/usr/local/lib"
    LDFLAGS="$LDFLAGS -F/usr/local/Frameworks -arch x86_64"
    export LDFLAGS
}

clean_macvim () {
  make -C $MACVIM_DIR clean distclean
}

config_macvim () {
  python_setenv
  cd $MACVIM_DIR && \
  ./configure          \
    --with-compiledby=luc@mbp         \
    --with-features=huge              \
    --with-macsdk=10.6                \
    --disable-gpm                     \
    --disable-selinux                 \
    --disable-sysmouse                \
    --disable-xim                     \
    --disable-xsmp                    \
    --disable-xsmp-interact           \
    --enable-cscope                   \
    --enable-fail-if-missing          \
    --enable-luainterp                \
    --enable-multibyte                \
    --enable-mzschemeinterp           \
    --enable-perlinterp               \
    --enable-python3interp=yes        \
    --enable-pythoninterp=yes         \
    --enable-rubyinterp               \
    --enable-tclinterp                \
    --with-lua-prefix=`brew --prefix lua` \
    --with-tlib=ncurses               \

}

make_macvim () {
  python_setenv
  make -C $MACVIM_DIR/src/MacVim/icons getenvy
  make -C $MACVIM_DIR/src
}

if [ -z "$PS1" ]; then
  clean_macvim
  config_macvim
  make_macvim
fi
