#!/bin/bash -x

if [ $# -ne 1 ]; then
  echo "  `basename $0` base "
  echo
  echo "   base=6.8 or 7.2 "
  exit 1
fi

home=$PWD

base=$1

dstring=`date "+%Y-%m-%d_%H%M%S"`

### 'curl' the required file from chef/bento
url=opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/
prefix=opscode_centos-
suffix=_chef-provisionerless.box

box=${prefix}${base}${suffix}
temp_ovdir=${dstring}__${base}

mkdir ${temp_ovdir}
echo "curl -o ${temp_ovdir}/${box}  -R ${url}${box}  "
curl -o ${temp_ovdir}/${box}  -R ${url}${box} 

if [ $? -ne 0 ]; then
  echo "Curl failed ..."
  exit 1
fi

### Untar!
cd ${temp_ovdir}
echo "tar xvf ${box} "
tar xvf ${box}

if [ $? -ne 0 ]; then
   echo "tar failed ..."
   exit 1
fi

cd $home

######## Now begin building the boxes
./vm_build.sh $base centos-${base} ${temp_ovdir}

exit $?

