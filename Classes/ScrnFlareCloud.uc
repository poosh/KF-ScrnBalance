class ScrnFlareCloud extends Emitter;

var byte FlareCount; // more flares = wider cloud

replication 
{
	reliable if ( bNetDirty && Role == ROLE_Authority )
		FlareCount;
}

simulated function PostNetReceive()
{
	if ( Role < ROLE_Authority ) {
		if ( bHidden )
			Kill();
		else if (FlareCount > 1)
			AdjustCloudSize();
	}
}

function Timer()
{
	Kill();
	//Destroy();
}

simulated function AdjustCloudSize()
{
	local float clound_size;
	
	// more flares = wider cloud
	clound_size = 1.0 + 0.25 * min(10, FlareCount);
	Emitters[0].StartSizeRange.X.Max = default.Emitters[0].StartSizeRange.X.Max * clound_size;
	Emitters[0].StartSizeRange.Y.Max = default.Emitters[0].StartSizeRange.Y.Max * clound_size;	
}

		

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         FadeOut=True
         SpinParticles=True
         UseRegularSizeScale=False
         UniformSize=True
         BlendBetweenSubdivisions=True
         UseSubdivisionScale=True
         UseRandomSubdivision=True
         ColorScale(0)=(Color=(R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=174,G=174,R=255,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=113,G=113,R=255,A=255))
         ColorScaleRepeats=1.000000
         ColorMultiplierRange=(X=(Min=0.500000,Max=0.500000),Y=(Min=0.500000,Max=0.500000),Z=(Min=0.500000,Max=0.500000))
         FadeOutStartTime=0.500000
         CoordinateSystem=PTCS_Relative
         MaxParticles=50
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=1.000000)
         SpinsPerSecondRange=(X=(Max=0.070000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=1.000000)
         StartSizeRange=(X=(Min=20.000000,Max=50.000000),Y=(Min=20.000000,Max=50.000000),Z=(Max=200.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=0.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'kf_fx_trip_t.Misc.smoke_animated'
         TextureUSubdivisions=8
         TextureVSubdivisions=8
         SubdivisionEnd=7
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=2.000000)
         StartVelocityRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=1.000000,Max=1.000000),Z=(Min=20.000000,Max=100.000000))
         MaxAbsVelocity=(X=100.000000,Y=100.000000,Z=100.000000)
     End Object
     Emitters(0)=SpriteEmitter'ScrnBalanceSrv.ScrnFlareCloud.SpriteEmitter0'

     AutoDestroy=True
     AutoReset=True
     bNoDelete=False
     bAlwaysRelevant=True
     Physics=PHYS_Trailer
     RemoteRole=ROLE_SimulatedProxy
     bNetNotify=True
	 NetUpdateFrequency=5
}
