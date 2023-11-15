#!/bin/bash

# https://stackoverflow.com/a/246128
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

build_ladr () {
    # Make sure we are in the script directory
    if [ $(pwd) != $SCRIPT_DIR ]; then
        echo build_ladr was called outside $SCRIPT_DIR
        exit 1
    fi
    git submodule update --init
    cd deps/ladr || exit 1
    # Make sure the bin folder exists, otherwise make will fail
    ! [ -d bin ] && mkdir bin
    make clean
    make all
    cd $OLDPWD || exit 1

    # Make sure the GUI bin folder exists
    ! [ -d src/bin ] && mkdir src/bin
    # Copy the binaries to the GUI bin folder
    files_to_copy=("prover9" "prooftrans" "mace4" "interpformat" "isofilter" "isofilter2")
    for file in "${files_to_copy[@]}"; do
        cp "deps/ladr/bin/$file" "src/bin/"
    done
}

if [ $(pwd) == $SCRIPT_DIR ]; then
    (
        build_ladr $SCRIPT_DIR
    )
else
    cd "$SCRIPT_DIR" || exit 1
    # Run in subshell to avoid changing OLDPWD
    (
        build_ladr $SCRIPT_DIR
    )
    cd "$OLDPWD" || exit 1
fi

# Check if we are inside a conda environment, and if so exit
if [ -n "$CONDA_PREFIX" ]; then
   echo "You are in a conda environment. Bundling the GUI app under it will"
   echo "result in an unnecessarily large app. If you don't mind this, simply"
   echo "run"
   echo
   echo "   pip -r requirements.txt"
   echo "   python setup.py py2app"
   echo
   echo "Otherwise, please deactivate conda."
   exit 1
fi

if command -v python &> /dev/null && python --version 2>&1 | grep -q "Python 3"; then
    PYTHON=$(which python)
elif command -v python3 &> /dev/null && python3 --version 2>&1 | grep -q "Python 3"; then
    PYTHON=$(which python3)
else
    echo "Python 3 is not installed. Please install Python 3."
    exit 1
fi
echo "Python 3 found at $PYTHON."

VENV="$SCRIPT_DIR/venv"

if [[ -d $VENV ]]; then
    echo "Found existing virtual environment"
else
    echo Running $PYTHON -m venv $VENV
    $PYTHON -m venv $VENV
    if [[ -d $VENV ]]; then
        echo "Virtual environment created successfuly."
    else
        echo "Failed to create virtual environment."
        exit 1
    fi
fi

source $VENV/bin/activate
echo "Using $(which python)"
echo "Using $(which pip)"
echo "Installing dependencies..."
# Install wheel first to speed up the build process
pip install wheel
pip install -r $SCRIPT_DIR/requirements.txt
pip install py2app
cd "$SCRIPT_DIR" || exit 1
python $SCRIPT_DIR/setup_mac.py py2app
cd "$OLDPWD" || exit 1
deactivate

echo Build successful. Check the dist folder for the app bundle.

echo Cleaning up...
rm -rf $SCRIPT_DIR/build

echo Done!
