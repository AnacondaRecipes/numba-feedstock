set NUMBA_DEVELOPER_MODE=1
set NUMBA_DISABLE_ERROR_MESSAGE_HIGHLIGHTING=1
set NUMBA_CAPTURED_ERRORS=new_style
set PYTHONFAULTHANDLER=1

@rem Check Numba executables are there
numba -h

@rem Run system info tool
numba -s

@rem Check test discovery works
python -m numba.tests.test_runtests

@rem Run the whole test suite
python -m numba.runtests -m %CPU_COUNT% -b  --exclude-tags='long_running'

if errorlevel 1 exit 1

python -m pip check
if errorlevel 1 exit 1
