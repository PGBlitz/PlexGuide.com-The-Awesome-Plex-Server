#!/bin/bash
#
# GitHub:   https://github.com/Admin9705/PlexGuide.com-The-Awesome-Plex-Server
# Author:   Admin9705
# URL:      https://plexguide.com
#
# PlexGuide Copyright (C) 2018 PlexGuide.com
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

# Create Variables (If New) & Recall
variable () {
  file="$1"
  if [ ! -e "$file" ]; then echo "$2" > $1; fi
}

### GEN STARTED
bash /opt/plexguide/menu/interface/install/scripts/yml-gen.sh &>/dev/null &

###################### FOR VARIABLS ROLE SO DOESNT CREATE RED - START
file="/var/plexguide"
if [ ! -e "$file" ]; then
   mkdir -p /var/plexguide 1>/dev/null 2>&1
   chown 0755 /var/plexguide 1>/dev/null 2>&1
   chmod 1000:1000 /var/plexguide 1>/dev/null 2>&1
fi

file="/opt/appdata/plexguide"
if [ ! -e "$file" ]; then
   mkdir -p /opt/appdata/plexguide 1>/dev/null 2>&1
   chown 0755 /opt/appdata/plexguide 1>/dev/null 2>&1
   chmod 1000:1000 /opt/appdata/plexguide 1>/dev/null 2>&1
fi

###################### FOR VARIABLS ROLE SO DOESNT CREATE RED - START
variable /var/plexguide/pgfork.project "NOT-SET"
variable /var/plexguide/pgfork.version "NOT-SET"
variable /var/plexguide/tld.program "NOT-SET"
variable /opt/appdata/plexguide/plextoken "NOT-SET"
variable /var/plexguide/server.ht "NOT-SET"
variable /var/plexguide/server.email "NOT-SET"
variable /var/plexguide/server.domain "NOT-SET"

hostname -I | awk '{print $1}' > /var/plexguide/server.ip
###################### FOR VARIABLS ROLE SO DOESNT CREATE RED - END
echo "export NCURSES_NO_UTF8_ACS=1" >> /etc/bash.bashrc.local
mkdir /var/plexguide/ 1>/dev/null 2>&1

#clear warning messages
for txtfile in certchecker nopassword pingchecker; do
  echo -n '' > /var/plexguide/$txtfile; done

# security scan
bash /opt/plexguide/scripts/startup/pg-auth-scan.sh &
# traefik cert validation
bash /opt/plexguide/scripts/startup/certchecker.sh &

# copying rclone config to user incase bonehead is not root
cp /root/.config/rclone/rclone.conf ~/.config/rclone/rclone.conf 1>/dev/null 2>&1

# run pg main
bash /opt/plexguide/pg.sh
file="/var/plexguide/update.failed"
if [ -e "$file" ]; then rm -rf /var/plexguide/update.failed
  exit; fi

## Selects an edition
touch /var/plexguide/pg.edition
edition=$( cat /var/plexguide/pg.edition )
if [ "$edition" == "PG Edition - GDrive" ]; then a=b
elif [ "$edition" == "PG Edition - HD Multi" ]; then a=b
elif [ "$edition" == "PG Edition - HD Solo" ]; then a=b
elif [ "$edition" == "PG Edition - GCE Feed" ]; then
    bash /opt/plexguide/menu/interface/gce/gcechecker.sh
else
    file="/var/plexguide/pg.preinstall.stored"
    if [ -e "$file" ]; then
      touch /var/plexguide/pg.edition
      bash /opt/plexguide/menu/interface/install/scripts/edition.sh
      bash /opt/plexguide/pg.sh
    fi
fi

#################################################################################

# Touch Variables Incase They Do Not Exist
touch /var/plexguide/pg.edition
touch /var/plexguide/pg.serverid
touch /var/plexguide/pg.number
touch /var/plexguide/traefik.deployed
touch /var/plexguide/server.ht
touch /var/plexguide/server.ports

# Call Variables
edition=$(cat /var/plexguide/pg.edition)
serverid=$(cat /var/plexguide/pg.serverid)
pgnumber=$(cat /var/plexguide/pg.number)

# Declare Traefik Deployed Docker STate
docker ps --format '{{.Names}}' | grep traefik > /var/plexguide/traefik.deployed
traefik=$(cat /var/plexguide/traefik.deployed)
if [ "$traefik" == "" ]; then
  traefik="NOT DEPLOYED"
else
  traefik="DEPLOYED"
fi

# For ZipLocations
file="/var/plexguide/data.location"
if [ ! -e "$file" ]; then echo "/opt/appdata/plexguide" > /var/plexguide/data.location; fi

space=$(cat /var/plexguide/data.location)
used=$(df -h /opt/appdata/plexguide | tail -n +2 | awk '{print $3}')
capacity=$(df -h /opt/appdata/plexguide | tail -n +2 | awk '{print $2}')
percentage=$(df -h /opt/appdata/plexguide | tail -n +2 | awk '{print $5}')

edition=$( cat /var/plexguide/pg.edition )
if [ "$edition" == "PG Edition - GDrive" ]; then a=b
elif [ "$edition" == "PG Edition - GDrive" ]; then a=b
elif [ "$edition" == "PG Edition - HD Multi" ]; then a=b
elif [ "$edition" == "PG Edition - HD Solo" ]; then a=b; fi
# Menu Interface
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌎  $edition - $pgnumber - $serverid
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌵  PG Disk Used Space: $used of $capacity | $percentage Used Capacity

EOF
if [ "$edition" == "PG Edition - GDrive" ]; then echo "1 - Mounts & Data Transports"
elif [ "$edition" == "PG Edition - GCE Feed" ]; then echo "1 - Mounts & Data Transports"
elif [ "$edition" == "PG Edition - HD Multi" ]; then echo "1 - MultiHD Mount Deployment"
elif [ "$edition" == "PG Edition - HD Solo" ]; then echo "1 - No Mounts for Solo HD"; fi
tee <<-EOF
2 - Traefik & TLD Deployment [$traefik]
3 - PG Apps: [Installer]
4 - PG Apps: [UnInstall]
5 - Tools & Services
6 - Settings
7 - Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
# Standby
read -p 'Type a Number | Press [ENTER]: ' typed < /dev/tty

  if [ "$typed" == "1" ]; then

    if [ "$edition" == "PG Edition - GDrive" ]; then bash /opt/plexguide/menu/transport/transport.sh
    elif [ "$edition" == "PG Edition - GCE Feed" ]; then bash /opt/plexguide/menu/transport/transport.sh
    elif [ "$edition" == "PG Edition - HD Multi" ]; then bash /opt/plexguide/menu/multihd/scripts/main.sh
    elif [ "$edition" == "PG Edition - HD Solo" ]; then
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔️ WARNING! - Using Solo HD Edition! You Cannot Set Mounts! Restarting!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
sleep 3
     fi

elif [ "$typed" == "2" ]; then
  bash /opt/plexguide/menu/traefik/traefik.sh
elif [ "$typed" == "3" ]; then
  bash /opt/plexguide/menu/apps/apps.sh
elif [ "$typed" == "4" ]; then
  bash /opt/plexguide/menu/removal/removal.sh
elif [ "$typed" == "5" ]; then
  bash /opt/plexguide/menu/tools/tools.sh
elif [ "$typed" == "6" ]; then
  bash /opt/plexguide/menu/settings/settings.sh
elif [ "$typed" == "7" ]; then
  bash /opt/plexguide/roles/ending/ending.sh
  exit
else
  bash /opt/plexguide/menu/start/start.sh
  exit
fi

bash /opt/plexguide/menu/start/start.sh
exit
