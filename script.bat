@echo off
call:%~1
goto exit
*************************************************************************************
*    authored:Pallab Chakraborty
*    Script to create images for all components
**************************************************************************************

:variables
echo "initializing all variables"
set "current_dir=%cd%"
set artifactory=10.96.8.57
set artifactory_user=admin
set artifactory_password=Msci@Dev0ps123456
set wrk_dir=E:\MyWork\test\svctype
set cp_version=3.20.2.0B20
set azurecr=bdddev.azurecr.io
set azurecr_user=bdddev
set azurecr_password=TtjkAS67CpVqVbMYcG=qLBIr9pipi9+M
set windows_base_name=docker/windows/servercore
set windows_base_version=1809
set windows_wrk_dir=/app
set windows_base_vc_name=docker/commonplatform/windows/servercore_vc
set windows_base_vc_version=latest
set barra_software_win=cp-builds/commonplatform/barraone/software_win.zip
set windows_software_name=docker/commonplatform/dev/windows/software
set barra_build_share=\\pn8-st-nfilem02.mgmt.msci.org\dn8_mgmt_an_devqa_cp
set barra_build_dir=StoreFrontCP\BuildRepository\%cp_version%\
set barra_build_share_user=x_envmgmt
set barra_build_share_password=Pr0ject0ne
set windows_cphome=/app/cphome
set windows_barraone_name=docker/commonplatform/dev/windows/barraone
set windows_service_name=docker/commonplatform/dev/windows/service
goto :eof
:remove_previous_work_directory
        echo "remove previous work directory"
        IF EXIST "%wrk_dir%" (
            cd /d %wrk_dir%
            for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q)
        ) ELSE (
                echo "working directory is not available"
        )
goto :eof
:create_baseimage_directory
        echo "create baseimage directory"
        IF EXIST "%wrk_dir%" (
            md "%wrk_dir%\\baseimage"
        ) ELSE (
                echo "working directory is not available"
        )
goto :eof
:copy_windows_baseimage_Common_files
        echo "copy windows baseimage/common files"
        xcopy /E /F "%current_dir%\commonfiles\windows\baseimage\*.*"  "%wrk_dir%\\baseimage"
:process_dockerfile_base_vc
        echo "process dockerfile base_vc.df"
        (
        echo FROM %azurecr%/%windows_base_name%:%windows_base_version%        

        echo COPY . %windows_wrk_dir%
        echo WORKDIR %windows_wrk_dir%

        echo RUN Common\CRT9.0\setup.exe  /S /v/qn
        echo RUN Common\2k5_vcredist_x64_v1.exe /q
        echo RUN Common\2k5_vcredist_x64_v2.exe /q
        echo RUN Common\2k8_vcredist_x64_v1.exe /q
        echo RUN Common\2k8_vcredist_x64_v2.exe /q
        echo RUN Common\2k10_vcredist_x64.exe /q /norestart
        echo RUN Common\2k10_vcredist_x86.exe /q /norestart
        echo RUN Common\2k13_vcredist_x64.exe /install /quiet /norestart
        echo RUN Common\2k13_vcredist_x86.exe /install /quiet /norestart
        echo RUN reg add HKLM\system\currentcontrolset\services\afd\parameters /v enabledynamicbacklog /t REG_DWORD /d 0x1 /f
        echo RUN reg add hklm\system\currentcontrolset\services\afd\parameters /v dynamicbackloggrowthdelta /t REG_DWORD /d 16 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\afd\parameters /v minimumdynamicbacklog /t REG_DWORD /d 0x20 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\afd\parameters /v maximumdynamicbacklog /t REG_DWORD /d 0x4e20 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\afd\parameters /v NonBlockingSendSpecialBuffering /t REG_DWORD /d 0x1 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v maxuserport /t REG_DWORD /d 0xfffe /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v tcptimedwaitdelay /t REG_DWORD /d 0x1e /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v TcpMaxDataRetransmissions /t REG_DWORD /d 6 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v tcpmaxconnectresponseretransmissions /t REG_DWORD /d 0x2 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v tcpmaxhalfopen /t REG_DWORD /d 0x1f4 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v tcpmaxhalfopenretried /t REG_DWORD /d 0x190 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v tcpmaxportsexhausted /t REG_DWORD /d 0x5 /f
        echo RUN reg add HKLM\system\currentcontrolset\services\tcpip\parameters /v tcpwindowsize /t REG_DWORD /d 0xfaf0 /f
        echo RUN fsutil behavior set disablelastaccess 1
        echo RUN fsutil behavior set mftzone 4
        echo RUN fsutil behavior set SymlinkEvaluation R2R:1
        echo RUN fsutil behavior set SymlinkEvaluation L2L:1
        echo RUN fsutil behavior set SymlinkEvaluation L2R:1
        echo RUN fsutil behavior set SymlinkEvaluation R2L:1
        echo RUN copy /y Common\msvcr71.dll C:\Windows\SysWOW64
        echo RUN copy /y Common\msvcp71.dll C:\Windows\SysWOW64

        echo ENTRYPOINT ["cmd.exe"]
        )>>"%wrk_dir%\\baseimage\\Dockerfile"
goto :eof
:docker_login
        echo "docker login"
        docker login %azurecr% -u %azurecr_user% -p %azurecr_password%
goto :eof
:create_docker_image_with_vc
        echo "create docker image with vc"
        IF EXIST "%wrk_dir%\\baseimage\\Dockerfile" (
            cd "%wrk_dir%\\baseimage\\"
            docker build -f Dockerfile -t windowsservercore_vc .
        ) ELSE (
            echo "Dockerfile is not available"
        )
goto :eof
:docker_tag_base_image
        echo "docker tag base image"
        docker tag windowsservercore_vc %azurecr%/%windows_base_vc_name%:%windows_base_vc_version%
goto :eof
:docker_push_base_image
        echo "docker push base image"
        docker push %azurecr%/%windows_base_vc_name%:%windows_base_vc_version%
goto :eof
:create_software_directory
        echo "create software directory"
        IF EXIST "%wrk_dir%" (
            md "%wrk_dir%\\software"
        ) ELSE (
            echo "working directory is not available"
        )
goto :eof
:download_software  
        echo "download software"
        IF EXIST "%wrk_dir%" (
            powershell -command "& { (New-Object Net.WebClient).DownloadFile(http://%artifactory%/artifactory/%barra_software_win% ,'%wrk_dir%\\software\\software.zip') }"
            IF %ERRORLEVEL% GEQ 1 (
                EXIT /B 1
            ) ELSE (
                echo "extracting the zip file"
                "C:\Program Files\7-Zip\7z.exe" x %wrk_dir%\\software\\software.zip -o %wrk_dir%\\software\\
            )
        ) ELSE (
            echo "working directory not available"
        )
goto :eof
:process_software_dockerfile
        echo "process software dockerfile"
        (
        echo FROM %azurecr%/%windows_base_vc_name%:%windows_base_vc_version%

        echo COPY activemq %windows_wrk_dir%/activemq
        echo COPY ant %windows_wrk_dir%/ant
        echo COPY apache %windows_wrk_dir%/apache
        echo COPY apache-maven %windows_wrk_dir%/apache-maven
        echo COPY gnuPG %windows_wrk_dir%/gnuPG
        echo COPY gradle-2.0 %windows_wrk_dir%/gradle-2.0
        echo COPY gwt %windows_wrk_dir%/gwt
        echo COPY infinispan %windows_wrk_dir%/infinispan
        echo COPY Intex %windows_wrk_dir%/Intex
        echo COPY jdk %windows_wrk_dir%/jdk
        echo COPY jdk64 %windows_wrk_dir%/jdk64
        echo COPY jfreechart %windows_wrk_dir%/jfreechart
        echo COPY mks %windows_wrk_dir%/mks
        echo COPY oracle %windows_wrk_dir%/oracle
        echo COPY protobuf %windows_wrk_dir%/protobuf
        echo COPY ruby %windows_wrk_dir%/ruby
        echo COPY scala-2.11.8 %windows_wrk_dir%/scala-2.11.8
        echo COPY ssl_trust %windows_wrk_dir%/ssl_trust
        echo COPY tomcat %windows_wrk_dir%/tomcat
        echo COPY tools %windows_wrk_dir%/tools
        echo WORKDIR %windows_wrk_dir%
        echo ENTRYPOINT ["cmd.exe"]
        )>>"%wrk_dir%\\software\\Dockerfile"
goto :eof
:create_software_docker_image
        echo "create software docker image"
        IF EXIST "%wrk_dir%\\software\\Dockerfile" (
            cd "%wrk_dir%\\software\\"
            docker build -f Dockerfile -t windowsservercore_vc .
        ) ELSE (
            echo "Dockerfile is not available"
        )
goto :eof
:docker_tag_software
        echo "docker tag software"
        docker tag software %azurecr%/%windows_software_name%:%cp_version%
goto :eof
:docker_push_software
        echo "docker push software"
        docker push %azurecr%/%windows_software_name%:%cp_version%
goto :eof
:create_barraone_directory
        echo "create barraone directory"
        IF EXIST "%wrk_dir%" (
            md "%wrk_dir%\\barraone\\cphome"
        ) ELSE (
                echo "working directory is not available"
        )
goto :eof
:download_barraone_jar
        echo "download barraone jar"
        where net.exe >nul 2>nul
        IF ERRORLEVEL 0 (
            echo "net is available"
            "C:\Windows\System32\net.exe" use %barra_build_share% /user:%barra_build_share_user% %barra_build_share_password%
            IF ERRORLEVEL 0 (
            echo "downloading the barraone jar"
                robocopy %barra_build_share%\%barra_build_dir% %wrk_dir%\deploy_BarraOne_%cp_version%.jar
                move /y %wrk_dir%\deploy_BarraOne_%cp_version%.jar %wrk_dir%\barraone.jar
            )   
        )
goto :eof
:extract_barraone_jar
        echo "extract barraone jar"
        "C:\Program Files\7-Zip\7z.exe" x %wrk_dir%\\barraone.jar -o %wrk_dir%\\barraone\\cphome
goto :eof
:process_barraone_dockerfile
        echo "process barraone dockerfile"
        (
        echo FROM %azurecr%/%windows_software_name%:%cp_version%
        echo COPY b1tools %windows_cphome%/b1tools
        echo COPY bin %windows_cphome%/bin
        echo COPY bluebox-direct %windows_cphome%/bluebox-direct
        echo COPY calengine %windows_cphome%/calengine
        echo COPY calengine-3rdparty %windows_cphome%/calengine-3rdparty
        echo COPY cb %windows_cphome%/cb
        echo COPY dbpatch %windows_cphome%/dbpatch
        echo COPY dumps %windows_cphome%/dumps
        echo COPY etc %windows_cphome%/etc
        echo COPY hcpademo %windows_cphome%/hcpademo
        echo COPY install %windows_cphome%/install
        echo COPY integrityTest %windows_cphome%/integrityTest
        echo COPY lib %windows_cphome%/lib
        echo COPY md5 %windows_cphome%/md5
        echo COPY META-INF %windows_cphome%/META-INF
        echo COPY monitortool %windows_cphome%/monitortool
        echo COPY optimizer %windows_cphome%/optimizer
        echo COPY pdfuploader %windows_cphome%/pdfuploader
        echo COPY rmdr %windows_cphome%/rmdr
        echo COPY spotfire %windows_cphome%/spotfire
        echo COPY update %windows_cphome%/update
        echo COPY usr %windows_cphome%/usr
        echo COPY var %windows_cphome%/var
        echo COPY webapps %windows_cphome%/webapps
        echo WORKDIR %windows_wrk_dir%
        echo ENTRYPOINT ["cmd.exe"]
        )>>"%wrk_dir%\\barraone\\cphome\\Dockerfile"
goto :eof
:create_docker_image_barraone
        echo "create docker image barraone"
        IF EXIST "%wrk_dir%\\barraone\\cphome\\Dockerfile" (
            echo "creating image"
            cd "%wrk_dir%\\barraone\\cphome\\"
            docker build -f Dockerfile -t barraone .
goto :eof
:docker_tag_barraone
        echo "docker tag barraone"
        docker tag barraone %azurecr%/%windows_barraone_name%:%cp_version%
goto :eof
:docker_push_barraone
        echo "docker push barraone"
        docker push %azurecr%/%windows_barraone_name%:%cp_version%
goto :eof
:create_service_directory
        echo "create service directory"
        IF NOT EXIST "%wrk_dir%/service" (
                echo "creating directory"
                md "%wrk_dir%/service"
        ) ELSE (
              echo "service directory already available"  
        )
goto :eof
:process_service_dockerfile
        echo "process service dockerfile"
        IF EXIST "%wrk_dir%/service" (
                echo "creating the dockerfile for service"
                (
                echo FROM %azurecr%/%windows_barraone_name%:%cp_version%

                echo COPY run.bat %windows_wrk_dir%

                echo ENV CPHOME z:/cphome
                echo ENV SOFTWARE_HOME_REMOTE z:/software
                echo ENV CPHOME_LOCAL c:/app/cphome
                echo ENV SOFTWARE_HOME c:/app/software
                echo WORKDIR %windows_wrk_dir%
                echo ENTRYPOINT ["cmd.exe","/c","run.bat"]
                )>>"%wrk_dir%\\service\\Dockerfile"
        ) ELSE (
              echo "service directory not available"  
        )
goto :eof
:process_run_file
        echo "process run.bat"
        IF EXIST "%wrk_dir%/service" (
                echo "copy run file"
                xcopy /E "%current_dir%\\common\\windows\\run.bat"  "%wrk_dir%\\service"
        ) ELSE (
                echo "service directory not available"
        )
goto :eof
:create_docker_image_for_service
        echo "create docker image for service"
        IF EXIST "%wrk_dir%\\service\\Dockerfile" (
            cd "%wrk_dir%\\service\\"
            docker build -f Dockerfile -t service .
        ) ELSE (
            echo "Dockerfile is not available"
        )
goto :eof
:docker_tag_service
        echo "docker tag service"
        docker tag service %azurecr%/%windows_service_name%:%cp_version%
goto :eof
:docker_push_service
        echo "docker push service"
        docker push %azurecr%/%windows_service_name%:%cp_version%
goto :eof
:create_svctype_directory
        echo "create svctype directory"
        IF NOT EXIST "%wrk_dir%/svctype" (
                echo "creating directory"
                md "%wrk_dir%/svctype"
        ) ELSE (
              echo "svctype directory already available"  
        )
goto :eof
:process_services_all
        echo "process services all"
        IF EXIST "%wrk_dir%/svctype" (
                echo "copy service.all file"
                xcopy /E "%current_dir%\common\windows\services.all" "%wrk_dir%\\svctype"
        ) ELSE (
                echo "svctype directory not available"        
        )
goto :eof
:listing_all_servcies_from_services_all
        echo "listing all servcies from services_all"
        cd "%wrk_dir%\\svctype\\"
        FOR /F "tokens=2 delims==" %%a in ('findstr /B /I "type=" services.all') DO (
                echo "service type is %%a"
                (
                echo FROM %azurecr%/%windows_service_name%:%cp_version%
                echo WORKDIR %windows_wrk_dir%
                echo ENV SVC_NAME %%a
                echo ENTRYPOINT ["cmd.exe","/c","run.bat","%%a"]
                )>"%wrk_dir%\\svctype\\%%a.df"
		FOR /F "tokens=*" %%g IN ('lowercase.cmd %%a') do (
		cd "%wrk_dir%\\svctype\\"
		docker tag %%g %azurecr%/%windows_svctype_name%/%%g:%cp_version%
		docker push %azurecr%/%windows_svctype_name%/%%g:%cp_version%
		)
        )
:windows_base_vc
echo "process started for windowsservercore_vc"
call :variables
call :remove_previous_work_directory
call :create_baseimage_directory
call :copy_windows_baseimage_Common_files
call :process_dockerfile_base_vc
call :docker_login
call :create_docker_image_with_vc
call :docker_tag_base_image
call :docker_push_base_image
goto :eof
:windows_software
echo "process started for windows software"
call :variables
call :remove_previous_work_directory
call :create_baseimage_directory
call :create_software_directory
call :download_software
call :process_software_dockerfile
call :docker_login
call :create_software_docker_image
call :docker_tag_software
call :docker_push_software
goto :eof
:windows_barraone
echo "process started for windows barraone"
call :variables
call :remove_previous_work_directory
call :create_baseimage_directory
call :create_barraone_directory
call :download_barraone_jar
call :extract_barraone_jar
call :process_barraone_dockerfile
call :docker_login
call :create_docker_image_barraone
call :docker_tag_barraone
call :docker_push_barraone
goto :eof
:windows_service
echo "process started for windows service"
call :variables
call :create_service_directory
call :process_service_dockerfile
call :process_run_file
call :create_docker_image_for_service
call :docker_login
call :docker_tag_service
call :docker_push_service
goto :eof
:linux_svctype
echo "process started for linux svctype"
call :variables
call :create_svctype_directory
call :process_services_all
call :docker_login
call :listing_all_servcies_from_services_all
goto :eof