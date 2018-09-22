class ScrnM4203BulletFire extends ScrnM4Fire;

var int BurstSize;
var transient int BurstShotCount;       //how many bullets were fired in the current burst?
var transient float FireBurstEndTime;   //this is just to be sure we don't stuck inside FireBurst state, if shit happens

//those functions are used only in FireBurst
function PlayFiring() { }
function PlayFireEnd() { }
function ServerPlayFiring() { }



state WaitingForFireButtonRelease
{    
    ignores PlayFiring, ServerPlayFiring, PlayFireEnd, ModeDoFire;

    function ModeTick(float dt)
    {
        // allow fire as soon as player releases a fire button
        if ( Weapon.Instigator == none || Weapon.Instigator.Controller == none  
                || Weapon.Instigator.Controller.bFire == 0 )
            GotoState('');
    }
}

state FireBurst
{
    ignores PlayFiring, ServerPlayFiring; // ingnore because we play an anbient fire sound
    //ignores StopFiring;

    function BeginState()
    {
        //log ("ScrnM4Fire.FireBurst BEGIN STATE", 'ScrnBalance');
    
        BurstShotCount = 0;
        NextFireTime = Level.TimeSeconds - 0.000001; //fire now!
        FireBurstEndTime = Level.TimeSeconds + ( FireRate * BurstSize ) + 0.1; // if shit happens - get us out of this state when this time hits 
        
        if( KFWeap.bAimingRifle )
        {
            Weapon.LoopAnim(FireLoopAimedAnim, FireLoopAnimRate, TweenTime);
        }
        else
        {
            Weapon.LoopAnim(FireLoopAnim, FireLoopAnimRate, TweenTime);
        }

        PlayAmbientSound(AmbientFireSound);        
    }

    function EndState()
    {
        //log ("ScrnM4Fire.FireBurst END STATE", 'ScrnBalance');

        super.PlayFireEnd();
        Weapon.AnimStopLooping();
        PlayAmbientSound(none);
        
        if( Weapon.Instigator != none && Weapon.Instigator.IsLocallyControlled() &&
           Weapon.Instigator.IsFirstPerson() && StereoFireSound != none )
        {
            Weapon.PlayOwnedSound(FireEndStereoSound,SLOT_None,AmbientFireVolume/127,,AmbientFireSoundRadius,,false);
        }
        else
        {
            Weapon.PlayOwnedSound(FireEndSound,SLOT_None,AmbientFireVolume/127,,AmbientFireSoundRadius);
        }
        
        ScrnM4203AssaultRifle(Weapon).ReallyStopFire(ThisModeNum);  
        bIsFiring = false; // tbs
    }
    
    function StartFiring()
    {
        super(KFFire).StartFiring(); //bypass KFHighROFFire
    }
    
    function StopFiring()
    {
        GotoState('');
    }    


    function ModeTick(float dt)
    {
        //log ("ScrnM4Fire.FireBurst.ModeTick()", 'ScrnBalance');
        Super.ModeTick(dt);
        
        if ( !bIsFiring || !AllowFire() )
            GotoState('');
        else if ( Level.TimeSeconds > FireBurstEndTime ) {
            GotoState('');
            log("ScrnM4203BulletFire stuck inside FireBurst state after making "$BurstShotCount$" shots! Getting us out of it.", 'ScrnBalance');
        }
    }

    
    //copy-pasted from KFFire
    //add stopping fire after reaching the burst amount 
    function ModeDoFire()
    {
        local float Rec;
        local KFPlayerReplicationInfo KFPRI;

        if (!AllowFire())
            return;

        if( Instigator==None || Instigator.Controller==none )
            return;
            
        //log ("ScrnM4Fire.FireBurst.ModeDoFire()", 'ScrnBalance');

        KFPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

        Spread = GetSpread();

        Rec = GetFireSpeed();
        FireRate = default.FireRate/Rec;
        FireAnimRate = default.FireAnimRate*Rec;
        ReloadAnimRate = default.ReloadAnimRate*Rec;
        Rec = 1;

        if ( KFPRI != none && KFPRI.ClientVeteranSkill != none )
        {
            Spread *= KFPRI.ClientVeteranSkill.Static.ModifyRecoilSpread(KFPRI, self, Rec);
        }

        LastFireTime = Level.TimeSeconds;

        if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement)
        {
            if (FireRate > 0.25)
            {
                Weapon.Owner.Velocity.x *= 0.1;
                Weapon.Owner.Velocity.y *= 0.1;
            }
            else
            {
                Weapon.Owner.Velocity.x *= 0.5;
                Weapon.Owner.Velocity.y *= 0.5;
            }
        }

        Super(WeaponFire).ModeDoFire();

        // client
        if (Instigator.IsLocallyControlled())
        {
            if( bDoClientRagdollShotFX && Weapon.Level.NetMode == NM_Client )
            {
                DoClientOnlyFireEffect();
            }
            HandleRecoil(Rec);
        }
        
        if ( ++BurstShotCount >= BurstSize ) {
            //log ("ScrnM4203BulletFire.ChangeFireBurstState", 'ScrnBalance');
            //don't go to WaitingForFireButtonRelease state on server
            if ( Weapon.Instigator == none || Weapon.Instigator.Controller == none 
                    || !Weapon.Instigator.IsLocallyControlled() || Weapon.Instigator.Controller.bFire == 0
                    || KFWeapon(Weapon).MagAmmoRemaining < 1 || ScrnM4203AssaultRifle(Weapon).bTriggerReleased )
                GotoState('');
            else
                GotoState('WaitingForFireButtonRelease');
        }        
    }
}

defaultproperties
{
     BurstSize=3
     DamageType=Class'ScrnBalanceSrv.ScrnDamTypeM4203AssaultRifle'
     DamageMax=41
     FireAnimRate=0.75
     FireLoopAnimRate=1.4 //0.750000
     FireRate=0.100000
     AmmoClass=Class'KFMod.M4203Ammo'
}
