#!/bin/bash

set -e

export NUMBA_DEVELOPER_MODE=1
export NUMBA_DISABLE_ERROR_MESSAGE_HIGHLIGHTING=1
export NUMBA_CAPTURED_ERRORS="new_style"
export PYTHONFAULTHANDLER=1

unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
  SEGVCATCH=catchsegv
  export CC="${CC} -pthread"
elif [[ "$unamestr" == 'Darwin' ]]; then
  SEGVCATCH=""
else
  echo Error
fi

# limit CPUs in use on PPC64LE and AARCH64, fork() issues
# occur on high core count systems
archstr=`uname -m`
if [[ "$archstr" == 'ppc64le' ]]; then
    TEST_NPROCS=1
elif [[ "$archstr" == 'aarch64' ]]; then
    TEST_NPROCS=4
else
    TEST_NPROCS=${CPU_COUNT}
fi

# Disable NumPy dispatching to AVX512_SKX if the CPU supports it AND it's
# in NumPy's dispatch list. This avoids low accuracy SVML libm replacements.
# This is needed because only dispatched features can be disabled via NPY_DISABLE_CPU_FEATURES.
_NPY_CMD='from numba.misc import numba_sysinfo; si=numba_sysinfo.get_sysinfo();\
          print(si["NumPy AVX512_SKX detected"] and "AVX512_SKX" in si.get("NumPy Supported SIMD dispatch", ()))'
DISABLE_AVX512_SKX=$(python -c "$_NPY_CMD")
echo "Disable AVX512_SKX: $DISABLE_AVX512_SKX"

if [[ "$DISABLE_AVX512_SKX" == "True" ]]; then
    export NPY_DISABLE_CPU_FEATURES="AVX512_SKX"
fi

# Check Numba executables are there
numba -h

# run system info tool
numba -s

# Check test discovery works
python -m numba.tests.test_runtests

echo 'Running all the tests except long_running'
echo "Running: $SEGVCATCH python -m numba.runtests -b -m $TEST_NPROCS -- $TESTS_TO_RUN"
$SEGVCATCH python -m numba.runtests -b --exclude-tags='long_running' -m $TEST_NPROCS -- $TESTS_TO_RUN

pip check
