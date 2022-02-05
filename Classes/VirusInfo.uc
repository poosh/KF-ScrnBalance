class VirusInfo extends ScrnCustomPlayerInfo;

var SocIsoMut Mut;

var bool bInfected, bCured;
var float Damage;
var int DamageCounter;
var float DamageDelay;
var float DamageMod, DamageRate;
var transient int HealthSamples[5];
var transient int MinHealth;
var transient byte HealthIndex;
var transient float NextStateTime;

var int InfectionThreshhold, InfectionThreshholdRapid;
var transient int InfectionCounter, InfectionCounterRapid;
var transient int SpreadCounter;
var transient bool bCovidiotSocial;
var VirusInfo InfectedBy;
var transient int InfectGameTime;

var localized string strCoughedInShop;
var int CoughedInShopPenalty;

function Infect(float r) { }

function bool HasSymptoms() {
    return false;
}

function HealthSample(int Health)
{
    local int i;
    local int OldHealth;

    if ( Health <= 0 )
        return;

    if ( MinHealth <= 0 ) {
        // reset samples
        for ( i = 0; i < ArrayCount(HealthSamples); ++i ) {
            HealthSamples[HealthIndex] = 100;
        }
        MinHealth = 100;
    }

    if (++HealthIndex >= ArrayCount(HealthSamples))
        HealthIndex = 0;

    OldHealth = HealthSamples[HealthIndex];
    HealthSamples[HealthIndex] = Health;

    if (Health < MinHealth) {
        MinHealth = Health;
    }
    else if ( OldHealth == MinHealth ) {
        MinHealth = Health;
        for ( i = 0; i < ArrayCount(HealthSamples); ++i ) {
            if ( HealthSamples[HealthIndex] < MinHealth ) {
                MinHealth = HealthSamples[HealthIndex];
            }
        }
    }
}

function bool AnyHealthyInShop(ShopVolume Shop)
{
    local int i;
    local ScrnHumanPawn Other, MyPawn;
    local ScrnPlayerInfo OtherSPI;
    local VirusInfo OtherVirus;

    MyPawn = SPI.AlivePawn();
    for ( i = 0; i < Shop.Touching.length; ++i ) {
        Other = ScrnHumanPawn(Shop.Touching[i]);
        if (Other == none || Other == MyPawn)
            continue;

        OtherSPI = SPI.GameRules.GetPlayerInfo(PlayerController(Other.Controller));
        if ( OtherSPI == none )
            continue;

        OtherVirus = VirusInfo(OtherSPI.CustomInfo(class'VirusInfo'));
        if (OtherVirus != none && !OtherVirus.HasSymptoms())
            return true;
    }
    return false;
}

static function bool ShopBoot(ShopVolume Shop, ScrnHumanPawn Bootee)
{
    if( !Shop.bTelsInit )
        Shop.InitTeleports();
    if( !Shop.bHasTeles )
        return false;
    Bootee.PlayTeleportEffect(false, true);
    return Shop.TelList[rand(Shop.TelList.length)].Accept(Bootee, Shop);
}

auto state Healthy
{
    function BeginState()
    {
        bInfected = false;
        bCured = false;
        InfectionThreshhold = 150 + rand(450);
        InfectionThreshholdRapid = 30 + rand(90);
    }

    function Infect(float r)
    {
         if (r < 0.15) {
             GotoState('Asymptomatic');
         }
         else {
             Damage = r * 10.0 + 1;
             GotoState('Incubation');
         }
    }
}

state Infected
{
    ignores Infect;

    function BeginState()
    {
        if ( !bInfected ) {
            bInfected = true;
            InfectGameTime = Level.Game.GameReplicationInfo.ElapsedTime;
        }
    }

    function EndState()
    {
        // make sure timers are not carried between states
        SetTimer(0, false);
    }

    function Timer()
    {
        NextState();
    }

    function NextState()
    {
        warn("VirusInfo: NextState undefined");
    }
}

state Asymptomatic extends Infected
{
    function BeginState()
    {
        super.BeginState();
        Damage = 0;
        Mut.SocHandler.PlayerSick(self);
    }

    function NextState()
    {
        // do nothing
    }
}

state Incubation extends Infected
{
    function BeginState()
    {
        super.BeginState();
        NextStateTime = lerp(frand(), Mut.IncubationTimeMin, Mut.IncubationTimeMax, true);
        SetTimer(NextStateTime, false);
        NextStateTime += Level.TimeSeconds;
    }

    function NextState()
    {
        if ( Level.TimeSeconds < NextStateTime ) {
            SetTimer(NextStateTime - Level.TimeSeconds + 1.0, false);
        }
        else if ( Mut.bRevealSymptoms && SPI.AlivePawn() != none ) {
            GotoState('SickPhase1');
        }
        else {
            SetTimer(10.0 + 30.0*frand(), false);
        }
    }
}

state Sick extends Infected
{
    function BeginState()
    {
        super.BeginState();

        MinHealth = 0;
        DamageMod = 1.0;
        DamageRate = 1.0;
        NextStateTime = lerp(frand(), Mut.SickTimeMin, Mut.SickTimeMax, true) / 5;
        NextStateTime += Level.TimeSeconds;
        Timer();
    }

    function bool HasSymptoms() {
        return true;
    }

    function Timer()
    {
        local float NextDamageTime;
        local ScrnHumanPawn P;
        local ToiletPaperAmmo TPAmmo;
        local int d;
        local string s;
        local ShopVolume Shop;
        local KFGameType KF;

        if ( Level.TimeSeconds > NextStateTime ) {
            NextState();
            return;
        }

        P = SPI.AlivePawn();
        KF = SPI.GameRules.Mut.KF;

        if ( DamageCounter > 0 ) {
            if ( P != none ) {
                d = DamageMod * Damage * (0.5+frand()) + 0.5;
                if ( DamageCounter == default.DamageCounter ) {
                    HealthSample(P.Health);

                    TPAmmo = ToiletPaperAmmo(P.FindInventoryType(class'ToiletPaperAmmo'));
                    if ( TPAmmo != none && TPAmmo.AmmoAmount >= 3 ) {
                        // use 3 rolls of TP: consume 1 + two "recyclable"
                        // this gives ~30% damage resistance from coughing
                        TPAmmo.AmmoAmount--;
                        P.Crap(2);
                        d = 1;
                    }
                }
                // player has 50% resistance from self damage,
                // hence we need to pass the double value to get the desired result.
                P.TakeDamage(2*d, P, vect(0,0,0), vect(0,0,0), class'VirusDamage');
                Mut.SocHandler.PlayerCoughed(self, d);
                NextDamageTime = DamageDelay;
                --DamageCounter;

                if (KF.bTradingDoorsOpen && CoughedInShopPenalty > 0) {
                    foreach P.TouchingActors(class'ShopVolume', Shop) {
                        if (Shop.bCurrentlyOpen && !Shop.bAlwaysEnabled && AnyHealthyInShop(Shop)) {
                            SPI.PlayerOwner.PlayerReplicationInfo.Score -= CoughedInShopPenalty; // allow go negative
                            s = strCoughedInShop;
                            s = Repl(s, "%$", string(CoughedInShopPenalty), true);
                            SPI.PlayerOwner.ClientMessage(class'ScrnFunctions'.static.ColorString(s,192,128,1));
                            ShopBoot(Shop, P);
                            break;
                        }
                    }
                }
            }
            else {
                MinHealth = 0;
                NextDamageTime = 10.0;
                DamageCounter = 0;
            }
        }
        else {
            if ( P != none ) {
                DamageCounter = default.DamageCounter;
                // healthy players take damage rarer
                NextDamageTime = lerp(MinHealth/100.0, 5, 30, true);
                NextDamageTime *= 0.8 + 0.4*frand();
                NextDamageTime /= DamageRate;
            }
            else {
                // player is dead. Just look once in a while for respawn.
                NextDamageTime = 10.0;
            }
        }
        SetTimer(NextDamageTime, true);
    }
}

state SickPhase1 extends Sick
{
    function BeginState()
    {
        super.BeginState();
        Mut.SocHandler.PlayerSick(self);
    }

    function NextState()
    {
        GotoState('SickPhase2');
    }
}

state SickPhase2 extends Sick
{
    function BeginState()
    {
        super.BeginState();
        DamageMod = 1.0;
        DamageRate = 2.0;
    }

    function NextState()
    {
        GotoState('SickPhase3');
    }
}

state SickPhase3 extends Sick
{
    function BeginState()
    {
        super.BeginState();
        DamageMod = 1.5;
        DamageRate = 2.0;
    }

    function NextState()
    {
        GotoState('SickPhase4');
    }
}
state SickPhase4 extends Sick
{
    function BeginState()
    {
        super.BeginState();
        DamageMod = 2.0;
        DamageRate = 1.0;
    }

    function NextState()
    {
        GotoState('SickPhase5');
    }
}

state SickPhase5 extends Sick
{
    function NextState()
    {
        GotoState('Curing');
    }
}

state Curing extends Infected
{
    function BeginState()
    {
        super.BeginState();
        NextStateTime = lerp(frand(), Mut.IncubationTimeMin, Mut.IncubationTimeMax, true);
        SetTimer(NextStateTime, false);
        NextStateTime += Level.TimeSeconds;
    }

    function bool HasSymptoms() {
        return true;
    }

    function NextState()
    {
        GotoState('Cured');
    }
}

state Cured
{
    function BeginState()
    {
        bInfected = false;
        bCured = true;
    }
}


defaultproperties
{
    DamageCounter=3
    DamageDelay=0.5
    DamageMod=1.0
    DamageRate=1.0
    CoughedInShopPenalty=0
    strCoughedInShop="Virus spread warning! You have neen charged $%$ to disinfect the shop area."
}
