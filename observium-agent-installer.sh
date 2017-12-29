#!/bin/bash

# Exit if there is an error
set -e


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If script is executed as an unprivileged user
# Execute it as superuser, preserving environment variables
if [ $EUID != 0 ]; then
    sudo -E "$0" "$@"
    exit $?
fi

# If there is an .env file use it
# to set the variables
if [ -f $SCRIPT_DIR/.env ]; then
    source $SCRIPT_DIR/.env
fi

# Check all required variables are set
: "${OBSERVIUM_SVN_USERNAME:?must be set}"
: "${OBSERVIUM_SVN_PASSWORD:?must be set}"
: "${OBSERVIUM_SERVER_IP:?must be set}"
: "${OBSERVIUM_DEFAULT_SNMPV2C_COMMUNITY:?must be set}"

# Install required packages
/usr/bin/apt update -y
/usr/bin/apt install -y snmpd xinetd subversion

# Download the "scripts" directory only from subversion
/usr/bin/svn checkout --username "$OBSERVIUM_SVN_USERNAME" --password "$OBSERVIUM_SVN_PASSWORD" \
                      --non-interactive \
                      --depth empty \
                      http://svn.observium.org/svn/observium/branches/stable /tmp/observium

cd /tmp/observium && /usr/bin/svn update --username "$OBSERVIUM_SVN_USERNAME" --password "$OBSERVIUM_SVN_PASSWORD" \
                     --set-depth infinity scripts \

# Copy the xinetd config file into place
cp /tmp/observium/scripts/observium_agent_xinetd /etc/xinetd.d/observium_agent_xinetd

# Add the Observium server's IP address to the config file
sed -i "s/127.0.0.1/$OBSERVIUM_SERVER_IP/g" /etc/xinetd.d/observium_agent_xinetd

# Copy the Observium agent script into place
cp /tmp/observium/scripts/observium_agent /usr/bin/observium_agent

# Make directories for scripts
mkdir -p /usr/lib/observium_agent/scripts-available
mkdir -p /usr/lib/observium_agent/scripts-enabled

# Copy scripts into place
cp -r /tmp/observium/scripts/agent-local/* /usr/lib/observium_agent/scripts-available

# Enable basic scripts
ln -s /usr/lib/observium_agent/scripts-available/dpkg /usr/lib/observium_agent/scripts-enabled/dpkg
ln -s /usr/lib/observium_agent/scripts-available/dmi /usr/lib/observium_agent/scripts-enabled/dmi
ln -s /usr/lib/observium_agent/scripts-available/lmsensors /usr/lib/observium_agent/scripts-enabled/lmsensors
ln -s /usr/lib/observium_agent/scripts-available/vmwaretools /usr/lib/observium_agent/scripts-enabled/vmwaretools

# Add SNMP community to SNMPd config
echo "rocommunity $OBSERVIUM_DEFAULT_SNMPV2C_COMMUNITY" >> /etc/snmp/snmpd.conf

# Enable SNMPd listening on all interfaces
sed -i "s/agentAddress  udp:127.0.0.1:161/agentAddress udp:161/g" /etc/snmp/snmpd.conf

# Restart SNMPd and xinetd service with their new config files
/usr/sbin/service xinetd restart
/usr/sbin/service snmpd restart

# Change to the scripts directory and show what's enabled
echo
echo "Enabled Observium agent scripts in /usr/lib/observium_agent/scripts-enabled/:"
cd /usr/lib/observium_agent/scripts-enabled/ && ls
