#!/bin/bash
#
# RelView 8.2 Installation Script
#

if [ -z "$1" ]; then
    echo "Please specify an installation folder, e.g. $HOME/path/to/folder"
    exit 1
fi

RELVIEW_DIR=$1
HTTP="https://github.com/relview/packages/raw/master/"

# fetching packages
echo "Creating file system structure."
mkdir -p $RELVIEW_DIR/deps/ \
  && mkdir -p $RELVIEW_DIR/cudd/ \
  && mkdir -p $RELVIEW_DIR/kure/ \
  && mkdir -p $RELVIEW_DIR/relview/

echo "Acquiring source files."
wget $HTTP/relview-8.2.tar.gz -P $RELVIEW_DIR/deps/
wget $HTTP/kure2-2.2.tar.gz -P $RELVIEW_DIR/deps/
wget $HTTP/cudd-2.5.1_FIXED.tar.gz -P $RELVIEW_DIR/deps/
echo "Source files acquired."

echo "Unzipping sources"
cd $RELVIEW_DIR/deps/
for a in `ls -1 *.tar.gz`; do gzip -dc $a | tar xf -; done
rm *.tar.gz


#
# compile CUDD
echo "Preparing Makefile and compiling CUDD"
cd cudd-2.5.1

# Uncomment previous XCFLAGS
sed -i '/^XCFLAG/ s/^/#/' Makefile

# get CPU architecture a set in makefile
CUDD_XCFLAGS=""
if [ `uname -m` == "x86_64" ]
    then CUDD_XCFLAGS="XCFLAGS = -mtune=native -DHAVE_IEEE_754 -DBSD -DSIZEOF_VOID_P=8 -DSIZEOF_LONG=8"
    else CUDD_XCFLAGS="XCFLAGS = -m32 -mtune=native -malign-double -DHAVE_IEEE_754 -DBSD"
fi

# Write XFLAGS to Makefile
sed -i "59 a $CUDD_XCFLAGS" Makefile

# Build Cudd
make
cp -Rvp * $RELVIEW_DIR/cudd/
cd $RELVIEW_DIR/deps


# compile and install Kure
echo "Compiling KURE"
cd kure2-2.2
./configure LUAC=/usr/bin/luac5.1 \
     --with-cudd=$RELVIEW_DIR/cudd \
     --with-lua-pc=lua5.1 \
     --prefix=$RELVIEW_DIR/kure

# Check if everything was right
rc=$?
if [ $rc != 0 ]; then
  echo "Something went wrong during the configuration of Kure"
  exit $rc
fi

make && make install
export PKG_CONFIG_PATH=$RELVIEW_DIR/kure/lib/pkgconfig
cd $RELVIEW_DIR/deps


#
# compile and install RelView
echo "Compiling RelView"

# Get Needed CFLAGS and LIBS for RelView
RELVIEW_CFLAGS=`pkg-config --cflags gtk+-2.0 libxml-2.0`
RELVIEW_LIBS=`pkg-config --libs gtk+-2.0 libxml-2.0`
KURE_CFLAGS=`pkg-config --cflags kure2`
KURE_LIBS=`pkg-config --libs kure2`

cd relview-8.2
./configure LUAC=/usr/bin/luac5.1 \
            LDFLAGS=-llua5.1 \
            LIBS="-ldl $RELVIEW_LIBS" \
            CFLAGS="$RELVIEW_CFLAGS" \
          --prefix=$RELVIEW_DIR/relview

# Check if everything was right
rc=$?
if [ $rc != 0 ]; then
  echo "Something went wrong during the configuration of relivew"
  exit $rc
fi

make && make install
cd $RELVIEW_DIR

echo "RelView installed. You can start it by using $RELVIEW_DIR/relview/bin/relview"

# Kopieren des EPS2PDF Scripts
#sudo cp -Rvp epstopdf /usr/bin/


###########

echo "Installing plug-ins"
echo "Creating file system structure."
mkdir -p $RELVIEW_DIR/deps/plugins/ && mkdir -p ~/.relview-8.2/plugins && cd $RELVIEW_DIR/deps/


echo "Acquiring source files."
wget $HTTP/ascii-1.0.tar.gz -P $RELVIEW_DIR/deps/plugins/
wget $HTTP/graph-drawing-1.1.tar.gz -P $RELVIEW_DIR/deps/plugins/
wget $HTTP/wvg-1.0.tar.gz -P $RELVIEW_DIR/deps/plugins/
wget $HTTP/robdd-info-1.0.tar.gz -P $RELVIEW_DIR/deps/plugins/
wget $HTTP/simple-game-labels-1.0.tar.gz -P $RELVIEW_DIR/deps/plugins/
echo "Source files acquired."



echo "Unzipping sources"
cd $RELVIEW_DIR/deps/plugins/
for a in `ls -1 *.tar.gz`; do gzip -dc $a | tar xf -; done
rm *.tar.gz



echo "Creating symbolic links"
for a in `ls -1`; do
    mkdir -p $RELVIEW_DIR/deps/plugins/$a/include
    ln -s $RELVIEW_DIR/relview/include/relview-8.2/relview/ $RELVIEW_DIR/deps/plugins/$a/include
    ln -s $RELVIEW_DIR/cudd/include/* $RELVIEW_DIR/deps/plugins/$a/include
done


# Compiling and installing plug-ins
export PKG_CONFIG_PATH=$RELVIEW_DIR/relview/lib/pkgconfig
for a in `ls -1`; do
    echo "Compiling and installing $a"
    cd $a
    ./configure --prefix=$RELVIEW_DIR/relview  --with-plugin-dir=$HOME/.relview-8.2/plugins

    # Check if everything was right
    rc=$?
    if [ $rc != 0 ]; then
      echo "Something went wrong during the configuration of $a"
      exit $rc
    fi

    make && make install
    cd ..
done

echo "Plug-ins installed."
