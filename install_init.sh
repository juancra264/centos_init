#!/bin/bash

# ------------------------------------------------------------------------------
# Fecha: 03 Abril 2017
# Instalacion y configuracion Servidor Linux CentOS7
# Autor: jcramirez
# Copyright 2016
# Version: 2.0
# Revision: jcramirez
# Instruccion para la ejecucion (Permitir la ejecucion del script)
# chmod +x install.sh
# ------------------------------------------------------------------------------

#
# set variables globables
#
currentUser="$(whoami)"
selinuxPath='/etc/selinux/config'
selinuxBefore='SELINUX=.*'
selinuxAfter='SELINUX=disabled'

################################################################################
#                       Function Declarations                                  #
################################################################################
#
# Declaracion de entrega de usuario:
#
function prompt()
{
	echo -e -n "$1"
	read ans
} 

#
# Instalacion y configuración Inicial de CentOS7 o RHEL7
#
function inicial_startup
{
echo -e "**********************************************************"
echo -e " Actualizacion del servidor"
echo -e "**********************************************************"
yum -y update
if [ $? -ne 0 ]
then
	echo -e "\nActualizacion fallida at \"Instalacion de paquetes...\"\n."
	exit 7
fi
echo -e "**********************************************************"
echo -e " Instalacion de paquetes basico y plugins"
echo -e "**********************************************************"
yum -y install yum-plugin-priorities
# set [priority=1] to official repository
sed -i -e "s/\]$/\]\npriority=1/g" /etc/yum.repos.d/CentOS-Base.repo
# Instalacion de repositorio EPEL
yum -y install epel-release
# set [priority=5]
sed -i -e "s/\]$/\]\npriority=5/g" /etc/yum.repos.d/epel.repo
# Instalacion de SCLo Software colletions Repository
yum -y install centos-release-scl-rh centos-release-scl
# set [priority=10]
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl.repo 
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo

#Installing software
yum -y install vim-enhanced 
yum -y --nogpgcheck install bind-utils traceroute telnet finger wget autoconf 
yum -y --nogpgcheck install automake libtool make gcc tree net-tools perl 
yum -y --nogpgcheck install kernel-headers kernel-devel nano iperf3 iptraf-ng 
yum -y --nogpgcheck install dstat ntpdate nfs-utils samba-client cifs-utils 
yum -y --nogpgcheck install iftop htop python-pip python-dev openssl-devel
yum -y --nogpgcheck install tmux vim-enhanced bzip2-devel

if [ $? -ne 0 ]
then
	echo -e "\nInstalacion fallida at \"Instalacion de paquetes...\"\n."
	exit 7
fi
#
# Detencion de servicios que no se usaran
#
echo -e "**********************************************************"
echo -e " Detencion de servicios Firewalld y Postfix"
echo -e "**********************************************************"
# Apagado de servicios
systemctl stop firewalld
systemctl stop postfix
systemctl stop NetworkManager
# Deshabilitacion de inicio automatico
systemctl disable firewalld
systemctl disable postfix
systemctl disable NetworkManager

#
# set selinux to disabled
#
echo -e "**********************************************************"
echo -e " Deshabilitacion de SELinux "
echo -e "**********************************************************"
sed -i s/"^${selinuxBefore}"/"${selinuxAfter}"/g ${selinuxPath}

#
# sincronizacion de relojes con horalegal colombia
#
echo -e "**********************************************************"
echo -e " Sincronizacion de relojes con horalegal colombia ..."
echo -e "**********************************************************"
ntpdate -u horalegal.inm.gov.co
systemctl start ntpdate
systemctl enable ntpdate
hwclock --systohc
#
# complete
#
echo -e "\n*************************************************************************"
echo -e " Configuracion Inicial completa. Por favor reiniciar el servidor."
echo -e "*************************************************************************"
}

#
# Instalacion y configuración Inicial de Web Server Apache
#
function installApache
{
echo -e "**********************************************************"
echo -e " Instalacion de web Server Apache"
echo -e "**********************************************************"
#
# Instalacion de paquetes.
#
yum -y --nogpgcheck install install httpd php php-mbstring php-pear mod_ssl php-mysql
if [ $? -ne 0 ]
then
	echo -e "\nInstalacion fallida at \"Instalacion de paquetes...\"\n."
	exit 7
fi

#
# Ajustes de Index Inicial
#
cd /var/www/html/
touch index.html
echo "<html>" >> index.html 
echo "<body>" >> index.html
echo "TEST OK!" >> index.html
echo "</div>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html

#
# set service defaults
#
echo -e "**********************************************************"
echo "\n Configuracion de servicios por defecto Web Server Apache..."
echo -e "**********************************************************"
# Apagado de servicios
systemctl start httpd 
# Habilitacion de inicio automatico Apache
systemctl enable httpd

#
# complete
#
echo -e "**********************************************************"
echo -e "Instalacion de servicio web APACHE exitosa.\n Contenedor WEB: /var/www/html/ \n Archivos de configuración: /etc/httpd/conf/httpd.conf"
echo -e "**********************************************************\n"
}

#
# Instalacion y configuración Inicial de MySQL MariaDB
#
function installMariaDB
{
echo -e "**********************************************************"
echo -e " Instalacion de Base de Datos MySQL MariaDB"
echo -e "**********************************************************"
yum -y --nogpgcheck install install mariadb-server
if [ $? -ne 0 ]
then
	echo -e "\nInstalacion fallida at \"Instalacion de paquetes...\"\n."
	exit 7
fi

#
# set service defaults
#
echo -e "\n**********************************************************"
echo -e " Configuracion de servicios por defecto MariaDB..."
echo -e "**********************************************************"
# Apagado de servicios
systemctl start mariadb 
# Habilitacion inicio automatico de MariaDB
systemctl enable mariadb

#
# finalizacion de la instalacion y paso a inicializacion segura de base de datos
#
echo -e "**********************************************************"
echo -e " Instalacion de servicio MariaDB (MySQL) exitosa."
echo -e "**********************************************************"
echo -e "Se debe realizar la inicializacion segura de la BASE DATOS\n"
echo -e "Tener encuenta y llegar registro del password del usuario root\n"
read -p "Presione ENTER para continuar y siga los pasos indicados por el sistema...."
echo
mysql_secure_installation 
echo -e "\n\n********************************************************\nConfiguracion de Mariadb completa.\n\n********************************************************\n"
}

################################################################################
# MAIN          LInux Server installacion y configuracion inicial              #
################################################################################

#
# check usuario logueado como root
#
if [ ${currentUser} != "root" ]
then
	echo -e "\nPor favor ingrese como ROOT.\n"
	exit 2
fi

#
# Actualizacion e instalacion inicial:
#
echo -e "**************************************************************************"
echo -e "*                Instalacion y alistamiento de servidores                *"
echo -e "**************************************************************************"
echo -e "    Siga atentamente las preguntas: \n"

	
#	Instalacion Inicial		
while :
do
	prompt "\nDesea realizar instalacion inicial y actualizacion del servidor [S/N]? "
	case $ans in
		[sS]* ) inicial_startup ;;
		[nN]* ) break ;;
		*     ) echo -e "\n    Por favor digite S para Si o N para NO"
				continue ;;
	esac
	break
done
	
#	Instalacion de Apache	
while :
do
	prompt "\nDesea realizar instalacion web server Apache [S/N]? "
	case $ans in
		[sS]* ) installApache ;;
		[nN]* ) break ;;
		*     ) echo -e "\n    Por favor digite S para Si o N para NO"
				continue ;;
	esac
	break
done
#	Instalacion de MariaDB	
while :
do
	prompt "\nDesea realizar instalacion Base de Datos MariaDB [S/N]? "
	case $ans in
		[sS]* ) installMariaDB ;;
		[nN]* ) break ;;
		*     ) echo -e "\n    Por favor digite S para Si o N para NO"
				continue ;;
	esac
	break
done
echo -e "\n**************************************************************************"
echo -e "*                Instalacion y alistamiento Finalizado                   *"
echo -e "*                   Favor reiniciar el servidor                          *"
echo -e "**************************************************************************\n\n"
echo -e " En caso de alguna falla o Bug:,\n favor reportarlo a juancra264@hotmail.com \n gracias....\n"
while :
do
	prompt "\nDesea reiniciar el servidor [S/N]? "
	case $ans in
		[sS]* ) reboot ;;
		[nN]* ) break ;;
		*     ) echo -e "\n    Por favor digite S para Si o N para NO"
				continue ;;
	esac
	break
done
exit 0
