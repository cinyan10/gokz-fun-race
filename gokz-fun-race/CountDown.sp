#define COUNTDOWN_SOUND_START 7

Handle gH_CountdownSynchronizer; // 倒计时HUD
float gF_RaceStartCountDownTime; // 比赛开始倒计时的时间戳
int gI_CountDown; // 比赛倒计时时长

bool gB_SoundPlayed[COUNTDOWN_SOUND_START];

void OnPluginStart_CountDown()
{
	gH_CountdownSynchronizer = CreateHudSynchronizer();
}

void StartCountDown(int countdown)
{
	ResetCountDown();
	gF_RaceStartCountDownTime = GetGameTime();
	gI_CountDown = countdown;
	CreateTimer(0.1, Task_CountDown, 0, TIMER_REPEAT);
}

void ResetCountDown()
{
	gF_RaceStartCountDownTime = 0.0;
	gI_CountDown = 0;
	for(int i = 0; i < COUNTDOWN_SOUND_START; i++)
	{
		gB_SoundPlayed[i] = false;
	}
}

float GetCountDownRemain()
{
	return gI_CountDown > 0 ? gI_CountDown - (GetGameTime() - gF_RaceStartCountDownTime) : 0.0;
}

void ShowCountDown(int client, int countdown)
{
	// 显示倒计时HUD
	SetHudTextParams(-1.0, 0.4, 1.0, Clamp(countdown * 15, 0, 255), Clamp(255 - countdown * 15, 0, 255), 30, 0, 0, 0.0, 0.0, 0.0);
	if(countdown == 0)
	{
		ShowSyncHudText(client, gH_CountdownSynchronizer, "准备开冲!");
	}
	else
	{
		ShowSyncHudText(client, gH_CountdownSynchronizer, "%d", countdown);
	}
}

void PlayCountDownSound(int client, int countdown)
{
	if(countdown == COUNTDOWN_SOUND_START - 1)
	{
		EmitSoundToClientAny(client, gC_CountDownReadySound);
	}
	else if(countdown == 0)
	{
		EmitSoundToClientAny(client, gC_CountDownZeroSound);
	}
	else
	{
		EmitSoundToClientAny(client, gC_CountDownSound);
	}
}

void StartRacerTimer()
{
	for(int racer = 1; racer < MAXCLIENTS; racer++)
	{
		if(GOKZ_Fun_Race_IsRacer(racer))
		{
			GOKZ_StartTimer(racer, gI_RaceCourse, false);
		}
	}
}

// 倒计时定时任务
public Action:Task_CountDown(Handle timer)
{
	// 比赛取消则取消倒计时
	if(GOKZ_Fun_Race_GetCurrentRaceStatus() != RaceStatus_Running || GetCountDownRemain() <= 0.0)
	{
		ResetCountDown();
		StartRacerTimer();
		// 结束倒计时
		return Plugin_Stop;
	}

	int countdown = RoundToFloor(GetCountDownRemain());
	bool playSound = false;
	if(countdown < COUNTDOWN_SOUND_START && !gB_SoundPlayed[countdown])
	{
		playSound = true;
		gB_SoundPlayed[countdown] = true;
	}
	// 遍历玩家
	for(int client = 1; client < MAXCLIENTS; client++)
	{
		if(IsValidClient(client))
		{
			if (GOKZ_Fun_Race_IsRacer(client))
			{
				GOKZ_Fun_Race_CheckPause(client);
				float origin[3];
				GetClientAbsOrigin(client, origin);
				if (FloatCompare(origin[0], gF_StartPosition[0]) || FloatCompare(origin[1], gF_StartPosition[1]) || FloatCompare(origin[2], gF_StartPosition[2]))
				{
					GOKZ_TeleportToStart(client);
				}
			}
			
			if(GOKZ_Fun_Race_IsRacer(client) || (IsClientObserver(client) && GetObserverTarget(client) != -1 && GOKZ_Fun_Race_IsRacer(GetObserverTarget(client))))
			{
				ShowCountDown(client, countdown);

				if(playSound)
				{
					PlayCountDownSound(client, countdown);
				}
			}
		}
	}
	
	// 继续倒计时
	return Plugin_Continue;
}