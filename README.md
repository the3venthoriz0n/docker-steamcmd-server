# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD. It will also install the Deceive Inc. Dedicated Server and run it.

**Configuration:** The configuration is located at: `.../serverfiles/config/TripwireServer.ini`

The Deceive Inc. server ships its default `TripwireServer.ini` *inside* the SteamCMD-managed
files, which means a validate/update run would revert your edits. This container therefore copies
the packaged defaults once to `.../serverfiles/config/TripwireServer.ini` and starts the server
with the officially supported `-TripwireServerConfig=` flag, so your settings survive updates.
Every option is documented with a comment above it inside that file.

**The configuration file is authoritative.** The `GAME_PORT`, `QUERY_PORT` and `DISABLE_UPNP`
variables only supply the *initial* values, written once when the configuration is first created.
After that the container never rewrites the file, so every setting stays hand-editable.

If you later change a port, change it in **both** places - the config file and the container's
port mapping. On every start the container compares them and prints a warning if they disagree,
telling you which value the server will actually use (the config file's).

`bEnableUPnP` is seeded to `false` because UPnP relies on SSDP multicast, which does not reach a
router from inside a container - forward UDP 7777 and 7778 on your router instead.

**Note:** `AutoShutdownEmptyMinutes` in the config defaults to `0` (disabled). If you set it to a
non-zero value the server will shut itself down when empty, which stops the container.

ATTENTION: First Startup can take very long since it downloads the gameserver files (~1GB)!

Update Notice: Simply restart the container if a newer version of the game is available.

You can also run multiple servers with only one SteamCMD directory!

## Example Env params
| Name | Value | Example |
| --- | --- | --- |
| STEAMCMD_DIR | Folder for SteamCMD | /serverdata/steamcmd |
| SERVER_DIR | Folder for gamefile | /serverdata/serverfiles |
| GAME_ID | The GAME_ID that the container downloads at startup. If you want to install a static or beta version of the game change the value to: '5007710 -beta YOURBRANCH' (without quotes, replace YOURBRANCH with the branch or version you want to install). | 5007710 |
| GAME_NAME | Unreal Engine project name, also the name of the folder holding the server binary and packaged config. Do not change. | DeceiveInc |
| GAME_PORT | UDP game port clients connect on. Sets the initial GamePort when the configuration is first created; afterwards it is only used to warn you if it no longer matches the config. | 7777 |
| QUERY_PORT | UDP query port the server browser pings. Sets the initial QueryPort when the configuration is first created; afterwards only used for the mismatch warning. Must differ from GAME_PORT. | 7778 |
| SERVER_CONFIG | Full path to the live server configuration. Kept outside the SteamCMD-managed files so updates can't revert it. | /serverdata/serverfiles/config/TripwireServer.ini |
| DISABLE_UPNP | If 'true' the initial configuration is seeded with bEnableUPnP=false. Only applies when the config is first created. | true |
| GAME_PARAMS | Enter your game parameters | blank |
| GAME_PARAMS_EXTRA | Enter your Extra Game Parameters seperated with a space and - (eg: -useperfthreads -NoAsyncLoadingThread) | blank |
| UID | User Identifier | 99 |
| GID | Group Identifier | 100 |
| VALIDATE | Validates the game data | blank |
| USERNAME | Leave blank for anonymous login | blank |
| PASSWRD | Leave blank for anonymous login | blank |

The Deceive Inc. Dedicated Server (App ID 5007710) installs with an **anonymous** SteamCMD login,
so `USERNAME` and `PASSWRD` can be left blank.

## Run example
```
docker run --name DeceiveInc -d \
	-p 7777:7777/udp -p 7778:7778/udp \
	--env 'GAME_ID=5007710' \
	--env 'GAME_PORT=7777' \
	--env 'QUERY_PORT=7778' \
	--env 'DISABLE_UPNP=true' \
	--env 'UID=99' \
	--env 'GID=100' \
	--volume /path/to/steamcmd:/serverdata/steamcmd \
	--volume /path/to/deceiveinc:/serverdata/serverfiles \
	the3venthoriz0n/steamcmd:deceiveinc
```

## Troubleshooting
Search the server log for `[NetPosture]` to see the detected public address, the UPnP result, and
whether inbound UDP is arriving at all. If players outside your network never see the server,
start there.

Useful log markers:
- `FDIServerPingResponder: ... first inbound echo on query port` - a client's ping actually arrived.
- `GameNetDriver ... listening on port 7777` - the game port is bound.
- No `PreLogin` when someone tries to join means their packets never reached the server at all,
  which is a forwarding/networking problem rather than a server one.

Region auto-detection (`ServerRegion=` left empty) can fail inside a container - every Epic ping
host times out and the server registers with an empty region, which may hide it from browser
filters. Set `ServerRegion` explicitly (`us-east`, `us-central`, `us-west`, `eu`, `oce`, `br`,
`asia`, `me`).

This Docker was mainly edited for better use with Unraid, if you don't use Unraid you should definitely try it!

This Docker is forked from ich777's SteamCMD server framework, thank you for this wonderfull Docker.
