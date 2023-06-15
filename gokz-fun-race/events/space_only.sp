// 最多允许违规几次
#define MAX_SCROLL_VIOLATE 5
#define CHECK_SCROLL_COUNT 5

bool gB_JumpInputRecord[MAXCLIENTS][2]; // 最近两次usercmd是否起跳
bool gB_OnGroundLastTick[MAXCLIENTS]; // 最近1tick是否在地上
float gF_LastScrolledTime[MAXCLIENTS];
int gI_ScrollViolated[MAXCLIENTS]; // 累计使用滚轮次数


//////////////////
//	   函数	  //
//////////////////

/**
 * 重置空格跳比赛状态
 * @param client 重置对象
 */
void ResetStatus_SpaceOnly(int client)
{
	gI_ScrollViolated[client] = 0;
	gF_LastScrolledTime[client] = 0.0;
	gB_JumpInputRecord[client][0] = false;
	gB_JumpInputRecord[client][1] = false;
	gB_OnGroundLastTick[client] = false;
}

/**
 * 判断当前比赛是否为空格跳
 */
bool CheckRaceType_SpaceOnly()
{
	return GOKZ_Fun_Race_GetCurrentRaceType() == RaceType_SpaceOnly;
}

// -------- [ 事件 ] --------
void OnClientDisconnect_SpaceOnly(int client)
{
	ResetStatus_SpaceOnly(client);
}

void OnTimerStart_SpaceOnly(int client)
{
	ResetStatus_SpaceOnly(client);
}

void OnPlayerRunCmd_SpaceOnly(int client, int& buttons)
{
	if(GOKZ_Fun_Race_GetCurrentRaceStatus() != RaceStatus_Running)
	{
		return;
	}

	if(!CheckRaceType_SpaceOnly() || !GOKZ_Fun_Race_IsRacer(client) || GOKZ_Fun_Race_IsRacerFinished(client) || !GOKZ_GetTimerRunning(client))
	{
		return;
	}

	bool jump = (buttons & IN_JUMP) == IN_JUMP;
	if(!jump && gB_JumpInputRecord[client][0] && !gB_JumpInputRecord[client][1])
	{
		gF_LastScrolledTime[client] = GetGameTime();
	}

	bool onGround = Movement_GetOnGround(client);
	if(!onGround && gB_OnGroundLastTick[client] && GetGameTime() - gF_LastScrolledTime[client] < 0.05)
	{
		// 违规次数加一
		gI_ScrollViolated[client]++;

		// 通告玩家
		GOKZ_PrintToChat(client, true, "%s检测到滚轮跳[%d / %d]", gC_Colors[Color_Red], gI_ScrollViolated[client], MAX_SCROLL_VIOLATE);
		
		// 如果超过最大违规次数
		if(gI_ScrollViolated[client] >= MAX_SCROLL_VIOLATE)
		{
			// 惩罚玩家
			GOKZ_Fun_Race_Punish(client, "在空格跳比赛中多次使用滚轮跳");
			ResetStatus_SpaceOnly(client);
		}
	}
	gB_OnGroundLastTick[client] = onGround;
	gB_JumpInputRecord[client][1] = gB_JumpInputRecord[client][0];
	gB_JumpInputRecord[client][0] = jump;
}