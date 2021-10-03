/***
 * INSTALLATION: Add the following lines to "default_plugins.txt":
	"plugin"
	{
		"name" "TripminePickUp"
		"script" "TripminePickUp"
		"concommandns" "tpu"
	}
***/

TripminePickUp::CTripminePickUp@ g_TripminePickUp = @TripminePickUp::CTripminePickUp();

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Rizulix" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/svencoop" );

	g_TripminePickUp.OnInit();
}

void PluginExit()
{
	g_TripminePickUp.OnExit();
}

void MapInit()
{
	g_TripminePickUp.Initialize();
}

namespace TripminePickUp
{

final class CTripminePickUp
{
	private CCVar@ g_HoldTime;

	private bool[] m_hasSearched( g_Engine.maxClients + 1, false );
	private float[] m_startTime( g_Engine.maxClients + 1, 0.0f );
	private string[] m_pickupSound = { "items/gunpickup2.wav", "items/9mmclip1.wav" };

	void OnInit()
	{
		g_Hooks.RegisterHook( Hooks::Weapon::WeaponPrimaryAttack, WeaponPrimaryAttackHook( this.WeaponPrimaryAttack ) );
		g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, PlayerPreThinkHook( this.PlayerPreThink ) );
		g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlayerUseHook( this.PlayerUse ) );

		if( g_HoldTime is null )
			@g_HoldTime = CCVar( "holdtime", 1.0f, "How long by holding down the +USE Key (E) to pick up your tripmine(-1:disable the plugin)", ConCommandFlag::AdminOnly ); //as_command tpu.holdtime
	}

	void OnExit()
	{
		g_Hooks.RemoveHook( Hooks::Weapon::WeaponPrimaryAttack, WeaponPrimaryAttackHook( this.WeaponPrimaryAttack ) );
		g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, PlayerPreThinkHook( this.PlayerPreThink ) );
		g_Hooks.RemoveHook( Hooks::Player::PlayerUse, PlayerUseHook( this.PlayerUse ) );

		m_hasSearched.removeRange( 0, m_hasSearched.length() );
		m_startTime.removeRange( 0, m_startTime.length() );
	}

	void Initialize()
	{
		m_hasSearched = bool[]( g_Engine.maxClients + 1, false );
		m_startTime = float[]( g_Engine.maxClients + 1, 0.0f );

		for( uint i = 0; i < m_pickupSound.length(); i++ )
			g_SoundSystem.PrecacheSound( m_pickupSound[i] );
	}

	private CBaseEntity@ FindTripmineForward( CBaseEntity@ pMe, float flDistance, bool bHasOwner )
	{
		if( pMe is null )
			return null;

		TraceResult tr;
		CBaseEntity@[] pEnts( 64 );
		Math.MakeVectors( pMe.pev.v_angle );
		Vector vecSrc = pMe.pev.origin + pMe.pev.view_ofs;
		Vector vecEnd = vecSrc + g_Engine.v_forward * flDistance;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pMe.edict(), tr );
		Vector vecMin = tr.vecEndPos + Vector( -8, -8, -8 ), vecMax = tr.vecEndPos + Vector( 8, 8, 8 );
		int iEntitiesInBox = g_EntityFuncs.EntitiesInBox( @pEnts, vecMin, vecMax, 0 );
		for( int i = 0; i < iEntitiesInBox; i++ )
		{
			if( pEnts[i] !is null && pEnts[i].pev.classname == "monster_tripmine" )
			{
				if( !bHasOwner )
				{
					if( pEnts[i].pev.euser4 is null )
						return pEnts[i];
				}
				else //has owner and it's me
				{
					if( pEnts[i].pev.euser4 is pMe.edict() )
						return pEnts[i];
				}
			}
		}
		return null;
	}

	private void GiveItem( EHandle ePlayer )
	{
		if( !ePlayer )
			return;

		cast<CBasePlayer@>( ePlayer.GetEntity() ).GiveNamedItem( "weapon_tripmine" );
	}

	private void PickUpMyTripmine( CBasePlayer@ pPlayer, CBaseEntity@ pTripmine )
	{
		if( pPlayer is null || pTripmine is null )
			return;

		if( pPlayer.HasNamedPlayerItem( "weapon_tripmine" ) !is null && pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Trip Mine" ) ) <= 0 )
			g_Scheduler.SetTimeout( this, "GiveItem", 0.11f, EHandle( pPlayer ) );
		else if( pPlayer.HasNamedPlayerItem( "weapon_tripmine" ) is null )
			pPlayer.GiveNamedItem( "weapon_tripmine" );
		else
		{
			if( pPlayer.GiveAmmo( 1, "Trip Mine", pPlayer.GetMaxAmmo( "Trip Mine" ) ) == -1 )
				return;
		}

		for( uint i = 0; i < m_pickupSound.length(); i++ )
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, m_pickupSound[i], i == 0 ? 0.95f : 1.0f, ATTN_NORM );

		g_EntityFuncs.Remove( pTripmine );
	}

	HookReturnCode WeaponPrimaryAttack( CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon )
	{
		if( pPlayer is null || pWeapon is null )
			return HOOK_CONTINUE;

		if( pWeapon.pev.classname == "weapon_tripmine" )
		{
			CBaseEntity@ pTripmine = FindTripmineForward( pPlayer, 128.0f, false );
			if( pTripmine !is null )
				@pTripmine.pev.euser4 = @pPlayer.edict();
		}
		return HOOK_CONTINUE;
	}

	HookReturnCode PlayerUse( CBasePlayer@ pPlayer, uint& out )
	{
		if( pPlayer is null || pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Trip Mine" ) ) == pPlayer.GetMaxAmmo( "Trip Mine" ) || g_HoldTime.GetFloat() != 0.0f )
			return HOOK_CONTINUE;

		if( pPlayer.m_afButtonPressed & IN_USE == 0 )
			return HOOK_CONTINUE;

		CBaseEntity@ pTripmine = FindTripmineForward( pPlayer, 32.0f, true );
		if( pTripmine !is null )
			PickUpMyTripmine( pPlayer, pTripmine );

		return HOOK_CONTINUE;
	}

	HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out )
	{
		if( pPlayer is null || !pPlayer.IsAlive() || pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Trip Mine" ) ) == pPlayer.GetMaxAmmo( "Trip Mine" ) || g_HoldTime.GetFloat() <= 0.0f )
			return HOOK_CONTINUE;

		const int iEntIndex = pPlayer.entindex();
		if( pPlayer.m_afButtonPressed & IN_USE == 0 && pPlayer.m_afButtonLast & IN_USE == 0 )
		{
			if( m_startTime[iEntIndex] != 0.0f || m_hasSearched[iEntIndex] )
			{
				m_startTime[iEntIndex] = 0.0f;
				m_hasSearched[iEntIndex] = false;
			}
			return HOOK_CONTINUE;
		}
		else
		{
			if( m_startTime[iEntIndex] == -1.0f || (m_hasSearched[iEntIndex] && m_startTime[iEntIndex] == 0.0f) )
				return HOOK_CONTINUE;

			if( !m_hasSearched[iEntIndex] )
				m_hasSearched[iEntIndex] = true;

			CBaseEntity@ pTripmine = FindTripmineForward( pPlayer, 32.0f, true );
			if( pTripmine !is null )
			{
				if( m_startTime[iEntIndex] == 0.0f )
					m_startTime[iEntIndex] = g_Engine.time + g_HoldTime.GetFloat();

				if( m_startTime[iEntIndex] < g_Engine.time )
				{
					m_startTime[iEntIndex] = -1.0f;
					PickUpMyTripmine( pPlayer, pTripmine );
				}
			}
			else
			{
				if( m_startTime[iEntIndex] > 0.0f )
					m_startTime[iEntIndex] = 0.0f;
			}
		}
		return HOOK_CONTINUE;
	}
}

}

