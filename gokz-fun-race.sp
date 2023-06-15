#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <movement>
#include <emitsoundany>
#include <gokz_fun_race>
#include <gokz>
#include <gokz/core>
#include <gokz/jumpstats>
#include <funrace/zone>



int gI_BeamMaterialIndex; // 区域边界射线模型索引
RaceStatus gI_RaceStatus; // 比赛状态

RaceType gI_RaceType; // 比赛项目
int gI_RaceCourse; // 当前比赛关卡
int gI_RaceMode; // 当前比赛模式
int gI_RacerCount; // 当前比赛参赛人数
int gI_RacerFinishCount; // 当前比赛完赛人数
bool gB_AllowCheckpoint; // 当前比赛是否允许存点
bool gB_AllowRespawn; // 当前比赛是否允许回起点
bool gB_IsRacePause; // 当前比赛暂停状态
bool gB_IsRacer[MAXCLIENTS]; // 玩家参赛状态
bool gB_IsRacerStarted[MAXCLIENTS]; // 玩家是否已经按过开始
bool gB_IsRacerFinished[MAXCLIENTS]; // 玩家完赛状态
char gC_RacerRank[MAXCLIENTS][128]; // 玩家排名
float gF_StartPosition[3];
float gF_StartAngle[3];


#include "gokz-fun-race/zone.sp"

#include "gokz-fun-race/events/space_only.sp"
#include "gokz-fun-race/events/low_gravity.sp"
#include "gokz-fun-race/events/relay.sp"

#include "gokz-fun-race/countdown.sp"
#include "gokz-fun-race/menu.sp"
#include "gokz-fun-race/command.sp"

#include "gokz-fun-race/native.sp"

public Plugin:myinfo = 
{
	name = "GOKZ Fun Race",
	author = "Nep & 1",
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
	GOKZ_Fun_Race_ResetRaceStatus();

	for (int i = 0; i < 3; i++)
	{
		gF_StartPosition[i] = 0.0;
		gF_StartAngle[i] = 0.0;
	}
	OnMapStart_Zone();
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
	
	OnPluginStart_LowGravity();

	OnPluginStart_Menu();
	OnPluginStart_CountDown();

	GOKZ_PrintToChatAll(true, "娱乐比赛插件重载完成")
}

public void OnClientPutInServer(int client)
{
	OnClientPutInServer_Menu(client);
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

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	OnPlayerRunCmd_SpaceOnly(client, buttons);
}

// 玩家落地时触发
public void GOKZ_JS_OnLanding(Jump jump)
{
	GOKZ_Fun_Race_CheckPause(jump.jumper);
	// OnLanding_SpaceOnly(jump);
}

public void GOKZ_OnStartPositionSet_Post(int client, StartPositionType type, const float origin[3], const float angles[3])
{
	GOKZ_Fun_Race_ResetRacerStartPosition(client, origin[0], origin[1], origin[2]);
}

// 玩家启动计时器时触发
public Action GOKZ_OnTimerStart(int client, int course)
{
	// 如果当前正在比赛 且 该玩家为参赛者
	if(gI_RaceStatus == RaceStatus_Running && gB_IsRacer[client])
	{
		// 如果 已经开始过计时 且 还没有完成比赛
		if(!gB_IsRacerFinished[client] && gB_IsRacerStarted[client])
		{
			return Plugin_Stop;
		}

		// 如果模式不对
		if(GOKZ_GetCoreOption(client, Option_Mode) != gI_RaceMode)
		{
			GOKZ_SetCoreOption(client, Option_Mode, gI_RaceMode);
			return Plugin_Stop;
		}

		// 如果 关卡不对 或 倒计时未结束
		if(gB_IsRacePause || course != gI_RaceCourse || GetCountDownRemain() > 0)
		{
			// 禁止开始
			return Plugin_Stop;
		}

		// 若能开始 则让各个项目开始处理事件
		OnTimerStart_SpaceOnly(client);
		
		// 更新玩家是否已经开始计时
		gB_IsRacerStarted[client] = true;
	}
	return Plugin_Continue;
}

public void GOKZ_OnTimerStopped(int client)
{
	// 如果比赛进行中 且 没有完成比赛
	if(gI_RaceStatus == RaceStatus_Running && GetCountDownRemain() == 0 && gB_IsRacer[client] && !gB_IsRacerFinished[client])
	{
		GOKZ_Fun_Race_SurrenderRace(client);
	}
}

public Action GOKZ_OnMakeCheckpoint(int client)
{
	// 如果比赛进行中 且 没有完成比赛
	if(gI_RaceStatus == RaceStatus_Running && gB_IsRacer[client] && !gB_IsRacerFinished[client])
	{
		// 如果不允许存点
		if(!gB_AllowCheckpoint)
		{
			GOKZ_PlayErrorSound(client);
			GOKZ_PrintToChat(client, true, "%c当前比赛不允许存点", gC_Colors[Color_Red]);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

// 玩家结束计时时触发
public Action GOKZ_OnTimerEnd(int client, int course, float time, int teleportsUsed){
	// 如果当前是比赛状态
	if(gI_RaceStatus == RaceStatus_Running && gB_IsRacer[client])
	{
		GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s完成了比赛! %s[%s | %d TP]", gC_Colors[Color_Green], gC_Colors[Color_Purple], client, gC_Colors[Color_Green], gC_Colors[Color_Yellow], GOKZ_FormatTime(time), teleportsUsed);
		GOKZ_Fun_Race_FinishRace(client, time);
		GOKZ_StopTimer(client);
		OnTimerEnd_Relay(client, time);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action GOKZ_OnResume(int client)
{
	if (!GOKZ_Fun_Race_IsRacer(client))
	{
		return Plugin_Continue;
	}

	if (GetCountDownRemain() > 0)
	{
		GOKZ_PrintToChat(client, true, "%c比赛还在倒计时, 请勿抢跑!", gC_Colors[Color_Red]);
		GOKZ_PlayErrorSound(client);
		return Plugin_Stop;
	}
	else if(gB_IsRacePause && gI_RaceStatus == RaceStatus_Running && GOKZ_Fun_Race_IsRacer(client))
	{
		GOKZ_PrintToChat(client, true, "%c比赛暂停中, 请耐心等待", gC_Colors[Color_Red]);
		GOKZ_PlayErrorSound(client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]))
	{
		if (newValue != gI_RaceMode && gI_RaceStatus == RaceStatus_Running && GOKZ_Fun_Race_IsRacer(client) && !gB_IsRacerFinished[client])
		{
			GOKZ_SetCoreOption(client, Option_Mode, gI_RaceMode);
			GOKZ_PrintToChat(client, true, "%c比赛中, 禁止切换模式", gC_Colors[Color_Red]);
			GOKZ_PlayErrorSound(client);
		}
	}
}

public Action GOKZ_OnTeleportToStart(int client, int course)
{
	if (gI_RaceStatus == RaceStatus_Running && gB_IsRacer[client] && !gB_IsRacerFinished[client])
	{
		if (course == gI_RaceCourse && gB_AllowRespawn)
		{
			GOKZ_PrintToChat(client, true, "%c本次比赛禁止回起点", gC_Colors[Color_Red]);
			GOKZ_PlayErrorSound(client);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}