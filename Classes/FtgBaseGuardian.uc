class FtgBaseGuardian extends TSCBaseGuardian
    abstract;

var localized string strBlame;
var transient bool bBlamed;

function PawnBaseDied()
{
    local vector base_loc;
    if ( Pawn(Base) != none ) {
        base_loc = Base.Location;
        Base.DetachFromBone(self);
        SetBase(none);
        SetLocation( base_loc + vect(0, 0, 20) );
        Velocity = PhysicsVolume.Gravity;
        if ( TSCGRI.MaxMonsters > 10 || KFGameType(Level.Game).bWaveBossInProgress )
            GotoState('SettingUp');
        else
            GotoState('Dropped');
    }
}

function BaseSetupFailed()
{
    BlameBaseSetter(strBlame);
    if ( TSCGRI.bWaveInProgress ) {
        TscGame(Level.Game).BootShopPlayers();
    }

    MoveToShop(MyShop); // teleport next to shop
    Score();

    if ( !bActive ) {
        log( "Base setup failed", class.name );
        SendHome();
    }
}

function BlameBaseSetter(string BlameStr)
{
    if ( bBlamed )
        return;

    bBlamed = true;
    TscGame(Level.Game).ScrnBalanceMut.BlamePlayer(GetBaseSetter(), BlameStr);
}

auto state Home
{
    function BeginState()
    {
        local StinkyController SC;

        super.BeginState();

        if ( Team != none )
            SC = FTGGame(Level.Game).StinkyControllers[Team.TeamIndex];
        if ( SC != none )
            SC.Pawn.Suicide();
    }
}

state Guarding
{
    ignores TakeDamage;

    function bool ValidHolder(Actor other)
    {
        return StinkyClot(other) != none; // only StinkyClot can grab the guardian while guarding
    }

    function EndState()
    {
        if ( Holder != none ) {
            // make sure that Stinky Clot is not holding me
            Holder.DetachFromBone(self);
            SetBase(none);
        }
        Holder = none;
        bHeld = false;
        bBlamed = false;

        super.EndState();
    }

    function bool ShouldWipeOnBaseLost()
    {
        return WipeOnBaseLost != none && !Level.Game.bGameEnded
                && (TSCGRI.MaxMonsters > 10 || KFGameType(Level.Game).bWaveBossInProgress);
    }

    function Timer()
    {
        local int OldSameTeamCounter;

        OldSameTeamCounter = SameTeamCounter;
        super.Timer();
        if (OldSameTeamCounter != SameTeamCounter && Holder != none && StinkyController(Holder.Controller) != none) {
            // adjust StinkyClot's speed if all players leave the base or return back
            StinkyController(Holder.Controller).AdjustSpeed();
        }
    }
}

defaultproperties
{
    GameObjBone="CHR_RArmPalm"
    GameObjOffset=(X=5,Y=-10,Z=-10)
    GameObjRot=(Pitch=0,Yaw=0,Roll=0)

    WipeOnBaseLost=class'DamTypeEnemyBase'
    bSkipActorPropertyReplication=false
    bReplicateMovement=true
    CollisionHeight=12
    DrawScale=0.5
    PrePivot=(Z=23)
    SameTeamCounter=30
    Damage=2 // do less damage to enemies due to moving
    HealthMax=0 // cannot be stunned

    LightRadius=25
    GuardianLightRadius=25
    LightBrightness=50
    GuardianBrightness=50

    strBlame="%p blamed for base setup failure"
}
