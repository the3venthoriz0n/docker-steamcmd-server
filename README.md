# SteamCMD in Docker optimized for Unraid
This Docker will download and install SteamCMD. It will also install the Deceive Inc. Dedicated Server and run it.

**Configuration:** The configuration is located at: `.../serverfiles/DeceiveInc/Saved/Config/LinuxServer/GameUserSettings.ini`

On first boot, the container automatically generates a default `GameUserSettings.ini` template if one does not already exist. Because Unreal Engine stores this file inside its `Saved` directory, SteamCMD updates and validation runs will **never** overwrite or revert your edits.

You can edit this file directly on your host to configure your server name (`ServerName`), player counts, and other server settings.

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
| GAME_PORT | UDP game port clients connect on. | 7777 |
| QUERY_PORT | UDP query port the server browser pings. Must differ from GAME_PORT. | 7778 |
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