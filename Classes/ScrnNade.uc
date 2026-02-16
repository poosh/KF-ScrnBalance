class ScrnNade extends Nade;

var class<ScrnExplosiveFunc> Func;
var bool bBlewInHands;


simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum,
        vector HitLocation )
{
    local int NumKilled;

    if ( bHurtEntry )
        return;

    LastTouched = none;
    NumKilled = Func.static.HurtRadius(self, DamageAmount, DamageRadius, DamageType, Momentum, HitLocation, true);

    if (Role == ROLE_Authority && bBlewInHands && NumKilled >= 5) {
        class'ScrnAchCtrl'.static.Ach2Pawn(Instigator, 'SuicideBomber', 1);
    }
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local PlayerController  LocalPlayer;
    local Projectile P;
    local byte i;

    if (bHasExploded)
        return;

    bHasExploded = True;
    BlowUp(HitLocation);

    // null reference fix
    if ( ExplodeSounds.length > 0 )
        PlaySound(ExplodeSounds[rand(ExplodeSounds.length)],,2.0);

    // Shrapnel
    for( i=Rand(6); i<10; i++ )
    {
        P = Spawn(ShrapnelClass,,,,RotRand(True));
        if( P!=None )
            P.RemoteRole = ROLE_None;
    }
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    Destroy();
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
    local Pawn P;

    if (KFBulletWhipAttachment(Other) != none)
        return;

    P = Pawn(Other);
    if (Instigator != none && P != none) {
        if (Other == Instigator || Other.Base == Instigator)
            return;

        // dead bodies must not stop nades to prevent blowup on a net lag
        if (P.Health <= 0)
            return;

        // don't hit teammates
        if (Instigator.GetTeamNum() == P.GetTeamNum())
            return;

        // fall down when hitting an enemy
        Velocity = Vect(0,0,0);
    }
    else if (Other.IsA('NetKActor')) {
        KAddImpulse(Velocity, HitLocation);
    }
    else if (!Other.bWorldGeometry) {
        // XXX: do we need this?
        Velocity = Vect(0,0,0);
    }
}

simulated function ClientSideTouch(Actor Other, Vector HitLocation)
{
    // prevent blowing dead bodies with nade impact damage
    // Other.TakeDamage(Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
}

defaultproperties
{
    Func = class'ScrnExplosiveFunc_Nade'

    ExplodeSounds(0)=SoundGroup'KF_GrenadeSnd.Nade_Explode_1'
    ExplodeSounds(1)=SoundGroup'KF_GrenadeSnd.Nade_Explode_2'
    ExplodeSounds(2)=SoundGroup'KF_GrenadeSnd.Nade_Explode_3'
}
