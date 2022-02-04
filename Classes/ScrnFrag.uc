class ScrnFrag extends Frag;

var transient float CookExplodeTimer;
var transient bool bCooking, bThrowingCooked;
var transient bool bBlewInHands; //client didn't throw nade - it blew up in his hands
//var float CookThrowRate; //how faster we throwing a cooked nade comparing with regular throw

replication
{
    reliable if(Role < ROLE_Authority)
        ServerCookNade;

    reliable if(Role == ROLE_Authority)
        ClientThrowCooked;
}

//executed on client-side only
simulated function CookNade()
{
    if( !Instigator.IsLocallyControlled() )
        return;

    HandleSleeveSwapping(); // use proper arms

    ServerCookNade();
    if( Role < ROLE_Authority ) {
        CookExplodeTimer = Level.TimeSeconds + class'ScrnNade'.default.ExplodeTimer;
        bCooking = true;
        bThrowingCooked = false;
    }
    KFPawn(Instigator).SecondaryItem = self; //it'll be replicated
    PlayAnim(TossAnim, 10, 0.0, 0);
    FreezeAnimAt(4.8, 0);
}

simulated function bool CanCook()
{
    return Ammo[0].AmmoAmount >= FireMode[0].AmmoPerFire;
}

//server
function ServerCookNade()
{
    CookExplodeTimer = Level.TimeSeconds + class'ScrnNade'.default.ExplodeTimer;
    bCooking = true;
    bThrowingCooked = false;
    bBlewInHands = false;
}

function Tick( float DeltaTime )
{
    super.Tick(DeltaTime);

    //server: tell client to throw nade, when countdown reached
    if (bCooking && !bThrowingCooked && Level.TimeSeconds >= CookExplodeTimer) {
        bBlewInHands = true;
        ClientThrowCooked();
    }
}

simulated function ClientThrowCooked()
{
    if( !Instigator.IsLocallyControlled() )
        return;

    bThrowingCooked = true;
    StartThrow();
    if( Role < ROLE_Authority )
        bCooking = false; //set here to immediately hide progress bar from the HUD
}


simulated function StartThrow()
{
    if (bCooking && !bThrowingCooked)
        return; //can't throw nade while cooking

    HandleSleeveSwapping(); // use proper arms

    super.StartThrow();
}

function ServerStartThrow()
{
    if( !Instigator.IsLocallyControlled() ) {
        bThrowingCooked = bCooking;
    }
    super.ServerStartThrow();
}

function ServerThrow()
{
    local int f;

    if ( HasAmmo() ) {
        f = PickFireMode();
        ConsumeAmmo(f, 1);
        FireMode[f].DoFireEffect();
        if ( f == 0 ) {
            PlaySound(ThrowSound, SLOT_Interact, 2.0);
        }
        else {
            PlaySound(FireMode[f].FireSound, SLOT_Interact, 2.0);
        }
    }
}

function int PickFireMode()
{
    if (Ammo[0].AmmoAmount == 0 && Ammo[1] != none && Ammo[1].AmmoAmount >= 1)
        return 1;

    return 0;
}

// Spawning Frag should not give TP ammo
function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
    local bool bNoTP;

    bNoTP = Ammo[m] == none;
    super.GiveAmmo(m, WP, bJustSpawned);
    if ( m == 1 && bNoTP && Ammo[1] != none ) {
        Ammo[1].AmmoAmount = 0;
    }
}

defaultproperties
{
     Weight=0.000000
     FireModeClass(0)=class'ScrnFragFire'
     FireModeClass(1)=class'ToiletPaperFire'
     bHasSecondaryAmmo=false  // prevents buying TP ammo from frags
     PickupClass=class'ScrnFragPickup'
     ItemName="Frag Grenade SE"
     bAlwaysRelevant=True
}
