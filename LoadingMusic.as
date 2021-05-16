const string MUSIC_PATH = "scripts/plugins/store/LoadingMusic.txt";

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Rizulix" );
	g_Module.ScriptInfo.SetContactInfo( "discord.gg/svencoop" );

	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );

	ReadFile();
}

void MapInit()
{
	for( uint i = 0; i < MUSIC_LIST.length(); i++ ) {
		g_Game.PrecacheGeneric( "sound/" + MUSIC_LIST[i] );
	}
}

uint RandomTrack( uint& in number ) {
	return Math.RandomLong( 0, number - 1 );
}

array<string> MUSIC_LIST;

array<string> MEDIA_LIST = { 
	"gamestartup.mp3", "gamestartup2.mp3",
	"Half-Life01.mp3", "Half-Life02.mp3", "Half-Life03.mp3", "Half-Life04.mp3", "Half-Life05.mp3",
	"Half-Life06.mp3", "Half-Life07.mp3", "Half-Life08.mp3", "Half-Life09.mp3", "Half-Life10.mp3",
	"Half-Life11.mp3", "Half-Life12.mp3", "Half-Life13.mp3", "Half-Life14.mp3", "Half-Life15.mp3",
	"Half-Life16.mp3", "Half-Life17.mp3", "Half-Life18.mp3", "Half-Life19.mp3", "Half-Life20.mp3",
	"Half-Life21.mp3", "Half-Life22.mp3", "Half-Life23.mp3", "Half-Life24.mp3", "Half-Life25.mp3",
	"Half-Life26.mp3", "Half-Life27.mp3",
	"opfor/OpposingForce01.mp3", "opfor/OpposingForce02.mp3", "opfor/OpposingForce03.mp3", "opfor/OpposingForce04.mp3", "opfor/OpposingForce05.mp3",
	"opfor/OpposingForce06.mp3", "opfor/OpposingForce07.mp3", "opfor/OpposingForce08.mp3", "opfor/OpposingForce09.mp3", "opfor/OpposingForce10.mp3",
	"opfor/OpposingForce11.mp3", "opfor/OpposingForce12.mp3", "opfor/OpposingForce13.mp3", "opfor/OpposingForce14.mp3", "opfor/OpposingForce15.mp3",
	"opfor/OpposingForce16.mp3", "opfor/OpposingForce17.mp3", "opfor/OpposingForce18.mp3", "opfor/OpposingForce19.mp3"
};

void ReadFile() {
	File@ pFile = g_FileSystem.OpenFile( MUSIC_PATH, OpenFile::READ );

	if( pFile is null || !pFile.IsOpen() ) {
		g_Game.AlertMessage( at_console, "ATTENTION: \"%1\" failed to open or file not exist, the OST of the game will be used instead.\n", MUSIC_PATH );
		return;
	} while( !pFile.EOFReached() ) {
		string szLine;
		pFile.ReadLine( szLine );
		if( szLine.SubString(0,1) == "#" || szLine.SubString(0,2) == "//" || szLine.IsEmpty() ) continue;
		MUSIC_LIST.insertLast( szLine );
	}
	pFile.Close();
}

void ClientCommand( edict_t@ pEdict, const string& in szCommand ) {
	NetworkMessage netmsg( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, @pEdict );
		netmsg.WriteString( szCommand );
	netmsg.End();
}

void ClientCommand( CBasePlayer@ pPlayer, const string& in szCommand ) {
	NetworkMessage netmsg( MSG_ONE_UNRELIABLE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict() );
		netmsg.WriteString( szCommand );
	netmsg.End();
}

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in, const string& in, bool& out, string& out )
{
	if( pEdict is null )
		return HOOK_CONTINUE;

	if( MUSIC_LIST.length() != 0 ) {
		uint i = RandomTrack( MUSIC_LIST.length() );
		ClientCommand( pEdict, ";mp3 loop \"sound/" + MUSIC_LIST[i] + "\";" );
	} else {
		uint i = RandomTrack( MEDIA_LIST.length() );
		ClientCommand( pEdict, ";mp3 loop \"media/" + MEDIA_LIST[i] + "\";" );
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if( pPlayer is null )
		return HOOK_CONTINUE;

	ClientCommand( pPlayer, "mp3 stop" );

	return HOOK_CONTINUE;
}
