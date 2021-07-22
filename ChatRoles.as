/***
 Inspired by a friend's joke on discord.
 Use say ">> words..." to send the message to members of your role.
 * INSTALLATION: Add the following lines to "default_plugins.txt":
	"plugin"
	{
		"name" "ChatRoles"
		"script" "ChatRoles"
	}
	* NOTE: I recommend that this plugin be the last one in the archive "default_plugins.txt" to avoid problems with chat commands from other plugins.
***/

ChatRoles::CChatRoles@ g_ChatRoles = @ChatRoles::CChatRoles();

const string szFilePath = "scripts/plugins/store/ChatRoles.txt";

CClientCommand _crhelp( "crhelp", "Shows you the available commands", ClientCommandCallback( g_ChatRoles.ClientCommand ) );
CClientCommand _listroles( "listroles", "List all ChatRoles", ClientCommandCallback( g_ChatRoles.ClientCommand ) );
CClientCommand _setrole( "setrole", "Set the new role on <target> (steamid or nickname)", ClientCommandCallback( g_ChatRoles.ClientCommand ), ConCommandFlag::AdminOnly );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Rizulix" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/svencoop" );

	g_ChatRoles.OnInit();
}

void PluginExit()
{
	g_ChatRoles.OnExit();
}

void MapInit()
{
	g_ChatRoles.Initialize();
}

namespace ChatRoles
{

final class CChatRoles
{
	private dictionary m_playerRoles;
	private dictionary m_totalNumber;

	private array<string> m_listRoles;

	private uint8 SAY_TEAM = 1 << 0;
	private uint8 SAY_ME = 1 << 1;
	private uint8 SAY_SPECIAL = 1 << 2;

	void OnInit()
	{
		g_Hooks.RegisterHook( Hooks::Player::ClientSay, ClientSayHook( this.ClientSay ) );

		ReadRoles();
	}

	void OnExit()
	{
		g_Hooks.RemoveHook( Hooks::Player::ClientSay, ClientSayHook( this.ClientSay ) );

		m_playerRoles.deleteAll();
		m_totalNumber.deleteAll();

		m_listRoles.removeRange( 0, m_listRoles.length() );
	}

	void Initialize()
	{
		m_playerRoles.deleteAll();
		m_totalNumber.deleteAll();

		m_listRoles.removeRange( 0, m_listRoles.length() );

		ReadRoles();
	}

	private void AddRoles( string szAuthId, string szRole )
	{
		if( m_playerRoles.exists(szAuthId) )
			return;

		m_playerRoles[szAuthId] = szRole;

		if( m_listRoles.find( szRole ) >= 0 )
			m_totalNumber[szRole] = int(m_totalNumber[szRole]) + 1;
		else
		{
			m_listRoles.insertLast( szRole );
			m_totalNumber[szRole] = 1;
		}
	}

	private void ReadRoles()
	{
		File@ pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::READ );

		if( pFile is null || !pFile.IsOpen() )
		{
			g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: \"%1\" failed to open or file not exist\n", szFilePath );
			return;
		}
		while( !pFile.EOFReached() )
		{
			string szLine;
			pFile.ReadLine( szLine );
			if( szLine.SubString(0,1) == "#" || szLine.SubString(0,2) == "//" || szLine.IsEmpty() )
				continue;

			array<string> parsed = szLine.Split(" ");
			if( parsed.length() < 2 )
				continue;

			AddRoles( parsed[0], parsed[1] );
		}
		pFile.Close();
	}

	void ClientCommand( const CCommand@ args )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		const string szFirstArg = args.Arg(0).ToLowercase();

		if( args.ArgC() == 1 && szFirstArg == ".crhelp" )
			Help( pPlayer );
		else if( args.ArgC() == 1 && szFirstArg == ".listroles" )
			ListRoles( pPlayer );
		else if( args.ArgC() <= 3 && szFirstArg == ".setrole" )
			SetRole( pPlayer, args, true );
	}

	private void Help( CBasePlayer@ pPlayer )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "AVAILABLE CHATROLES COMMANDS:\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "------------------------\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".listroles\" in console to list all roles.\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".crhelp\" in console to shows you the available commands.\n" );
		if( g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Type \".setrole <target> <role>\", in the console or in the chat to set the new role on target.\n" );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Where target can be: \"nickname\" or \"steamid\", to delete a role <role> must be \"none\"\n" );
		}
	}

	private void ListRoles( CBasePlayer@ pPlayer )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "CURRENT ROLE LIST\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "------------------------\n" );

		for( uint i = 0; i < m_listRoles.length(); i++ )
		{
			if( m_listRoles[i] == "" || int(m_totalNumber[m_listRoles[i]]) <= 0 )
				continue;

			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "* " + m_listRoles[i] + " ( " + int(m_totalNumber[m_listRoles[i]]) + " )\n" );
		}
	}

	private void UpdateRoleList( string szNewRole )
	{
		if( m_totalNumber.exists(szNewRole) )
			m_totalNumber[szNewRole] = int(m_totalNumber[szNewRole]) + 1;
		else
		{
			m_listRoles.insertLast( szNewRole );
			m_totalNumber[szNewRole] = 1;
		}
	}

	private void UpdateRole( CBasePlayer@ pPlayer, CBasePlayer@ pTarget, const CCommand@ args, bool bConsole )
	{
		File@ pFile;
		array<string> save;
		bool bUpdated = false, bReaded = false;
		string szNewRole = args.Arg(2), szChecker = szNewRole;
		string szAuthId = auth_id(pTarget), szNetname = pTarget.pev.netname;
		bool bRemove = szChecker.ToLowercase() == "none";

		@pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::READ );
		if( pFile is null || !pFile.IsOpen() )
		{
			g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Player \"%1\" attempted to open \"%2\" but failed to open or file not exist\n", pPlayer.pev.netname, szFilePath );
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Something is wrong, unable to reach file\n" );
			return;
		}
		while( !pFile.EOFReached() )
		{
			string szLine;
			pFile.ReadLine( szLine );
			array<string> parsed = szLine.Split(" ");
			if( parsed[0] == szAuthId )
			{
				if( bRemove )
				{
					if( parsed.length() >= 2 )
					{
						g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Removing Role \"%1\" for \"%2\". Requested by: \"%4\"\n", parsed[1], szAuthId, pPlayer.pev.netname );
						g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Removing Role \"" + parsed[1] + "\" for \"" + szNetname + "\"\n" );
						m_totalNumber[parsed[1]] = int(m_totalNumber[parsed[1]]) - 1;
					}
					else
					{
						g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Player \"" + szNetname + "\" did not have role!\n" );
					}
					save.insertLast( szAuthId );
					bUpdated = true;
					szNewRole = "";
					continue;
				}
				else
				{
					if( parsed.length() >= 2 )
					{
						g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Replacing \"%1\" with \"%2\" for \"%3\". Requested by: \"%4\"\n", parsed[1], szNewRole, szAuthId, pPlayer.pev.netname );
						g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Replacing \"" + parsed[1] + "\" with \"" + szNewRole + "\" for \"" + szNetname + "\"\n" );
						m_totalNumber[parsed[1]] = int(m_totalNumber[parsed[1]]) - 1;
						UpdateRoleList( szNewRole );
					}
					else
					{
						g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Adding Role \"%1\" for \"%2\". Requested by: \"%3\"\n", szNewRole, szNetname, pPlayer.pev.netname );
						g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Adding \"" + szNewRole + "\" for \"" + szNetname + "\"\n" );
						UpdateRoleList( szNewRole );
					}
					save.insertLast( szAuthId + " " + szNewRole );
					bUpdated = true;
					continue;
				}
			}
			save.insertLast( szLine );
		}
		bReaded = true;
		pFile.Close();

		if( bReaded )
		{
			if( !bUpdated )
			{
				if( bRemove )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Player \"" + szNetname + "\" did not have role!\n" );
					szNewRole = "";
				}
				else
				{
					g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Creating Role \"%1\" for \"%2\". Requested by: \"%3\"\n", szNewRole, szAuthId, pPlayer.pev.netname );
					g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Created Role \"" + szNewRole + "\" for \"" + szNetname + "\"\n" );
					UpdateRoleList( szNewRole );
					save.insertLast( szAuthId + " " + szNewRole );
				}
			}

			@pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::WRITE );
			if( pFile !is null && pFile.IsOpen() )
			{
				for( uint i = 0; i < save.length(); i++ )
				{
					if( i < save.length()-1 )
						pFile.Write( save[i] + "\n" );
					else
						pFile.Write( save[i] );
				}
				pFile.Close();
			}
			m_playerRoles[szAuthId] = szNewRole;
		}
	}

	private void SetRole( CBasePlayer@ pPlayer, const CCommand@ args, bool bConsole )
	{
		if( g_PlayerFuncs.AdminLevel( pPlayer ) < ADMIN_YES )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] You don't have permission for this command!\n" );
			return;
		}

		if( args.Arg(1).SubString(0,6).ToLowercase() == "steam_" )
		{
			CBasePlayer@ pTarget = null;
			for( int i = 1; i <= g_Engine.maxClients; i++ )
			{
				CBasePlayer@ pTemp = g_PlayerFuncs.FindPlayerByIndex( i );
				if( pTemp is null || !pTemp.IsConnected() )
					continue;

				string szAuthId = auth_id(pTemp);
				szAuthId.ToLowercase();

				if( szAuthId == args.Arg(1).ToLowercase() )
					@pTarget = pTemp;
			}

			if( pTarget is null || !pTarget.IsConnected() || args.Arg(2) == "" )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] " + (args.Arg(2) == "" ? "Empty argument!" : "Invalid target id!") + "\n" );
				return;
			}
			UpdateRole( pPlayer, pTarget, args, bConsole );
		}
		else if( args.Arg(1) != "" )
		{
			CBasePlayer@ pTarget = null;
			for( int i = 1; i <= g_Engine.maxClients; i++ )
			{
				CBasePlayer@ pTemp = g_PlayerFuncs.FindPlayerByIndex( i );
				if( pTemp is null || !pTemp.IsConnected() )
					continue;

				if( string(pTemp.pev.netname).ToLowercase() == args.Arg(1).ToLowercase() )
					@pTarget = pTemp;
			}

			if( pTarget is null || !pTarget.IsConnected() || args.Arg(2) == "" )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] " + (args.Arg(2) == "" ? "Empty argument!" : "Invalid target id!") + "\n" );
				return;
			}
			UpdateRole( pPlayer, pTarget, args, bConsole );
		}
		else
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] You must write a target!\n" );
			return;
		}
	}

	private void SayWithRole( CBasePlayer@ pPlayer, const uint8 uiFlags, const string szMessage )
	{
		const string szTeamTag = (bit_set( uiFlags, SAY_TEAM ) ? "(TEAM) [" : "[");

		if( bit_set( uiFlags, SAY_SPECIAL ) )
		{
			for( int i = 1; i <= g_Engine.maxClients; i++ )
			{
				CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( i );
				if( pTarget is null || !pTarget.IsConnected() )
					continue;

				if( string(m_playerRoles[auth_id(pPlayer)]) != string(m_playerRoles[auth_id(pTarget)]) )
					continue;

				g_PlayerFuncs.SayText( pTarget, ">> " + szTeamTag + string(m_playerRoles[auth_id(pPlayer)]) + "] " + pPlayer.pev.netname + ": " + szMessage + "\n" );
			}
		}
		else
			g_PlayerFuncs.SayTextAll( pPlayer, (bit_set( uiFlags, SAY_ME ) ? "* " : "") + szTeamTag + string(m_playerRoles[auth_id(pPlayer)]) + "] " + pPlayer.pev.netname + (bit_set( uiFlags, SAY_ME ) ? " " : ": ") + szMessage + "\n" );
	}

	private void SayWithRole( CBasePlayer@ pPlayer, ClientSayType sayTipe, string szMessage )
	{
		uint8 uiFlags = 0;
		array<string> parsed = szMessage.Split(" ");
		if( sayTipe == CLIENTSAY_SAYTEAM ) uiFlags |= SAY_TEAM;
		if( parsed[0] == "/me" && parsed.length() >= 2 ) uiFlags |= SAY_ME;
		if( parsed[0] == ">>" && parsed.length() >= 2 ) uiFlags |= SAY_SPECIAL;

		if( bit_set( uiFlags, SAY_ME ) || bit_set( uiFlags, SAY_SPECIAL ) )
		{
			szMessage = "";
			for( uint i = 1; i < parsed.length(); i++ )
			{
				if( i < parsed.length()-1 )
					szMessage += parsed[i] + " ";
				else
					szMessage += parsed[i];
			}
		}

		if( bit_set( uiFlags, SAY_TEAM ) )
		{
			const int iClass = pPlayer.Classify();
			if( iClass >= 16 && iClass <= 19 )
			{
				for( int i = 1; i <= g_Engine.maxClients; i++ )
				{
					CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( i );
					if( pTarget is null || !pTarget.IsConnected() )
						continue;

					if( pTarget.Classify() != iClass )
						continue;

					if( bit_set( uiFlags, SAY_SPECIAL ) )
					{
						if( string(m_playerRoles[auth_id(pPlayer)]) != string(m_playerRoles[auth_id(pTarget)]) )
							continue;

						g_PlayerFuncs.SayText( pTarget, ">> (TEAM) [" + string(m_playerRoles[auth_id(pPlayer)]) + "] " + pPlayer.pev.netname + ": " + szMessage + "\n" );
					}
					else
						g_PlayerFuncs.SayText( pTarget, (bit_set( uiFlags, SAY_ME ) ? "* (TEAM) [" : "(TEAM) [") + string(m_playerRoles[auth_id(pPlayer)]) + "] " + pPlayer.pev.netname + (bit_set( uiFlags, SAY_ME ) ? " " : ": ") + szMessage + "\n" );
				}
			}
			else
				SayWithRole( pPlayer, uiFlags, szMessage );
		}
		else
			SayWithRole( pPlayer, uiFlags, szMessage );
	}

	HookReturnCode ClientSay( SayParameters@ pParams )
	{
		CBasePlayer@ pPlayer = pParams.GetPlayer();
		const CCommand@ args = pParams.GetArguments();
		const bool bHasRole = m_playerRoles.exists(auth_id(pPlayer)) && string(m_playerRoles[auth_id(pPlayer)]) != "";

		if( args.ArgC() <= 3 && args.Arg(0).ToLowercase() == ".setrole" )
		{
			pParams.ShouldHide = true;
			SetRole( pPlayer, args, false );
			return HOOK_HANDLED;
		}
		else if( args.ArgC() >= 1 && bHasRole )
		{
			pParams.ShouldHide = true;
			SayWithRole( pPlayer, pParams.GetSayType(), args.GetCommandString() );
			return HOOK_HANDLED;
		}
		return HOOK_CONTINUE;
	}

	private bool bit_set( uint8 a , uint8 b )
	{
		return a & b != 0;
	}

	private string auth_id( CBasePlayer@ plr )
	{
		string szAuthId = g_EngineFuncs.GetPlayerAuthId( plr.edict() );
		if( szAuthId == "STEAM_ID_LAN" || szAuthId == "BOT" )
			szAuthId = plr.pev.netname;
		return szAuthId;
	}
}

}

