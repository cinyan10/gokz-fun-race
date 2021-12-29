#include <gokz/anticheat>

// 最多允许违规几次
#define MAX_SCROLL_VIOLATE 5
#define CHECK_SCROLL_COUNT 5

int gI_ScrollViolated[MAXCLIENTS]; // 累计使用滚轮次数
int gI_LastScrollPattern[MAXCLIENTS][CHECK_SCROLL_COUNT]; // 上次跳跃数据


//////////////////
//	   函数	  //
//////////////////

/**
 * 重置空格跳比赛状态
 * @param client 重置对象
 */
void SpaceOnly_ResetStatus(int client)
{
	gI_ScrollViolated[client] = 0;
}

/**
 * 判断当前比赛是否为空格跳
 */
bool CheckRaceType_SpaceOnly()
{
	return GOKZ_Fun_Race_GetCurrentRaceType() == RaceType_SpaceOnly;
}

//////////////////
//	   事件	  //
//////////////////

void OnClientDisconnect_SpaceOnly(int client)
{
	SpaceOnly_ResetStatus(client);
}

void OnTimerStart_SpaceOnly(int client)
{
	if(!CheckRaceType_SpaceOnly())
	{
		return;
	}
	
	SpaceOnly_ResetStatus(client);
}

void OnTimerEnd_SpaceOnly(int client, float time, int cp)
{
	if(!CheckRaceType_SpaceOnly())
	{
		return;
	}

	GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s完成地图! %s[%s | %d TP]", gC_Colors[Color_Green], gC_Colors[Color_Purple], client, gC_Colors[Color_Green], gC_Colors[Color_Yellow], GOKZ_FormatTime(time), cp);
	GOKZ_Fun_Race_FinishRace(client);
}
 
 /**
  * 当玩家完成一次跳跃时
  * @param jump 起跳详细数据
  */
void OnLanding_SpaceOnly(Jump jump)
{
	if(!CheckRaceType_SpaceOnly())
	{
		return;
	}

	// 获取跳跃者
	int client = jump.jumper;
 
	// 判断计时是否开始
	if(!GOKZ_Fun_Race_IsRacer(client) || !GOKZ_GetTimerRunning(client))
	{
		return;
	}
	 
	// 获取最近一次连跳pattern
	int pattern[CHECK_SCROLL_COUNT];
	GOKZ_AC_GetJumpInputs(client, pattern, CHECK_SCROLL_COUNT);
	// 如果pattern超过2 则有极大概率是使用了滚轮
	if(pattern[0] > 2)
	{
		// 判断连跳pattern较上次起跳变没变
		bool same = true;
		// 判断同时保存这次pattern
		for(int i = 0; i < CHECK_SCROLL_COUNT; i++)
		{
			if(pattern[i] != gI_LastScrollPattern[client][i])
			{
				same = false;
			}
			gI_LastScrollPattern[client][i] = pattern[i];
		}

		// 如果没变则略过这次
		if(same)
		{
			return;
		}

		// 违规次数加一
		gI_ScrollViolated[client]++;

		// 通告玩家
		GOKZ_PrintToChat(client, true, "%s检测到非空格连跳[%d / %d]", gC_Colors[Color_Red], gI_ScrollViolated[client], MAX_SCROLL_VIOLATE);
		
		// 如果超过最大违规次数
		if(gI_ScrollViolated[client] >= MAX_SCROLL_VIOLATE)
		{
			// 惩罚玩家
			GOKZ_Fun_Race_Punish(client, "在空格跳比赛中多次使用滚轮跳");
		}
	}
}