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

VERSION=0.1alpha0
INSTALLER_PACKAGE=tensorflow_macos-$VERSION.tar.gz
INSTALLER_PATH=https://github.com/apple/tensorflow_macos/releases/download/$VERSION/INSTALLER_PACKAGE.tar.gz
INSTALLER_SCRIPT=tensorflow_venv.sh

# Check to make sure we're good to go.
if [[ $(uname) != Darwin ]] || [[ $(sw_vers -productName) != macOS ]] || [[ $(sw_vers -productVersion) != "11."* ]] ; then 
  error_exit "TensorFlow with ML Compute acceleration is only available on macOS 11.0 and later." 
fi

# This 
echo "Installation script for pre-release tensorflow_macos 0.1alpha0.  Please visit https://github.com/apple/tensorflow_macos "
echo "for instructions and license information."   
echo
echo "This script will download tensorflow_macos 0.1alpha0 and needed binary dependencies, then install them into a new "
echo "or existing Python 3.8 virtual enviornoment."

# Make sure the user knows what's going on.  
read -p 'Continue [y/N]? ' -n 1 -r   

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
exit 1
fi
echo

echo "Downloading installer."
tmp_dir=$(mktemp)

pushd $tmp_dir

curl -LO $INSTALLER_PATH 

echo "Extracting installer."
tar xf $INSTALLER_PACKAGE

cd tensorflow_macos 
bash $INSTALLER_SCRIPT --prompt 

popd
rm -rf $tmp_dir










