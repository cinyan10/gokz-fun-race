#if defined _gokz_run_race_included_
#endinput
#endif
#define _gokz_run_race_included_




// -------- [ 字段 ] --------
// 最大玩家数
#define MAXCLIENTS 65

stock char gC_CountDownSound[64] = "ui/competitive_accept_beep.wav"; // 倒计时音效
stock char gC_CountDownZeroSound[64] = "ui/mm_success_lets_roll.wav"; // 倒计时结束音效
stock char gC_CountDownReadySound[64] = "ui/lobby_notification_matchready.wav"; // 倒计时5秒音效

// 比赛状态枚举
enum RaceStatus:
{
	RaceStatus_End = 0, // 当前无比赛
	RaceStatus_Waiting, // 当前正在等待玩家接受比赛
	RaceStatus_Running, // 当前正在进行比赛
	RACESTATUS_COUNT,
}

// 比赛项目枚举
enum RaceType:
{
	RaceType_None = 0, // 当前无比赛
	RaceType_LeftHand, // 左手KZ
	RaceType_LowGravity, // 低重力
	RaceType_Relay, // 接力赛
	RaceType_WASD, // 更改WASD键位
	RaceType_SpaceOnly, // 空格跳
	RaceType_ADStrafeBind, // AD绑定视角
	RACETYPE_COUNT,
}

// 比赛项目名称
stock char gC_RaceTypeName[RACETYPE_COUNT][20] = {
	"无",
	"左手KZ",
	"低重力",
	"接力赛",
	"更改WASD键位",
	"空格跳",
	"AD绑定视角",
};

// 颜色枚举
enum Color:
{
	Color_White = 0,
	Color_Red,
	Color_Purple,
	Color_Green,
	Color_GreenYellow,
	Color_DarkGreen,
	Color_DarkRed,
	Color_Grey,
	Color_Yellow,
	COLOR_COUNT,
}
stock char gC_Colors[COLOR_COUNT][5] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09"};

stock int Clamp(int target, int min, int max)
{
	return target > min ? (target < max ? target : max) : min;
}



// -------- [ 接口 ] --------

/**
 * 惩罚违反规则的玩家(直接处死->终止计时并回出生点)
 * 并进行服内通告
 * @param client 对象
 * @param reason 惩罚原因
 */
native void GOKZ_Fun_Race_Punish(int client, const char[] reason);

/**
 * 获取当前正在进行的比赛项目
 */
native RaceType GOKZ_Fun_Race_GetCurrentRaceType();

 /**
	* 获取当前比赛状态
	*/
native RaceStatus GOKZ_Fun_Race_GetCurrentRaceStatus();

 /**
	* 重置所有比赛状态
	*/
native void GOKZ_Fun_Race_ResetRaceStatus();

 /**
	* 初始化新的比赛
	* @param client 操作者
	* @param raceType 比赛项目
	* @param course 比赛关卡
	*/
native void GOKZ_Fun_Race_SetupRace(int client, RaceType raceType, int course, int mode);

/**
	* 开始比赛
	* @param client 操作者
	*/
native void GOKZ_Fun_Race_StartRace(int client);

/**
	* 结束当前比赛
	* @param client 操作者
	* @param reason 结束原因
	*/
native void GOKZ_Fun_Race_EndRace(int client, char[] reason);

/**
	* 获取当前比赛是否暂停
 */
native bool GOKZ_Fun_Race_IsRacePause();

/**
	* 检查暂停状态
	* @param client 玩家
 */
native void GOKZ_Fun_Race_CheckPause(int client);

/**
	* 暂停当前比赛
	* @param client 操作者
 */
native void GOKZ_Fun_Race_PauseRace(int client);

/**
	* 恢复当前比赛
	* @param client 操作者
 */
native void GOKZ_Fun_Race_ResumeRace(int client);

/**
	* 完成比赛
	* @param client 玩家
 */
native void GOKZ_Fun_Race_FinishRace(int client);

/**
	* 比赛弃权
	* @param client 玩家
 */
native void GOKZ_Fun_Race_SurrenderRace(int client);

/**
 * 判断玩家是否为参赛者
 * @param client 玩家
 */
native bool GOKZ_Fun_Race_IsRacer(int client);

/**
 * 判断玩家是否完成比赛
 * @param client 玩家
 */
native bool GOKZ_Fun_Race_IsRacerFinished(int client);

/**
 * 添加参赛者
 * @param client 参赛者
 */
native void GOKZ_Fun_Race_AddRacer(int client);
