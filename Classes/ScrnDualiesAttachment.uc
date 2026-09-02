class ScrnDualiesAttachment extends DualiesAttachment;

var bool bLastMyTurn;

// it's better to avoid dynamic mesh loading for this
static function PreloadAssets(optional KFWeaponAttachment Spawned)  { }
static function bool UnloadAssets() { return true; }

simulated function PostNetReceive()
{
    local bool b;

    if (Instigator != LastInstig) {
        LastInstig = Instigator;
        InstigatorChange();
    }

    if (bIsOffHand)
        return;

    if (OldSpawnHitCount != SpawnHitCount) {
        b = bMyFlashTurn;
        bMyFlashTurn = bLastMyTurn;
        HitEffects();
        bMyFlashTurn = b;
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    InstigatorChange();
}

simulated function InstigatorChange()
{
    local KFPawn KFP;
    local ScrnFire_Dualies F;

    KFP = KFPawn(Instigator);
    if (KFP == none)
        return;

    KFP.SetWeaponAttachment(self);

    if (KFP.Weapon == none)
        return;

    F = ScrnFire_Dualies(KFP.Weapon.GetFireMode(0));
    if (F != none) {
        bMyFlashTurn = !F.GetPistolFireOrder();
        bLastMyTurn = bMyFlashTurn;
    }
}

simulated function DoFlashEmitter()
{
    if (bIsOffHand)
        return;

    if (bMyFlashTurn)
        ActuallyFlash();
    else if(brother != None)
        brother.ActuallyFlash();

    // For locally-controlled instigator, bMyFlashTurn is set by ScrnFire_Dualies
    if (!Instigator.IsLocallyControlled()) {
        bMyFlashTurn = !bMyFlashTurn;
    }
    bLastMyTurn = bMyFlashTurn;
}

simulated event ThirdPersonEffects()
{
    local KFPawn KFP;

    // Prevents tracers from spawning if player is using the flashlight function of the 9mm
    if (FiringMode == 1)
        return;

    if (Level.NetMode == NM_DedicatedServer || Instigator == None)
        return;

    KFP = KFPawn(Instigator);
    if (KFP == none)
        return;

    if (FlashCount > 0) {
        // We don't really have alt fire, but use the alt fire anims as the left hand firing anims
        KFP.StartFiringX(!bMyFlashTurn, bRapidFire);

        if( bDoFiringEffects ) {
            if (Level.TimeSeconds - LastRenderTime > 0.2 && !Instigator.IsLocallyControlled())
                return;

            WeaponLight();
            DoFlashEmitter();

            if (!bIsOffHand) {
                if (!bMyFlashTurn) {
                    ThirdPersonShellEject();
                }
                else if (brother != none) {
                    brother.ThirdPersonShellEject();
                }
            }
        }
    }
    else {
        bLastMyTurn = bMyFlashTurn;
        GotoState('');
        KFP.StopFiring();
    }

    HitEffects();
}

simulated function HitEffects()
{
    local PlayerController PC;

    if (OldSpawnHitCount == SpawnHitCount || bIsOffHand)
        return;

    OldSpawnHitCount = SpawnHitCount;
    GetHitInfo();
    PC = Level.GetLocalPlayerController();
    if ((Instigator != none && Instigator.Controller == PC)
            || VSizeSquared(PC.ViewTarget.Location - mHitLocation) < 16000000) {
        if (mHitActor != none)
            Spawn(class'ROBulletHitEffect',,, mHitLocation, Rotator(-mHitNormal));
        CheckForSplash();
        SpawnTracer();
    }
}

simulated function vector GetTracerStart()
{
    local Pawn p;
    local Dualies DualWeap;

    p = Pawn(Owner);

    if (p != none && p.IsFirstPerson() && p.Weapon != None) {
        DualWeap = Dualies(p.Weapon);
        if (DualWeap == none) {
            return p.Weapon.GetEffectStart();
        }
        else if (bMyFlashTurn) {
            return DualWeap.GetBoneCoords(DualWeap.default.FlashBoneName).Origin;
        }
        else {
            return DualWeap.GetBoneCoords(DualWeap.default.altFlashBoneName).Origin;
        }
    }

    // 3rd person
    if ( mMuzFlash3rd != None && bMyFlashTurn)
        return mMuzFlash3rd.Location;

    if ( brother != none && brother.mMuzFlash3rd != None && !bMyFlashTurn)
        return  brother.mMuzFlash3rd.Location;

    return Location;
}


defaultproperties
{
    bMyFlashTurn=True
    bLastMyTurn=true
}