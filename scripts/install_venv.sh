#!/bin/bash

# Copyright (C) 2020 Apple Inc. All Rights Reserved.
# 
# IMPORTANT:  This Apple software is supplied to you by Apple
# Inc. ("Apple") in consideration of your agreement to the following
# terms, and your use, installation, modification or redistribution of
# this Apple software constitutes acceptance of these terms.  If you do
# not agree with these terms, please do not use, install, modify or
# redistribute this Apple software.
# 
# In consideration of your agreement to abide by the following terms, and
# subject to these terms, Apple grants you a personal, non-exclusive
# license, under Apple's copyrights in this original Apple software (the
# "Apple Software"), to use, reproduce, modify and redistribute the Apple
# Software, with or without modifications, in source and/or binary forms;
# provided that if you redistribute the Apple Software in its entirety and
# without modifications, you must retain this notice and the following
# text and disclaimers in all such redistributions of the Apple Software.
# Neither the name, trademarks, service marks or logos of Apple Inc. may
# be used to endorse or promote products derived from the Apple Software
# without specific prior written permission from Apple.  Except as
# expressly stated in this notice, no other rights or licenses, express or
# implied, are granted by Apple herein, including but not limited to any
# patent rights that may be infringed by your derivative works or by other
# works in which the Apple Software may be incorporated.
# 
# The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
# MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
# OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
# 
# IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
# MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
# AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 

set -e

arch_list_x86_64=( numpy-1.18.5-cp38-cp38-macosx_11_0_x86_64.whl
                   grpcio-1.33.2-cp38-cp38-macosx_11_0_x86_64.whl       
                   h5py-2.10.0-cp38-cp38-macosx_11_0_x86_64.whl
                   scipy-1.5.4-cp38-cp38-macosx_11_0_x86_64.whl )

arch_list_arm64=(  numpy-1.18.5-cp38-cp38-macosx_11_0_arm64.whl
                   grpcio-1.33.2-cp38-cp38-macosx_11_0_arm64.whl       
                   h5py-2.10.0-cp38-cp38-macosx_11_0_arm64.whl )


tensorflow_version=0.1a3


function usage() {

  echo "Installs the pre-release version of TensorFlow for Macos into a virtual environment." 
  echo
  echo "Usage: $0 [options] <virtual_env>"
  echo
  echo "WARNING: Existing packages in this virtual environment may be modified."
  echo
  echo "  -p, --prompt                      Prompt for the path to the virtual environment."
  echo
  echo "  --python=<python path>            Path to the python executable to use."
  echo
  echo "  -y, --yes                         Execute without prompting."
  echo

  exit 1
}


function error_exit() { 
  >&2 echo '##############################################################'
  >&2 echo 
  >&2 echo "ERROR: $1" 
  >&2 echo 

  exit 1
}


python_path_opt=""
yes_opt=0
no_dependencies_opt=0
venv_opt=""

function check_virtual_env() {
  if [[ ! -z $venv_opt ]] ; then 
    error_exit "Multiple arguments given for virtual environment \($venv_opt, $1\)"
  fi
}

###############################################################################
#
# Parse command line configure flags ------------------------------------------
#
while [ $# -gt 0 ]
  do case $1 in
    --python=*)      python_path_opt=${1##--python=};;
    --python)        python_path_opt=${2}; shift ;;

    --yes|-y)        yes_opt=1;;

    --help|-h)       usage;;
    
    --prompt|-p)     prompt_venv=1;;

    -*)              error_exit "Unknown option $1.";;

    *)               check_virtual_env ; venv_opt=$1;;
  esac
  shift
done


# Do a software version check.

if [[ $(sw_vers -productName) != macOS ]] || [[ $(sw_vers -productVersion) != "11."* ]] ; then 
  error_exit "TensorFlow with ML Compute acceleration is only available on macOS 11.0 and later." 
fi

# Are we running the script from the correct location?
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
arch=$(uname -m)
package_dir="$script_dir/$arch"

if [[ ! -d "$package_dir" ]] ; then  
  error_exit "Package resource directory $package_dir does not exist.  Please ensure that this script is located inside the unpacked archive." 
fi 

# Check: Are all the packages properly present and installed?  
if [[ $arch == x86_64 ]] ; then
  packages=( ${arch_list_x86_64[@]} )
elif [[ $arch == arm64 ]] ; then
  packages=( ${arch_list_arm64[@]} )
else 
  error_exit "Architecture $arch not supported; must be x86_64 or arm64."
fi 

# Verify virtual environment stuff
if [[ $prompt_venv == 1 ]] ; then 

  default="$HOME/tensorflow_macos_venv/" 

  # Get the directory 
  read -p "Path to new or existing virtual environment [default: ${default}]: "
  
  eval venv_opt="${REPLY}"
  
  if [[ -z $venv_opt ]] ; then 
    venv_opt=$default
  fi
else 
  if [[ -z $venv_opt ]] ; then 
    usage
  fi
fi



# Check: Did the right virtual environment arguments get passed in? 
function abspath () {	
  echo "$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
}

virtual_env=$(abspath "$venv_opt")

if [[ -z $virtual_env ]] ; then 
  usage
fi


print_messages=( "$0 will perform the following operations: " ) 
tf_install_message=""

# Now, see if a virtual environment was given as an argument.
if [[ -e $virtual_env ]] ; then 
  if [[ ! -d "$virtual_env" ]] || [[ ! -e "$virtual_env/bin/python" ]]  ; then 
    error_exit "$virtual_env does not seem to be a virtual environment.  Please specify a new directory or an existing Python 3.8 virtual environment. "
  fi
  create_venv=0

  python_bin="$virtual_env/bin/python"

  # Check: Make sure the python version is correct.  
  if [[ $("$python_bin" --version) != *"3.8"* ]] ; then 
    error_exit "Python version in specificed virtual environment $virtual_env not 3.8.   Python 3.8 required for tensorflow_macos $tensorflow_version."
  fi

  if [[ ! -z $python_path_opt ]] && [[ ! "$python_path_opt" -ef "$python_bin" ]] ; then 
    error_exit "Specifying an existing Virtual Environment requires the use of the same Python version."
  fi
 
  # Finally, check if tensorflow is currently installed.

  if ls "$virtual_env"/lib/python3.8/site-packages/tensorflow-*.dist-info 1> /dev/null 2>&1; then 
    uninstall_tf=1
    print_messages+=( "  -> Uninstall existing tensorflow installation." )
  fi
  
  print_messages+=( "  -> Install tensorflow_macos $tensorflow_version into existing virtual environment $virtual_env." )

else 

  uninstall_tf=0 
  create_venv=1
  print_messages+=(  "  -> Create new python 3.8 virtual environment at $virtual_env." 
                     "  -> Install tensorflow_macos $tensorflow_version into created virtual environment $virtual_env."  )

  if [[ ! -z $python_path_opt ]] ; then 
    python_bin=$python_path_opt
    
    if [[ ! -x $python_bin ]] ; then 
      error_exit "$python_bin does not seem to be valid Python executable."
    fi
  else 
    # Check: Make sure we get the correct python framework to install this from if possible. 
    python_bin=`which python3`
    if [[ ! -e $python_bin ]] ; then 
      python_bin=`which python`
    fi

    # Check: python bin executable
    if [[ ! -e $python_bin ]] ; then 
      error_exit "No suitable Python executable found in path.  Please specify a Python 3.8 executable with the --python option."
    fi
  fi

  # Check: Make sure the python version is correct.  
  if [[ $($python_bin --version) != *"3.8"* ]] ; then 
    error_exit "Error retrieving python version, or python executable $python_bin not version 3.8.  Please specify a Python 3.8 executable with the --python option."
  else
    echo "Using python from $python_bin." 
  fi

fi

python_filetypes=$(file $python_bin | grep -o -E 'Mach-O 64-bit executable [a-zA-Z0-9_]+$' | sed -E 's|^.*Mach-O 64-bit executable ([a-zA-Z0-9_]+)$|\1|g')

is_present=0
arm64e_present=0

for t in $python_filetypes ; do
  if [[ $t -eq $arch ]] ; then
    is_present=1
  fi
  if [[ $t -eq arm64e ]] ; then 
    arm64e_present=1
  fi
done

if [[ $is_present -eq 0 ]] && [[ $arm64e_present -eq 1 ]] && [[ $arch -eq arm64 ]] ; then
  error_exit "Python executable has CPU subtype arm64e; only arm64 CPU subtype is currently supported.  Please use the Python version bundled in the Xcode Command Line Tools."
fi


# Print out confirmation of actions, run with it

if [[ $no_dependencies_opt == 0 ]] ; then
  
  s="  -> Install bundled binary wheels for "

  for p in "${packages[@]}" ; do  
    s="$s ${p%%-cp38*whl}, " 
  done
  
  s="${s%%, } into $virtual_env."

  print_messages+=( "$s" )
fi

echo
echo '###########################################################################'
echo

for msg in "${print_messages[@]}" ; do 
  echo $msg
done

echo $tf_install_message

echo

if [[ $yes_opt != 1 ]] ; then
  read -p 'Confirm [y/N]? ' -n 1 -r

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo
    exit 1
  fi
  echo
  echo
fi 


if [[ $create_venv == 1 ]] ; then
  echo 
  "$python_bin" -m venv "$virtual_env"
fi

# Test for existence here -- If it's a conda environment that's already activated, this allows the script to still work. 
if [[ -e "$virtual_env/bin/activate" ]] ; then 
  . "$virtual_env/bin/activate"
fi

python_bin="$virtual_env/bin/python3"

export MACOSX_DEPLOYMENT_TARGET=11.0

if [[ $uninstall_tf == 1 ]] ; then 
  "$python_bin" -m pip uninstall -y tensorflow || echo "WARNING: Error attempting to uninstall prior tensorflow version."
fi


# Upgrade pip and base packages 
echo ">> Installing and upgrading base packages."
"$python_bin" -m pip install --force pip==20.2.4 wheel setuptools cached-property six packaging

echo ">> Installing bundled binary dependencies."

# Note: As soon python packaging supports macOS 11.0 in full, we can remove the -t hackery.
for f in ${packages[@]} ; do 
  "$python_bin" -m pip install --upgrade -t "$virtual_env/lib/python3.8/site-packages/" --no-dependencies --force "$package_dir/$f"
done

# Manually install all the other dependencies. 
echo ">> Installing dependencies."
"$python_bin" -m pip install absl-py astunparse flatbuffers gast google_pasta keras_preprocessing opt_einsum protobuf tensorflow_estimator termcolor typing_extensions wrapt wheel tensorboard typeguard

# Install some convenience tools.
"$python_bin" -m pip install ipython

# Install the tensorflow wheel itself.
"$python_bin" -m pip install --upgrade --force -t "$virtual_env/lib/python3.8/site-packages/" --no-dependencies "$package_dir"/tensorflow_macos*-cp38-cp38-macosx_11_0_$arch.whl

# Install the tensorflow-addons wheel.
"$python_bin" -m pip install --upgrade --force -t "$virtual_env/lib/python3.8/site-packages/" --no-dependencies "$package_dir"/tensorflow_addons_macos*-cp38-cp38-macosx_11_0_$arch.whl

# Finally, upgrade pip to give the developers the correct version.
"$python_bin" -m pip install --upgrade pip

echo '###########################################################################'
echo 
echo "TensorFlow and TensorFlow Addons with ML Compute for macOS 11.0 successfully installed."
echo 

if [[ -e "$virtual_env/bin/activate" ]] ; then  
  echo "To begin, activate the virtual environment:"
  echo  
  echo "   . \"$virtual_env/bin/activate\" "
  echo 
fi



