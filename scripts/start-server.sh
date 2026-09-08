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
UE_CONFIG_DIR="${SERVER_DIR}/${GAME_NAME}/Saved/Config/LinuxServer"
SERVER_CONFIG="${UE_CONFIG_DIR}/GameUserSettings.ini"
mkdir -p "${UE_CONFIG_DIR}"

if [ ! -f "${SERVER_CONFIG}" ]; then
  echo "---Configuration not found, creating default GameUserSettings.ini---"
  cat <<EOF > "${SERVER_CONFIG}"
[/Script/Engine.GameSession]
ServerName=Deceive Inc Player Server
MaxPlayers=12
EOF
  echo "---Default configuration created successfully---"
else
  echo "---Existing GameUserSettings.ini found, keeping current settings---"
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

if [ -f ${SERVER_DIR}/${GAME_NAME}/Binaries/Linux/DeceiveIncServer-Linux-Shipping ]; then
  cd ${SERVER_DIR}
  chmod +x ${SERVER_DIR}/${GAME_NAME}/Binaries/Linux/DeceiveIncServer-Linux-Shipping

  exec ${SERVER_DIR}/${GAME_NAME}/Binaries/Linux/DeceiveIncServer-Linux-Shipping ${GAME_NAME} \
    ${GAME_PARAMS} ${GAME_PARAMS_EXTRA}
else
  echo "---Something went wrong, can't find the executable, putting container into sleep mode!---"
  sleep infinity
fi