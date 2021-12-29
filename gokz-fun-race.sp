#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <emitsoundany>
#include <gokz_fun_race>
#include <gokz>
#include <gokz/core>
#include <gokz/jumpstats>

RaceStatus gI_RaceStatus; // 比赛状态

RaceType gI_RaceType; // 比赛项目
int gI_RaceCourse; // 当前比赛关卡
int gI_RaceMode; // 当前比赛模式
int gI_RacerCount; // 当前比赛参赛人数
int gI_RacerFinishCount; // 当前比赛完赛人数
int gI_RaceStartCountDown; // 当前比赛倒计时
bool gB_IsRacePause; // 当前比赛暂停状态
bool gB_IsRacer[MAXCLIENTS]; // 玩家参赛状态
bool gB_IsRacerFinished[MAXCLIENTS]; // 玩家完赛状态
char gC_RacerRank[MAXCLIENTS][64]; // 玩家排名

Handle gH_CountdownSynchronizer; // 倒计时HUD

#include "gokz-fun-race/events/space_only.sp"
#include "gokz-fun-race/events/low_gravity.sp"

#include "gokz-fun-race/menu.sp"
#include "gokz-fun-race/command.sp"

#include "gokz-fun-race/native.sp"

public Plugin:myinfo = 
{
	name = "GOKZ Fun Race",
	author = "Nep & One",
	description = "Create for funny racing with community",
	version = "1.0",
	url = "https://gokz.cn"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	return APLRes_Success;
}

public OnMapStart() {
	PrecacheSounds();
}

void PrecacheSounds()
{
	PrecacheSoundAny(gC_CountDownSound);
	PrecacheSoundAny(gC_CountDownZeroSound);
	PrecacheSoundAny(gC_CountDownReadySound);
}

public void OnPluginStart()
{

	GOKZ_Fun_Race_ResetRaceStatus();

	RegisterCommands();

	OnPluginStart_Menu();

	OnPluginStart_LowGravity();

	gH_CountdownSynchronizer = CreateHudSynchronizer();
}

public void OnAllPluginsLoaded()
{
	DisableGOKZSettingEnforcer();
}

void DisableGOKZSettingEnforcer()
{
	ConVar convar_gokz_enforcer = FindConVar("gokz_settings_enforcer");
	if(convar_gokz_enforcer == null)
	{
		PrintToServer("Can't find cvar 'gokz_settings_enforcer'.");
	}
	else
	{
		SetConVarBool(convar_gokz_enforcer, false);
	}
}

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_LowGravity(client);
}

public void OnClientDisconnect(int client)
{
	// 判断是否参赛者
	if(gB_IsRacer[client])
	{
		// 如果是参赛者且没有完赛
		if(!gB_IsRacerFinished[client])
		{
			// 视为弃权
			GOKZ_Fun_Race_SurrenderRace(client);
		}
	}
	// 之后各个比赛项目处理玩家离开事件
	OnClientDisconnect_SpaceOnly(client);
}

// 玩家落地时触发
public void GOKZ_JS_OnLanding(Jump jump)
{
	OnLanding_SpaceOnly(jump);
}

// 玩家启动计时器时触发
public Action GOKZ_OnTimerStart(int client, int course)
{
	// 如果当前正在比赛 且 该玩家为参赛者
	if(gI_RaceStatus == RaceStatus_Running && gB_IsRacer[client])
	{
		// 如果模式不对
		if(GOKZ_GetCoreOption(client, Option_Mode) != gI_RaceMode)
		{
			GOKZ_SetCoreOption(client, Option_Mode, gI_RaceMode);
			return Plugin_Stop;
		}

		// 如果 关卡不对 或 倒计时结束
		if(course != gI_RaceCourse || gI_RaceStartCountDown > 0)
		{
			// 禁止开始
			return Plugin_Stop;
		}
	}
	
	// 若能开始 则让各个项目开始处理事件
	OnTimerStart_SpaceOnly(client);
	return Plugin_Continue;
}

// 玩家结束计时时触发
public Action GOKZ_OnTimerEnd(int client, int course, float time, int teleportsUsed){
	// 如果当前是比赛状态
	if(gI_RaceStatus == RaceStatus_Running && GOKZ_Fun_Race_IsRacer(client))
	{
		OnTimerEnd_SpaceOnly(client, time, teleportsUsed);
		OnTimerEnd_LowGravity(client, time, teleportsUsed);
		GOKZ_StopTimer(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action GOKZ_OnResume(int client)
{
	if(gB_IsRacePause && gI_RaceStatus == RaceStatus_Running && GOKZ_Fun_Race_IsRacer(client))
	{
		GOKZ_PrintToChat(client, true, "%c比赛暂停中，请耐心等待", gC_Colors[Color_Red]);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}