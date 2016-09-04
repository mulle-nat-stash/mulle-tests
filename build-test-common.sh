#! /bin/sh
#
# assume:
#   project/CMakeLists.txt
#   project/dependencies
#   project/addictions
#   project/tests/<us.sh>
#
# PWD=project/tests  <--- we are here
#
# create:
#   project/tests/lib
#   project/tests/include
# using:
#   project/tests/build
#

usage()
{
   cat <<EOF >&2
usage: build-for-test.sh [-dj]

   -d   : rebuild parent depedencies
   -j   : number of cores parameter for make (${CORES})
EOF
   exit 1
}


CORES="${CORES:-2}"


while [ $# -ne 0 ]
do
   case "$1" in
      -h|--help)
         usage
      ;;

      -d)
         REBUILD="YES"
      ;;

      -j)
         shift
         [ $# -eq 0 ] && usage

         CORES="$1"
      ;;

      -*)
         usage
      ;;

      *)
         break
      ;;
   esac

   shift
done


BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
OSX_SYSROOT="${OSX_SYSROOT:-macosx}"
BUILD_OPTIONS="${BUILD_OPTIONS:--c Debug -k}"
prefix="`pwd -P`"

if [ "${REBUILD}" = "YES" -a -d ../.bootstrap ]
then
   if [ ! -d ../.repos -a ! -d ../archive ]
   then
      ( cd .. ; mulle-bootstrap fetch )
   fi
   ( cd .. ; mulle-bootstrap build ${BUILD_OPTIONS} "$@" )
fi


if [ ! -f "../CMakeLists.txt" ]
then
   echo "No CMakeLists.txt file found. So only dependencies may have been built." >&2
   exit 0
fi

if [ ! -d "${BUILD_DIR}" ]
then
   mkdir "${BUILD_DIR}" 2> /dev/null
fi

cd "${BUILD_DIR}" || exit 1


if [ ! -z "${CC}" ]
then
   CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_C_COMPILER=${CC}"
fi

if [ ! -z "${CXX}" ]
then
   CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_CXX_COMPILER=${CXX}"
fi

cmake "-DCMAKE_OSX_SYSROOT=${OSX_SYSROOT}" \
      "-DCMAKE_INSTALL_PREFIX=${prefix}" \
      "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}" \
      ${CMAKE_FLAGS} \
      ../.. || exit 1
make install
