#!/bin/bash
artifactory="10.96.8.57"
artifactory_user="admin"
artifactory_password="Msci@Dev0ps123456"
wrk_dir="/opt/data/cpdocker"
cp_version="3.20.2.0B20"
linux_cphome="/opt/data/cphome"
linux_home_sym="/opt/data/home"
azurecr="bdddev.azurecr.io_pallab"
azurecr_user="bdddev"
azurecr_password="TtjkAS67CpVqVbMYcG=qLBIr9pipi9+M"
software="cp-builds/commonplatform/barraone/3.19.5.0B2/software.tar"
linux_baseimage_name="docker/oraclelinux"
linux_baseimage_version="7.6"
linux_software_name="docker/commonplatform/dev/linux/software"
linux_barraone_name="docker/commonplatform/dev/linux/barraone"
linux_service_name="docker/commonplatform/dev/linux/service"
linux_svctype_name="docker/commonplatform/dev/linux"
image_work_dir="/opt/data"
image_software_work_dir="/opt/data/software"
barra_build_share="\\pn8-st-nfilem02.mgmt.msci.org\dn8_mgmt_an_devqa_cp"
barra_build_dir="StoreFrontCP\BuildRepository\\$cp_version\\"

remove_previous_work_directory() {
        echo "remove previous work directory"
        if [ -d "$wrk_dir" ];then
                echo "Removing the working directory"
                rm -rf "$wrk_dir"
        else
                echo "Working directory is not available"
        fi
        sleep 10
}
create_software_directory() {
        echo "create software directory"
        mkdir -p "$wrk_dir/software"
        chmod -R 755 "$wrk_dir/software"
        sleep 10
}
download_software() {
        echo "download software"
        if [ ! -d "$wrk_dir/software" ];then
                echo "Software directory not available"
                exit 1
        else
                echo "Downloading software files"
                wget -qc --user=$artifactory_user --password=$artifactory_password "http://$artifactory/artifactory/$software" -O "$wrk_dir/software.tar"
                if [ $? -eq 0 ]
                then
                        tar -xvf "$wrk_dir/software/software.tar"
                else
                        exit #?
                fi
        fi
        sleep 10
}
process_latest_repo() {
        echo "process latest repo"
        cp latest.repo "$wrk_dir/software"
        chmod 777  "$wrk_dir/software/latest.repo"
        sleep 10
}
process_software_dockerfile(){
	echo "Creating dockerfile for software"
	{
        echo "FROM $azurecr/$linux_baseimage_name:$linux_baseimage_version"
        echo 'ENTRYPOINT ["/bin/bash"]'
        echo "WORKDIR $image_work_dir"
        echo "ENV JAVA_HOME $image_software_work_dir/jdk64_linux"
        echo 'ENV PATH $image_software_work_dir/jdk64_linux/bin:$PATH'
        echo "RUN yum -y install ruby bind-utils telnet nano vim less strace netstat nc"
        echo "COPY activemq $image_software_work_dir/activemq"
        echo "COPY jdk64_linux $image_software_work_dir/jdk64_linux"
        echo "COPY tomcat $image_software_work_dir/tomcat"
	echo "COPY tools $image_software_work_dir/tools"
	echo "RUN chmod 777 -R $image_software_work_dir"
	echo "COPY latest.repo /etc/yum.repos.d/latest.repo"
	} >> "$wrk_dir/software/Dockerfile"
	sleep 10

}
docker_login(){
	echo "docker login in repository"
	docker login $azurecr -u $azurecr_user -p $azurecr_password
	sleep 10
}
create_software_docker_image(){
	echo "create software docker image"
	cd "$wrk_dir/software"
	docker build -f Dockerfile -t software .
	sleep 10
}
docker_tag_software(){
	echo "docker tag software"
	docker tag software $azurecr/$linux_software_name:$cp_version
	sleep 10
}
docker_push_software(){
	echo "docker push software"
	docker push $azurecr/$linux_software_name:$cp_version
	sleep 10
}
create_barraone_directory() {
        echo "create barraone directory"
        mkdir -p "$wrk_dir/barraone/cphome"
        chmod -R 777 "$wrk_dir/barraone/cphome"
        sleep 10
}
install_smbclient() {
        echo "install smbclient"
        if [ $(dpkg-query -W -f='${Status}' smbclient 2>/dev/null | grep -c "ok installed") -eq 0 ];
        then
                sudo apt install -y smbclient;
        else
                echo "Smbclient is already available"
        fi
        sleep 10
}
install_python_pexpect_module() {
        echo "install pexpect module"
        pip list | grep pexpect
        if [ $? -eq 0 ]
        then
                echo "python-pip and pexpect module is already installed"
        else
                if [ $(dpkg-query -W -f='${Status}' python-pip 2>/dev/null | grep -c "ok installed") -eq 0 ];
                then
                        apt install -y python-pip;
                        pip list | grep pexpect;
                        if [ $? -eq 0 ]
                        then
                                echo "python-pip installed but pexpect module is already available"
                        else
                                pip install pexpect
                        fi
                else
                        echo "python-pip is installed"
                        pip install pexpect
                fi
        fi
        sleep 10
}
download_barraone_jar() {
        echo "download barraone jar"
        smbclient -U "msci\arnozac" "$barra_build_share" --directory "$barra_build_dir" -c "get deploy_BarraOne_$cp_version.jar $wrk_dir/deploy_BarraOne_$cp_version.jar"
        if [ $? -eq 0 ]
        then
                if [ $(dpkg-query -W -f='${Status}' unzip 2>/dev/null | grep -c "ok installed") -eq 0 ];
                then
                        echo "install unzip and extracting jar"
                        apt install -y unzip;
                        unzip "$wrk_dir/deploy_BarraOne_$cp_version.jar" -d "$wrk_dir/barraone/cphome"
                else
                        echo "unzip is already installed"
                        unzip "$wrk_dir/deploy_BarraOne_$cp_version.jar" -d "$wrk_dir/barraone/cphome"
                fi
        else
                exit #?
        fi
        sleep 10
}
process_barraone_dockerfile() {
        echo "process barraone dockerfile"
	{
        echo "FROM $azurecr/$linux_baseimage_name:$cp_version"
        echo "WORKDIR $wrk_dir"
        echo "RUN ln -s $linux_cphome $linux_home_sym"
        echo 'ENTRYPOINT ["/bin/bash"]'
        echo "RUN yum -y install ruby bind-utils telnet nano vim less strace netstat nc"
        echo "COPY cphome $linux_cphome"
        } >> "$wrk_dir/barraone/Dockerfile"
        sleep 10
}
create_docker_image_barraone() {
        echo "create docker image barraone"
        cd "$wrk_dir/barraone"
        docker build -f Dockerfile -t barraone .
        sleep 10
}
docker_tag_barraone() {
        echo "docker tag barraone"
        docker tag barraone $azurecr/$linux_barraone_name:$cp_version
	sleep 10
}
docker_push_barraone() {
	echo "docker push barraone"
	docker push $azurecr/$linux_barraone_name:$cp_version
	sleep 10
}
create_service_directory() {
        echo "create service directory"
        mkdir -p "$wrk_dir/service"
        chmod -R 777 "$wrk_dir/service"
        sleep 10
}
process_service_dockerfile() {
        echo "process service dockerfile"
        {
        echo "FROM $azurecr/$linux_barraone_name:$cp_version"
        echo 'ENTRYPOINT ["/bin/bash","./run.sh"]'
        echo "ENV CPHOME /shares/cphome"
        echo "ENV SOFTWARE_HOME /shares/software"
        echo "ENV CPHOME_LOCAL /opt/data/home"
        echo "RUN mkdir -p /shares/cphome /shares/software"
        echo "COPY run.sh /opt/data"
        } >> Dockerfile
        sleep 10
}
create_docker_image_for_service() {
        echo "create docker image for service"
        cd "$wrk_dir/service"
        docker build -f Dockerfile -t service .
        sleep 10
}
docker_tag_service() {
        echo "docker tag service"
        docker tag service $azurecr/$linux_service_name:$cp_version
        sleep 10
}
docker_push_service() {
        echo "docker push service"
        docker push service $azurecr/$linux_service_name:$cp_version
        sleep 10
}
create_svctype_directory() {
        echo "create svctype directory"
        mkdir -p "$wrk_dir/svctype"
        chmod -R 777 "$wrk_dir/svctype"
        sleep 10
}
process_services_all() {
        echo "process services all"
        cp services.all "$wrk_dir/svctype"
        chmod 777  "$wrk_dir/svctype/services.all"
        sleep 10
}
listing_services_creating_image() {
        echo "listing all the services and createing/pushing image into repository"
	for i in `grep '^type=' "services.all" | awk -F "=" '{print $2}'`;
	do
      		echo "Creating Dockerfile for service $i"
      		{
      		echo "FROM $azurecr/$linux_service_name:$cp_version"
      		echo "WORKDIR $image_work_dir"
      		echo "ENV SVC_NAME $i"
      		echo 'ENTRYPOINT ["/bin/bash","./run.sh","${SVC_NAME}"]'
      		} >> $wrk_dir/svctype/$i.df
                echo "Creating image for the service $i"
                name_lower=`echo $i | tr A-Z a-z`
                docker build -f "$i.df" "$wrk_dir/svctype/" -t $azurecr/$linux_svctype_name/$name_lower:$cp_version
                docker push $azurecr/$linux_svctype_name/$name_lower:$cp_version
                docker image rm $azurecr/$linux_svctype_name/$name_lower:$cp_version
	done
}

linux_software() {
	remove_previous_work_directory
	create_software_directory
	download_software
	process_latest_repo
	process_software_dockerfile
	docker_login
	create_software_docker_image
	docker_tag_software
        docker_push_software
        create_svctype_directory
}
linux_barraone() {
        remove_previous_work_directory
        create_barraone_directory
        install_smbclient
        install_python_pexpect_module
        download_barraone_jar
        process_barraone_dockerfile
        docker_login
        create_docker_image_barraone
        docker_tag_barraone
        docker_push_barraone
        create_svctype_directory
}
linux_service() {
        create_service_directory
        process_service_dockerfile
        create_docker_image_for_service
        docker_login
        docker_tag_service
        docker_push_service
        create_svctype_directory
}
linux_svctype() {
	create_svctype_directory
	process_services_all
	docker_login
	listing_services_creating_image
}

$1