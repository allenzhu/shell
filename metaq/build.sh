#!/bin/bash
TMP_FILE=/tmp/tmp_wget
CURL_BIN=/usr/bin/curl
PROG_NAME=$0
ACTION=$1
SPACE_STR="..................................................................................................."

#切换回调服务器
ARTHUR_CALLBACK_SERVER_HOST="scm.taobao.net"
if [ -f "$HOME/webclient/arthur.pid" ]; then
	NEW_TEMP_HOST=`cat $HOME/webclient/arthur.pid`
	if [ "${NEW_TEMP_HOST}" != "" ]; then
		ARTHUR_CALLBACK_SERVER_HOST="${NEW_TEMP_HOST}"
	fi
fi

SEND_SIGNAL_SERVER_URL="http://${ARTHUR_CALLBACK_SERVER_HOST}/acceptDeploySignal.htm?account=${LOGNAME}&deployStatus="

SEND_PACK_PATH_SERVER_URL="http://${ARTHUR_CALLBACK_SERVER_HOST}/packFileReceive.htm?account=${LOGNAME}&packFilePath="

GET_RSYNC_PATH_SERVER_URL="http://${ARTHUR_CALLBACK_SERVER_HOST}/getRsyncPaths.htm?account=${LOGNAME}"

OPER_SUCCESS_SIGN="Revolution Operate Success"
OPER_FAILED_SIGN="Revolution Operate Failed"

DEPLOY_STATUS_IDLE=0  #空闲
DEPLOY_STATUS_STARTING=2  #开始部署
DEPLOY_STATUS_SVN_UP=31  #开始更新代码
DEPLOY_STATUS_SVN_UP_FAILED=32  #更新代码失败

DEPLOY_STATUS_RESOLVED_CODE_FAILED=38  #解决冲突代码失败

DEPLOY_STATUS_MERGING=41  #开始合并代码
DEPLOY_STATUS_MERGING_CONFLICT=42  #合并代码失败-代码冲突
DEPLOY_STATUS_MERGING_WORK_COPY_NOT_EXIST=43  #合并代码失败-工作拷贝不存在

DEPLOY_STATUS_BINARY_UP=51  #开始更新二方包
DEPLOY_STATUS_BINARY_UP_FAILED=52  #更新二方包失败

DEPLOY_STATUS_BUILDING=61  #开始编译
DEPLOY_STATUS_BUILDING_FAILED=62  #编译失败

DEPLOY_STATUS_RESTARTING_BALANCE=71  #负载均衡开始重启
DEPLOY_STATUS_RESTARTING_BALANCE_FAILED=72  #负载均衡重启失败
DEPLOY_STATUS_RESTARTING=73  #开始重启
DEPLOY_STATUS_RESTARTING_FAILED=74  #重启失败

DEPLOY_STATUS_CHECKING_BALANCE=81  #开始检查负载均衡
DEPLOY_STATUS_CHECKING_BALANCE_FAILED=82  #负载均衡检查失败
DEPLOY_STATUS_CHECKING=83  #开始检查应用状态
DEPLOY_STATUS_CHECKING_FAILED=84  #检查失败

DEPLOY_STATUS_FAILED=98  #部署失败
DEPLOY_STATUS_CANCEL=99  #部署取消
DEPLOY_STATUS_SUCCESS=100  #部署成功

excluderename="shopcenter servicemanager hjuppbridge terminator-search mytaobao tradeadmin mercury dmc htm spueditor" 

shellpath=$0
pwdpath=`pwd`

if [ -L $shellpath ];then
        shellpath=`ls -l $shellpath|awk '{printf $NF}'`
fi

cd `dirname $shellpath`
shellpath=`pwd`
cd $pwdpath
shellpath=`dirname $shellpath`
shellpath="$shellpath/function"

source $HOME/.bash_profile

mvn -version
echo -e "\r"

XMLREADURL="$shellpath/xmlreader_innertext.sh"

PROJECT_WORK=`$shellpath/getprjpath.sh 2>/dev/null` #代码路径

CODE_NAME=`basename $PROJECT_WORK 2>/dev/null` #代码库名

APP_NAME=`basename $PROJECT_WORK 2>/dev/null` #应用名 JBOSS应用目录名

APP_INSTALL="ie pamirs-ie et pamirs-et"

INSTALL_TAG=`echo $APP_INSTALL |grep $APP_NAME |grep -v grep`

if [ ! x"$INSTALL_TAG" = "x" ];then
	
	MVN_INSTALL="install"
else
	MVN_INSTALL=" "	
fi

#BuildTool=`$shellpath/maveninfo.sh $CODE_NAME BuildTool 2>/dev/null`
#PACKAGE_FILE_DIR=`$shellpath/maveninfo.sh $CODE_NAME PACKAGE_FILE_DIR 2>/dev/null`
#PACKAGE_FILE_NAME=`$shellpath/maveninfo.sh $CODE_NAME PACKAGE_FILE_NAME 2>/dev/null`
#PACKAGE_FILE_FOLDER="tadget"
#MavenPackageCmd=`$shellpath/maveninfo.sh $CODE_NAME MavenPackageCmd 2>/dev/null`

MAVEN_ADDTION_CMD=""
if [ `curl --connect-timeout 10 "http://scm.taobao.net/isDailyStandard.htm"` == "true" ];then
	if [[ "$LOGNAME" =~ "test$" ]]; then
		MAVEN_ADDTION_CMD=" com.taobao.land:maven-land-plugin:1.0.0-SNAPSHOT:enforce com.taobao.land:maven-land-plugin:1.0.0-SNAPSHOT:dep -Dland.dep.publish_type=5 -Dland.dep.app_name=$CODE_NAME"
	fi
	if [[ "$LOGNAME" =~ "build$" ]]; then
		MAVEN_ADDTION_CMD=" com.taobao.land:maven-land-plugin:1.0.0-SNAPSHOT:enforce com.taobao.land:maven-land-plugin:1.0.0-SNAPSHOT:dep -Dland.dep.publish_type=0 -Dland.dep.app_name=$CODE_NAME"
	fi
fi

if [ x"$APP_NAME" = "xloginxxx" ];then
MavenPackageCmdWEB="mvn install -U -Dmaven.test.skip=true"
else
MavenPackageCmdWEB="mvn $MVN_INSTALL package -U -Dmaven.test.skip=true"
fi
MavenPackageCmdHSF="mvn $MVN_INSTALL package -U -Dmaven.test.skip=true assembly:assembly"
MavenPackageCmdLand="mvn package -U -Dmaven.test.skip=true"

#WAR=`$shellpath/maveninfo.sh $CODE_NAME WAR 2>/dev/null`
#BuildKey=`$shellpath/maveninfo.sh $CODE_NAME BuildKey 2>/dev/null`
#MoveMode=`$shellpath/maveninfo.sh $CODE_NAME MOVEMODE 2>/dev/null`        
#echo $PROJECT_WORK
#echo $CODE_NAME 
#echo $BuildTool 
#echo $PACKAGE_FILE_DIR 
#echo $PACKAGE_FILE_NAME
#echo $PACKAGE_FILE_FOLDER
#echo $MavenPackageCmd
#echo $WAR
#echo $BuildKey
#echo $MoveMode

echo "XMLREADER $XMLREADURL"
LISTST=0

#日志目录
#LOG_HOME=$HOME/$APP_NAME/logs

#OnlineKey=/opt/taobao/buildkey

#应用日志文件地址
#APP_LOG_FILE_URL=$LOG_HOME/$HOSTNAME/$PROJECT_NAME-debug.log

buildstatus=0

echo -e "\033[33;1m提醒：请确认该应用的配置项是否有变更 \033[0m \r" 
sleep 1


#export PACKAGE_FILE_DIR
#export PACKAGE_FILE_NAME
#export PACKAGE_FILE_FOLDER

prebuild(){

        [ -f  $HOME/$APP_NAME/bin/prebuild.sh ] && . $HOME/$APP_NAME/bin/prebuild.sh

}

afterbuild(){

         [ -f  $HOME/$APP_NAME/bin/afterbuild.sh ] && . $HOME/$APP_NAME/bin/afterbuild.sh
}

lastdo()
{
	[ -f  $HOME/$APP_NAME/bin/lastdo.sh ] && sh $HOME/$APP_NAME/bin/lastdo.sh
}

cleanpackage()
{

        if [ -d $PROJECT_WORK/target ];then
                echo "delete $PROJECT_WORK/target"
                rm -rf $PROJECT_WORK/target
        fi      
        
}   

getprjinfo()
{
if [ "$LISTST" = "1" ];then
	return
fi
	prjtype=""
	if [ -f $PROJECT_WORK/pom.xml ];then
        assemblyst=`cat $PROJECT_WORK/pom.xml|grep "maven-assembly-plugin"|grep -v "grep"`
	packagest=`$XMLREADURL "$PROJECT_WORK/pom.xml" "packaging" 2>/dev/null`
	landst=`cat $PROJECT_WORK/pom.xml|grep "maven-land-plugin"|grep -v "grep"`
	    if [ ! x"$assemblyst" = "x" ];then
		prjtype="hsf"
		elif [ -f $PROJECT_WORK/deploy/pom.xml ];then 
		assemblyst_deploy=`cat $PROJECT_WORK/deploy/pom.xml|grep "maven-assembly-plugin"|grep -v "grep"`
			if [ ! x"$assemblyst_deploy" = "x" ];then
				prjtype="web"
			fi
	    elif [ x"$packagest" = x"war" ] && [ ! x"$landst" = "x" ];then
		prjtype="land"
	    else
		echo"打包格式不正确"
		exit 2
            fi
	
        else
                echo "工程的POM未找到!,退出"
                exit 1
        fi
	case "$prjtype" in
		web)
			echo "打包方式 web"
			cd $PROJECT_WORK/deploy
                	PACKAGE_FILE_FOLDER="deploy/target"
                	MavenPackageCmd=$MavenPackageCmdWEB
			;;
		hsf)
			echo "打包方式 hsf"
			 cd $PROJECT_WORK
                	 PACKAGE_FILE_FOLDER="target"
               		 MavenPackageCmd=$MavenPackageCmdHSF
			;;
		land)	
			echo "打包方式land"
			cd $PROJECT_WORK
                	PACKAGE_FILE_FOLDER="target"
                	MavenPackageCmd=$MavenPackageCmdLand
			;;
	esac
                finalName=`$XMLREADURL "pom.xml" "finalName" 2>/dev/null`
                        if [ ! $? = 0 ];then
                                echo "tgz 包名未得到, 编译错误 , 退出!"
                                exit 2
                        fi

                 st=`echo $finalName |sed 's/^ *//g'|sed 's/ *$//g'|awk '{printf NF}'`
                        if [ x"$st" = "x0" ];then
				finalName=`$XMLREADURL "deploy/pom.xml" "finalName" 2>/dev/null`
				 st=`echo $finalName |sed 's/^ *//g'|sed 's/ *$//g'|awk '{printf NF}'`
				if [ x"$st" = "x0" ];then
                                echo "finalName 读取错误,退出!"
                                exit 3
				fi
                        fi
		
		  if [ ! x"$st" = "x1" ];then
				echo "finlName 设置过多,默认使用最后一项"
				finalName=`echo $finalName |sed 's/^ *//g'|sed 's/ *$//g'|awk '{printf $NF}'`
		  fi

                        echo "finalName = $finalName"
		
		  if [ x"$prjtype" = x"web" ] || [  x"$prjtype" = x"hsf" ];then
			descriptor=`$XMLREADURL "pom.xml" "descriptor" 2>/dev/null`
                        if [ ! $? = 0 ];then
                                echo " descriptor 未得到, 编译错误 , 退出!"
                                exit 4
                        fi

                        st=`echo $descriptor |sed s/" "/""/g|awk '{printf NF}'`

                        if [ ! x"$st" = "x1" ];then
                                echo "descriptor = $descriptor ,个数错误,退出!"
                                exit 5
                        fi

                        echo "descriptor = $descriptor"

                        if [ ! -f $descriptor ];then
                                echo " $descriptor 不存在,编译错误,退出!"
                                exit 6
                        fi
 #                       pwd
 #                       echo "$XMLREADURL "$descriptor" "format""
                        formats=`$XMLREADURL "$descriptor" "format" 2>/dev/null`

                        if [ ! $? = 0 ];then
                                echo " 包的格式读取失败,编译错误,退出!"
                                exit 7
                        fi

                        st=`echo $formats |sed s/" "/""/g|awk '{printf NF}'`

                        if [ ! x"$st" = "x1" ];then
                                echo "formats = $formats ,个数错误,退出!"
                                exit 8
                        fi
                  
			echo "formats = $formats"

                        PACKAGE_FILE_NAME_POM="$finalName.$formats"
                        echo "PACKAGE_FILE_NAME_POM = $PACKAGE_FILE_NAME_POM"
			
			excludefs=`echo $excluderename|grep "\b${APP_NAME}\b"|grep -v grep`
	#		echo "excludefs=$excludefs"
			if [  x"$excludefs" = "x" ] && [ "$formats" = "tar.gz" ];then
				MoveMode="true"
				PACKAGE_FILE_NAME="$finalName.tgz"

			else

				PACKAGE_FILE_NAME=$PACKAGE_FILE_NAME_POM
			fi
			
		  else
			PACKAGE_FILE_NAME=$finalName.war.tgz
		  fi
		     echo "PACKAGE_FILE_NAME = $PACKAGE_FILE_NAME"   

                     LISTST=1
}


build()
{

	sh $shellpath/buildcount.sh #add by jingde
	
	cleanpackage

    cd $HOME
if [ `curl --connect-timeout 10 "http://scm.taobao.net/isDailyHost.htm"` == "true" ];then
        echo "同步配置项."
        /opt/taobao/taurus/release/taurus.sh up

fi
    sed -i 's/\ \+$//' antx.properties

   if [ -d "$HOME/vmcommon" ]; then
                echo "update vmcommon"
                cd $HOME/vmcommon
                svn up --non-interactive
    fi;

#解决冲突代码操作
${shellpath}/merge.sh resolve
if [[ $? = 1 ]];then
	echo " "
	echo "代码解决冲突失败！操作退出"
	exit 1;
fi

curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_MERGING}" > /dev/null
    
#合并代码操作
${shellpath}/merge.sh
if [[ $? = 1 ]];then
	echo " "
	echo "代码合并失败！操作退出"
	exit 1;
fi

    echo "svn up $PROJECT_WORK"
    cd $PROJECT_WORK
    svn up --non-interactive
    ${shellpath}/code.sh workinfo $PROJECT_WORK
    curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_SVN_UP}" > /dev/null

	getprjinfo
			
	echo "begin clean project  mvn clean "
	sleep 1
	cd $PROJECT_WORK
	mvn clean


    	echo "${MavenPackageCmd}${MAVEN_ADDTION_CMD}"
    	curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_BUILDING}" > /dev/null
   	echo "no" | ${MavenPackageCmd}${MAVEN_ADDTION_CMD}

		if [ ! $? = 0 ];then
			echo "编译错误,退出"
			curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_BUILDING_FAILED}" > /dev/null
			exit 1
		fi
		if [ x"$APP_NAME" = "xloginxxx" ];then #delete
			cd web/member
			echo "mvn war:war -Dmaven.test.skip=true"
			mvn war:war -Dmaven.test.skip=true
			cd $PROJECT_WORK
		fi	
		if [ "$prjtype" = "web" ];then
			
			cd $PROJECT_WORK/deploy
			mvn assembly:assembly -Dmaven.test.skip=true
			if [ ! $? = 0 ];then
				echo "assembly错误,退出"
				exit 1
			fi
			
		fi	
		
		if [ "$MoveMode" = "true" ];then
			echo "mv $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME_POM  $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME"
			mv $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME_POM $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME
			if [ ! $? = 0 ];then
			 	echo "rename $PACKAGE_FILE_NAME_POM to $PACKAGE_FILE_NAME error"
			 	exit 1
			fi
		fi

}

checkPackage()
{
    if [ -f "$PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME" ];then
	curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_SUCCESS}" > /dev/null
    else
	curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_FAILED}" > /dev/null
    fi
}

deploy()
{
    preloadstatus=0
	#if [ -f "$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME" ]; then
     if [ -f "$PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME" ];then
        if [ -f $HOME/$APP_NAME/bin/balance.sh ];then
	    curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_RESTARTING_BALANCE}" > /dev/null
            $HOME/$APP_NAME/bin/balance.sh $APP_NAME $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME balance
            if [[ $? = 1 ]];then
            		echo " "
		$HOME/$APP_NAME/bin/balance.sh $APP_NAME $PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME stopcheck
                echo "备机自检错误，主机停止部署"
		$HOME/$APP_NAME/bin/balance.sh $APP_NAME $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME stopcheck
		curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_RESTARTING_BALANCE_FAILED}" > /dev/null
                exit 1;
            else
                preloadstatus=1
            fi 
        fi
		    echo "copy deploy package to local deploy folder"
            echo "cp $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME $HOME/$APP_NAME/target/"
		    curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_RESTARTING}" > /dev/null
		    /bin/cp -af $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME $HOME/$APP_NAME/target/

################################################################################### add by guqi for TCC Depend
if [ `curl --connect-timeout 10 "http://scm.taobao.net/isDailyHost.htm"` == "true" ];then
#cd $HOME/$APP_NAME/bin/
#`sed -i "/tcc-emma-1.0-SNAPSHOT.jar/d" jbossctl`
#`sed -i "/emma.jar/d" jbossctl`
#`sed -i "/tcc_install.pl/d" jbossctl`
StartTarget="$JBOSS_HOME\/bin\/run.sh"
#echo $PROJECT_NAME
EVN_TCC="export JBOSS_CLASSPATH=/home/admin/TCC/lib/emma.jar"
EVN_TCC2="export JBOSS_CLASSPATH=/home/admin/tcc/lib/tcc-emma-1.0-SNAPSHOT.jar"
#EVN_Depend='JAVA_OPTS="\$JAVA_OPTS\ -javaagent:/home/admin/depend/classAgent.jar"'
TargetDepend="export\ JAVA_OPTS"
StartShell="perl /opt/taobao/scriptcenter/tcc_depend/tcc_install.pl \$PROJECT_NAME start;"
StopShell="perl /opt/taobao/scriptcenter/tcc_depend/tcc_install.pl \$PROJECT_NAME stop;"

cd $HOME/$APP_NAME/bin/
#STATE_Depend=`sed -e "/\/home\/admin\/depend\/classAgent.jar/p" -n jbossctl`
#if [  -n "$STATE_Depend" ];then
#echo "$STATE_Depend is deployed."
#else
#`sed -i "/$TargetDepend/i\\ $EVN_Depend" jbossctl`
#
#    if [ ! -d /home/admin/depend ];then
#       mkdir /home/admin/depend
#    fi
# cd /home/admin/depend
# rm -rf classAgent.jar asm-2.2.3-tb.jar
# cp /opt/taobao/scriptcenter/tcc_depend/classAgent.jar /home/admin/depend/
# cp /opt/taobao/scriptcenter/tcc_depend/asm-2.2.3-tb.jar /home/admin/depend/
#   cd /home/admin/tbskip/bin/
# cd $HOME/$APP_NAME/bin/
#fi


STATE_JAR=`sed -e "/emma.jar/p" -n jbossctl`

if [ -n "$STATE_JAR" ];then
`sed -i "/emma.jar/d" jbossctl`
`sed -i "/tcc_install.pl/d" jbossctl`
fi

STATE_TCC=`sed -e "/tcc_install.pl/p" -n jbossctl`
if [  -n "$STATE_TCC" ];then
#`sed -i "/$StartTarget/i\\ $EVN_TCC2" jbossctl`
echo "TCC_Code is deployed."
else
`sed -i "/$StartTarget/i\\ $EVN_TCC2" jbossctl`
`sed -i "/$StartTarget/i\\ $StartShell" jbossctl`

NUM=`sed -n "/stop()/=" jbossctl`
let "NUM=$NUM + 1"
sed -i "$NUM"a\\"$StopShell" jbossctl
fi

else
echo "Not daily host.Don't need install TCC and depend."
cd $HOME/$APP_NAME/bin/
`sed -i "/tcc_install.pl/d" jbossctl`
#`sed -i "/tcc-emma-1.0-SNAPSHOT.jar/d" jbossctl`
`sed -i "/emma.jar/d" jbossctl`
fi
###################################################################################

		    cd $HOME/$APP_NAME/bin/
		  if [ -f jettyctl.sh ];then
			./jettyctl.sh restart
		  else
		    ./jbossctl restart;
		  fi
            
            if [[ $preloadstatus = 0 ]];then
                if [ -f $HOME/$APP_NAME/bin/preload.sh ];then
		   curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_CHECKING}" > /dev/null
		    echo "正在执行自检脚本,请稍后......."
                   result=` $HOME/$APP_NAME/bin/preload.sh`
                   resultA=`echo $result|grep OK`
                        if [[ x"$resultA" = "x" ]];then
				 resultA=`echo $result|grep 确定`
				if [[ x"$resultA" = "x" ]];then
                            		echo "=========== Check FAILED ! EXIT ==============="
					curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_CHECKING_FAILED}" > /dev/null
                            		exit 1;
				fi
                        fi
                fi
            fi
            if [[ $buildstatus != 2 ]];then
            $shellpath/backup.sh $APP_NAME backup
            fi
	    curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_SUCCESS}" > /dev/null
            echo "deploy success!"
	else
		echo "build error! $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME not exist! please check it"
		curl -sf "${SEND_SIGNAL_SERVER_URL}${DEPLOY_STATUS_BUILDING_FAILED}" > /dev/null
	fi
}

restart()
{
	#$HOME/$APP_NAME/bin/jbossctl restart /dev/null 2>&1 &
    
    if [ -f $HOME/$APP_NAME/bin/balance.sh ];then
            echo "start backup machine"
            $HOME/$APP_NAME/bin/balance.sh $APP_NAME $PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME restart
    fi
            echo -e "\e[0mstart main machine"

################################################################################### add by guqi for TCC Depend
if [ `curl --connect-timeout 10 "http://scm.taobao.net/isDailyHost.htm"` == "true" ];then
#cd $HOME/$APP_NAME/bin/
#`sed -i "/tcc-emma-1.0-SNAPSHOT.jar/d" jbossctl`
#`sed -i "/emma.jar/d" jbossctl`
#`sed -i "/tcc_install.pl/d" jbossctl`
StartTarget="$JBOSS_HOME\/bin\/run.sh"
#echo $PROJECT_NAME
EVN_TCC="export JBOSS_CLASSPATH=/home/admin/TCC/lib/emma.jar"
EVN_TCC2="export JBOSS_CLASSPATH=/home/admin/tcc/lib/tcc-emma-1.0-SNAPSHOT.jar"
#EVN_Depend='JAVA_OPTS="\$JAVA_OPTS\ -javaagent:/home/admin/depend/classAgent.jar"'
TargetDepend="export\ JAVA_OPTS"
StartShell="perl /opt/taobao/scriptcenter/tcc_depend/tcc_install.pl \$PROJECT_NAME start;"
StopShell="perl /opt/taobao/scriptcenter/tcc_depend/tcc_install.pl \$PROJECT_NAME stop;"

#STATE_Depend=`sed -e "/\/home\/admin\/depend\/classAgent.jar/p" -n jbossctl`
#if [  -n "$STATE_Depend" ];then
#echo "$STATE_Depend is deployed."
#else
#`sed -i "/$TargetDepend/i\\ $EVN_Depend" jbossctl`
#fi
#if [ ! -d /home/admin/depend ];then
#   mkdir /home/admin/depend
#fi
#   cd /home/admin/depend
#   rm -rf classAgent.jar asm-2.2.3-tb.jar
#   cp /opt/taobao/scriptcenter/tcc_depend/classAgent.jar /home/admin/depend/
#   cp /opt/taobao/scriptcenter/tcc_depend/asm-2.2.3-tb.jar /home/admin/depend/
#   cd /home/admin/tbskip/bin/
   cd $HOME/$APP_NAME/bin/

STATE_JAR=`sed -e "/emma.jar/p" -n jbossctl`

if [ -n "$STATE_JAR" ];then
`sed -i "/emma.jar/d" jbossctl`
`sed -i "/tcc_install.pl/d" jbossctl`
fi

STATE_TCC=`sed -e "/tcc_install.pl/p" -n jbossctl`
if [  -n "$STATE_TCC" ];then
#`sed -i "/$StartTarget/i\\ $EVN_TCC2" jbossctl`
echo "TCC_Code is deployed."
else
`sed -i "/$StartTarget/i\\ $EVN_TCC2" jbossctl`
`sed -i "/$StartTarget/i\\ $StartShell" jbossctl`

NUM=`sed -n "/stop()/=" jbossctl`
let "NUM=$NUM + 1"
sed -i "$NUM"a\\"$StopShell" jbossctl
fi

else
echo "Not daily host.Don't need install TCC and depend."
cd $HOME/$APP_NAME/bin/
`sed -i "/tcc_install.pl/d" jbossctl`
#`sed -i "/tcc-emma-1.0-SNAPSHOT.jar/d" jbossctl`
`sed -i "/emma.jar/d" jbossctl`
fi

###################################################################################
  
    $HOME/$APP_NAME/bin/jbossctl restart /dev/null 2>&1 &
}

up()
{
	echo "antx.properties update"
	/opt/taobao/taurus/release/taurus.sh up
}

diff()
{
	echo "antx.properties diff"
	/opt/taobao/taurus/release/taurus.sh diff
}

cleanup()
{
	echo "antx.properties cleanup"
	/opt/taobao/taurus/release/taurus.sh cleanup
}

revert()
{
$shellpath/backup.sh $APP_NAME revert
 if [ -f $HOME/$APP_NAME/bin/balance.sh ];then
            $HOME/$APP_NAME/bin/balance.sh $APP_NAME $PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME revert
 fi
restart

}


deleteLog()
{
    if [ ! -z "$LOG_HOME" ]; then
        rm -rf $LOG_HOME/*
        echo "======> Log is deleted"
    fi
}

viewlog(){

    tail -f $LOG_HOME/$HOSTNAME/$CODE_NAME-debug.log

}


viewJbosslog(){

    tail -f $LOG_HOME/jboss_stdout.log 

}

listFile()
{
getprjinfo
PACKAGE_FULL_PATH="$PROJECT_WORK/$PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME"
echo ""
echo "$APP_NAME"
echo "HostName:"$HOSTNAME
echo "Path:"$PACKAGE_FULL_PATH
echo "Detail: "`ls -l $PACKAGE_FULL_PATH`
curl -sf "${SEND_PACK_PATH_SERVER_URL}$PACKAGE_FULL_PATH"  > /dev/null 2>&1 &
sleep 1
}

help() {
    echo "Usage: $PROG_NAME {build|deploy|restart|restart|deleteLog|viewlog|viewJbosslog}"
    echo "build:only build code ,package tgz file"
    echo "deploy:deploy the tgz file to target hosts ,and restart server"
    echo "no arg: this will do build and deploy operation"
    exit 1;
}


writetime()
{

date +%F\ %R>~/.timebk

}

readtime()
{
if [ -f ~/.timebk ];then
cat ~/.timebk
else
echo "No time recorded"
fi
}

listtime()
{
        writetime
        readtime

}

#update vmcommon
vmcommon ()
{
        if [ -d "$HOME/vmcommon/.svn" ]; then
                echo "update vmcommon"
                cd $HOME/vmcommon
		svn info
                svn up --non-interactive
        fi
}

getprjinfo #read pom

scpvmcommon ()
{
    echo "开始同步模板！"
    RSYNC_PATH_DATA=`curl -sf ${GET_RSYNC_PATH_SERVER_URL}`
    if [ "${RSYNC_PATH_DATA}" = "" ];then
	echo "${OPER_FAILED_SIGN}:当前环境未设置模版同步信息!";
        exit 0;
    else
    RSYNC_INFO_ARRAY=`echo   "${RSYNC_PATH_DATA}"   |   awk   -F  ';'   '{print   $0}'   |   sed   "s/;/   /g"`
    for singleRsyncInfo in ${RSYNC_INFO_ARRAY}
        do
                sourcePath=`echo ${singleRsyncInfo}|awk   -F   '|'   '{print   $1}'`
                targetPath=`echo ${singleRsyncInfo}|awk   -F   '|'   '{print   $2}'`
		if [ -f $HOME/$APP_NAME/bin/balance.sh ];then
			$HOME/$APP_NAME/bin/balance.sh $APP_NAME $PACKAGE_FILE_FOLDER/$PACKAGE_FILE_NAME scpvmcommon $targetPath
		else 
			echo "未找到备机信息！"
		fi
        done
    fi
}


dotns()
{
	sh /opt/taobao/scriptcenter/tns/tns.sh
}
checkds()
{
        sh /opt/taobao/scriptcenter/ds/ds.sh
}
case "$ACTION" in
    build)
        build
    ;;
    deploy)
	deploy
    ;;
    restart)
        restart
    ;;
     scpvmcommon)
	scpvmcommon
    ;;
    deleteLog)
        deleteLog
    ;;
    viewlog)
        viewlog
    ;;
    viewJbosslog)
        viewJbosslog
    ;;
    help)
	help
    ;;
    show)
        listFile
    ;;
    time)
	readtime
    ;;
    revert)
        revert
    ;;
    vmcommon)
        vmcommon
	;;
    tns)
	dotns
	;;
    up)
        up
    ;;
    diff)
        diff
    ;;
    cleanup)
        cleanup
    ;;
    assets)
        sh /opt/taobao/scriptcenter/function/assets.sh
        ;;
    buildinfo)
	getprjinfo
	;;
   ds)
	checkds
	;;
    *)
	prebuild
	dotns
	checkds
        build
	afterbuild
        listFile
        if [ "$HOME" = "/home/admin" ];then
	. $shellpath/../dtd/dtdtrace.sh "$APP_NAME" "maven_beta"
		deploy
	. $shellpath/../dtd/checkdtdlog.sh "$APP_NAME" "maven_beta"
        else
		checkPackage
        fi
	lastdo
	listtime
    ;;
esac
