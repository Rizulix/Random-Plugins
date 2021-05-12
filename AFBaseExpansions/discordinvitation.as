DiscordInvitation discordinvitation;

void DiscordInvitation_Call()
{
	discordinvitation.RegisterExpansion( discordinvitation );
}

class DiscordInvitation : AFBaseClass
{
	void ExpansionInfo()
	{
		this.AuthorName = "Rizulix";
		this.ExpansionName = "DiscordInvitation";
		this.ShortName = "DI";
	}

	void ExpansionInit()
	{
		@DiscordInvitation::g_cvarTimer = CCVar( "cvar_countdown", 1800, "- Time(sec) between each automatic message", ConCommandFlag::AdminOnly );
		@DiscordInvitation::g_cvarMsg = CCVar( "cvar_message", "Join our Discord Server: discord.gg/hTKzmak", "- Message content for DiscordInvitation", ConCommandFlag::AdminOnly );

		RegisterCommand( "countdown", "!i", "- Time(sec) between each automatic message", ACCESS_E, @DiscordInvitation::Settings );
		RegisterCommand( "message", "!s", "- Message content for DiscordInvitation", ACCESS_E, @DiscordInvitation::Settings );
		RegisterCommand( "say !discord", "", "- Show you discord invitation link", ACCESS_Z, @DiscordInvitation::invitation_cmd_handle, CMD_SUPRESS );
	}

	void MapInit()
	{
		if( DiscordInvitation::g_InvitationThink !is null )
			g_Scheduler.RemoveTimer( DiscordInvitation::g_InvitationThink );

		@DiscordInvitation::g_InvitationThink = g_Scheduler.SetInterval( "InvitationThink", DiscordInvitation::g_cvarTimer.GetInt() );
	}

	void StopEvent()
	{
		if( DiscordInvitation::g_InvitationThink !is null )
			g_Scheduler.RemoveTimer( DiscordInvitation::g_InvitationThink );
	}

	void StartEvent()
	{
		if( DiscordInvitation::g_InvitationThink is null )
			@DiscordInvitation::g_InvitationThink = g_Scheduler.SetInterval( "InvitationThink", DiscordInvitation::g_cvarTimer.GetInt() );
	}
}

namespace DiscordInvitation
{
	CCVar@ g_cvarTimer;
	CCVar@ g_cvarMsg;

	CScheduledFunction@ g_InvitationThink = null;

	void Settings( AFBaseArguments@ args )
	{
		CBasePlayer@ pPlayer = args.User;

		if( pPlayer is null )
			return;

		const string szCommand = args.RawArgs[0];

		if( args.GetCount() < 1 )
		{
			if( szCommand == "countdown" )
			{
				discordinvitation.Tell( "\"countdown\" is \"" + g_cvarTimer.GetInt() + "\"", pPlayer, HUD_PRINTCONSOLE );
			}
			else if( szCommand == "message" )
			{
				discordinvitation.Tell( "\"message\" is \"" + g_cvarMsg.GetString() + "\"", pPlayer, HUD_PRINTCONSOLE );
			}
		}
		else if( args.GetCount() == 1 )
		{
			if( szCommand == "countdown" )
			{
				if( args.GetInt(0) != g_cvarTimer.GetInt() )
				{
					g_cvarTimer.SetInt( args.GetInt(0) );
					discordinvitation.Tell( "\"countdown\" changed to \"" + g_cvarTimer.GetInt() + "\"", pPlayer, HUD_PRINTCONSOLE );
					discordinvitation.Log( "\"countdown\" changed to \"" + g_cvarTimer.GetInt() + "\"" );
					RefreshScheduler();
				}
			}
			else if( szCommand == "message" )
			{
				if( args.GetString(0) != g_cvarMsg.GetString() )
				{
					g_cvarMsg.SetString( args.GetString(0) );
					discordinvitation.Tell( "\"message\" changed to \"" + g_cvarMsg.GetString() + "\"", pPlayer, HUD_PRINTCONSOLE );
					discordinvitation.Log( "\"message\" changed to \"" + g_cvarMsg.GetString() + "\"" );
				}
			}
		}
	}

	void invitation_cmd_handle( AFBaseArguments@ args )
	{
		CBasePlayer@ pPlayer = args.User;

		discordinvitation.Tell( g_cvarMsg.GetString(), pPlayer, HUD_PRINTTALK );
	}

	void InvitationThink()
	{
		discordinvitation.TellAll( g_cvarMsg.GetString(), HUD_PRINTTALK );
	}

	void RefreshScheduler()
	{
		if( g_InvitationThink !is null )
			g_Scheduler.RemoveTimer( g_InvitationThink );

		@g_InvitationThink = g_Scheduler.SetInterval( "InvitationThink", g_cvarTimer.GetInt() );
	}
}
