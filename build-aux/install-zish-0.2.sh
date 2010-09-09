#! /bin/bash 
#TODO
# for RH 7.2 load_and_expand fails because the \n replacement become just "n"
# cheetah fails for RH 7.2 too at _namemapper.c
# we should make sure Apache proper modules ( userdir, rewrite, etc.. ) are loaded


#You can change this versions at your own risk
URLS_SRC_PLONE3="http://www.python.org/ftp/python/2.4.6/Python-2.4.6.tar.bz2 \
http://prdownloads.sourceforge.net/tcl/tcl8.5.7-src.tar.gz \
http://prdownloads.sourceforge.net/tcl/tk8.5.7-src.tar.gz \
http://effbot.org/downloads/Imaging-1.1.6.tar.gz \
http://www.xmlsoft.org/sources/python/libxml2-python-2.6.15.tar.gz \
http://www.zope.org/Products/Zope/2.11.3/Zope-2.11.3-final.tgz \
http://www.free-instants.org/downloads/zish/pcgi.tar.gz \
http://www.free-instants.org/downloads/zish/config.tar.gz \
http://peak.telecommunity.com/dist/ez_setup.py"


#You can change this versions at your own risk for Plone 4
URLS_SRC_PLONE4="http://www.python.org/ftp/python/2.6.6/Python-2.6.6.tar.bz2 \
http://prdownloads.sourceforge.net/tcl/tcl8.5.7-src.tar.gz \
http://prdownloads.sourceforge.net/tcl/tk8.5.7-src.tar.gz \
http://effbot.org/downloads/Imaging-1.1.6.tar.gz \
http://www.xmlsoft.org/sources/python/libxml2-python-2.6.15.tar.gz \
http://pypi.python.org/packages/source/Z/Zope2/Zope2-2.13.0a3.zip \
http://www.free-instants.org/downloads/zish/pcgi.tar.gz \
http://www.free-instants.org/downloads/zish/config.tar.gz \
http://peak.telecommunity.com/dist/ez_setup.py"

#URLS_SRC_LOCAL="http://localhost/downloads/src/zish/Python-2.4.6.tar.bz2 \
#http://localhost/downloads/src/zish/tcl8.5.7-src.tar.gz \
#http://localhost/downloads/src/zish/tk8.5.7-src.tar.gz \
#http://localhost/downloads/src/zish/Imaging-1.1.6.tar.gz \
#http://localhost/downloads/src/zish/libxml2-python-2.6.15.tar.gz \
#http://localhost/downloads/src/zish/Zope-2.11.3-final.tgz \
#http://localhost/downloads/src/zish/pcgi.tar.gz \
#http://localhost/downloads/src/zish/config.tar.gz \
#http://localhost/downloads/src/zish/ez_setup.py"


# get Missing OpenSSL es necesario para easy_install hashlib para el buildout de plone 4
# podria ser necesario openssl en primer lugar para que pudiera acceder el buildout
#http://www.openssl.org/source/openssl-1.0.0a.tar.gz , tambien podriamos encontrarla 
# añadirla al LD_LIBARY_PATH o al ld.so.conf y no sufrir tanto. Lo he solucionado 
# exportando CPPFLAGS y LDFLAGS antes del configure.


abs_builddir=${abs_builddir:-$PWD}
#================ autoconf connection =============================================
# Most of this variables can be sourced from the makefile execution
 if test -e $abs_builddir/zish.vars ;then
		echo "sourcing zish variables from $abs_builddir "
		source $abs_builddir/zish.vars   #... or not
		distutilscfg=$(echo | awk -v var=$distutilscfg '{ gsub(".in","",var) ; print var }' )
        echo "distutils file is $distutilscfg "
 else
    echo "zish.vars not found in abs_builddir: " $abs_builddir
    exit 1
fi
#==================================================================================
#app parameters
 
zishinstancename="zish_instance"
buildoutver=${buildoutver:-"bconf/buildoutsProd4"} 
PYTHON_VERSION=${PYTHON_VERSION:-"2.6"}             # 2 digits only
PLONE_VERSION="4.0rc1"   #"3.2.1"                   # minimun Plone 4 version = 4.0rc1
ZOPE_VERSION="2.12.10"   #                          # minimun Zope2 version for Plone 4 = 2.12.10
URL_SRC=$URL_SRC_PLONE4

distutilscfg=${distutilscfg:-"none"}
prefix=${prefix:-"$HOME/opt"}
ZISHRC=${ZISHRC:-"$HOME/.zishrc"}
ROOT_PATH=${ROOT_PATH:-"/sbin:/usr/sbin"}
PATH=${PATH:-"$prefix/bin:$PATH:$ROOT_PATH"}
abs_top_builddir=${abs_top_builddir:-$PWD}
abs_top_srcdir=${abs_top_srcdir:-"$PWD"}
abs_builddir=${abs_builddir:-$PWD}
FILE_LOG=$abs_builddir/install.log
ERROR_LOG=$abs_builddir/errors.log

zishworkdir="$abs_top_srcdir/src"
zishtemplatesdir="$abs_top_srcdir/config/"    
zishconfigdir="$abs_builddir/output"          
zishinstancesdir="$prefix/var/zopeservers/instances"
zishinstancedir="$zishinstancesdir/$zishinstancename"
zisheggs="$prefix/var/zopeservers/packages/eggs"
zishpkg="$prefix/var/zopeservers/packages/downloads"
zishhtmldir="$HOME/public_html/$zishinstancename"
zishpythonlibdir=${prefix}/lib/python${PYTHON_VERSION}  
zishpythonsitedir=$zishpythonlibdir/site-packages
zishpythondistutilsdir=$zishpythonlibdir/distutils

# where the package will install their own libraries and includes 
libdir=${libdir:-"$prefix/lib"}  # i use it later in -rpath , todo should be nice to detect lib or lib64
includedir=${includedir:-"$prefix/include"}

CPPFLAGS=$(find / -maxdepth 3 \( -type d  -iname include \) -printf " -I%p " 2>/dev/null)
LDFLAGS=$(find / -maxdepth 3 \( -type d  -name lib -o -name lib32 -o -name lib64 \) -printf "-L%p " 2>/dev/null) 


#zlib_path=$(find $PATH_NONSTANDARD -maxdepth 5  \( -iname "libz.so" -o -iname "zlib.h" \) -printf "\"%p\" ," )
#jpeg_path=$(find $PATH_NONSTANDARD  -maxdepth 5  \( -iname "libjpeg*.so" -o -iname "*jpeglib*.h" \) -printf "\"%p\" ," )
#freetype_path=$(find $PATH_NONSTANDARD  -maxdepth 5  \( -iname "libfreetype*.so" -o -iname "freetype*.h" \) -printf "\"%p\" ," )
#tiff_path=$(find $PATH_NONSTANDARD  -maxdepth 5  \( -iname "libtiff*.so" -o -iname "freetype*.h" \) -printf "\"%p\" ," )
#tcl_path=$(find $prefix  -maxdepth 5  \( -iname "libtcl*.so" -o -iname "tcl.h" \) -printf "\"%p\" ," )
includes=$( echo $CPPFLAGS| awk ' { for(i=1;i<=NF;i++)  gsub(/-I/,"",$i) gsub(/.*/,"\"&\"\\, ",$i) ; print } ' )
libraries=$( echo $LDFLAGS| awk ' { for(i=1;i<=NF;i++)   gsub(/-L/,"",$i) gsub(/.*/,"\"&\"\\, ",$i) ; print } ' )


HEADING="#---zish---"
PYTHONHOME=$prefix
PYTHONPATH=$zishpythonsitedir
BUILDPYTHON=$prefix/bin/python
BUILDPASTER=$prefix/bin/paster

DIR_TREE={$prefix/srv,$prefix/tmp/{build,lib,scripts},$zishinstancedir,$zisheggs,$zishpkg,$zishhtmldir}

prepare_account()
{
echo "prepare_account: begin.. "
cat > $ZISHRC <<_EOF_
 $HEADING
 PREFIX=$prefix
 PATH=$prefix/bin:\$PATH
 LD_LIBRARY_PATH=$prefix/lib:$prefix/lib64
 export PATH LD_LIBRARY_PATH
_EOF_
PROFILE=$(ls $HOME/.bash_profile 2>/dev/null || \
ls $HOME/.bash_login  2>/dev/null  || \
ls $HOME/.profile 2>/dev/null || \
( touch $HOME/.profile && echo "$HOME/.profile"  ))
token=$(grep -l "zish" $PROFILE)
	if [[ -z $token ]];then
		echo -e "prepare_account : updating profile $PROFILE ..."
		echo "source \$HOME/.zishrc" >> $PROFILE
	fi
tree_done=$(eval ls $DIR_TREE &>/dev/null || echo 1)
test -n $tree_done && eval mkdir -p $DIR_TREE 
	if test -d $zishconfigdir ; then
		echo "prepare_account : directory of config files $zishconfigdir "
		cp -Ru $zishtemplatesdir/* $zishconfigdir/          # where zishconfigdir is relative to the abs_builddir , trying to do it everything relative con buiddir
		load_and_expand $zishconfigdir/$buildoutver/htaccess.in $zishhtmldir/.htaccess none
		load_and_expand $zishconfigdir/$buildoutver/Zope.cgi.in $zishhtmldir/Zope.cgi none 
        chmod +x $zishhtmldir/Zope.cgi
	fi
source $ZISHRC
echo " prepare_account : end "	
}

get_sources()
{ #
# We try to download the sources with wget to make sure we haven't lost any tarball file
# Anyway would be better to check it before trying to connect, as far as the tarballs are already in local
echo "get_sources: begin downloading in $zishworkdir "
test -e $zishworkdir/Python-2.6.6 && return 0;	
echo "files .. " $NUM_FILE
		for URL in $URLS_SRC;
		do
			wget --limit-rate=100k  --wait=5 --directory-prefix=$zishworkdir  \
				 --no-clobber $URL    --progress=bar  #--output-file=$FILE_LOG
			FILE_NAME=$(basename $URL)
			FILE_PATH=$zishworkdir/$FILE_NAME  
            test -e $FILE_PATH || { echo " ERROR: file couldng't be downloaded" ; false ; }
			DIR_NAME=$(echo | awk -v n=$FILE_NAME '{ l=match(n,"\.|/"); substr(n,1,l-1) ; print n }')
			echo "get_sources : Directory LIBRARY_DIRS name is : " $FILE_NAME --  $DIR_NAME 
			if [[ -n $DIR_NAME ]]; then
				DIR_PATH=$(ls -d $zishworkdir/$DIR_NAME* 2>/dev/null || echo $zishworkdir/$DIR_NAME  )
				JUSTONE=$(echo $DIR_PATH | wc -l)
				# If an error happens, an exception is raised and the "else" clausule is not reached. 
				# To avoid this we give a default value after the "||" logic operator
				if [[ ! -d $DIR_PATH ]]; then
					echo "get_sources : uncompressing $FILE_NAME ..."
			   		echo $FILE_PATH $zishworkdir $FILE_LOG | 
						awk '$1 ~ /.bz2$/ {system("tar -xjvkf " $1 " -C " $2 " 2>"$3 )}; 
							 $1 ~ /.tar.gz$|.tgz$/ 	{system("tar -xzvkf " $1 " -C " $2 " 2>"$3 )};
                             $1 ~ /.zip$/ {system("zip " $1 " -d " $2 " 2>"$3 )}; '
				elif [[ -d $DIR_PATH && $JUSTONE -eq 1 ]]; then
					echo "get_sources : directory already exists; skipping..."
				else
					echo "get_sources : ERROR: more than one posibility "
					#return 1
				fi

			fi
		done
echo "get_sources : end"
}


get_missing()
{
# Consider use custom configurations for apt or urpmi to download the pkgs.
echo "get_missing: begin... $missing_libs"
if [[ -z $missing_libs ]] ; then 
	echo "get_missing: no missing libraries " 
	return 0
elif [[ -z $distribution ]] ; then 
	echo "get_missing: no distribution detected " 
	return 1
fi
pkg="@----------@"
tmpdir=${abs_top_srcdir}/src/tmp
if [[ -d $tmpdir ]];then
	cd $tmpdir
	case $distribution in
	ubuntu|debian)
		URL_PKG=""
		sys_pkgs="gcc gcc-c++ build-essential automake nonexistent"
		lib_pkgs="zlib libjpeg libfreetype libreadline libtool zlib1g-dev libjpeg62-dev libfreetype6-dev libreadline5-dev"
		dev_pkgs="libldap2-dev libssl-dev libsasl2-dev python-ldap python-libxml2 python-libxslt1 python-mysqldb libmysql++-dev python-beautifulsoup"
		spec_pkgs=""
		pkgs="$sys_pkgs $lib_pkgs $dev_pkgs $spec_pkgs"
		comm_get_pkg="apt-get install -d -o=Dir::Cache::archives=$tmpdir $pkg"
		comm_ext_pkg="ar -m $pkg data.tar.gz | tar -xzvf -C $tmpdir"
	;;
	redhat)
		URL_PKG=""
		sys_pkgs="gcc gcc-c++ build-essential automake"
		lib_pkgs="libtool zlib1g-dev libjpeg62-dev libfreetype6-dev libreadline5-dev"
		dev_pkgs="libldap2-dev libssl-dev libsasl2-dev python-ldap python-libxml2 python-libxslt1 python-mysqldb libmysql++-dev python-beautifulsoup"
		spec_pkgs=""
		pkgs="$sys_pkgs $lib_pkgs $dev_pkgs $spec_pkgs"
		comm_get_pkg="up2date"
		comm_ext_pkg="$RPM2CPIO $pkg | $CPIO -i --make-directories --no-absolute-filenames --preserve-modification-time -v "

	;;
	*)
		URL_PKG=""
		sys_pkgs="gcc gcc-c++ build-essential automake"
		lib_pkgs="zlib libjpeg libfreetype libreadline libtool zlib1g-dev libjpeg62-dev libfreetype6-dev libreadline5-dev"
		dev_pkgs="libldap2-dev libssl-dev libsasl2-dev python-ldap python-libxml2 python-libxslt1 python-mysqldb libmysql++-dev python-beautifulsoup"
		spec_pkgs=""
		pkgs="$sys_pkgs $lib_pkgs $dev_pkgs $spec_pkgs"
		comm_get_pkg="yum "
		comm_ext_pkg="$RPM2CPIO $pkg | $CPIO -i --make-directories --no-absolute-filenames --preserve-modification-time -v "
	;;
	esac

	for lib in $missing_libs; do
	 	for pkg in $pkgs; do
			echo "get_missing : trying to get $lib from $pkg "
			j=$(expr match $pkg ".*$lib")
			if [[ $j -gt 0 ]];then	
				comm_get=$(echo $comm_get_pkg | sed $sed_opts 's/@[-]\{10,10\}@/'$pkg'/g')
				comm_ext=$(echo $comm_ext_pkg | sed $sed_opts 's/@[-]\{10,10\}@/'$pkg'/g')
				echo "get_missing : trying to get $lib for $distribution .. with $comm_get"
				#$comm_get_pkg
				#$comm_ext_pkg
				#rm ${tmpdir}/$pkg && mv ${tmpdir}/* ${prefix}
			fi
		done
	done
fi
echo "get_missing: end "
}



check_dirs()
{
echo "check_dirs : begin .... "
DIR_SRC_PYTHON=$(find $zishworkdir -maxdepth 1 -type d -iname python-${PYTHON_VERSION}* ) 
DIR_SRC_TCL=$(find $zishworkdir -maxdepth 1 -type d -iname tcl* )  
DIR_SRC_TK=$(find $zishworkdir -maxdepth 1 -type d -iname tk* )  
DIR_SRC_PIL=$(find $zishworkdir -maxdepth 1 -type d -iname imaging* )  
DIR_SRC_XML2=$(find $zishworkdir -maxdepth 1 -type d -iname libxml2-python* )  
DIR_SRC_ZOPE=$(find $zishworkdir -maxdepth 1 -type d -iname Zope* )  
DIR_SRC_PCGI=$(find $zishworkdir -maxdepth 1 -type d -iname pcgi* ) 
echo "check_dirs : end. "
}

compile_python()
{
# Python does not support related environment variables (PYTHONPATH, ..) while compiling.
echo "compile_python: begin in " $DIR_SRC_PYTHON
#test -x $BUILDPYTHON && return 0
if [[ -n $DIR_SRC_PYTHON && -d $DIR_SRC_PYTHON ]];then
 		cd $DIR_SRC_PYTHON
		#load_and_expand $zishconfigdir/$buildoutver/$distutilscfg  $DIR_SRC_PYTHON/Lib/distutils/distutils.cfg  none # Not supported so soon ?.
        #LDFLAGS+=' , -Wl, -rpath=\$$LIB:'$prefix'/lib ' # use with care i think could be better LD_RUN_PATH="$LD_RUN_PATH" or LD_LIBRARY_PATH In .zish
		SPECIFIC_OPTS=" --prefix=$prefix --exec-prefix=$prefix --libdir=$libdir --includedir=$includedir --enable-unicode=ucs4 --with-pth " 
		CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"  ./configure  $SPECIFIC_OPTS  $PLATFORM_OPTIONS 
		cp ./Makefile Makefile.python.bkp 
		  make && make install
		# This is important because dependent code needs to find Python.h and other headers	
		cp $DIR_SRC_PYTHON/Include/* $prefix/include/python${PYTHON_VERSION}
 		if [[ -n $zishpythonlibdir &&  -d $zishpythonlibdir ]]; then
			 load_and_expand $zishconfigdir/$buildoutver/altinstall.pth.in 	$zishpythonlibdir/site-packages/altinstall.pth none  
			 load_and_expand $zishconfigdir/$buildoutver/zish.pth.in		$zishpythonlibdir/site-packages/zish.pth none   
			 load_and_expand $zishconfigdir/$buildoutver/$distutilscfg.in 	$zishpythonlibdir/distutils/distutils.cfg none  
			 load_and_expand $zishconfigdir/$buildoutver/sitecustomize.py.in  $zishpythonlibdir/site-packages/sitecustomize.py none  
            #TOLEARN: any conflict with .pth files ?
		fi
	which python
fi
echo "compile_python: end "
}

 	
compile_xml2()
{
echo "compile_xml2: begin "
test -e $prefix/lib/python2.4/xml && return 0
if [[ -n $DIR_SRC_XML2 && -d $DIR_SRC_XML2 ]]; then
	cd $DIR_SRC_XML2
		SPECIFIC_OPTS=
		sed $sed_opts ' {
		 s,\(^[ 	]*includes_dir[ 	]*=[ 	]*\[\)\(.*$\),\1'"$includes"'\2,g ; 
		 s,\(^[ 	]*libdirs[ 	]*=[ 	]*\[\)\(.*$\),\1'"$libraries"'\2,g ;  } ' ./setup.py > ./setup.py.xml.tmp 
		cp ./setup.py ./setup.py.xml.bkp && cp ./setup.py.xml.tmp ./setup.py 
		  $BUILDPYTHON setup.py build_ext -i
		  $BUILDPYTHON setup.py install
fi
echo "compile_xml2: end "
}


compile_tcl()
{
echo "compile_tcl: begin "
test -e $prefix/lib/libtcl8.5.so && return 0
if [[ -n $DIR_SRC_TCL && -d $DIR_SRC_TCL ]];then
	cd $DIR_SRC_TCL/unix
		SPECIFIC_OPTS=" --prefix=$prefix --exec-prefix=$prefix --libdir=$libdir --includedir=$includedir "
		 ./configure $SPECIFIC_OPTS $PLATFORM_OPTIONS  
		  cp ./Makefile ./Makefile.tcl.bkp
		  make &&	 make install
fi
echo "compile_tcl: end"
}

compile_tk()
{
echo "compile_tk: begin "
test -e $prefix/lib/libtk8.5.so && return 0
if [[ -n $DIR_SRC_TK && -d $DIR_SRC_TK ]];then
	cd $DIR_SRC_TK/unix
		SPECIFIC_OPTS=" --prefix=$prefix --exec-prefix=$prefix --libdir=$libdir --includedir=$includedir "
		 ./configure $SPECIFIC_OPTS $PLATFORM_OPTIONS 
		cp ./Makefile ./Makefile.tk.bkp
		  make	&& 	make install
fi
echo "compile_tk: end "
}


compile_pil()
{
echo "compile_pil: begin "
test -e "$zishpythonsitedir/PIL.pth" && return 0 
echo "$zishpythonsitedir/PIL.pth"

if [[ -n $DIR_SRC_PIL &&  -d $DIR_SRC_PIL ]]; then
	cd $DIR_SRC_PIL
	#TOLEARN .. the prefix from all this libraries should be $prefix/lib if we really want to build from custom sources. #QUE LO ENCUENTRE AUTOCONF
	FREETYPE_PATH='"/root/lib" \, "'$prefix'/include"'  #; freetype_path=$(echo $zlib_path | awk '{ for(i=1;i<NF;i++) gsubs(/.*/,"\"&\" \, ",$i) ; print $0 }' )
	JPEG_PATH='"/root/lib" \, "'$prefix'/include"'      #; jpeg_path=$(echo $zlib_path | awk '{ for(i=1;i<NF;i++) gsubs(/.*/,"\"&\" \, ",$i) ; print $0 }' )
	TIFF_PATH='"/root/lib" \, "'$prefix'/include"'      #; tiff_path=$(echo $zlib_path | awk '{ for(i=1;i<NF;i++) gsubs(/.*/,"\"&\" \, ",$i) ; print $0 }' )
	ZLIB_PATH='"/root/lib" \, "'$prefix'/include"'      #; zlib_path=$(echo $zlib_path | awk '{ for(i=1;i<NF;i++) gsubs(/.*/,"\"&\" \, ",$i) ; print $0 }' )
	TCL_PATH='"'$prefix'/lib" \, "'$prefix'/include"' 	#; tcl_path=$(echo $zlib_path | awk '{ for(i=1;i<NF;i++) gsubs(/.*/,"\"&\" \, ",$i) ; print $0 }' )
	sed $sed_opts  '{  s,^FREETYPE_ROOT[ 	]\+=[ 	]\+None,FREETYPE_ROOT='"$FREETYPE_PATH"',g ; 
			 s,^JPEG_ROOT[ 	]\+=[ 	]\+None,JPEG_ROOT='"$JPEG_PATH"',g ;
			 s,^TIFF_ROOT[ 	]\+=[ 	]\+None,TIFF_ROOT='"$TIFF_PATH"',g ; 
			 s,^ZLIB_ROOT[ 	]\+=[ 	]\+None,ZLIB_ROOT='"$ZLIB_PATH"',g ; 
			 s,TCL_ROOT[ 	]\+=[ 	]\+None,TCL_ROOT='"$TCL_PATH"',g ;
			 s,^\([ 	]*\)library_dirs[ 	]*=[ 	]*\[.*\],\1library_dirs = ['"$libraries"'],g ;
			 s,^\([ 	]*\)include_dirs[ 	]*=[ 	]*\[.*\],\1include_dirs = ['"$includes"'],g ; } ' setup.py > setup.py.pil.tmp
		 cp ./setup.py ./setup.py.pil.bkp &&  cp ./setup.py.pil.tmp ./setup.py
		   $BUILDPYTHON setup.py build_ext -i 
		   $BUILDPYTHON selftest.py
		   $BUILDPYTHON setup.py install #FIX: Files from .Imaging-1.1.16/PIL/* are not copied to zishpythonlibdir/site-packages/PIL even disttuils.cfg
fi
echo "compile_pil : end"
}
 
compile_zope_standalone()
{
test -e "$prefix/bin/mkzopeinstance.py" && return 0
if [[ -d $DIR_SRC_ZOPE && -x $BUILDPYTHON ]]; then
	cd $DIR_SRC_ZOPE
	SPECIFIC_OPTS=" --prefix=$prefix --with-python=$BUILDPYTHON "
	 ./configure $SPECIFIC_OPTS  # you must supply either home or prefix, no both  ?? system distutils should not globally define "prefix"
	  make && make install
	# Whith persistent 
	if [[ -d $DIR_SRC_PCGI ]]; then
		cd $DIR_SRC_PCGI
		SPECIFIC_OPTS=" --prefix=$prefix  --exec-prefix=$prefix --libdir=$libdir --includedir=$includedir " 
		 ./configure  $PLATFORM_OPTIONS $SPECIFIC_OPTS 
		  make && make install
          cp pcgi_publisher.py $prefix/bin/pcgi_publisher.py
	fi
fi
}


install_setuptools()
{
echo "install_setuptools: begin... "
if test -x $BUILDPYTHON ; then
	echo "install_setuptools: entering in :" $BUILDPYTHON 
	test -e "$zishpythonsitedir/setuptools*egg"  || $BUILDPYTHON "$zishworkdir/ez_setup.py" #can fail if Cheetah or other eggs doesn't find headers  
	test -e  "$zishpythonsitedir/ZopeSkel*egg" ||   $prefix/bin/easy_install ZopeSkel
	test -e  "$zishpythonsitedir/virtualenv*egg" ||   $prefix/bin/easy_install virtualenv
		if test -d $zishinstancesdir; then
			cd $zishinstancesdir
			echo "install_setuptools: entering in :" $zishinstancesdir
			load_and_expand $zishconfigdir/$buildoutver/paster.cfg.in $zishinstancesdir/paster.cfg none
			$BUILDPASTER create --no-interactive -t plone3_buildout --config=paster.cfg $zishinstancename
			if test -d $zishinstancedir ; then
				cd $zishinstancedir 
				echo "install_setuptools: entering in :" $zishinstancedir				
				#zc.buildout creates the directories relatives to the configuration file (buildout.cfg) 
				#finding a way to set a temporary directory to easy_install without raising a SandBoxViolation error.
				load_and_expand $zishconfigdir/$buildoutver/buildoutB.cfg.in  $zishinstancedir/buildoutB.cfg none
				load_and_expand $zishconfigdir/$buildoutver/buildoutT.cfg.in  $zishinstancedir/buildoutT.cfg none
				load_and_expand $zishconfigdir/$buildoutver/versions-${PLONE_VERSION}.cfg.in $zishinstancedir/versions-${PLONE_VERSION}.cfg none
				load_and_expand $zishconfigdir/$buildoutver/versions-Zope-${ZOPE_VERSION}.cfg.in $zishinstancedir/versions-Zope-${ZOPE_VERSION}.cfg none
				test -x $BUILDPYTHON &&  $BUILDPYTHON ./bootstrap.py -c buildoutT.cfg
				test -x ./bin/buildout && ./bin/buildout -c buildoutT.cfg
				load_and_expand $zishconfigdir/$buildoutver/zope.conf.in ./parts/instance/etc/zope.conf none
				test -x ./bin/instance &&  ./bin/instance start
			else
				echo "install_setuptools : ERROR instance directory does not exist."
			fi
		else
			echo "install_setuptools : ERROR instances directories does not exist."
		fi
fi
echo "install_setuptools: end."
}

do_make()
{
if [[ $(expr $distutilscfg : '.*'prefix ) -gt 0 ]];then
	echo "Trying to install with prefix strategy "
	ALTINST=" --prefix=$prefix "
elif [[ $(expr $distutilscfg : '.*'home ) -gt 0 ]];then
	echo "Trying to install with home/install-base strategy "
	ALTINST=" --home=$prefix "
else
	echo "Error assigning distutils.cfg file"
	exit 1
fi 
get_distro
distro_tunning
prepare_account
get_missing
get_sources 
check_dirs
}


do_make_install()
{

if [[ $(expr $distutilscfg : '.*'prefix ) -gt 0 ]];then
	echo "Trying to install with prefix strategy "
	ALTINST=" --prefix=$prefix "
elif [[ $(expr $distutilscfg : '.*'home ) -gt 0 ]];then
	echo "Trying to install with home/install-base strategy "
	ALTINST=" --home=$prefix "
else
	echo "Error assigning distutils.cfg file"
	exit 1
fi 
prepare_account
get_distro
distro_tunning
#get_missing
get_sources 
check_dirs
compile_tcl
compile_tk
compile_python
compile_xml2
compile_pil
compile_zope_standalone
install_setuptools
}



tests()
{
echo "tests: $(basename $0) test suite"
echo "tests: begin ... "
echo "tests: autoconf cached results :"
echo "tests: prefix is :		   :"   $prefix
echo "tests: abs_top_builddir is   :"   $abs_top_builddir
echo "tests: abs_top_srcdir is	   :"   $abs_top_srcdir
echo "tests: zishworkdir is		   :"   $zishworkdir
echo "tests: distutils approach is :"   $distutilscfg   #${distutilscfg%.in} only in Debian.
echo "tests: PLATFORM_OPTIONS      :" 	$PLATFORM_OPTIONS
echo "tests: LDFLAGS:"    $LDFLAGS
echo "tests: CPPFLAGS:"   $CPPFLAGS
echo "tests: libraries :" $libraries
echo "tests: includes :" $includes
get_distro
distro_tunning
#prepare_account
#get_missing
#get_sources
check_dirs
echo "tests: distro seems: " $distribution
echo "tests: src dir for python created :" $DIR_SRC_PYTHON
#load_and_expand $zishconfigdir/$buildoutver/zope.conf.in $zishinstancedir/parts/instance/etc/zope.conf none
echo "tests: end "
}

function get_distro()
{
echo "get_distro: begin..."
LOWER='abcdefghijklmnopqrstuvwxyz'
UPPER='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
distros="ubuntu vector slackware debian redhat arch suse gentoo conectiva mandriva mandrake pardus kanotix generic-undetected"
distro_file=$(ls /etc/{*version,*release} 2>/dev/null || true)
if [[ -z $distro_file ]];then
	echo "get_distro: /proc/version approach"
	distro_file=$(cat /proc/version )
elif [[ -z $distro_file ]];then
	echo "get_distro: binary lbs_release approach"
	distro_file=""
elif [[ -z $distro_file ]];then
	echo "get_distro: binary gcc --version approach"
	distro_file=""
fi
distro_file=$(echo $distro_file | sed "{ y/$UPPER/$LOWER/ ; s/[ 	$)#(,.:]*//g ; }" )
distribution="generic-undetected"
for distro in $distros ;do
	i=$(expr match $distro_file ".*$distro")
	if [[ $i -gt 0 ]];then
		distribution=$distro	
	fi
done
echo "get_distro: found $distribution . End"
}


distro_tunning()
{
echo "distro_tunning: begin.. "
if [[ -n $distro_type ]];then
	echo "distro_tunning: already set $distro_type "
	#return 0;
fi

case $distribution in
redhat|mandriva)
	sed_opts=""
	find_opts=""
	awk_opts=""
	distro_type="rpm"
;;
debian)
	sed_opts=" --posix "
	find_opts=""
	awk_opts=""
	distro_type="debian"
;;
*)
	sed_opts=""
	find_opts=""
	awk_opts=""
    distro_type=""
;;
esac
echo "distro_tunning: for $distro_type "
echo "sed options: " $sed_opts
echo "find options:" $find_opts
echo "awk options: " $awk_opts
echo "distro_tunning: end.. "
}


usage()
{
cat <_EOF_
Usage : $(basename $0) 
	do-make 		: 
	do-make-install :
	tests			:
_EOF_
}


function load_and_expand()
{
# @params  input_file output_file [vars_file]
# in the input file , variables we want to expand must be in the form ${VAR},  
# to difference them from the others $VAR we want to let them be
# It' s not a good idea to use ASCII codes because this codes can change depending the encoding, page code or language
Q="'"		 #  token="\"   ( ASCII code \x27 )
D="\$"	     #  token="$"   ( ASCII code \x24 )
TI="@"		 #  token="@"   ( ASCII code \x40 )
TF="@"		 #  token="@"   ( ASCII code \x40 )
CI="{"		 #  curly="{"   ( ASCII code \x7B )
CF="}"       #  curly="}"   ( ASCII code \x7D )
#TOKEN="#{"  #  token="#{"  ( ASCII code \x23\x7B )  his will substitute variables of the form #{VAR} to ${VAR}
if [[ -n $1 && -n $2 ]]; then
	if [ -e $3 ];then
	 . $3  # dot "." means same than "source"
	fi
	eval echo -ne $(cat -E $1 | sed $sed_opts ' {  s/^/'$Q'/g ;  s/$/'$Q'/g  ; s/'$TI'\([a-zA-Z0-9_]\+\)'$TF'/'$Q$D$CI'\1'$CF$Q'/g ; } ' ) | \
    sed $sed_opts "s,\(\$ \|\$$\),\n,g" >$2      # this last step fails in some old sed versions because they can not put the  \n replacement.
else 
	echo -e "Usage $0 : INPUT_FILE OUPUT_FILE  [VAR_FILES ] 
			 (vars must be in the form \${VAR})"
fi
}




# ............................................................................................
ERROR_LOG=/dev/null
function setErrOptions()
{
	echo "$0 : setting error options"
	set -o errexit
	set -o nounset
	set -o errtrace
	set -o posix
	#trap onexit hup int term ERR 
    trap onbreak HUP INT TERM ERR  # la segunda machaca la primera. 

}

function clearErrOptions()
{
# This function reset all the error handling options to do not affect 
# the system environment after this script execution
	echo "$0 : cleaning error options"
	set +o errexit
	set +o nounset
	set +o errtrace
	set +o posix
	trap - ERR
}


function onexit(){
	local exit_status=${1:-$?}
	local ERROR=""
	if [[ $exit_status -gt 0 ]]; then
        ERROR="ERROR"
	fi
	echo "$0 : $ERROR onexit exiting with estatus: $exit_status" 
	clearErrOptions
	exit $exit_status
}

function onbreak(){
	local exit_status=${1:-$?}
	local ERROR=""
	if [[ $exit_status -gt 0 ]]; then
        ERROR="ERROR"
	fi
	echo "$0 : $ERROR onbreak exiting with estatus: $exit_status" 
	clearErrOptions
 break;
}


# llamada al script ..........................................
setErrOptions
while true;
do 
    echo "$0 : main loop "
    # my commands ...    
    case "$1" in 
	    do-make)
	    do_make   2>&1 | tee $FILE_LOG
	    ;;
	    do-make-install)
	    tests &> $FILE_LOG
	    do_make_install 2>&1 | tee -a $FILE_LOG
	    ;;
	    tests)
	    tests 2> $ERROR_LOG 
	    ;;
	    *)
	    usage
     	;;
    esac
    # ..............................
    break
done 
clearErrOptions 
echo "$0 : end"
exit 0

