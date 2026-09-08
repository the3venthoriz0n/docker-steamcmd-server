FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="the3venthoriz0n"
LABEL org.opencontainers.image.source="https://github.com/the3venthoriz0n/docker-steamcmd-server"

RUN apt-get update && \
    apt-get -y install --no-install-recommends lib32gcc-s1 lib32stdc++6 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV DATA_DIR="/serverdata"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"
ENV SERVER_DIR="${DATA_DIR}/serverfiles"
ENV GAME_ID="5007710"
ENV GAME_NAME="DeceiveInc"
ENV GAME_PARAMS=""
ENV GAME_PARAMS_EXTRA=""
ENV GAME_PORT=7777
ENV QUERY_PORT=7778
ENV SERVER_CONFIG="${SERVER_DIR}/${GAME_NAME}/Saved/Config/LinuxServer/TripwireServer.ini"
ENV VALIDATE=""
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV USERNAME=""
ENV PASSWRD=""
ENV USER="steam"
ENV DATA_PERM=770

RUN mkdir $DATA_DIR && \
    mkdir $STEAMCMD_DIR && \
    mkdir $SERVER_DIR && \
    useradd -d $DATA_DIR -s /bin/bash $USER && \
    chown -R $USER $DATA_DIR && \
    ulimit -n 2048

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]