class ScrnLAWExplosion extends LAWExplosion;
//ScrN LAW Explosion has the light from nadelight added, but it is larger and lasts 0.5s instead of 0.25s

//added nadelight
simulated function PostBeginPlay()
{
	Super.Postbeginplay();
	NadeLight();
}

simulated function NadeLight()
{
	if ( !Level.bDropDetail && (Instigator != None)
		&& ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
	{
		bDynamicLight = true;
		SetTimer(0.5, false); //0.25
	}
	else Timer();
}

simulated function Timer()
{
	bDynamicLight = false;
}

defaultproperties
{
    bUnlit=false //true

    //added lights
    LightType=LT_Steady
    LightBrightness=220.0 //128
    LightRadius=14.000000 //4.0
    LightHue=20 //made it a little bit more orange (old 25)
    LightSaturation=100
    LightCone=16
    bDynamicLight=false
    
    //copypaste from kfnadeexplosion just in case
    RemoteRole=ROLE_SimulatedProxy
    bNotOnDedServer=False
    bNoDelete=False
    AutoDestroy=True
}