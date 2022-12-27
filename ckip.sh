#!/bin/bash

#v2.7.1
clear
shnm=${BASH_SOURCE##*/}

time=$(date)
echo "--------------"
echo "执行时间$time"
sleep 1

if [ ! -f "/root/$shnm" ];
	then
		echo "文件没有存放在/root目录下，执行失败"
		exit
	else
#创建日志文件夹
echo "--------------"
echo "正在检测日志文件夹"
sleep 1
if [ ! -d "/root/log/" ];
	then
		echo "--------------"
		echo "正在创建日志文件夹"
		mkdir /root/log
	else
		echo "--------------"
		echo "当前已存在日志文件夹"
fi

#首次使用设置DDNS域名
echo "--------------"
echo "正在检测本地是否存在DDNS域名文件"
if [ -f "/root/log/ddns" ];
	then
		sleep 1
		echo "--------------"
		ymdz=`cat /root/log/ddns`
		echo "已读取到DDNS域名文件"
		echo "$ymdz"
	else
		sleep 1
		echo "--------------"
		echo "首次使用请输入DDNS域名!"
		echo "写入该文件内/root/log/ddns"
		echo "如有变化请手动修改"
		read -p "请输入域名 >>" ddns
		echo "$ddns" > /root/log/ddns
		ymdz=`cat /root/log/ddns`
fi


echo "--------------"
echo "等待5秒后开始启动"
sleep 2



#判断和写入定时脚本
sleep 3
echo "--------------"
echo "正在判断定时命令,执行日志保存在/root/log/iplog"
#设置定时
echo "--------------"
echo "正在检测定时任务设置"
if [ -f "/root/log/ds" ];
	then
		sleep 1
		echo "--------------"
		cronds=`cat /root/log/ds`
		echo "当前为每 $cronds 分钟检测一次"
	else
		sleep 1
		echo "--------------"
		echo "首次使用请设定IP变动检测间隔时间,单位分钟"
		echo "写入该文件内/root/log/ds"
		echo "如有变化请手动修改"
		read -p "请输入数字 >>" ds
		echo "$ds" > /root/log/ds
		cronds=`cat /root/log/ds`
fi
dspd=`cat /var/spool/cron/root | grep $shnm`
#定时任务执行时间*(分) *(时) *(日) *(月) *(周几)
dsml='*/'$cronds' * * * * /root/'$shnm' > /root/log/iplog'
#定义每周日5：30删除日志
scrz='30 5 * * 7 rm -f /root/log/lsip /root/log/iplog'
#判断是否添加相关命令
if [ "$dspd" = "$dsml" ];
	then
		echo "--------------"
		echo "crontab中存在相关定时命令，不需要添加"
	else
		echo "--------------"
		echo "正在添加相关的定时命令"
		sed -i '/'$shnm'/d' /var/spool/cron/root
		sed -i '/rm -f/d' /var/spool/cron/root 		
		echo "$dsml" >> /var/spool/cron/root
		echo "$scrz" >> /var/spool/cron/root
fi

#重启定时服务
sleep 1
systemctl reload crond

#读取原IP
oldip=`cat /home/neople/game/cfg/siroco11.cfg | grep 'nxj_ipg_ip' | awk -F '= ' '{print $2}'`
if [ "Z$oldip" = "Z" ]; then
	echo "没有频道文件！"
	exit
fi
echo "--------------"
echo "当前频道文件内IP为 $oldip"
sleep 2
#读取现在的IP
newip=`ping $ymdz -c 1 -w 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
if [ "Z$newip" == "Z" ]; then
	echo "DDNS获取IP为空，执行失败，请检查!"
	exit
fi
echo "--------------"
echo "当前DDNS取得IP为 $newip"
echo "--------------"
#读取第三方软件的获取的IP
sleep 2
ulip=`curl -sL --connect-timeout 3 ns1.dnspod.net:6666`
if [ "Z$ulip" == "Z" ]; then
	ulip=`curl -sL --connect-timeout 3 http://ifconfig.me/ip`
fi
if [ "Z$ulip" == "Z" ]; then
	ulip=`curl -sL --connect-timeout 3 https://checkip.amazonaws.com`
fi
if [ "Z$ulip" == "Z" ]; then
	ulip=`curl -sL --connect-timeout 3 whatismyip.akamai.com`
fi
if [ "Z$ulip" == "Z" ]; then
	echo "IP网站获取IP为空，执行失败，请检查!"
	exit
fi
echo "当前IP网站取得IP为 $ulip"
sleep 2
echo "--------------"
echo "正在保存频道文件中历史IP记录"
echo "$time" >> /root/log/lsip
echo "$oldip" >> /root/log/lsip
echo "--------------" >> /root/log/lsip
sleep 2

#比对IP判断是否需要替换
if [ "$newip" = "$ulip" ];
	then
		if [ "$ulip" = "$oldip" ];
			then
				echo "--------------"
				echo "三方获取IP相同，不需要进行替换"
				FWQ=closs
			else
				echo "--------------"
				echo "公网IP与频道内IP不同，将进行替换！"
				sleep 3
				#替换频道11、56的IP地址,可添加对应的频道文件。
				sed -i "s/${oldip}/${newip}/g" /home/neople/game/cfg/siroco11.cfg
				sed -i "s/${oldip}/${newip}/g" /home/neople/game/cfg/siroco56.cfg
				FWQ=open
		fi
	else
		echo "--------------"
		echo "三方获取的IP不相同，请排查！"
		exit
fi	

#判断频道的文件全部IP地址是否都修改正确
sleep 1
echo "--------------"
echo "校验频道文件内IP是否全部更改"
bfip1=`cat /home/neople/game/cfg/siroco11.cfg | grep 'ip' | head -n 1| awk -F '= ' '{print $2}'`
bfip2=`cat /home/neople/game/cfg/siroco11.cfg | grep 'udp_ip_of_hades' | head -n 1| awk -F '= ' '{print $2}'`
bfip3=`cat /home/neople/game/cfg/siroco11.cfg | grep 'ipg_ip' | head -n 1| awk -F '= ' '{print $2}'`
bfip4=`cat /home/neople/game/cfg/siroco11.cfg | grep 'relay_ip' | head -n 1| awk -F '= ' '{print $2}'`
bfip5=`cat /home/neople/game/cfg/siroco11.cfg | grep 'stun_ip' | head -n 1| awk -F '= ' '{print $2}'`

if [ "Z$bfip1" == "Z" ]; then
	bfip=no
	echo "--------------"
	echo "频道文件内IP地址为空！请手动检查频道文件IP！"
	exit
	else
		if [ "$bfip1" == "$bfip2" ]; then
			bfip=ok1
			echo "--------------"
			echo "udp_ip_of_hades 字段更改正常"
			if [ "$bfip2" == "$bfip3" ]; then
			bfip=ok2
			echo "ipg_ip 字段更改正常"
				if [ "$bfip3" == "$bfip4" ]; then
				bfip=ok3
				echo "relay_ip 字段更改正常"
					if [ "$bfip4" == "$bfip5" ]; then
					bfip=ok4
					echo "stun_ip 字段更改正常"
					fi
				fi
			fi
		fi
fi

sleep 1
if [ "$bfip" == "ok4" ]; 
	then
		echo "--------------"
		echo "频道文件IP一致"
	else
		echo "--------------"
		echo "频道文件中IP不一致，请排查"
		exit
fi


#创建服务执行脚本
sleep 1
echo "--------------"
echo "正在检测服务端执行脚本"
if [ -f "/root/log/dnfrun.sh" ];
	then
		echo "--------------"
		echo "已创建执行文件/root/log/dnfrun.sh"
	else
		#判断是否需要执行统一网关
		sleep 1
		if [ -f "/root/GateRestart" ];
			then
				echo "--------------"
				echo "存在统一网关启动文件，将写入执行脚本"
				echo "#!/bin/bash" >> /root/log/dnfrun.sh
				echo "/root/GateRestart > /root/log/wglog 2>&1" >> /root/log/dnfrun.sh
		fi
		echo "--------------"
		echo "正在创建执行文件/root/log/dnfrun.sh"
		echo "/root/stop > /root/log/stoplog 2>&1" >> /root/log/dnfrun.sh
		echo "/root/stop > /root/log/stoplog 2>&1" >> /root/log/dnfrun.sh
		echo "/root/dprun" >> /root/log/dnfrun.sh
		chmod 755 /root/log/dnfrun.sh
fi

#执行服务器运行判断
sleep 1
echo "--------------"
echo "正在判断是否需要启动服务器"
sleep 1
PIDS=`ps -ef |grep 'df_game_r siroco11 start' |grep -v grep`
if [ "$FWQ" = "closs" ];
	then
		if [ "$PIDS" != "" ];
			then
				echo "--------------"
				echo "服务器可能正在运行中,如果不确定可手动执行/root/log/dnfrun.sh"
			else
				echo "--------------"
				echo "未发现服务端进程，将自动执行启动服务"
				sleep 1
				echo "--------------"
				sleep 1
				chmod 755 /root/log/dnfrun.sh
				/root/log/dnfrun.sh
		fi
	else
		echo "--------------"
		echo "检测到频道文件内IP发生变动，5秒后将重启服务器"
		sleep 5
		/root/stop > /root/log/stoplog 2>&1
		sleep 1
		/root/stop > /root/log/stoplog 2>&1
		sleep 1
		/root/dprun
fi	

echo "--------------"
echo "IP检测脚本执行完毕"
time2=$(date)
echo "--------------"
echo "结束时间$time2"
echo "--------------"
fi
