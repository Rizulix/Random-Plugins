/***
 * IMPORTANT: Only support mp3 files.
 * INSTALLATION: Add the following lines to "default_plugins.txt":
	"plugin"
	{
		"name" "LoadingMusic"
		"script" "LoadingMusic"
		"concommandns" "lm"
	}
***/

LoadingMusic::CLoadingMusic@ g_LoadingMusic = @LoadingMusic::CLoadingMusic();

const string szFilePath = "scripts/plugins/store/LoadingMusic.txt";

CClientCommand _loadingmusic( "loadingmusic", "List all LoadingMusic", @ClientCommandCallback( @g_LoadingMusic.ClientCommand ), ConCommandFlag::AdminOnly );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Rizulix" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/svencoop" );

	g_LoadingMusic.OnInit();
}

void PluginExit()
{
	g_LoadingMusic.OnExit();
}

void MapInit()
{
	g_LoadingMusic.Initialize();
}

namespace LoadingMusic
{

final class CTrack
{
	private string m_szName;
	private string m_szFile;
	private string m_szDuration;

	string Name
	{
		get const { return m_szName; }
		set { m_szName = value; }
	}

	string File
	{
		get const { return m_szFile; }
		set { m_szFile = value; }
	}

	string Duration
	{
		get const { return m_szDuration; }
		set { m_szDuration = value; }
	}

	CTrack( string szName, string szFile, string szDuration )
	{
		m_szName = szName;
		m_szFile = szFile;
		m_szDuration = szDuration;
	}
}

final class CLoadingMusic
{
	private CCVar@ g_PlayList;
	private CCVar@ g_OnJoinDelay;

	private array<CTrack@> m_mediaList = 
	{
		CTrack( "Sven Co-op Theme - Pavel Perepelitsa", "gamestartup.mp3", "1:49" ), 
		CTrack( "Sven Co-op Halloween Theme", "gamestartup_halloween.mp3", "3:02" ), 
		CTrack( "Sven Co-op Theme Alt.", "gamestartup2.mp3", "6:55" ), 
		CTrack( "Adrenaline Horror - Kelly Bailey", "Half-Life01.mp3", "2:09" ), 
		CTrack( "Vague Voices (Black Mesa Inbound) - Kelly Bailey", "Half-Life02.mp3", "2:11" ), 
		CTrack( "Klaxon Beat - Kelly Bailey", "Half-Life03.mp3", "1:00" ), 
		CTrack( "Space Ocean (Echoes of a Resonance Cascade) - Kelly Bailey", "Half-Life04.mp3", "1:36" ), 
		CTrack( "Cavern Ambiance (Zero Point Energy Field) - Kelly Bailey", "Half-Life05.mp3", "1:39" ), 
		CTrack( "Apprehensive Short - Kelly Bailey", "Half-Life06.mp3", "0:23" ), 
		CTrack( "Bass String Short - Kelly Bailey", "Half-Life07.mp3", "0:08" ), 
		CTrack( "Hurricane Strings (Neutrino Trap) - Kelly Bailey", "Half-Life08.mp3", "1:33" ), 
		CTrack( "Diabolical Adrenaline Guitar (Lambda Core) - Kelly Bailey", "Half-Life09.mp3", "1:44" ), 
		CTrack( "Valve Theme [Long Version] (Hazardous Environments) - Kelly Bailey", "Half-Life10.mp3", "1:22" ), 
		CTrack( "Nepal Monastery - Kelly Bailey", "Half-Life11.mp3", "2:08" ), 
		CTrack( "Alien Shock (Biozeminade Fragment) - Kelly Bailey", "Half-Life12.mp3", "0:36" ), 
		CTrack( "Sirens in the Distance (Triple Entanglement) - Kelly Bailey", "Half-Life13.mp3", "1:12" ), 
		CTrack( "Nuclear Mission Jam (Something Secret Steers Us) - Kelly Bailey", "Half-Life14.mp3", "2:00" ), 
		CTrack( "Scared Confusion Short - Kelly Bailey", "Half-Life15.mp3", "0:16" ), 
		CTrack( "Drums and Riffs (Tau-9) - Kelly Bailey", "Half-Life16.mp3", "2:03" ), 
		CTrack( "Hard Technology Rock - Kelly Bailey", "Half-Life17.mp3", "1:40" ), 
		CTrack( "Steam in the Pipes (Negative Pressure) - Kelly Bailey", "Half-Life18.mp3", "1:55" ), 
		CTrack( "Electric Guitar Ambiance (Escape Array) - Kelly Bailey", "Half-Life19.mp3", "1:24" ), 
		CTrack( "Dimensionless Deepness (Dirac Shore) - Kelly Bailey", "Half-Life20.mp3", "1:24" ), 
		CTrack( "Military Precision - Kelly Bailey", "Half-Life21.mp3", "1:20" ), 
		CTrack( "Jungle Drums - Kelly Bailey", "Half-Life22.mp3", "1:49" ), 
		CTrack( "Traveling through Limbo (Singularity) - Kelly Bailey", "Half-Life23.mp3", "1:17" ), 
		CTrack( "Closing Theme (Tracking Device) - Kelly Bailey", "Half-Life24.mp3", "1:39" ), 
		CTrack( "Threatening Short (Xen Relay) - Kelly Bailey", "Half-Life25.mp3", "0:37" ), 
		CTrack( "Dark Piano Short - Kelly Bailey", "Half-Life26.mp3", "0:17" ), 
		CTrack( "Sharp Fear Short - Kelly Bailey", "Half-Life27.mp3", "0:06" ), 
		CTrack( "Valve Theme [Short Version] (Hazardous Environments) - Kelly Bailey", "valve.mp3", "0:11" ), 
		CTrack( "Scientific Proof - Chris Jensen", "opfor/OpposingForce01.mp3", "0:17" ), 
		CTrack( "Orbit - Chris Jensen", "opfor/OpposingForce02.mp3", "0:48" ), 
		CTrack( "Name - Chris Jensen", "opfor/OpposingForce03.mp3", "1:52" ), 
		CTrack( "Listen - Chris Jensen", "opfor/OpposingForce04.mp3", "0:17" ), 
		CTrack( "Fright - Chris Jensen", "opfor/OpposingForce05.mp3", "1:00" ), 
		CTrack( "Storm - Chris Jensen", "opfor/OpposingForce06.mp3", "1:38" ), 
		CTrack( "Trample - Chris Jensen", "opfor/OpposingForce07.mp3", "1:18" ), 
		CTrack( "Bust - Chris Jensen", "opfor/OpposingForce08.mp3", "1:48" ), 
		CTrack( "The Beginning - Chris Jensen", "opfor/OpposingForce09.mp3", "2:07" ), 
		CTrack( "Lost in Thought - Chris Jensen", "opfor/OpposingForce10.mp3", "1:21" ), 
		CTrack( "Danger Rises - Chris Jensen", "opfor/OpposingForce11.mp3", "1:16" ), 
		CTrack( "Soothing Antagonist - Chris Jensen", "opfor/OpposingForce12.mp3", "1:27" ), 
		CTrack( "Run - Chris Jensen", "opfor/OpposingForce13.mp3", "0:53" ), 
		CTrack( "Open the Valve - Chris Jensen", "opfor/OpposingForce14.mp3", "1:24" ), 
		CTrack( "Tunnel - Chris Jensen", "opfor/OpposingForce15.mp3", "1:26" ), 
		CTrack( "Chamber - Chris Jensen", "opfor/OpposingForce16.mp3", "1:33" ), 
		CTrack( "Maze - Chris Jensen", "opfor/OpposingForce17.mp3", "0:59" ), 
		CTrack( "Alien Forces - Chris Jensen", "opfor/OpposingForce18.mp3", "1:16" ), 
		CTrack( "Planet - Chris Jensen", "opfor/OpposingForce19.mp3", "1:32" ), 
		CTrack( "Cyborg - Steve 'BLEVO' Blevin", "cyborg-blevo.mp3", "3:32" ), 
		CTrack( "Sven Co-op 3.0 Theme - Ilkka Richt (Gluem)", "SC30_Menu-Gleum.mp3", "1:08" )
	};
	private array<CTrack@> m_musicList;

	private int m_iPlayList;
	private float m_flOnJoinDelay;

	void OnInit()
	{
		g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnectedHook( this.ClientConnected ) );
		g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServerHook( this.ClientPutInServer ) );

		if( g_PlayList is null || g_OnJoinDelay is null )
		{
			@g_PlayList = CCVar( "playlist", 0, "0:auto(if no custom music is available, the ost will be used), 1:only ost", ConCommandFlag::AdminOnly, @CVarCallback( this.CVar ) ); // as_command lm.playlist
			@g_OnJoinDelay = CCVar( "onjoindelay", 0.0f, "", ConCommandFlag::AdminOnly, @CVarCallback( this.CVar ) ); // as_command lm.onjoindelay
		}

		ReadMusic();
		GetValidValues( m_iPlayList, m_flOnJoinDelay );
	}

	void OnExit()
	{
		g_Hooks.RemoveHook( Hooks::Player::ClientConnected, @ClientConnectedHook( this.ClientConnected ) );
		g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, @ClientPutInServerHook( this.ClientPutInServer ) );

		m_musicList.removeRange( 0, m_musicList.length() );
	}

	void Initialize()
	{
		m_musicList.removeRange( 0, m_musicList.length() );

		LoadMusic();
	}

	private void AddTrack( CTrack@ pTrack )
	{
		if( pTrack is null )
			return;

		if( m_musicList.findByRef( @pTrack ) >= 0 )
			return;

		m_musicList.insertLast( pTrack );
	}

	private void ReadMusic()
	{
		File@ pFile = g_FileSystem.OpenFile( szFilePath, OpenFile::READ );

		if( pFile is null || !pFile.IsOpen() )
		{
			g_Game.AlertMessage( at_console, "[LoadingMusic] ATTENTION: \"%1\" failed to open or file not exist.\n", szFilePath );
			return;
		}
		while( !pFile.EOFReached() )
		{
			string szLine;
			pFile.ReadLine( szLine );
			if( szLine.SubString(0,1) == "#" || szLine.SubString(0,2) == "//" || szLine.IsEmpty() )
				continue;

			array<string> parsed = szLine.Split("|");
			if( parsed.length() < 3 )
				continue;

			for( uint i = 0; i < parsed.length(); i++ )
				parsed[i].Trim();

			AddTrack( CTrack( parsed[0], parsed[1], parsed[2] ) );
		}
		pFile.Close();
	}

	private void LoadMusic()
	{
		ReadMusic();

		for( uint i = 0; i < m_musicList.length(); i++ )
		{
			CTrack@ pTrack = m_musicList[i];
			g_Game.PrecacheGeneric( "sound/" + pTrack.File );
		}
	}

	private void GetValidValues( int& out iPlayList, float& out flOnJoinDelay )
	{
		iPlayList = Math.clamp( 0, 1, g_PlayList.GetInt() );
		flOnJoinDelay = Math.clamp( 0.0f, Math.FLOAT_MAX, g_OnJoinDelay.GetFloat() );
	}

	void ClientCommand( const CCommand@ args )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		const string szFirstArg = args.Arg(0).ToLowercase();

		if( args.ArgC() == 1 && szFirstArg == ".loadingmusic" )
			ListLoadingMusic( pPlayer );
	}

	void CVar( CCVar@ cvar, const string& in, float )
	{
		if( cvar is g_PlayList || cvar is g_OnJoinDelay )
			GetValidValues( m_iPlayList, m_flOnJoinDelay );
	}

	private void ListLoadingMusic( CBasePlayer@ pPlayer )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "AVALIABLE MUSIC FOR LOADING SCREENS\n" );
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "------------------------\n" );

		if( m_musicList.length() > 0 )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "* CUSTOM PLAYLIST" + (m_iPlayList == 0 ? " [IN USE] :" : ":" ) + "\n" );
			for( uint i = 0; i < m_musicList.length(); i++ )
			{
				CTrack@ pTrack = m_musicList[i];
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, string(i+1) + ". " + pTrack.Name + " - " + pTrack.Duration + "\n" );
			}
		}

		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "* IN-GAME PLAYLIST" + ((m_iPlayList == 1 || m_musicList.length() == 0) ? " [IN USE] :" : ":" ) + "\n" );
		for( uint i = 0; i < m_mediaList.length(); i++ )
		{
			CTrack@ pTrack = m_mediaList[i];
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, string(i+1) + ". " + pTrack.Name + " - " + pTrack.Duration + "\n" );
		}
	}

	private void ClientCommand( edict_t@ pEdict, string szCommand )
	{
		NetworkMessage netmsg( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, @pEdict );
			netmsg.WriteString( szCommand );
		netmsg.End();
	}

	private void MediaLoop( edict_t@ pEdict )
	{
		if( pEdict is null )
			return;

		CTrack@ pTrack = m_mediaList[Math.RandomLong(0,m_mediaList.length()-1)];
		string szTrack = pTrack.File;
		szTrack = szTrack.SubString(0,szTrack.Find("."));
		if( pTrack.Name.Find("BLEVO") != String::INVALID_INDEX || pTrack.Name.Find("Gluem") != String::INVALID_INDEX )
			ClientCommand( pEdict, ";mp3 loop \"mp3/" + szTrack + "\";" );
		else
			ClientCommand( pEdict, ";mp3 loop \"media/" + szTrack + "\";" );
	}

	private void Mp3Loop( edict_t@ pEdict )
	{
		if( pEdict is null )
			return;

		ClientCommand( pEdict, ";mp3 stop;" );

		switch( m_iPlayList )
		{
			case 0:
			{
				if( m_musicList.length() > 0 )
				{
					CTrack@ pTrack = m_musicList[Math.RandomLong(0,m_musicList.length()-1)];
					string szTrack = pTrack.File;
					szTrack = szTrack.SubString(0,szTrack.Find("."));
					ClientCommand( pEdict, ";mp3 loop \"sound/" + szTrack + "\";" );
				}
				else
					MediaLoop( pEdict );
				break;
			}
			case 1:
			{
				MediaLoop( pEdict );
				break;
			}
		}
	}

	private void Mp3Stop( edict_t@ pEdict )
	{
		if( pEdict is null )
			return;

		ClientCommand( pEdict, ";mp3 stop;" );
	}

	HookReturnCode ClientConnected( edict_t@ pEdict, const string& in, const string& in, bool& out, string& out )
	{
		if( pEdict is null )
			return HOOK_CONTINUE;

		if( m_flOnJoinDelay > 0 )
			g_Scheduler.SetTimeout( @this, "Mp3Loop", m_flOnJoinDelay, @pEdict );
		else
			Mp3Loop( pEdict );
		return HOOK_CONTINUE;
	}

	HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
	{
		if( pPlayer is null )
			return HOOK_CONTINUE;

		Mp3Stop( pPlayer.edict() );
		return HOOK_CONTINUE;
	}
}

}

