// Inspired by a friend's joke on discord.
// Use say ">| words..." to send the message to members of your role.

ChatRoles::CChatRoles@ g_ChatRoles = @ChatRoles::CChatRoles();

const string szFilePath = "scripts/plugins/store/ChatRoles.txt";

CClientCommand _listroles( "listroles", "List all roles", @ClientCommand );
CClientCommand _crhelp( "crhelp", "Shows you the available commands", @ClientCommand );
CClientCommand _setrole( "setrole", "Set the new role on <target> (steamid or nickname)", @ClientCommand );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Rizulix" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/svencoop" );

	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );

	g_ChatRoles.ReadRoles();
}

void PluginExit()
{
	g_Hooks.RemoveHook( Hooks::Player::ClientSay, @ClientSay );

	g_ChatRoles.OnExit();
}

void MapInit()
{
	g_ChatRoles.Initialize();
}

void ClientCommand( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if( args.Arg(0).ToLowercase() == ".listroles" )
		g_ChatRoles.ListRoles( pPlayer );
	else if( args.Arg(0).ToLowercase() == ".crhelp" )
		g_ChatRoles.Help( pPlayer );
	else if( args.Arg(0).ToLowercase() == ".setrole" )
		g_ChatRoles.SetRole( pPlayer, args, true );
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	return g_ChatRoles.ClientSay( pParams );
}

namespace ChatRoles
{

final class CChatRoles
{
	private dictionary m_playerRoles;
	private dictionary m_totalNumber;

	private array<string> m_listRoles;

	void ReadRoles()
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

			m_playerRoles[parsed[0]] = parsed[1];

			if( m_listRoles.find( parsed[1] ) < 0 )
			{
				m_listRoles.insertLast( parsed[1] );
				m_totalNumber[parsed[1]] = 1;
			}
			else
				m_totalNumber[parsed[1]] = int(m_totalNumber[parsed[1]]) + 1;
		}
		pFile.Close();
	}

	private void UpdateRole( CBasePlayer@ pPlayer, string szNetname, string szAuthId, string szNewRole )
	{
		File@ pFile;
		bool bUpdated = false, bReaded = false;
		string szChecker = szNewRole;
		bool bRemove = szChecker.ToLowercase() == "none";
		array<string> m_save;

		@pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::READ );
		if( pFile is null || !pFile.IsOpen() )
		{
			g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Player \"%1\" attempted to open \"%2\" but failed to open or file not exist\n", pPlayer.pev.netname, szFilePath );
			g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Something is wrong, unable to reach file\n" );
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
						g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Removing Role \"" + parsed[1] + "\" for \"" + szNetname + "\"\n" );
						m_totalNumber[parsed[1]] = int(m_totalNumber[parsed[1]]) - 1;
					}
					else
					{
						g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Player \"" + szNetname + "\" did not have role!\n" );
					}
					m_save.insertLast( szAuthId );
					bUpdated = true;
					szNewRole = "";
					continue;
				}
				else
				{
					if( parsed.length() >= 2 )
					{
						g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Replacing \"%1\" with \"%2\" for \"%3\". Requested by: \"%4\"\n", parsed[1], szNewRole, szAuthId, pPlayer.pev.netname );
						g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Replacing \"" + parsed[1] + "\" with \"" + szNewRole + "\" for \"" + szNetname + "\"\n" );
						m_totalNumber[parsed[1]] = int(m_totalNumber[parsed[1]]) - 1;
						if( m_totalNumber.exists(szNewRole) )
							m_totalNumber[szNewRole] = int(m_totalNumber[szNewRole]) + 1;
						else
						{
							m_listRoles.insertLast( szNewRole );
							m_totalNumber[szNewRole] = 1;
						}
					}
					else
					{
						g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Adding Role \"%1\" for \"%2\". Requested by: \"%3\"\n", szNewRole, szNetname, pPlayer.pev.netname );
						g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Adding \"" + szNewRole + "\" for \"" + szNetname + "\"\n" );
						if( m_totalNumber.exists(szNewRole) )
							m_totalNumber[szNewRole] = int(m_totalNumber[szNewRole]) + 1;
						else
						{
							m_listRoles.insertLast( szNewRole );
							m_totalNumber[szNewRole] = 1;
						}
					}
					m_save.insertLast( szAuthId + " " + szNewRole );
					bUpdated = true;
					continue;
				}
			}
			m_save.insertLast( szLine );
		}
		bReaded = true;
		pFile.Close();

		if( bReaded )
		{
			if( !bUpdated )
			{
				if( bRemove )
				{
					g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Player \"" + szNetname + "\" did not have role!\n" );
					szNewRole = "";
				}
				else
				{
					g_Game.AlertMessage( at_console, "[ChatRoles] ATTENTION: Creating Role \"%1\" for \"%2\". Requested by: \"%3\"\n", szNewRole, szAuthId, pPlayer.pev.netname );
					g_PlayerFuncs.SayText( pPlayer, "[ChatRoles] Created Role \"" + szNewRole + "\" for \"" + szNetname + "\"\n" );
					if( m_totalNumber.exists(szNewRole) )
						m_totalNumber[szNewRole] = int(m_totalNumber[szNewRole]) + 1;
					else
					{
						m_listRoles.insertLast( szNewRole );
						m_totalNumber[szNewRole] = 1;
					}
					m_save.insertLast( szAuthId + " " + szNewRole );
				}
			}

			@pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::WRITE );
			if( pFile !is null && pFile.IsOpen() )
			{
				for( uint i = 0; i < m_save.length(); i++ )
				{
					if( i < m_save.length()-1 )
						pFile.Write( m_save[i] + "\n" );
					else
						pFile.Write( m_save[i] );
				}
				pFile.Close();
			}
			m_playerRoles[szAuthId] = szNewRole;
		}
	}

	void Initialize()
	{
		m_playerRoles.deleteAll();
		m_totalNumber.deleteAll();

		m_listRoles.removeRange( 0, m_listRoles.length() );

		ReadRoles();
	}

	void OnExit()
	{
		m_playerRoles.deleteAll();
		m_totalNumber.deleteAll();

		m_listRoles.removeRange( 0, m_listRoles.length() );
	}

	void ListRoles( CBasePlayer@ pPlayer )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "CURRENT ROLE LIST\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "------------------------\n" );

		for( uint i = 0; i < m_listRoles.length(); i++ )
		{
			if( m_listRoles[i] == "" || int(m_totalNumber[m_listRoles[i]]) <= 0 )
				continue;

			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "* " + m_listRoles[i] + " (" + int(m_totalNumber[m_listRoles[i]]) + ")\n" );
		}
	}

	void Help( CBasePlayer@ pPlayer )
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

	void SetRole( CBasePlayer@ pPlayer, const CCommand@ args, bool bConsole )
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

			if( pTarget is null || !pTarget.IsConnected() )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Invalid target id!\n" );
				return;
			}
			if( args.Arg(2) == "" )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Empty argument!\n" );
				return;
			}
			UpdateRole( pPlayer, pTarget.pev.netname, auth_id(pTarget), args.Arg(2) );
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

			if( pTarget is null || !pTarget.IsConnected() )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Invalid target name!\n" );
				return;
			}
			if( args.Arg(2) == "" )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] Empty argument!\n" );
				return;
			}
			UpdateRole( pPlayer, pTarget.pev.netname, auth_id(pTarget), args.Arg(2) );
		}
		else
		{
			g_PlayerFuncs.ClientPrint( pPlayer, bConsole ? HUD_PRINTCONSOLE : HUD_PRINTTALK, "[ChatRoles] You must write a target!\n" );
			return;
		}
	}

	private void SayWithRole( CBasePlayer@ pPlayer, ClientSayType sayTipe, string szMessage )
	{
		const string szNetname = pPlayer.pev.netname;
		const int iClass = pPlayer.Classify();
		array<string> parsed = szMessage.Split(" ");
		bool bItsMe = parsed[0] == "/me";
		bool bItsEx = parsed[0] == ">|";

		if( bItsMe && parsed.length() >= 2 )
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
		if( bItsEx && parsed.length() >= 2 )
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

		if( sayTipe == CLIENTSAY_SAYTEAM )
		{
			if( iClass >= 16 && iClass <= 19 )
			{
				for( int i = 1; i <= g_Engine.maxClients; i++ )
				{
					CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( i );
					if( pTarget is null || !pTarget.IsConnected() )
						continue;

					if( pTarget.Classify() != iClass )
						continue;

					g_PlayerFuncs.SayText( pTarget, (bItsMe ? "* (TEAM) [" : "(TEAM) [") + string(m_playerRoles[auth_id(pPlayer)]) + "] " + szNetname + (bItsMe ? " " : ": ") + szMessage + "\n" );
				}
			}
			else
			{
				if( bItsEx )
				{
					for( int i = 1; i <= g_Engine.maxClients; i++ )
					{
						CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( i );
						if( pTarget is null || !pTarget.IsConnected() )
							continue;

						if( string(m_playerRoles[auth_id(pPlayer)]) != string(m_playerRoles[auth_id(pTarget)]) )
							continue;

						g_PlayerFuncs.SayText( pTarget, (bItsMe ? "* (TEAM) [" : "(TEAM) [") + string(m_playerRoles[auth_id(pPlayer)]) + "] " + szNetname + (bItsMe ? " " : ": ") + szMessage + "\n" );
					}
				}
				else
					g_PlayerFuncs.SayTextAll( pPlayer, (bItsMe ? "* (TEAM) [" : "(TEAM) [") + string(m_playerRoles[auth_id(pPlayer)]) + "] " + szNetname + (bItsMe ? " " : ": ") + szMessage + "\n" );
			}
		}
		else
		{
			if( bItsEx )
			{
				for( int i = 1; i <= g_Engine.maxClients; i++ )
				{
					CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( i );
					if( pTarget is null || !pTarget.IsConnected() )
						continue;

					if( string(m_playerRoles[auth_id(pPlayer)]) != string(m_playerRoles[auth_id(pTarget)]) )
						continue;

					g_PlayerFuncs.SayText( pTarget, (bItsMe ? "* [" : "[") + string(m_playerRoles[auth_id(pPlayer)]) + "] " + szNetname + (bItsMe ? " " : ": ") + szMessage + "\n" );
				}
			}
			else
				g_PlayerFuncs.SayTextAll( pPlayer, (bItsMe ? "* [" : "[") + string(m_playerRoles[auth_id(pPlayer)]) + "] " + szNetname + (bItsMe ? " " : ": ") + szMessage + "\n" );
		}
	}

	HookReturnCode ClientSay( SayParameters@ pParams )
	{
		CBasePlayer@ pPlayer = pParams.GetPlayer();
		const CCommand@ args = pParams.GetArguments();
		const bool bHasRole = m_playerRoles.exists(auth_id(pPlayer)) && string(m_playerRoles[auth_id(pPlayer)]) != "";

		if( args.ArgC() < 4 && ( args.Arg(0).ToLowercase() == ".setrole" ) )
		{
			pParams.ShouldHide = true;
			SetRole( pPlayer, args, false );
			return HOOK_HANDLED;
		}
		if( args.ArgC() != 0 && bHasRole )
		{
			pParams.ShouldHide = true;
			SayWithRole( pPlayer, pParams.GetSayType(), args.GetCommandString() );
			return HOOK_HANDLED;
		}
		return HOOK_CONTINUE;
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
