# Note: The script was tested on c4.large and r3.large. The latest official release by StarCluster does not support
#       c4.large. However, the bleeding-edge of github (as of 28-March 2016) does support it.
#
# This script seems to only work with Ubuntu 15.04 (maybe also newer, but not 14.04).
#
# To launch a base Ubuntu 15.04 machine I used:
#   (FOR COMPUTE OPTIMIZED AMI)
#   starcluster start -o -s 1 -I c4.large -m ami-20435d41 imagehost
#   (FOR MEMORY OPTIMIZED AMI)
#   starcluster start -o -s 1 -I r3.large -m ami-20435d41 imagehost
# Now ssh to the instance using:
#   starcluster sshmaster imagehost

sudo locale-gen UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# Run Alex Gitten's script to base config the system.
wget https://github.com/github/git-lfs/releases/download/v1.1.0/git-lfs-linux-amd64-1.1.0.tar.gz
tar zxvf git-lfs-linux-amd64-1.1.0.tar.gz
cd git-lfs-1.1.0/
./install.sh
cd ..
rm -rf git-lfs-*
git clone https://github.com/rustandruin/starcluster-spark-skylark.git
mv starcluster-spark-skylark/doall.sh starcluster-spark-skylark/sge.tar.gz starcluster-spark-skylark/scimage_13.04.py .
rm -rf starcluster-spark-skylark/
chmod +x doall.sh
./doall.sh

# apt-get install a few more pacakges
yes | apt-get install cmake libcr-dev cython
yes | apt-get install python-setuptools python-matplotlib
yes | apt-get install ipython ipython-notebook
yes | apt-get install python-pandas python-sympy python-nose
yes | apt-get install swig swig-examples swig2.0-examples
yes | apt-get install doxygen graphviz python-sphinx dvipng unzip subversion maven
yes | apt-get install libz-dev

# Remove OpenMPI so we use mpich
yes | apt-get remove openmpi-bin openmpi-common libopenmpi1.6 libopenmpi-dev

# Install HDF5 (TODO: maybe parallel too?)
wget https://support.hdfgroup.org/ftp/HDF5/current18/src/hdf5-1.8.18.tar.gz
tar zxvf hdf5-1.8.18.tar.gz
cd hdf5-1.8.18/
./configure --prefix=/usr/local --enable-cxx
make -j2
make install
cd ..
rm -rf hdf5-*

# easy-install some pacakges
easy_install mpi4py
easy_install h5py
easy_install networkx

# Install Random123
wget http://www.thesalmons.org/john/random123/releases/1.08/Random123-1.08.tar.gz
tar zxvf Random123-1.08.tar.gz
cp -r Random123-1.08/include/Random123 /usr/local/include
rm -rf Random123-1.08*

# Install Boost
wget http://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.tar.gz
tar zxvf boost_1_60_0.tar.gz
cd boost_1_60_0/
./bootstrap.sh --with-libraries=mpi,python,random,serialization,program_options,system,filesystem
echo "using mpi ;" >> project-config.jam
./b2 -j 2 link=static,shared
./b2 install
cd ..
rm -rf boost*

# Install FFTW
wget http://www.fftw.org/fftw-3.3.4.tar.gz
tar zxvf fftw-3.3.4.tar.gz
cd fftw-3.3.4/
./configure --enable-single --enable-mpi --enable-shared
make -j 2
make install
./configure --enable-mpi --enable-shared
make -j 2
make install
cd ..
rm -rf fftw*

# Install SPIRAL
wget http://www.ece.cmu.edu/~spiral/software/spiral-wht-1.8.tgz
tar zxvf spiral-wht-1.8.tgz
cd spiral-wht-1.8
./configure CC=gcc CFLAGS="-fPIC -fopenmp" PCFLAGS="-fPIC -fopenmp" --enable-RAM=16000 --enable-DDL --enable-IL --enable-PARA=16
make -j2
make install
cd ..
rm -rf spiral*


# Install OpenBLAS
wget http://github.com/xianyi/OpenBLAS/archive/v0.2.15.tar.gz
tar zxvf v0.2.15.tar.gz
cd OpenBLAS-0.2.15/
make USE_OPENMP=1 FC=gfortran
make PREFIX=/usr/local install
cd ..
rm -rf OpenBLAS-0.2.15/
rm v0.2.15.tar.gz

# Install LAPACK
wget http://www.netlib.org/lapack/lapack-3.6.0.tgz
tar zxvf lapack-3.6.0.tgz
cd lapack-3.6.0/
mkdir build; cd build
cmake -DBUILD_SHARED_LIBS=ON -DBLAS_LIBRARIES="-L/usr/local/lib -lopenblas -lm" ..
make -j2
make install
cd ..
rm -rf lapack*

# Install Elemental
git clone https://github.com/elemental/Elemental.git
cd Elemental
git checkout tags/v0.87.6
mkdir build; cd build
cmake -DEL_USE_64BIT_INTS=ON -DEL_HAVE_QUADMATH=OFF -DCMAKE_BUILD_TYPE=Release -DEL_HYBRID=ON -DBUILD_SHARED_LIBS=ON -DINSTALL_PYTHON_PACKAGE=ON -DMATH_LIBS="-L/usr/local/lib -llapack -lopenblas -lm" ../
make -j2
make install

# Now create an AMI, e.g. using the command:
#   starcluster ebsimage <instance-id> <imagename>
#
# You can use 'starcluster listclusters' to find the instance-id.

# On this AMI, you should be able to compile libskylark using:
#   git clone https://github.com/xdata-skylark/libskylark.git
#   cd libskylark
#   mkdir build
#   cd build
#   export BLAS_LIBRARIES="-L/usr/local/lib -lopenblas -lm"
#   export LAPACK_LIBRARIES="-L/usr/local/lib -lopenblas -lm"
#   CC=mpicc CXX=mpicxx cmake -DBUILD_EXAMPLES=ON ..
#   make
