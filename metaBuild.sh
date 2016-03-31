DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PREFIX=$DIR/.libs

if [ -z "$3" ]; then
  ARCH="x86-64"
else 
  ARCH="$3"
fi


if [ "$1" = "build" ]; then
  SYSTEM_NAME=`uname -s` 
  if [ "$SYSTEM_NAME" = "Darwin" -o "$SYSTEM_NAME" = "Linux" ]; then
    echo "Building for OSX, architecture set to $ARCH"
    if [ "$SYSTEM_NAME" = "Dwarin" ]; then
      DARWIN_ARGS="--mmacosx-version-min=10.8 -stdlib=libc++"
    fi
    (cd $DIR && \
    ./configure --libdir=$PREFIX CC=clang CXX=clang++ CXXFLAGS="-std=c++11 -march=$ARCH -mtune=generic $DARWIN_ARGS" CFLAGS="-march=$ARCH -mtune=generic" --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
    make)
  elif echo "$SYSTEM_NAME" | grep -q "MINGW64_NT"; then
    echo "Building for Windows"
    (cd $DIR && \
    ./configure --libdir=$PREFIX --host=corei7-w64-mingw64 --enable-fat --enable-cxx --enable-gmpcompat --disable-static --enable-shared && \
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
