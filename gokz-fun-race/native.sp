// 注册native接口
void CreateNatives()
{
	// 主插件
	CreateNative("GOKZ_Fun_Race_Punish", Native_Fun_Race_Punish);
	CreateNative("GOKZ_Fun_Race_GetCurrentRaceType", Native_Fun_Race_GetCurrentRaceType);
	CreateNative("GOKZ_Fun_Race_GetCurrentRaceStatus", Native_Fun_Race_GetCurrentRaceStatus);
	CreateNative("GOKZ_Fun_Race_ResetRaceStatus", Native_Fun_Race_ResetRaceStatus);
	CreateNative("GOKZ_Fun_Race_SetupRace", Native_Fun_Race_SetupRace);
	CreateNative("GOKZ_Fun_Race_StartRace", Native_Fun_Race_StartRace);
	CreateNative("GOKZ_Fun_Race_EndRace", Native_Fun_Race_EndRace);
	CreateNative("GOKZ_Fun_Race_CheckPause", Native_Fun_Race_CheckPause);
	CreateNative("GOKZ_Fun_Race_PauseRace", Native_Fun_Race_PauseRace);
	CreateNative("GOKZ_Fun_Race_ResumeRace", Native_Fun_Race_ResumeRace);
	CreateNative("GOKZ_Fun_Race_FinishRace", Native_Fun_Race_FinishRace);
	CreateNative("GOKZ_Fun_Race_SurrenderRace", Native_Fun_Race_SurrenderRace);
	CreateNative("GOKZ_Fun_Race_IsRacePause", Native_Fun_Race_IsRacePause);
	CreateNative("GOKZ_Fun_Race_IsRacer", Native_Fun_Race_IsRacer);
	CreateNative("GOKZ_Fun_Race_IsRacerFinished", Native_Fun_Race_IsRacerFinished);
	CreateNative("GOKZ_Fun_Race_AddRacer", Native_Fun_Race_AddRacer);
}


public int Native_Fun_Race_Punish(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char reason[1024];
	FormatNativeString(0, 2, 3, sizeof(reason), _, reason);
	// 处死该玩家
	ForcePlayerSuicide(client);
	// 服内通报
	GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s由于 %s %s而被处死.", gC_Colors[Color_Red], gC_Colors[Color_Yellow], client, gC_Colors[Color_Red], reason, gC_Colors[Color_Red]);
}

public int Native_Fun_Race_ResetRaceStatus(Handle plugin, int numParams)
{
	gI_RaceType = RaceType_None;
	gI_RaceStatus = RaceStatus_End;
	gI_RaceMode = 0;
	gI_RaceCourse = 0;
	gI_RacerCount = 0;
	gI_RacerFinishCount = 0;
	gI_RaceStartCountDown = 0;
	gB_IsRacePause = false;
	for(int client = 1; client < MAXCLIENTS; client++)
	{
		gB_IsRacer[client] = false;
		gB_IsRacerFinished[client] = false;
		gC_RacerRank[client] = "";
	}
}

public any Native_Fun_Race_GetCurrentRaceType(Handle plugin, int numParams)
{
	return gI_RaceType;
}

public any Native_Fun_Race_GetCurrentRaceStatus(Handle plugin, int numParams)
{
	return gI_RaceStatus;
}

public int Native_Fun_Race_SetupRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	// 更新状态
	GOKZ_Fun_Race_ResetRaceStatus();
	gI_RaceType = view_as<RaceType>(GetNativeCell(2));
	gI_RaceCourse = GetNativeCell(3);
	gI_RaceMode = GetNativeCell(4);
	gI_RaceStatus = RaceStatus_Waiting;
	GOKZ_PrintToChatAll(true, "%s管理员 %s%N %s发起了比赛!", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow]);
	GOKZ_PrintToChatAll(true, "%s - 比赛项目: %s%s", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], gC_RaceTypeName[gI_RaceType]);
	GOKZ_PrintToChatAll(true, "%s - 比赛关卡: %s%d", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], gI_RaceCourse);
	GOKZ_PrintToChatAll(true, "%s - 比赛模式: %s%s", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], gC_ModeNames[gI_RaceMode]);
	GOKZ_PrintToChatAll(true, "%s ===== 输入!bm以参与比赛 =====", gC_Colors[Color_Green]);
}

// 倒计时定时任务
// HUD显示还有点问题，得修修 
// TODO
public Action:Task_CountDown(Handle timer)
{
	// 如果比赛取消或者倒计时该结束了
	if(gI_RaceStatus != RaceStatus_Running || gI_RaceStartCountDown == 0)
	{
		// 结束倒计时
		return Plugin_Stop;
	}

	// 倒计时
	gI_RaceStartCountDown--;

	// 遍历参赛者
	for(int racer = 1; racer < MAXCLIENTS; racer++)
	{
		if(IsValidClient(racer) && GOKZ_Fun_Race_IsRacer(racer))
		{
			// 显示倒计时HUD
			SetHudTextParams(-1.0, 0.4, 2.0, gI_RaceStartCountDown * 17, 255 - (gI_RaceStartCountDown * 17), 0, 0, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(racer, gH_CountdownSynchronizer, "%d", gI_RaceStartCountDown);
			
			// 播放声音
			if(gI_RaceStartCountDown <= 6)
			{
				if(gI_RaceStartCountDown == 0)
				{
					ShowSyncHudText(racer, gH_CountdownSynchronizer, "开始!");
					EmitSoundToAllAny(gC_CountDownZeroSound);
				}
				else if(gI_RaceStartCountDown == 6)
				{
					EmitSoundToAllAny(gC_CountDownReadySound);
				}
				else
				{
					EmitSoundToAllAny(gC_CountDownSound);
				}
			}
		}
	}
	
	// 继续倒计时
	return Plugin_Continue;
}

public int Native_Fun_Race_StartRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	// 如果参赛人数足够
	if(gI_RacerCount > 1)
	{
		// 更新状态
		gI_RaceStatus = RaceStatus_Running;
		gI_RaceStartCountDown = 15;
	
		// 将所有参赛者集中至起点
		for(int racer = 1; racer < MAXCLIENTS; racer++)
		{
			if(GOKZ_Fun_Race_IsRacer(racer))
			{
				GOKZ_StopTimer(racer);
				GOKZ_TeleportToStart(racer);
				GOKZ_SetCoreOption(client, Option_Mode, gI_RaceMode);
			}
		}
	
		GOKZ_PrintToChatAll(true, "%s管理员 %s%N %s启动了比赛! 比赛将在%d秒后开始.", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow], gI_RaceStartCountDown);
		
		// 启动倒计时
		CreateTimer(1.0, Task_CountDown, 0, TIMER_REPEAT);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%s比赛人数不足! 无法开始比赛", gC_Colors[Color_Red]);
		GOKZ_PlayErrorSound(client);
	}
}

public int Native_Fun_Race_EndRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char reason[1024];
	FormatNativeString(0, 2, 3, sizeof(reason), _, reason);
	// 更新状态
	gI_RaceStatus = RaceStatus_End;
	// 输出比赛排名
	for(int rank = 1; rank <= gI_RacerFinishCount; rank++)
	{
		GOKZ_PrintToChatAll(true, "%s#%d %s- %s%s", gC_Colors[Color_Purple], rank, gC_Colors[Color_Grey], gC_Colors[Color_Purple], gC_RacerRank[rank]);
	}

	// 如果是人为结束比赛
	if(IsValidClient(client))
	{
		GOKZ_PrintToChatAll(true, "%s管理员 %s%N %s强制结束了比赛", gC_Colors[Color_Red], gC_Colors[Color_Purple], client, gC_Colors[Color_Red]);
	}
	GOKZ_PrintToChatAll(true, "%s%s, 比赛结束! ", gC_Colors[Color_Yellow], reason);
}

public int Native_Fun_Race_CheckPause(Handle plugin, int numParams)
{
	if(gB_IsRacePause)
	{
		int client = GetNativeCell(1);
		if(gB_IsRacer[client] && !gB_IsRacerFinished[client] && !GOKZ_GetPaused(client) && Movement_GetOnGround(client))
		{
			Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
			GOKZ_Pause(client);
		}
	}
}

public int Native_Fun_Race_PauseRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	// 更新状态
	gB_IsRacePause = true;
	for(int racer = 1; racer < MAXCLIENTS; racer++)
	{
		if(IsValidClient(racer) && gB_IsRacer[racer] && !GOKZ_GetPaused(racer))
		{
			GOKZ_Fun_Race_CheckPause(racer);
		}
	}
	GOKZ_PrintToChatAll(true, "%s管理员 %s%N %s暂停了比赛", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow]);
}

public int Native_Fun_Race_ResumeRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	// 更新状态
	gB_IsRacePause = false;
	for(int racer = 1; racer < MAXCLIENTS; racer++)
	{
		if(IsValidClient(racer) && gB_IsRacer[racer] && GOKZ_GetPaused(racer))
		{
			GOKZ_Resume(racer);
		}
	}
	GOKZ_PrintToChatAll(true, "%s管理员 %s%N %s恢复了比赛", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow]);
}

// 检查比赛剩余参赛者
void CheckRemainRacers()
{
	// 如果当前状态不是比赛中
	if(gI_RaceStatus != RaceStatus_Running)
	{
		return;
	}

	// 如果只有一名参赛者剩余
	if(gI_RacerCount <= 1)
	{
		GOKZ_Fun_Race_EndRace(0, "比赛人数过少");
		return;
	}
	
	// 如果刚好只剩一个人没完成 不知道可能会出什么BUG 我感觉可能会出
	if(gI_RacerFinishCount == gI_RacerCount - 1)
	{
		// 找到那个没排名的
		for(int client = 1; client < MAXCLIENTS; client++)
		{
			if(IsValidClient(client) && gB_IsRacer[client] && !gB_IsRacerFinished[client])
			{
				// 给排名
				GOKZ_Fun_Race_FinishRace(client);
				break;
			}
		}
		GOKZ_Fun_Race_EndRace(0, "所有人均已获得排名");
	}
}

public int Native_Fun_Race_FinishRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	// 更新状态
	gB_IsRacerFinished[client] = true;
	gI_RacerFinishCount++;
	// 记录玩家名字和名次
	char name[64];
	GetClientName(client, name, sizeof(name));
	gC_RacerRank[gI_RacerFinishCount] = name;

	GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s完成了比赛! %s[#%d / %d]", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow], gC_Colors[Color_Grey], gI_RacerFinishCount, gI_RacerCount);
	
	// 检查剩余参赛者数量
	CheckRemainRacers();
}

public int Native_Fun_Race_SurrenderRace(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	// 更新状态
	gB_IsRacerFinished[client] = false;
	gI_RacerCount--;
	gB_IsRacer[client] = false;
	GOKZ_StopTimer(client);

	GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s放弃了比赛...", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow]);
	
	// 检查剩余参赛者数量
	CheckRemainRacers();
}

public any Native_Fun_Race_IsRacePause(Handle plugin, int numParams)
{
	return gB_IsRacePause;
}

public any Native_Fun_Race_IsRacer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return gB_IsRacer[client];
}

public any Native_Fun_Race_IsRacerFinished(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return gB_IsRacerFinished[client];
}

public int Native_Fun_Race_AddRacer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	// 更新玩家参赛状态
	gB_IsRacer[client] = true;
	gI_RacerCount++;
	GOKZ_PrintToChatAll(true, "%s玩家 %s%N %s报名了 [#%d]", gC_Colors[Color_Yellow], gC_Colors[Color_Purple], client, gC_Colors[Color_Yellow], gI_RacerCount);
}