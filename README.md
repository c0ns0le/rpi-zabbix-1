# rpi-zabbix
Zabbix 3.0 service on single docker container for RaspberryPi

**Prerequirements:**
* docker installed
* machine with arm architecture, prefered RaspberryPi with Raspbian

To create docker image please download repository to your local drive

`git clone https://github.com/tomaszderkowski/rpi-zabbix.git`

Enter to created directory 

`cd rpi-zabbix`

then build the image from dockerfile:

`docker build .`

After few minutes you can run docker container

`docker container run -d -p 80:80 -p 3306:3306 -p 10051:10051`

This command map all ports http, mysql and zabbix server.

_port 3306 is optional if we dont need access to mysql server from outside_

