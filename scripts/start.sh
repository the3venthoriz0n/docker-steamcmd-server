#!/bin/bash
echo "---Ensuring UID: ${UID} matches user---"
usermod -u ${UID} ${USER}
echo "---Ensuring GID: ${GID} matches user---"
groupmod -g ${GID} ${USER} > /dev/null 2>&1 ||:
usermod -g ${GID} ${USER}
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "---Checking for optional scripts---"
cp -f /opt/custom/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:
cp -f /opt/scripts/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:

if [ -f /opt/scripts/start-user.sh ]; then
  echo "---Found optional script, executing---"
  chmod -f +x /opt/scripts/start-user.sh ||:
  /opt/scripts/start-user.sh || echo "---Optional Script has thrown an Error---"
else
  echo "---No optional script found, continuing---"
fi

echo "---Taking ownership of data...---"
chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} ${DATA_DIR}

echo "---Starting...---"
term_handler() {
	# The server is started through 'su', which does not forward signals to its child,
	# so target the game process directly by name and wait for it to exit cleanly.
	# Guard against an empty pidof: the server may not have finished installing yet.
	SERVER_PID="$(pidof DeceiveIncServer-Linux-Shipping)"
	if [ ! -z "${SERVER_PID}" ]; then
		kill -SIGTERM ${SERVER_PID}
		tail --pid=${SERVER_PID} -f 2>/dev/null
	fi
}

trap 'kill ${!}; term_handler' SIGTERM
su ${USER} -c "/opt/scripts/start-server.sh" &
killpid="$!"
while true
do
  wait $killpid
  exit 0;
done
