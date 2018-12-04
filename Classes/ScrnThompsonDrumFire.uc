class ScrnThompsonDrumFire extends ThompsonDrumFire;

var() Sound BoltCloseSound;
var string BoltCloseSoundRef;
var bool bClientEffectPlayed;

var float AmbientSoundPitchMult;

//load additional sound
static function PreloadAssets(LevelInfo LevelInfo, optional KFFire Spawned)
{
    local ScrnThompsonDrumFire ScrnSpawned;

    super.PreloadAssets(LevelInfo, Spawned);
    if ( default.BoltCloseSoundRef != "" )
    {
        default.BoltCloseSound = sound(DynamicLoadObject(default.BoltCloseSoundRef, class'Sound', true));
    }
    ScrnSpawned = ScrnThompsonDrumFire(Spawned);
    if ( ScrnSpawned != none )
    {
        ScrnSpawned.BoltCloseSound = default.BoltCloseSound;
    }
}

static function bool UnloadAssets()
{
    default.BoltCloseSound = none;
    return super.UnloadAssets();
}

function DoCloseBolt()
{
    ScrnThompsonDrum(KFWeap).CloseBolt();

    if (BoltCloseSound != none && !bClientEffectPlayed )
    {
        Weapon.PlayOwnedSound(BoltCloseSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,1.00,false);
        bClientEffectPlayed = true;
    }
}

//setting bBoltClosed in a non simulated function test
function ModeDoFire()
{
    if ( Instigator != none && Instigator.IsLocallyControlled() ) {
        if (KFWeap.MagAmmoRemaining <= 0 && !KFWeap.bIsReloading && ( Level.TimeSeconds - LastFireTime>FireRate )
                && !ScrnThompsonDrum(KFWeap).bBoltClosed )
        {
            LastFireTime = Level.TimeSeconds; 
            DoCloseBolt(); //plays sound and sets bBoltClosed
        }
        else
        {
            bClientEffectPlayed = false; //reset if not empty
        }
    }
    Super.ModeDoFire();
}

// fixes double shot bug -- PooSH
state FireLoop
{
    function BeginState()
    {
        super.BeginState();

        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
    }
    function ModeTick(float dt)
    {
        if( KFWeap.MagAmmoRemaining < 1 )
        {
            DoCloseBolt(); //plays sound and sets bBoltClosed
        }
	    Super.ModeTick(dt);
    }
}

function PlayFiring()
{
    local float RandPitch;

	if ( Weapon.Mesh != None )
	{
		if ( FireCount > 0 )
		{
			if( KFWeap.bAimingRifle )
			{
                if ( Weapon.HasAnim(FireLoopAimedAnim) )
    			{
    				Weapon.PlayAnim(FireLoopAimedAnim, FireLoopAnimRate, 0.0);
    			}
    			else if( Weapon.HasAnim(FireAimedAnim) )
    			{
    				Weapon.PlayAnim(FireAimedAnim, FireAnimRate, TweenTime);
    			}
    			else
    			{
                    Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
    			}
			}
			else
			{
                if ( Weapon.HasAnim(FireLoopAnim) )
    			{
    				Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
    			}
    			else
    			{
    				Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
    			}
			}
		}
		else
		{
            if( KFWeap.bAimingRifle )
			{
                if( Weapon.HasAnim(FireAimedAnim) )
    			{
                    Weapon.PlayAnim(FireAimedAnim, FireAnimRate, TweenTime);
    			}
    			else
    			{
                    Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
    			}
			}
			else
			{
                Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
			}
		}
	}


	if( Weapon.Instigator != none && Weapon.Instigator.IsLocallyControlled() &&
	   Weapon.Instigator.IsFirstPerson() && StereoFireSound != none )
	{
        if( bRandomPitchFireSound )
        {
            RandPitch = FRand() * RandomPitchAdjustAmt;

            if( FRand() < 0.5 )
            {
                RandPitch *= -1.0;
            }
        }

        Weapon.PlayOwnedSound(StereoFireSound,SLOT_Interact,TransientSoundVolume * 0.85,,TransientSoundRadius,(1.0*AmbientSoundPitchMult + RandPitch),false);
    }
    else
    {
        if( bRandomPitchFireSound )
        {
            RandPitch = FRand() * RandomPitchAdjustAmt;

            if( FRand() < 0.5 )
            {
                RandPitch *= -1.0;
            }
        }

        Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,(1.0*AmbientSoundPitchMult + RandPitch),false);
    }
    ClientPlayForceFeedback(FireForce);  // jdf

    FireCount++;
}




// Handles toggling the weapon attachment's ambient sound on and off
// Overriden to change ambient sound pitch (700rpm to 800rpm)
function PlayAmbientSound(Sound aSound)
{
	local WeaponAttachment WA;

	WA = WeaponAttachment(Weapon.ThirdPersonActor);

    if ( Weapon == none || (WA == none))
        return;

	if(aSound == None)
	{
		WA.SoundVolume = WA.default.SoundVolume;
		WA.SoundRadius = WA.default.SoundRadius;
        WA.SoundPitch = WA.default.SoundPitch*AmbientSoundPitchMult;
	}
	else
	{
		WA.SoundVolume = AmbientFireVolume;
		WA.SoundRadius = AmbientFireSoundRadius;
        WA.SoundPitch = 64*AmbientSoundPitchMult;
	}

    WA.AmbientSound = aSound;
}


defaultproperties
{
     AmmoClass=Class'ScrnBalanceSrv.ScrnThompsonDrumAmmo'
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeThompsonDrum'
     BoltCloseSoundRef="KF_FNFALSnd.FNFAL_Bolt_Forward"

     RecoilRate=0.040000 //0.080000
     maxVerticalRecoilAngle=150
     maxHorizontalRecoilAngle=100
     DamageMax=40
     Momentum=12500.000000
     FireRate=0.071 //0.085700
     FireAnimRate=1.2
     AmbientSoundPitchMult=1.2
     Spread=0.012000
     SpreadStyle=SS_Random
}
