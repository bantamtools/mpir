DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PREFIX=$DIR/.libs
echo $DIR
if [ -z "$2" ]; then
  ARCH="x86-64"
else
  ARCH="$2"
fi


if [ "$1" = "release" -o "$1" = "debug" ]; then
  SYSTEM_NAME=`uname -s`
  if [ "$SYSTEM_NAME" = "Darwin" ]; then
    echo "Building for OSX, architecture set to $ARCH"
    (cd $DIR && \
    ./configure --libdir=$PREFIX CXX='clang++ -std=c++11 -stdlib=libc++' CXXFLAGS="-march=$ARCH -mtune=generic -mmacosx-version-min=10.8" CFLAGS="-march=$ARCH -mtune=generic" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
    make)
  elif [ "$SYSTEM_NAME" = "Linux" ]; then
    echo "Building for Linux, architecture set to $ARCH"
    if [ "$ARCH" = "arm" ]; then
      # FIXME: Not sure how to get clang working in dockcross yet
      # ./configure --build=$ARCH --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -mcpu=arm7 -mtune=generic-arm7" CFLAGS="-mcpu=arm7 -mtune=generic-arm7" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      # this doesn't make a share library for some reason:
      # ./configure --build=$ARCH --libdir=$PREFIX CXXFLAGS="-fPIC" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      (cd $DIR && \
      ./configure --build=$ARCH --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -march=armv7" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      make)
    else
      (cd $DIR && \
      ./configure --build=$ARCH --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -march=$ARCH -mtune=generic" CFLAGS="-march=$ARCH -mtune=generic" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
      make)
    fi
  elif echo "$SYSTEM_NAME" | grep -q "MINGW64_NT"; then
    echo "Building for Windows"
    (cd $DIR && \
    ./configure --libdir=$PREFIX --host=x86_64-w64-mingw64 --enable-fat --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
    make)
  elif echo "$SYSTEM_NAME" | grep -q "MSYS"; then
    echo "ERROR: the MSYS shell is not supported. Please use the MinGW-w64 Win64 Shell instead."
    exit 1
  else
    echo "ERROR: Unrecognized or unsupported platform: $SYSTEM_NAME!"
    exit 1
  fi
elif [ "$1" = "clean" ]; then
  (cd $DIR && \
    make clean)
else
  echo "Missing or unrecognized metabuild argument \"$1\""
  exit 1
fi
