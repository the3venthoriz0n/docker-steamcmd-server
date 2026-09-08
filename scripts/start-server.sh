#!/bin/bash
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
  echo "SteamCMD not found!"
  wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz
  tar --directory ${STEAMCMD_DIR} -xvzf ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
  rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
if [ "${USERNAME}" == "" ]; then
  ${STEAMCMD_DIR}/steamcmd.sh \
  +login anonymous \
  +quit
else
  ${STEAMCMD_DIR}/steamcmd.sh \
  +login ${USERNAME} ${PASSWRD} \
  +quit
fi

echo "---Update Server---"
if [ "${USERNAME}" == "" ]; then
  if [ "${VALIDATE}" == "true" ]; then
    echo "---Validating installation---"
    ${STEAMCMD_DIR}/steamcmd.sh \
    +force_install_dir ${SERVER_DIR} \
    +login anonymous \
    +app_update ${GAME_ID} validate \
    +quit
  else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +force_install_dir ${SERVER_DIR} \
    +login anonymous \
    +app_update ${GAME_ID} \
    +quit
  fi
else
  if [ "${VALIDATE}" == "true" ]; then
    echo "---Validating installation---"
    ${STEAMCMD_DIR}/steamcmd.sh \
    +force_install_dir ${SERVER_DIR} \
    +login ${USERNAME} ${PASSWRD} \
    +app_update ${GAME_ID} validate \
    +quit
  else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +force_install_dir ${SERVER_DIR} \
    +login ${USERNAME} ${PASSWRD} \
    +app_update ${GAME_ID} \
    +quit
  fi
fi

if [ -d "${SERVER_DIR}/steamapps" ] ; then
  if grep -qP '"StateFlags"\s+"6"' ${SERVER_DIR}/steamapps/appmanifest_${GAME_ID}.acf ; then
    echo "---Update Error detected, retrying...---"
    rm -f ${SERVER_DIR}/steamapps/appmanifest_${GAME_ID}.acf
    if [ "${USERNAME}" == "" ]; then
      ${STEAMCMD_DIR}/steamcmd.sh \
      +force_install_dir ${SERVER_DIR} \
      +login anonymous \
      +app_update ${GAME_ID} \
      +quit
    else
      ${STEAMCMD_DIR}/steamcmd.sh \
      +force_install_dir ${SERVER_DIR} \
      +login ${USERNAME} ${PASSWRD} \
      +app_update ${GAME_ID} \
      +quit
    fi
  fi
fi

echo "---Checking if configuration is in place---"
# The packaged config lives inside the SteamCMD-managed file set, so a 'validate' run would
# revert any edits. Keep the live config outside that file set and point the server at it with
# the officially supported -TripwireServerConfig flag.
CONFIG_SEEDED="false"
if [ ! -f "${SERVER_CONFIG}" ]; then
  echo "---Configuration not found, seeding from packaged defaults...---"
  mkdir -p "$(dirname "${SERVER_CONFIG}")"
  if [ -f ${SERVER_DIR}/${GAME_NAME}/TripwireServer.ini ]; then
    cp ${SERVER_DIR}/${GAME_NAME}/TripwireServer.ini "${SERVER_CONFIG}"
    CONFIG_SEEDED="true"
  else
    echo "---Can't find packaged configuration, server will start with built-in defaults!---"
  fi
else
  echo "---Configuration found, continuing...---"
fi

# Container variables only provide the INITIAL values, written once when the configuration is
# first created. After that the configuration file is authoritative and is never rewritten, so
# it stays hand-editable.
if [ "${CONFIG_SEEDED}" == "true" ]; then
  echo "---Writing initial settings into the new configuration---"
  if [ ! -z "${GAME_PORT}" ]; then
    sed -i "s/^GamePort=.*/GamePort=${GAME_PORT}/" "${SERVER_CONFIG}"
  fi
  if [ ! -z "${QUERY_PORT}" ]; then
    sed -i "s/^QueryPort=.*/QueryPort=${QUERY_PORT}/" "${SERVER_CONFIG}"
  fi
  # UPnP uses SSDP multicast, which cannot reach a router from a bridged container.
  # Default it off; users on host networking can turn it back on in the config.
  if [ "${DISABLE_UPNP}" == "true" ]; then
    sed -i "s/^bEnableUPnP=.*/bEnableUPnP=false/" "${SERVER_CONFIG}"
  fi
  echo "---From now on ${SERVER_CONFIG} is authoritative, edit it directly to change settings---"
fi

if [ -f "${SERVER_CONFIG}" ]; then
  echo "---Checking configuration against container settings---"
  CFG_GAME_PORT="$(grep -oP '^GamePort=\K.*' "${SERVER_CONFIG}" | tr -d '[:space:]')"
  CFG_QUERY_PORT="$(grep -oP '^QueryPort=\K.*' "${SERVER_CONFIG}" | tr -d '[:space:]')"
  CFG_UPNP="$(grep -oP '^bEnableUPnP=\K.*' "${SERVER_CONFIG}" | tr -d '[:space:]')"

  if [ ! -z "${GAME_PORT}" ] && [ ! -z "${CFG_GAME_PORT}" ] && [ "${GAME_PORT}" != "${CFG_GAME_PORT}" ]; then
    echo "---WARNING: The server will listen on GamePort ${CFG_GAME_PORT} but this container publishes ${GAME_PORT}!---"
    echo "---WARNING: The configuration file wins. Change GamePort in ${SERVER_CONFIG} or fix the port mapping.---"
  fi
  if [ ! -z "${QUERY_PORT}" ] && [ ! -z "${CFG_QUERY_PORT}" ] && [ "${QUERY_PORT}" != "${CFG_QUERY_PORT}" ]; then
    echo "---WARNING: The server will answer queries on QueryPort ${CFG_QUERY_PORT} but this container publishes ${QUERY_PORT}!---"
    echo "---WARNING: The configuration file wins. Change QueryPort in ${SERVER_CONFIG} or fix the port mapping.---"
  fi
  if [ ! -z "${CFG_GAME_PORT}" ] && [ "${CFG_GAME_PORT}" == "${CFG_QUERY_PORT}" ]; then
    echo "---WARNING: GamePort and QueryPort are both ${CFG_GAME_PORT}, the server will shift one of them by 1!---"
  fi
  if [ "${CFG_UPNP}" == "true" ]; then
    echo "---WARNING: bEnableUPnP is true, this only works with host networking and is wasted time otherwise.---"
  fi
fi

echo "---Prepare Server---"
if [ ! -f ${SERVER_DIR}/Engine/Binaries/Linux/steamclient.so ]; then
  mkdir -p ${SERVER_DIR}/Engine/Binaries/Linux
  ln -s ${SERVER_DIR}/linux64/steamclient.so ${SERVER_DIR}/Engine/Binaries/Linux/steamclient.so
fi
if [ ! -d ${DATA_DIR}/.steam/sdk64 ]; then
  mkdir -p ${DATA_DIR}/.steam/sdk64
  cp -R ${SERVER_DIR}/linux64/* ${DATA_DIR}/.steam/sdk64/
fi

chmod -R ${DATA_PERM} ${DATA_DIR}
echo "---Server ready---"

echo "---Start Server---"
# Call the server binary directly rather than the shipped DeceiveIncServer.sh wrapper: that
# wrapper does not 'exec' its child, so it would swallow the SIGTERM sent on container stop.
if [ -f ${SERVER_DIR}/${GAME_NAME}/Binaries/Linux/DeceiveIncServer-Linux-Shipping ]; then
  cd ${SERVER_DIR}
  chmod +x ${SERVER_DIR}/${GAME_NAME}/Binaries/Linux/DeceiveIncServer-Linux-Shipping
  exec ${SERVER_DIR}/${GAME_NAME}/Binaries/Linux/DeceiveIncServer-Linux-Shipping ${GAME_NAME} \
    -TripwireServerConfig="${SERVER_CONFIG}" ${GAME_PARAMS} ${GAME_PARAMS_EXTRA}
else
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
fi
