class ScrnHUD extends SRHUDKillingFloor;

#exec OBJ LOAD FILE=ScrnTex.utx

//var byte colR, colG, colB;

var localized string strCowboyMode;

var() config int                MinMagCapacity; //don't show low ammo warning, if weapon magazine smaller than this
var() config float              LowAmmoPercent;

var() texture                   texCowboy;
var() config float              CowboyTileY, CowboyTileWidth;

var()   SpriteWidget            BlamedIcon;
var     float                   BlamedIconSize;

var()   SpriteWidget            SingleNadeIcon;

// configurable variables from ScrnBuyMenuSaleList
var config color TraderGroupColor, TraderActiveGroupColor, TraderSelectedGroupColor;
var config Color TraderPriceButtonColor, TraderPriceButtonDisabledColor, TraderPriceButtonSelectedColor;

var protected class<ScrnScoreBoard> ScrnScoreBoardClass; // modder friendly interface
var protected transient class<ScrnVeterancyTypes> ScrnPerk;
var private transient class<KFVeterancyTypes> PrevPerk;

var HudOverlay PerkOverlay;

var config byte SpecHeaderFont;
var localized string strFollowing;

struct SHitInfo
{
    var string Text;
    var float LastHit;
};

struct DamageInfo
{
    var int Damage;
    var float HitTime;
    var Vector HitLocation;
    var byte DamTypeNum;
    var float RandX, RandY;
    var color FontColor;
};

const DAMAGEPOPUP_COUNT = 32;
var DamageInfo DamagePopups[32];
var int NextDamagePopupIndex;
var() config bool bShowDamages;
var() config byte DamagePopupFont;
var() config float DamagePopupFadeOutTime;

var() config bool bShowSpeed;
var() config float SpeedometerX, SpeedometerY; 
var() config byte SpeedometerFont; 

var bool bHidePlayerInfo;

var config bool bOldStyleIcons;

var class<KFMonster> BlamedMonsterClass;
var float BlameCountdown;
var float BlameDrawDistance; // max distance to draw a turn on blamed pawn's head

var config bool bDrawSpecDeaths;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    // prevent using spedometer as crosshair
    if ( SpeedometerX > 0.4 && SpeedometerX < 0.6
            && SpeedometerY > 0.4 && SpeedometerY < 0.6 ) {
        SpeedometerX = 0.985;
        SpeedometerY = 0.80;
        PlayerOwner.ClientMessage("HUD Cheat Prevention: Speedometer position set to default");
    }
    class'ScrnBalanceSrv.ScrnVeterancyTypes'.default.bOldStyleIcons = bOldStyleIcons;
    
    if ( MyColorMod==None )
    {
        MyColorMod = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
        MyColorMod.AlphaBlend = True;
        MyColorMod.Color.R = 255;
        MyColorMod.Color.B = 255;
        MyColorMod.Color.G = 255;
    }    
    
    SpecHeaderFont = clamp(SpecHeaderFont, 0, 1);
}

// Draw Health Bars for damage opened doors.
function DrawDoorHealthBars(Canvas C)
{
    local KFDoorMover DamageDoor;
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local name DoorTag;
    local int i;
    local float Distance;

    if( PawnOwner==None )
        return;

    if ( (Level.TimeSeconds>LastDoorBarHealthUpdate) || (Welder(PawnOwner.Weapon)!=none && PlayerOwner.bFire==1) )
    {
        Distance = 300.00;        
        //while holding welder door health bars are visible from longer distance
        if ( ScrnPerk != none && Welder(PawnOwner.Weapon) != none) {
            Distance *= ScrnPerk.static.GetDoorHealthVisibilityScaling(KFPRI, PawnOwner);
        }
        
        DoorCache.Length = 0;

        foreach CollidingActors(class'KFDoorMover', DamageDoor, Distance, PlayerOwner.CalcViewLocation)
        {
            if ( DamageDoor.WeldStrength<=0 )
                continue;

            DoorCache[DoorCache.Length] = DamageDoor;

            C.GetCameraLocation(CameraLocation, CameraRotation);
            TargetLocation = DamageDoor.WeldIconLocation;
            TargetLocation.Z = CameraLocation.Z;
            CamDir    = vector(CameraRotation);

            if ( Normal(TargetLocation - CameraLocation) dot Normal(CamDir) >= 0.1 && DamageDoor.Tag != DoorTag && FastTrace(DamageDoor.WeldIconLocation - ((DoorCache[i].WeldIconLocation - CameraLocation) * 0.25), CameraLocation) )
            {
                HBScreenPos = C.WorldToScreen(TargetLocation);
                DrawDoorBar(C, HBScreenPos.X, HBScreenPos.Y, DamageDoor.WeldStrength / DamageDoor.MaxWeld, 255);
                DoorTag = DamageDoor.Tag;
            }
        }
        LastDoorBarHealthUpdate = Level.TimeSeconds+0.2;
    }
    else
    {
        for ( i = 0; i < DoorCache.Length; i++ )
        {
            if ( DoorCache[i].WeldStrength<=0 )
                continue;
             C.GetCameraLocation(CameraLocation, CameraRotation);
            TargetLocation = DoorCache[i].WeldIconLocation;
            TargetLocation.Z = CameraLocation.Z;
            CamDir    = vector(CameraRotation);

            if ( Normal(TargetLocation - CameraLocation) dot Normal(CamDir) >= 0.1 && DoorCache[i].Tag != DoorTag && FastTrace(DoorCache[i].WeldIconLocation - ((DoorCache[i].WeldIconLocation - CameraLocation) * 0.25), CameraLocation) )
            {
                HBScreenPos = C.WorldToScreen(TargetLocation);
                DrawDoorBar(C, HBScreenPos.X, HBScreenPos.Y, DoorCache[i].WeldStrength / DoorCache[i].MaxWeld, 255);
                DoorTag = DoorCache[i].Tag;
            }
        }
    }
}


simulated function DrawCowboyMode(Canvas C)
{
    C.SetDrawColor(255, 64, 64, KFHUDAlpha);
    C.SetPos(0.5 * C.ClipX * (1.0 - CowboyTileWidth), C.ClipY * CowboyTileY);
    C.DrawTile(texCowboy, C.ClipX * CowboyTileWidth, 64 * (C.ClipX * CowboyTileWidth)/512.0, 0, 0, 512, 64);
}

simulated function DrawSpeed(Canvas C)
{
    local float TextWidth, TextHeight;
    local int Speed;
    local string s;

    if ( PawnOwner == none )
        return;

    Speed = VSize(PawnOwner.Velocity);
    s = string(Speed);
    if ( PlayerOwner.Pawn == PawnOwner ) {
        // GroundSpeed is replicated to owner pawn only
        Speed = PawnOwner.GroundSpeed;
        s $= "/" $ Speed; 
    }
    else
        
    
    s  @= "uups";
    //draw near in the top middle
    C.Font = LoadSmallFontStatic(SpeedometerFont);
    C.StrLen(s, TextWidth, TextHeight);
    C.SetPos(C.ClipX * SpeedometerX - TextWidth, C.ClipY * SpeedometerY);

    if ( Speed > 240 ) { 
        // speed bonus - in blue
        C.DrawColor.R = 0;
        C.DrawColor.G = 100;
        C.DrawColor.B = 255;
    }
    else if ( Speed > 200 ) { 
        // melee speed - in green
        C.DrawColor.R = 0;
        C.DrawColor.G = 206;
        C.DrawColor.B = 0;
    }
    else {
        // red
        C.DrawColor.R = 255;
        C.DrawColor.G = 64;
        C.DrawColor.B = 64;
    }
    C.DrawColor.A = KFHUDAlpha;

    C.DrawText(s);
}

simulated function bool IsLowAmmo(KFWeapon Weapon)
{
    if (Weapon == none)
        return false;
    
    if (Weapon.MagCapacity > MinMagCapacity 
            && Weapon.MagAmmoRemaining <= max(Weapon.MagCapacity*LowAmmoPercent, 2))
        return true;

    return false;    
}


simulated function DrawCookingBar(Canvas C)
{
    //local inventory inv;
    local ScrnFrag aFrag;
    local float MyBarPercentage;
    local float MyBarLength, MyBarHeight, PosX, PosY;
    local float colR, colG;

    if ( KFPawn(PawnOwner) == none )
        return;
        
    aFrag = ScrnFrag(KFPawn(PawnOwner).SecondaryItem);
    if ( aFrag == none || !aFrag.bCooking) 
        return;
    
    if ( ScrnPerk == none || !ScrnPerk.static.CanShowNadeCookingBar(KFPRI) )
        return;

    MyBarPercentage = 1.0 - fclamp((aFrag.CookExplodeTimer - Level.TimeSeconds) 
        / class'ScrnBalanceSrv.ScrnNade'.default.ExplodeTimer, 0, 1);
        
    MyBarLength = C.ClipX * 0.2;
    MyBarHeight = 12;    
    PosX = (C.ClipX - MyBarLength) / 2;
    PosY = C.ClipY * 0.8; //bottom center

    //border
    C.SetPos(PosX, PosY);
    C.SetDrawColor(192, 192, 192, KFHUDAlpha);
    C.DrawTileStretched(WhiteMaterial, MyBarLength, MyBarHeight);

    //fill
    C.SetPos(PosX + 1.0, PosY + 1.0);
    // green -> yellow -> red
    if ( MyBarPercentage > 0.5 ) 
        colR = 255;
    if ( MyBarPercentage < 0.75 )
        colG = 255;               
    C.SetDrawColor(colR, colG, 0, KFHUDAlpha);
    C.DrawTileStretched(WhiteMaterial, (MyBarLength - 2.0) * MyBarPercentage, MyBarHeight - 2.0);        
}


simulated function DrawEndGameHUD(Canvas C, bool bVictory)
{
    super.DrawEndGameHUD(C, bVictory);
    //display end-game achievements
    C.Reset();
    DisplayLocalMessages(C);
}

/*
simulated function DrawMessage( Canvas C, int i, float PosX, float PosY, out float DX, out float DY )
{
    super.DrawMessage( C, i, PosX, PosY, DX, DY );
    log("DrawMessage("$i$") Alpha=" $ C.DrawColor.A, class.outer.name);
}

simulated function DisplayLocalMessages( Canvas C )
{
    local int i;
    
    log("DisplayLocalMessages("$C$")", class.outer.name);
    for ( i = 0; i < ArrayCount(LocalMessages); ++i ) {
        log(i$". " $ LocalMessages[i].Message, class.outer.name);
    }
    super.DisplayLocalMessages(C);
}

simulated function LocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject, optional String CriticalString)
{
    local int i;
    
    super.LocalizedMessage(Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject, CriticalString);
    log("LocalizedMessage: bIsCinematic="$bIsCinematic, class.outer.name);
    
    for ( i = 0; i < ArrayCount(LocalMessages); ++i ) {
        log(i$". " $ LocalMessages[i].Message, class.outer.name);
    }
}
*/

final static function String FormatTime( int Seconds )
{
    local int Minutes, Hours;
    local String Time;

    if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

        Time = Hours$":";
	}
	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    if( Minutes >= 10 )
        Time = Time $ Minutes $ ":";
    else
        Time = Time $ "0" $ Minutes $ ":";

    if( Seconds >= 10 )
        Time = Time $ Seconds;
    else
        Time = Time $ "0" $ Seconds;

    return Time;
}

simulated function DrawHudPassA (Canvas C)
{
    local KFHumanPawn KFHPawn;
    local ScrnHumanPawn ScrnPawn;
    local bool bSpectating, bSpectatingZED;
    local KFWeapon KFWeapon;
    local class<KFWeapon> WeaponClass;
    local Material TempMaterial, TempStarMaterial;
    local int i, TempLevel;
    local float TempX, TempY, TempSize;
    local byte Counter;
    local class<SRVeterancyTypes> SV;
    local string s;

    DrawStoryHUDInfo(C);
    
    if ( PawnOwner != none ) {
        KFHPawn = KFHumanPawn(PawnOwner);
        ScrnPawn = ScrnHumanPawn(PawnOwner);
        bSpectating = ScrnPawn != none && PlayerOwner.Pawn != ScrnPawn;
        bSpectatingZED = !bSpectating && PlayerOwner.Pawn != PawnOwner && KFMonster(PawnOwner) != none; 
        
        KFWeapon = KFWeapon(PawnOwner.Weapon);
        if ( bSpectating )
            WeaponClass = ScrnPawn.SpecWeapon;
        else if ( KFWeapon != none )
            WeaponClass = KFWeapon.class;
    }

    if ( !bShowScoreBoard && !bSpectating && ScrnPawn != none && ScrnPawn.bCowboyMode )
        DrawCowboyMode(C); 
            
    DrawDoorHealthBars(C);

    if ( !bLightHud && !bSpectatingZED )
        DrawSpriteWidget(C, HealthBG);

    DrawSpriteWidget(C, HealthIcon);
    DrawNumericWidget(C, HealthDigits, DigitsSmall);

    if ( !bSpectatingZED ) {
        if ( !bLightHud )
            DrawSpriteWidget(C, ArmorBG);
        DrawSpriteWidget(C, ArmorIcon);
        DrawNumericWidget(C, ArmorDigits, DigitsSmall);

        if ( KFHPawn != none ) {
            C.SetPos(C.ClipX * WeightBG.PosX, C.ClipY * WeightBG.PosY);

            if ( !bLightHud )
                C.DrawTile(WeightBG.WidgetTexture, WeightBG.WidgetTexture.MaterialUSize() * WeightBG.TextureScale * 1.5 * HudCanvasScale * ResScaleX * HudScale, WeightBG.WidgetTexture.MaterialVSize() * WeightBG.TextureScale * HudCanvasScale * ResScaleY * HudScale, 0, 0, WeightBG.WidgetTexture.MaterialUSize(), WeightBG.WidgetTexture.MaterialVSize());

            DrawSpriteWidget(C, WeightIcon);

            C.Font = LoadSmallFontStatic(5);
            C.FontScaleX = C.ClipX / 1024.0;
            C.FontScaleY = C.FontScaleX;
            C.SetPos(C.ClipX * WeightDigits.PosX, C.ClipY * WeightDigits.PosY);
            C.DrawColor = WeightDigits.Tints[0];
            if ( bSpectating )
                C.DrawText(string(ScrnPawn.SpecWeight));
            else
                C.DrawText(int(KFHPawn.CurrentWeight)$"/"$int(KFHPawn.MaxCarryWeight));
            C.FontScaleX = 1;
            C.FontScaleY = 1;
        }
    
        if ( !bLightHud )
            DrawSpriteWidget(C, GrenadeBG);
        DrawSpriteWidget(C, GrenadeIcon);
        DrawNumericWidget(C, GrenadeDigits, DigitsSmall);

        if ( WeaponClass != none )
        {
            if ( ClassIsChildOf(WeaponClass, class'Syringe') )
            {
                if ( !bLightHud )
                {
                    DrawSpriteWidget(C, SyringeBG);
                }

                DrawSpriteWidget(C, SyringeIcon);
                DrawNumericWidget(C, SyringeDigits, DigitsSmall);
            }
            else
            {
                if ( bDisplayQuickSyringe )
                {
                    TempSize = Level.TimeSeconds - QuickSyringeStartTime;
                    if ( TempSize < QuickSyringeDisplayTime )
                    {
                        if ( TempSize < QuickSyringeFadeInTime )
                        {
                            QuickSyringeBG.Tints[0].A = int((TempSize / QuickSyringeFadeInTime) * 255.0);
                            QuickSyringeBG.Tints[1].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeIcon.Tints[0].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeIcon.Tints[1].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeDigits.Tints[0].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeDigits.Tints[1].A = QuickSyringeBG.Tints[0].A;
                        }
                        else if ( TempSize > QuickSyringeDisplayTime - QuickSyringeFadeOutTime )
                        {
                            QuickSyringeBG.Tints[0].A = int((1.0 - ((TempSize - (QuickSyringeDisplayTime - QuickSyringeFadeOutTime)) / QuickSyringeFadeOutTime)) * 255.0);
                            QuickSyringeBG.Tints[1].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeIcon.Tints[0].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeIcon.Tints[1].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeDigits.Tints[0].A = QuickSyringeBG.Tints[0].A;
                            QuickSyringeDigits.Tints[1].A = QuickSyringeBG.Tints[0].A;
                        }
                        else
                        {
                            QuickSyringeBG.Tints[0].A = 255;
                            QuickSyringeBG.Tints[1].A = 255;
                            QuickSyringeIcon.Tints[0].A = 255;
                            QuickSyringeIcon.Tints[1].A = 255;
                            QuickSyringeDigits.Tints[0].A = 255;
                            QuickSyringeDigits.Tints[1].A = 255;
                        }

                        if ( !bLightHud )
                        {
                            DrawSpriteWidget(C, QuickSyringeBG);
                        }

                        DrawSpriteWidget(C, QuickSyringeIcon);
                        DrawNumericWidget(C, QuickSyringeDigits, DigitsSmall);
                    }
                    else
                    {
                        bDisplayQuickSyringe = false;
                    }
                }

                if ( KFMedicGun(PawnOwner.Weapon) != none )
                {
                    MedicGunDigits.Value = KFMedicGun(PawnOwner.Weapon).ChargeBar() * 100;

                    if ( MedicGunDigits.Value < 50 )
                    {
                        MedicGunDigits.Tints[0].R = 128;
                        MedicGunDigits.Tints[0].G = 128;
                        MedicGunDigits.Tints[0].B = 128;

                        MedicGunDigits.Tints[1] = SyringeDigits.Tints[0];
                    }
                    else if ( MedicGunDigits.Value < 100 )
                    {
                        MedicGunDigits.Tints[0].R = 192;
                        MedicGunDigits.Tints[0].G = 96;
                        MedicGunDigits.Tints[0].B = 96;

                        MedicGunDigits.Tints[1] = SyringeDigits.Tints[0];
                    }
                    else
                    {
                        MedicGunDigits.Tints[0].R = 255;
                        MedicGunDigits.Tints[0].G = 64;
                        MedicGunDigits.Tints[0].B = 64;

                        MedicGunDigits.Tints[1] = MedicGunDigits.Tints[0];
                    }

                    if ( !bLightHud )
                    {
                        DrawSpriteWidget(C, MedicGunBG);
                    }

                    DrawSpriteWidget(C, MedicGunIcon);
                    DrawNumericWidget(C, MedicGunDigits, DigitsSmall);
                }
                
                if ( ClassIsChildOf(WeaponClass, class'Welder') )
                {
                    if ( !bLightHud )
                    {
                        DrawSpriteWidget(C, WelderBG);
                    }

                    DrawSpriteWidget(C, WelderIcon);
                    DrawNumericWidget(C, WelderDigits, DigitsSmall);
                }
                else if ( !WeaponClass.default.bMeleeWeapon && WeaponClass.default.bConsumesPhysicalAmmo )
                {
                    if ( !bLightHud )
                    {
                        DrawSpriteWidget(C, ClipsBG);
                    }

                    if ( ClassIsChildOf(WeaponClass, class'HuskGun') )
                    {
                        ClipsDigits.PosX = 0.873;
                        DrawNumericWidget(C, ClipsDigits, DigitsSmall);
                        ClipsDigits.PosX = default.ClipsDigits.PosX;
                    }
                    else
                    {
                        DrawNumericWidget(C, ClipsDigits, DigitsSmall);
                    }

                    if ( ClassIsChildOf(WeaponClass, class'LAW') )
                    {
                        DrawSpriteWidget(C, LawRocketIcon);
                    }
                    else if ( ClassIsChildOf(WeaponClass, class'Crossbow') )
                    {
                        DrawSpriteWidget(C, ArrowheadIcon);
                    }
                    else if ( ClassIsChildOf(WeaponClass, class'CrossBuzzSaw') )
                    {
                        DrawSpriteWidget(C, SawAmmoIcon);
                    }                
                    else if ( ClassIsChildOf(WeaponClass, class'PipeBombExplosive') )
                    {
                        DrawSpriteWidget(C, PipeBombIcon);
                    }
                    else if ( ClassIsChildOf(WeaponClass, class'M79GrenadeLauncher') )
                    {
                        DrawSpriteWidget(C, M79Icon);
                    }
                    else if ( ClassIsChildOf(WeaponClass, class'HuskGun') )
                    {
                        DrawSpriteWidget(C, HuskAmmoIcon);
                    }
                    else if ( ClassIsChildOf(WeaponClass, class'M99SniperRifle') )
                    {
                        DrawSpriteWidget(C, SingleBulletIcon);
                    }                    
                    else
                    {
                        if ( !bLightHud )
                        {
                            DrawSpriteWidget(C, BulletsInClipBG);
                        }

                        DrawNumericWidget(C, BulletsInClipDigits, DigitsSmall);

                        if ( ClassIsChildOf(WeaponClass, class'Flamethrower') || ClassIsChildOf(WeaponClass, class'ScrnChainsaw') )
                        {
                            DrawSpriteWidget(C, FlameIcon);
                            DrawSpriteWidget(C, FlameTankIcon);
                        }
                        else if ( ClassIsChildOf(WeaponClass, class'Shotgun') || ClassIsChildOf(WeaponClass, class'BoomStick') || ClassIsChildOf(WeaponClass, class'Winchester')
                            || ClassIsChildOf(WeaponClass, class'BenelliShotgun') )
                        {
                            DrawSpriteWidget(C, SingleBulletIcon);
                            DrawSpriteWidget(C, BulletsInClipIcon);
                        }
                        else if ( ClassIsChildOf(WeaponClass, class'ZEDGun') || ClassIsChildOf(WeaponClass, class'ZEDMKIIWeapon') )
                        {
                            DrawSpriteWidget(C, ClipsIcon);
                            DrawSpriteWidget(C, ZedAmmoIcon);
                        }     
                        else if ( ClassIsChildOf(WeaponClass, class'SealSquealHarpoonBomber') || ClassIsChildOf(WeaponClass, class'SeekerSixRocketLauncher') )
                        {
                            DrawSpriteWidget(C, ClipsIcon);
                            DrawSpriteWidget(C, SingleNadeIcon);
                        }
                        else if ( ClassIsChildOf(WeaponClass, class'M32GrenadeLauncher') )
                        {
                            DrawSpriteWidget(C, M79Icon);
                            DrawSpriteWidget(C, SingleNadeIcon);
                        }
                        
                        else
                        {
                            DrawSpriteWidget(C, ClipsIcon);
                            DrawSpriteWidget(C, BulletsInClipIcon);
                        }
                    }

                    if ( KFWeapon != none && KFWeapon.bTorchEnabled )
                    {
                        if ( !bLightHud )
                        {
                            DrawSpriteWidget(C, FlashlightBG);
                        }

                        DrawNumericWidget(C, FlashlightDigits, DigitsSmall);

                        if ( KFWeapon.FlashLight != none && KFWeapon.FlashLight.bHasLight )
                        {
                            DrawSpriteWidget(C, FlashlightIcon);
                        }
                        else
                        {
                            DrawSpriteWidget(C, FlashlightOffIcon);
                        }
                    }
                }

                // Secondary ammo
                if ( (KFWeapon != none && KFWeapon.bHasSecondaryAmmo) || (bSpectating && CurClipsSecondary > 0) )
                {
                    if ( !bLightHud )
                    {
                        DrawSpriteWidget(C, SecondaryClipsBG);
                    }

                    DrawNumericWidget(C, SecondaryClipsDigits, DigitsSmall);
                    DrawSpriteWidget(C, SecondaryClipsIcon);
                }
            }
        }



        if ( KFGRI != none && KFGRI.bHUDShowCash ) {
            DrawSpriteWidget(C, CashIcon);
            DrawNumericWidget(C, CashDigits, DigitsBig);
        }

        if( KFPRI != none )
            SV = Class<SRVeterancyTypes>(KFPRI.ClientVeteranSkill);

        if ( SV!=None ) {
            SV.Static.SpecialHUDInfo(KFPRI, C);
            //experience level
            TempSize = 36 * VeterancyMatScaleFactor * 1.4;
            TempX = C.ClipX * 0.007;
            TempY = C.ClipY * 0.93 - TempSize;
            C.DrawColor = WhiteColor;

            TempLevel = KFPRI.ClientVeteranSkillLevel;
            if( ClientRep!=None && (TempLevel+1)<ClientRep.MaximumLevel )
            {
                // Draw progress bar.
                bDisplayingProgress = true;
                if( NextLevelTimer<Level.TimeSeconds )
                {
                    NextLevelTimer = Level.TimeSeconds+3.f;
                    LevelProgressBar = SV.Static.GetTotalProgress(ClientRep,TempLevel+1);
                }
                C.DrawColor.A = 64;
                C.SetPos(TempX, TempY-TempSize*0.12f);
                C.DrawTileStretched(Texture'thinpipe_b',TempSize*2.f,TempSize*0.1f);
                if( VisualProgressBar>0.f )
                {
                    C.DrawColor.A = 150;
                    C.SetPos(TempX, TempY-TempSize*0.12f);
                    C.DrawTileStretched(Texture'thinpipe_f',TempSize*2.f*VisualProgressBar,TempSize*0.1f);
                }
            }

            C.DrawColor.A = 192;
            TempLevel = SV.Static.PreDrawPerk(C,TempLevel,TempMaterial,TempStarMaterial);

            C.SetPos(TempX, TempY);
            C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

            TempX += (TempSize - VetStarSize);
            TempY += (TempSize - (2.0 * VetStarSize));

            for ( i = 0; i < TempLevel; i++ )
            {
                C.SetPos(TempX, TempY-(Counter*VetStarSize*0.8f));
                C.DrawTile(TempStarMaterial, VetStarSize, VetStarSize, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());

                if( ++Counter==5 )
                {
                    Counter = 0;
                    TempX+=VetStarSize;
                }
            }
            
            // bonus level
            if (ScrnPerk != none && ScrnPerk.static.GetClientVeteranSkillLevel(KFPRI) != KFPRI.ClientVeteranSkillLevel) {
                TempSize = 36 * VeterancyMatScaleFactor * 1.4;
                //TempX = C.ClipX * 0.007 + (TempSize - VetStarSize) + 3*VetStarSize;
                TempX += VetStarSize;
                TempY = C.ClipY * 0.93 - TempSize;
                C.DrawColor = WhiteColor;
                Counter = 0;

                TempLevel = ScrnPerk.static.GetClientVeteranSkillLevel(KFPRI);

                C.DrawColor.A = 192;
                TempLevel = ScrnPerk.Static.PreDrawPerk(C,TempLevel,TempMaterial,TempStarMaterial);

                C.SetPos(TempX, TempY);
                C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

                TempX += (TempSize - VetStarSize);
                TempY += (TempSize - (2.0 * VetStarSize));

                for ( i = 0; i < TempLevel; i++ )
                {
                    C.SetPos(TempX, TempY-(Counter*VetStarSize*0.8f));
                    C.DrawTile(TempStarMaterial, VetStarSize, VetStarSize, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());

                    if( ++Counter==5 )
                    {
                        Counter = 0;
                        TempX+=VetStarSize;
                    }
                }
            }        
        }
    }

    if ( Level.TimeSeconds - LastVoiceGainTime < 0.333 )
    {
        if ( !bUsingVOIP && PlayerOwner != None && PlayerOwner.ActiveRoom != None &&
             PlayerOwner.ActiveRoom.GetTitle() == "Team" )
        {
            bUsingVOIP = true;
            PlayerOwner.NotifySpeakingInTeamChannel();
        }

        DisplayVoiceGain(C);
    }
    else
    {
        bUsingVOIP = false;
    }

    if ( bDisplayInventory || bInventoryFadingOut )
    {
        DrawInventory(C);
    }
    
    if ( BlamedMonsterClass != none )
        DrawBlameIcons(C);

    if ( bShowDamages )
        DrawDamage(C);    
        
    if ( bShowSpeed )
        DrawSpeed(C);         
    
    if ( bSpectating || bSpectatingZED ) {
        // player name
        C.SetDrawColor(200, 200, 200, KFHUDAlpha);
        C.Font = GetFontSizeIndex(C, -4);
        C.TextSize(strFollowing, TempX, TempY);
        c.SetPos((c.ClipX-TempX)/2, 0);
        c.DrawText(strFollowing);

        if ( bSpectatingZED ) {
            s = KFMonster(PawnOwner).MenuName;
            C.Font = LoadWaitingFont(1);
            C.SetDrawColor(100, 0, 0, KFHUDAlpha);
        }
        else {
            s = class'ScrnBalance'.default.Mut.ColoredPlayerName(PawnOwner.PlayerReplicationInfo);
            C.Font = GetFontSizeIndex(C, 0);
            C.SetDrawColor(255, 255, 255, KFHUDAlpha);
        }
        C.TextSize(s, TempX, TempSize);
        c.SetPos((c.ClipX-TempX)/2, TempY);
        c.DrawText(s);
        
        C.SetDrawColor(255, 255, 255, KFHUDAlpha);
        // weapon icon
        if ( WeaponClass != none && WeaponClass.default.TraderInfoTexture != none ) {
            TempSize = c.ClipY * 0.2;
            C.SetPos((c.ClipX-TempSize)/2, c.ClipY - TempSize);
            C.DrawTile(WeaponClass.default.TraderInfoTexture, TempSize, TempSize, 0, 0, WeaponClass.default.TraderInfoTexture.MaterialUSize(), WeaponClass.default.TraderInfoTexture.MaterialVSize());
        }
    }
    else {
        if ( ScrnPawn != none ) {
            DrawCookingBar(C);
        }
    }
}



simulated function DrawHudPassC(Canvas C)
{
	DrawFadeEffect(C);

	if ( bShowScoreBoard && ScoreBoard != None )
		ScoreBoard.DrawScoreboard(C);

	// portrait
	if ( bShowPortrait && (Portrait != None) )
		DrawPortraitSE(C); // finally this is not final :)  -- PooSH

	if( bCrosshairShow && bShowKFDebugXHair )
	{
		DrawCrosshair(C);
	}

	// Slow, for debugging only
	if( bDebugPlayerCollision && (class'ROEngine.ROLevelInfo'.static.RODebugMode() || Level.NetMode == NM_StandAlone) )
	{
		DrawPointSphere();
	}        
}

simulated function DrawWeaponName(Canvas C)
{
	local string CurWeaponName;
	local float XL,YL;

	if ( PawnOwner == None )
        return;
        
    if ( PawnOwner.Weapon != none ) 
        CurWeaponName = PawnOwner.Weapon.GetHumanReadableName();
    else if ( PlayerOwner.Pawn != PawnOwner && ScrnHumanPawn(PawnOwner) != none 
            && ScrnHumanPawn(PawnOwner).SpecWeapon != none )
        CurWeaponName = ScrnHumanPawn(PawnOwner).SpecWeapon.default.ItemName; 
        
    if ( CurWeaponName == "" )
        return;

	
	C.Font  = GetFontSizeIndex(C, -1);
	C.SetDrawColor(255, 50, 50, KFHUDAlpha);
	C.Strlen(CurWeaponName, XL, YL);

	// Diet Hud needs to move the weapon name a little bit or it looks weird
	if ( !bLightHud )
		C.SetPos((C.ClipX * 0.983) - XL, C.ClipY * 0.90);
	else
		C.SetPos((C.ClipX * 0.97) - XL, C.ClipY * 0.915);

	C.DrawText(CurWeaponName);
}

simulated function UpdateHud()
{
    local ScrnHuskGun aHuskGun;

    //reset to default values
    ClipsDigits.Tints[0] = default.ClipsDigits.Tints[0];
    ClipsDigits.Tints[1] = default.ClipsDigits.Tints[1];
    BulletsInClipDigits.Tints[0] = default.BulletsInClipDigits.Tints[0];
    BulletsInClipDigits.Tints[1] = default.BulletsInClipDigits.Tints[1];

    super.UpdateHud();

    if ( PawnOwner == none )
        return;


    if ( KFWeapon(PawnOwner.Weapon) != none )  {
        if ( CrossBuzzSaw(PawnOwner.Weapon) != none || M99SniperRifle(PawnOwner.Weapon) != none ) {
            ClipsDigits.Value = PawnOwner.Weapon.AmmoAmount(0);
        }
        else {
            aHuskGun = ScrnHuskGun(PawnOwner.Weapon);
            if ( aHuskGun != none && aHuskGun.ChargeAmount > 0.33 ) {
                if (aHuskGun.ChargeAmount > 0.99) {
                    ClipsDigits.Tints[0].R = 0;
                    ClipsDigits.Tints[0].G = 206;
                    ClipsDigits.Tints[0].B = 0;
                }
                else if (aHuskGun.ChargeAmount > 0.66) {
                    ClipsDigits.Tints[0].R = 206;
                    ClipsDigits.Tints[0].G = 206;
                    ClipsDigits.Tints[0].B = 0;
                } 
                else {
                    ClipsDigits.Tints[0].R = 206;
                    ClipsDigits.Tints[0].G = 103;
                    ClipsDigits.Tints[0].B = 0;
                } 
                ClipsDigits.Tints[1] = ClipsDigits.Tints[0];
            }
            else if (IsLowAmmo(KFWeapon(PawnOwner.Weapon))) {
                BulletsInClipDigits.Tints[0].R = 196;
                BulletsInClipDigits.Tints[0].G = 206;
                BulletsInClipDigits.Tints[0].B = 0;

                BulletsInClipDigits.Tints[1] = BulletsInClipDigits.Tints[0];
            } 
        }
    } 
    else if ( PlayerOwner.Pawn != PawnOwner && ScrnHumanPawn(PawnOwner) != none ) {
        // spectating
        GrenadeDigits.Value = ScrnHumanPawn(PawnOwner).SpecNades;
    }
}

simulated function CalculateAmmo()
{
    local KFWeapon W;
    local ScrnHumanPawn ScrnPawn;
    
	MaxAmmoPrimary = 1;
	CurAmmoPrimary = 0;
    CurClipsSecondary = 0;

	if ( PawnOwner == None  )
		return;
    
    ScrnPawn = ScrnHumanPawn(PawnOwner);    
    W = KFWeapon(PawnOwner.Weapon);    
    if ( W != none ) {
        W.GetAmmoCount(MaxAmmoPrimary,CurAmmoPrimary);

        if( W.bHasSecondaryAmmo && W.FireModeClass[1].default.AmmoClass != none )
           CurClipsSecondary = W.AmmoAmount(1);

        if( W.bHoldToReload ) {
            CurClipsPrimary = Max(CurAmmoPrimary-W.MagAmmoRemaining,0); // Single rounds reload, just show the true ammo count.
        }
        else {
            if ( CurAmmoPrimary <=  W.MagAmmoRemaining)
                CurClipsPrimary = 0;
            else
                CurClipsPrimary = ceil((CurAmmoPrimary - W.MagAmmoRemaining) / W.MagCapacity);
        }
    }
    else if ( ScrnPawn != none && PlayerOwner.Pawn != ScrnPawn && ScrnPawn.SpecWeapon != none ) {
        BulletsInClipDigits.Value = ScrnPawn.SpecMagAmmo;
        CurClipsPrimary = ScrnPawn.SpecMags;
        CurClipsSecondary = ScrnPawn.SpecSecAmmo;
        if ( ClassIsChildOf(ScrnPawn.SpecWeapon, class'Welder') )
            MaxAmmoPrimary = 300; // lame, but this value is used by welder only
    }
}

simulated function SetScoreBoardClass (class<Scoreboard> ScoreBoardClass)
{
    super.SetScoreBoardClass(ScoreBoardClass);
    
    if ( ScoreBoard != none )
        ScrnScoreBoardClass = class<ScrnScoreBoard>(ScoreBoard.class);
    if ( ScrnScoreBoardClass == none )
        ScrnScoreBoardClass = class'ScrnScoreBoard';
}

function DrawPlayerInfo(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
    local float XL, YL, TempX, TempY, TempSize;
    local float Dist, OffsetX;
    local byte BeaconAlpha,Counter;
    local float OldZ;
    local Material TempMaterial, TempStarMaterial;
    local byte i, TempLevel;
    local ScrnHumanPawn ScrnPawn;
    local bool bSameTeam;
    local KFPlayerReplicationInfo EnemyPRI;

    if ( bHidePlayerInfo )
        return;
    
    EnemyPRI = KFPlayerReplicationInfo(P.PlayerReplicationInfo);
    if ( P == none || EnemyPRI == none || KFPRI == none || KFPRI.bViewingMatineeCinematic )
    {
        return;
    }

    Dist = vsize(P.Location - PlayerOwner.CalcViewLocation);
    Dist -= HealthBarFullVisDist;
    Dist = FClamp(Dist, 0, HealthBarCutoffDist-HealthBarFullVisDist);
    Dist = Dist / (HealthBarCutoffDist - HealthBarFullVisDist);
    BeaconAlpha = byte((1.f - Dist) * 255.f);

    if ( BeaconAlpha == 0 )
    {
        return;
    }

    bSameTeam = KFPRI.Team == none || EnemyPRI.Team == none 
        || KFPRI.Team.TeamIndex == EnemyPRI.Team.TeamIndex;
        
    OldZ = C.Z;
    C.Z = 1.0;
    C.Style = ERenderStyle.STY_Alpha;

    // player name
    C.Font = GetConsoleFont(C);
    if ( bSameTeam ) 
        C.SetDrawColor(255, 255, 255, BeaconAlpha);
    else
        C.SetDrawColor(255, 0, 0, BeaconAlpha);
	ScrnScoreBoardClass.Static.TextSizeCountry(C,EnemyPRI,XL,YL);
	ScrnScoreBoardClass.Static.DrawCountryNameSE(C,EnemyPRI,ScreenLocX-(XL * 0.5),ScreenLocY-(YL * 0.75), 0, !bSameTeam);

    OffsetX = (36.f * VeterancyMatScaleFactor * 0.6) - (HealthIconSize + 2.0);

    if ( Class<SRVeterancyTypes>(EnemyPRI.ClientVeteranSkill)!=none 
            && EnemyPRI.ClientVeteranSkill.default.OnHUDIcon!=none )
    {
        TempLevel = Class<SRVeterancyTypes>(KFPlayerReplicationInfo(P.PlayerReplicationInfo).ClientVeteranSkill).Static.PreDrawPerk(C,
                    KFPlayerReplicationInfo(P.PlayerReplicationInfo).ClientVeteranSkillLevel,
                    TempMaterial,TempStarMaterial);

        TempSize = 36.f * VeterancyMatScaleFactor;
        TempX = ScreenLocX + ((BarLength + HealthIconSize) * 0.5) - (TempSize * 0.25) - OffsetX;
        TempY = ScreenLocY - YL - (TempSize * 0.75);

        C.SetPos(TempX, TempY);
        C.DrawTile(TempMaterial, TempSize, TempSize, 0, 0, TempMaterial.MaterialUSize(), TempMaterial.MaterialVSize());

        TempX += (TempSize - (VetStarSize * 0.75));
        TempY += (TempSize - (VetStarSize * 1.5));

        for ( i = 0; i < TempLevel; i++ )
        {
            C.SetPos(TempX, TempY-(Counter*VetStarSize*0.7f));
            C.DrawTile(TempStarMaterial, VetStarSize * 0.7, VetStarSize * 0.7, 0, 0, TempStarMaterial.MaterialUSize(), TempStarMaterial.MaterialVSize());

            if( ++Counter==5 )
            {
                Counter = 0;
                TempX+=VetStarSize;
            }
        }
    }

    ScrnPawn = ScrnHumanPawn(P);
    if ( bSameTeam || (ScrnPerk != none && ScrnPerk.static.ShowEnemyHealthBars(KFPRI, EnemyPRI))) {
        // Health
        if ( P.Health > 0 ) {
            if ( ScrnPawn != none && ScrnPawn.ClientHealthToGive > 0 ) {
                DrawKFBarEx(C, ScreenLocX - OffsetX, (ScreenLocY - YL) - 0.4 * BarHeight, FClamp(P.Health / P.HealthMax, 0, 1), BeaconAlpha, false, 
                    FClamp(ScrnPawn.ClientHealthToGive / P.HealthMax, 0, 1.0 - P.Health / P.HealthMax));
            }
            else
                DrawKFBarEx(C, ScreenLocX - OffsetX, (ScreenLocY - YL) - 0.4 * BarHeight, FClamp(P.Health / P.HealthMax, 0, 1), BeaconAlpha);
        }
        // Armor
        if ( P.ShieldStrength > 0 )
            DrawKFBarEx(C, ScreenLocX - OffsetX, (ScreenLocY - YL) - 1.5 * BarHeight, FClamp(P.ShieldStrength / 100.f, 0, 3), BeaconAlpha, true);
    }
    
    C.Z = OldZ;
}

simulated function DrawKFBarEx(Canvas C, float XCentre, float YCentre, float BarPercentage, byte BarAlpha, optional bool bArmor, optional float BarPercentage2)
{
    C.SetDrawColor(92, 92, 92, BarAlpha);
    C.SetPos(XCentre - 0.5 * BarLength, YCentre - 0.5 * BarHeight);
    C.DrawTileStretched(WhiteMaterial, BarLength, BarHeight);

    if ( bArmor )
    {
        C.SetDrawColor(255, 255, 255, BarAlpha);
        C.SetPos(XCentre - (0.5 * BarLength) - ArmorIconSize - 2.0, YCentre - (ArmorIconSize * 0.5));
        C.DrawTile(ArmorIcon.WidgetTexture, ArmorIconSize, ArmorIconSize, 0, 0, ArmorIcon.WidgetTexture.MaterialUSize(), ArmorIcon.WidgetTexture.MaterialVSize());

        C.SetDrawColor(0, 0, 255, BarAlpha);
        if ( BarPercentage > 1.0 ) {
            C.SetDrawColor(200, 200, 0, BarAlpha); //draw shield > 100 in yellow
            BarPercentage -= 1.0;
        }
        if ( BarPercentage > 1.0 ) {
            C.SetDrawColor(0, 200, 0, BarAlpha); //draw shield > 200 in green
            BarPercentage -= 1.0;
        }
    }
    else
    {
        C.SetDrawColor(255, 255, 255, BarAlpha);
        C.SetPos(XCentre - (0.5 * BarLength) - HealthIconSize - 2.0, YCentre - (HealthIconSize * 0.5));
        C.DrawTile(HealthIcon.WidgetTexture, HealthIconSize, HealthIconSize, 0, 0, HealthIcon.WidgetTexture.MaterialUSize(), HealthIcon.WidgetTexture.MaterialVSize());

        C.SetDrawColor(255, 0, 0, BarAlpha);
    }

    C.SetPos(XCentre - (0.5 * BarLength) + 1.0, YCentre - (0.5 * BarHeight) + 1.0);
    C.DrawTileStretched(WhiteMaterial, (BarLength - 2.0) * BarPercentage, BarHeight - 2.0);
    
    if ( BarPercentage2 > 0 ) {
        C.SetDrawColor(255, 128, 128, BarAlpha);
        C.SetPos(XCentre - (0.5 * BarLength) + 1.0 + (BarLength - 2.0) * BarPercentage, YCentre - (0.5 * BarHeight) + 1.0);
        C.DrawTileStretched(WhiteMaterial, (BarLength - 2.0) * BarPercentage2, BarHeight - 2.0);
    }
}

simulated function DrawBlamedIcon(Canvas C, float XCentre, float YBottom, byte BarAlpha)
{
    C.SetDrawColor(255, 255, 255, BarAlpha);
    C.SetPos(XCentre - (0.5 * BlamedIconSize), YBottom - BlamedIconSize);
    C.DrawTile(BlamedIcon.WidgetTexture, BlamedIconSize, BlamedIconSize, 0, 0, BlamedIcon.WidgetTexture.MaterialUSize(), BlamedIcon.WidgetTexture.MaterialVSize());
}

simulated function ShowDamage(int Damage, float HitTime, vector HitLocation, byte DamTypeNum)
{
    local color c;
    
    DamagePopups[NextDamagePopupIndex].damage = Damage;
    DamagePopups[NextDamagePopupIndex].HitTime = HitTime;
    DamagePopups[NextDamagePopupIndex].DamTypeNum = DamTypeNum;
    DamagePopups[NextDamagePopupIndex].HitLocation = HitLocation;
    //ser random speed of fading out, so multiple damages in the same hit location don't overlap each other
    DamagePopups[NextDamagePopupIndex].RandX = 2.0 * frand();
    DamagePopups[NextDamagePopupIndex].RandY = 1.0 + frand();
    
    c.A = 255;
    if ( DamTypeNum == 1 ) { // headshots
        
        c.R = 0;
        c.G = 100;
        c.B = 255;
    }
    else if ( DamTypeNum == 2 ) { // fire DoT
        c.R = 206;
        c.G = 103;
        c.B = 0;
    } 
    else if ( DamTypeNum == 10 ) { // player-to-player damage
        c.R = 206;
        c.G = 0;
        c.B = 206;
    }     
    else if ( Damage >= 500 ) {
        c.R = 0;
        c.G = 206;
        c.B = 0;
    }
    else if ( Damage >= 175 ) {
        c.R = 206;
        c.G = 206;
        c.B = 0;
    }
    /*
    else if ( Damage >= 100 ){
        c.R = 206;
        c.G = 64;
        c.B = 103;
    }
    */
    else if ( Damage > 0 ) {
        c.R = 206;
        c.G = 64;
        c.B = 64;
    } 
    else {
        c.R = 127;
        c.G = 127;
        c.B = 127;
    } 
    DamagePopups[NextDamagePopupIndex].FontColor = c;

    if( ++NextDamagePopupIndex >= DAMAGEPOPUP_COUNT)
        NextDamagePopupIndex=0;
}

simulated function DrawDamage(Canvas C)
{
    local int i;
    local float TimeSinceHit;
    local vector CameraLocation, CamDir;
    local rotator CameraRotation;
    local vector HBScreenPos;
    local float TextWidth, TextHeight, x;
      
    C.GetCameraLocation(CameraLocation, CameraRotation);
    CamDir    = vector(CameraRotation);

    if ( C.ClipX <= 800 )
        DamagePopupFont = 7;
    else if ( C.ClipX <= 1024 )
        DamagePopupFont = 6;
    else if ( C.ClipX < 1400 )
        DamagePopupFont = 5;
    else if ( C.ClipX < 1700 )
        DamagePopupFont = 4;
    else
        DamagePopupFont = 3;   
        
    C.Font = LoadFont(DamagePopupFont);

    for( i=0; i < DAMAGEPOPUP_COUNT ; i++ ) {
        TimeSinceHit = Level.TimeSeconds - DamagePopups[i].HitTime;
        if( TimeSinceHit > DamagePopupFadeOutTime 
                || ( Normal(DamagePopups[i].HitLocation - CameraLocation) dot Normal(CamDir) < 0.1 ) ) //don't draw if player faced back to the hit location
            continue;
        
        HBScreenPos = C.WorldToScreen(DamagePopups[i].HitLocation);    
        C.StrLen(DamagePopups[i].damage, TextWidth, TextHeight);  
        //draw just on the hit location
        HBScreenPos.Y -= TextHeight/2;
        HBScreenPos.X -= TextWidth/2;
        
        //let numbers to fly up
        HBScreenPos.Y -= TimeSinceHit * TextHeight * DamagePopups[i].RandY;
        x = Sin(2*Pi * TimeSinceHit/DamagePopupFadeOutTime) * TextWidth * DamagePopups[i].RandX;
        // odd numbers start to flying to the right side, even - left
        // So in situations of decapitaion player could see both damages
        if ( i % 2 == 0)
            x *= -1.0; 
        HBScreenPos.X += x;          

        C.DrawColor = DamagePopups[i].FontColor;
        C.DrawColor.A = 255 * cos(0.5*Pi * TimeSinceHit/DamagePopupFadeOutTime);

        C.SetPos( HBScreenPos.X, HBScreenPos.Y);
        C.DrawText(DamagePopups[i].damage);
    }
}

simulated function MyPerkChanged(class<KFVeterancyTypes> OldPerk)
{
    // destroy current PerkOverlay, unless new perk has the same one
    if ( PerkOverlay != none && (ScrnPerk == none || ScrnPerk.default.HUDOverlay != PerkOverlay.class) ) {
        PerkOverlay.Destroy();
        PerkOverlay = none;        
    }
    
    if ( PerkOverlay == none && ScrnPerk != none && ScrnPerk.default.HUDOverlay != none ) {
        PerkOverlay = spawn(ScrnPerk.default.HUDOverlay, self);
        if ( PerkOverlay != none )
            AddHudOverlay(PerkOverlay);
    }
}

simulated function Tick(float deltaTime)
{
    super.Tick(deltaTime);
    
    // update KFPRI for spectators
    if ( PawnOwner != none )
        KFPRI = KFPlayerReplicationInfo(PawnOwner.PlayerReplicationInfo);
    else if ( PlayerOwner != none )
        KFPRI = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
    
    if ( KFPRI != none && PawnOwner != none ) {
        if ( PrevPerk != KFPRI.ClientVeteranSkill ) {
            ScrnPerk = class<ScrnVeterancyTypes>(KFPRI.ClientVeteranSkill);
            MyPerkChanged(PrevPerk);
            PrevPerk = KFPRI.ClientVeteranSkill;
        }
    }    
    
    if ( BlamedMonsterClass != none ) {
        BlameCountdown -= deltaTime;
        if ( BlameCountdown <= 0 ) {
            BlamedMonsterClass = none;
            BlameCountdown = default.BlameCountdown; // set for the next blame
        }
    }
    
}


simulated function DrawHealthBar(Canvas C, Actor A, int Health, int MaxHealth, float Height)
{
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local float Dist, HealthPct;
    local color OldDrawColor;

    // rjp --  don't draw the health bar if menus are open
    // exception being, the Veterancy menu

    if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name != 'GUIVeterancyBinder' )
    {
        return;
    }

    OldDrawColor = C.DrawColor;

    C.GetCameraLocation(CameraLocation, CameraRotation);
    if ( KFMonster(A) != none && KFMonster(A).bUseExtendedCollision )
        TargetLocation = A.Location + vect(0, 0, 1) * (KFMonster(A).ColHeight + KFMonster(A).ColOffset.Z);
    else
        TargetLocation = A.Location + vect(0, 0, 1) * A.CollisionHeight;
    Dist = VSize(TargetLocation - CameraLocation);

    EnemyHealthBarLength = FMin(default.EnemyHealthBarLength * (float(C.SizeX) / 1024.f),default.EnemyHealthBarLength);
    EnemyHealthBarHeight = FMin(default.EnemyHealthBarHeight * (float(C.SizeX) / 1024.f),default.EnemyHealthBarHeight);


    CamDir  = vector(CameraRotation);

    // Check Distance Threshold / behind camera cut off
    if ( Dist > HealthBarCutoffDist || (Normal(TargetLocation - CameraLocation) dot CamDir) < 0 )
    {
        return;
    }

    // Target is located behind camera
    HBScreenPos = C.WorldToScreen(TargetLocation);

    if ( HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
    {
        return;
    }

    if ( FastTrace(TargetLocation, CameraLocation) )
    {
        C.SetDrawColor(192, 192, 192, 255);
        C.SetPos(HBScreenPos.X - EnemyHealthBarLength * 0.5, HBScreenPos.Y - EnemyHealthBarHeight);
        C.DrawTileStretched(WhiteMaterial, EnemyHealthBarLength, EnemyHealthBarHeight);

        HealthPct = 1.0f * Health / MaxHealth;

        C.SetDrawColor(255, 0, 0, 255);
        C.SetPos(HBScreenPos.X - EnemyHealthBarLength * 0.5 + 1.0, HBScreenPos.Y - EnemyHealthBarHeight + 1.0);
        C.DrawTileStretched(WhiteMaterial, (EnemyHealthBarLength - 2.0) * HealthPct, EnemyHealthBarHeight - 2.0);
    }

    C.DrawColor = OldDrawColor;
}


function DrawBlameIcons(Canvas C)
{
    local KFMonster M;
    local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
    local rotator CameraRotation;
    local float Dist, IconSize;
    local color OldDrawColor;

    if ( BlamedMonsterClass == none )
        return;

    // rjp --  don't draw the health bar if menus are open
    // exception being, the Veterancy menu

    if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name != 'GUIVeterancyBinder' )
    {
        return;
    }

    OldDrawColor = C.DrawColor;

    C.GetCameraLocation(CameraLocation, CameraRotation);
    
    foreach C.ViewPort.Actor.VisibleCollidingActors(class'KFMonster',M,BlameDrawDistance,C.ViewPort.Actor.CalcViewLocation) {
        if ( ClassIsChildOf(M.class, BlamedMonsterClass) && M.Health > 0 && !M.Cloaked() ) {
            if ( M.bUseExtendedCollision)
                TargetLocation = M.Location + vect(0, 0, 1) * (M.ColHeight + M.ColOffset.Z);
            else 
                TargetLocation = M.Location + vect(0, 0, 1) * M.CollisionHeight;
            Dist = VSize(TargetLocation - CameraLocation);
            IconSize = BlamedIconSize * fmax(0.5, (BlameDrawDistance - Dist) / BlameDrawDistance);
            IconSize *= float(C.SizeX) / 1024.f;

            CamDir  = vector(CameraRotation);

            // Check Distance Threshold / behind camera cut off
            if ( Dist > HealthBarCutoffDist || (Normal(TargetLocation - CameraLocation) dot CamDir) < 0 )
            {
                continue;
            }

            // Target is located behind camera
            HBScreenPos = C.WorldToScreen(TargetLocation);

            if ( HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
            {
                continue;
            }

            if ( FastTrace(TargetLocation, CameraLocation) )
            {
                C.SetDrawColor(192, 192, 192, 255);
                C.SetPos(HBScreenPos.X - IconSize * 0.5, HBScreenPos.Y - IconSize);
                C.DrawTile(BlamedIcon.WidgetTexture, IconSize, IconSize, 0, 0, BlamedIcon.WidgetTexture.MaterialUSize(), BlamedIcon.WidgetTexture.MaterialVSize());
            }
        }
    }

    C.DrawColor = OldDrawColor;
}


simulated function DrawDirPointer(Canvas C, KFShopDirectionPointer DirPointer, Vector PointAt, 
    int Row, int Col, optional bool bHideText, optional string TextPrefix, optional bool bRightSide)
{
    local color TextColor;
    local float size;
	local vector   ScreenPos, WorldPos, FixedZPos;
    local rotator  DirPointerRotation;
    local vector MyLocation;
    local actor dummy;
    
    if ( DirPointer == none )
        return;
    
    if ( bHideHud ) {
        DirPointer.bHidden = true;
        return;
    }
    
    TextColor = C.DrawColor;
    
    size = C.SizeX / 16.0;
    if ( bRightSide )
        ScreenPos.X = c.ClipX - size * (0.8 + Row*2.1);
    else
        ScreenPos.X = size * (0.8 + Row*2.1);
	ScreenPos.Y = size * (1.0 + Col*1.5);
	WorldPos = PlayerOwner.Player.Console.ScreenToWorld(ScreenPos) * 10.f * (PlayerOwner.default.DefaultFOV / PlayerOwner.FovAngle) + PlayerOwner.CalcViewLocation;
	DirPointer.SetLocation(WorldPos);
    
    // Let's check for a real Z difference (i.e. different floor) doesn't make sense to rotate the arrow
    // only because the trader is a midget or placed slightly wrong
    if ( PawnOwner != none )
        MyLocation = PawnOwner.Location;
    else 
        PlayerOwner.PlayerCalcView(dummy, MyLocation, DirPointerRotation);
        
    if ( PointAt.Z > MyLocation.Z + 50.f || PointAt.Z < MyLocation.Z - 50.f )
    {
        DirPointerRotation = rotator(PointAt - MyLocation);
    }
    else
    {
        FixedZPos = PointAt;
        FixedZPos.Z = MyLocation.Z;
        DirPointerRotation = rotator(FixedZPos - MyLocation);
    }
   	DirPointer.SetRotation(DirPointerRotation);

	C.DrawActor(None, False, True); // Clear Z.
	DirPointer.bHidden = false;
	C.DrawActor(DirPointer, False, false);
	DirPointer.bHidden = true;
    
    C.DrawColor = TextColor;
    if ( !bHideText ) {
        C.SetPos(ScreenPos.X, ScreenPos.Y + size * 0.5);
        DrawPointerDistance(C, PointAt, TextPrefix, MyLocation);    
    }
       
}

// must be called only from DrawDirPointer!
protected simulated function DrawPointerDistance(Canvas C, Vector PointAt, string TextPrefix, Vector MyLocation)
{
	local int       FontSize;
	local float     XL, YL;
	local string    S;

    S = TextPrefix $ int(VSize(PointAt - MyLocation) / 50) $ DistanceUnitString;
    if ( C.ClipX <= 800 )
        FontSize = 7;
    else if ( C.ClipX <= 1024 )
        FontSize = 6;
    else if ( C.ClipX < 1400 )
        FontSize = 5;
    else if ( C.ClipX < 1700 )
        FontSize = 4;
    else
        FontSize = 3;
    C.Font = LoadFont(FontSize);
    C.StrLen(S, XL, YL);
    C.CurX -= XL/2; 
    C.DrawText(S);
}


// seems like I'm the first who removed that bloody "final" mark  -- PooSH
simulated function DrawPortraitSE( Canvas C )
{
	local float PortraitWidth, PortraitHeight, XL, YL;
	local int Abbrev;
    
    
	PortraitWidth = 0.125 * C.ClipY;
	PortraitHeight = 1.5 * PortraitWidth;
	C.DrawColor = WhiteColor;

	C.SetPos(-PortraitWidth * PortraitX + 0.025 * PortraitWidth, 0.5 * (C.ClipY - PortraitHeight) + 0.025 * PortraitHeight);
	C.DrawTile(Portrait, PortraitWidth, PortraitHeight, 0, 0, 256, 384);

	C.SetPos(-PortraitWidth * PortraitX, 0.5 * (C.ClipY - PortraitHeight));
	C.Font = GetFontSizeIndex(C, -2);

	C.DrawColor = C.static.MakeColor(160, 160, 160);
	C.SetPos(-PortraitWidth * PortraitX + 0.025 * PortraitWidth, 0.5 * (C.ClipY - PortraitHeight) + 0.025 * PortraitHeight);
	C.DrawTile( Material'kf_fx_trip_t.Misc.KFModuNoise', PortraitWidth, PortraitHeight, 0.0, 0.0, 512, 512 );

	C.DrawColor = WhiteColor;
	C.SetPos(-PortraitWidth * PortraitX, 0.5 * (C.ClipY - PortraitHeight));
	C.DrawTileStretched(texture'InterfaceContent.Menu.BorderBoxA1', 1.05 * PortraitWidth, 1.05 * PortraitHeight);

	if ( PortraitPRI != None )
	{
		if ( PortraitPRI.Team != None )
		{
			if ( PortraitPRI.Team.TeamIndex == 0 )
				C.DrawColor = RedColor;
			else C.DrawColor = TurqColor;
		}

		ScrnScoreBoardClass.Static.TextSizeCountry(C,PortraitPRI,XL,YL);
		if ( XL > PortraitWidth )
		{
			C.Font = GetFontSizeIndex(C, -4);
			ScrnScoreBoardClass.Static.TextSizeCountry(C,PortraitPRI,XL,YL);

			if ( XL > PortraitWidth )
			{
				XL = float(Len(PortraitPRI.PlayerName)) * PortraitWidth / XL;
				Abbrev = XL;
				XL = PortraitWidth;
			}
		}
        ScrnScoreBoardClass.Static.DrawCountryNameSE(C,PortraitPRI,C.ClipY / 256 - PortraitWidth * PortraitX + 0.5 * (PortraitWidth - XL), 0.5 * (C.ClipY + PortraitHeight) + 0.06 * PortraitHeight,Abbrev);
	}
	else if ( Portrait == TraderPortrait )
	{
		C.DrawColor = RedColor;
		C.TextSize(TraderString, XL, YL);
		C.SetPos(C.ClipY / 256 - PortraitWidth * PortraitX + 0.5 * (PortraitWidth - XL), 0.5 * (C.ClipY + PortraitHeight) + 0.06 * PortraitHeight);
		C.DrawTextClipped(TraderString,true);
	}
}

// a lot of copy-paste job, because some devs are using "final" mark too much
simulated function DrawSpectatingHud(Canvas C)
{
	local rotator CamRot;
	local vector CamPos, ViewDir, ScreenPos;
	local KFPawn KFBuddy;
    local bool bGameEnded;

	DrawModOverlay(C);

	if( bHideHud )
		return;

	PlayerOwner.PostFX_SetActive(0, false);

	// Grab our View Direction
	C.GetCameraLocation(CamPos, CamRot);
	ViewDir = vector(CamRot);

	// Draw the Name, Health, Armor, and Veterancy above other players (using this way to fix portal's beacon errors).
	foreach VisibleCollidingActors(Class'KFPawn',KFBuddy,1000.f,CamPos)
	{
		KFBuddy.bNoTeamBeacon = true;
		if ( KFBuddy.PlayerReplicationInfo!=None && KFBuddy.Health>0 && ((KFBuddy.Location - CamPos) Dot ViewDir)>0.8 )
		{
			ScreenPos = C.WorldToScreen(KFBuddy.Location+vect(0,0,1)*KFBuddy.CollisionHeight);
			if( ScreenPos.X>=0 && ScreenPos.Y>=0 && ScreenPos.X<=C.ClipX && ScreenPos.Y<=C.ClipY )
				DrawPlayerInfo(C, KFBuddy, ScreenPos.X, ScreenPos.Y);
		}
	}

	DrawFadeEffect(C);

	if ( KFPlayerController(PlayerOwner) != None && KFPlayerController(PlayerOwner).ActiveNote != None )
		KFPlayerController(PlayerOwner).ActiveNote = None;

    bGameEnded = KFGRI != none && KFGRI.EndGameType > 0;    
	if( KFGRI != none && KFGRI.EndGameType > 0 ) {
		if( KFGRI.EndGameType == 2 ) {
			DrawEndGameHUD(C, True);
			DrawStoryHUDInfo(C);
		}
		else 
            DrawEndGameHUD(C, False);
	}

    if ( PlayerOwner.PlayerReplicationInfo != none && !PlayerOwner.PlayerReplicationInfo.bOnlySpectator )
        DrawKFHUDTextElements(C);
	DisplayLocalMessages(C);

	if ( bShowScoreBoard && ScoreBoard != None )
		ScoreBoard.DrawScoreboard(C);
    else if ( !bGameEnded && (PlayerOwner.PlayerReplicationInfo == none || PlayerOwner.PlayerReplicationInfo.bOnlySpectator) )
        DrawSpecialSpectatingHUD(C);
        

	// portrait
	if ( bShowPortrait && Portrait != None )
		DrawPortraitSE(C);

	// Draw hints
	if ( bDrawHint )
		DrawHint(C);
	
	DrawStoryHUDInfo(C);
    
    if ( bShowDamages )
        DrawDamage(C);     
}

simulated function DrawSpecialSpectatingHUD(Canvas C)
{
    local float XL, YL;
    local string S;
    local int i, d;

    if ( KFGRI == none || !KFGRI.bMatchHasBegun )
        return;

    C.Font = LoadWaitingFont(SpecHeaderFont); // 0 - big, 1 - smaller
    C.DrawColor = WhiteColor;
    C.DrawColor.A = KFHUDAlpha;        
        
    // draw time, if game is not finished yet
    if ( KFGRI.EndGameType == 0 && KFGRI.ElapsedTime > 0 ) {
        // total time
        C.SetPos(0, 0);
        C.DrawText(FormatTime(KFGRI.ElapsedTime));
        
        // wave num
        S = WaveString @ string(KFGRI.WaveNumber + 1);
        C.TextSize(S, XL, YL);
        C.SetPos((C.ClipX-XL)*0.5, 0);
        C.DrawText(S);
        
        // number of zeds
        if ( KFGRI.bWaveInProgress )
            S = string(KFGRI.MaxMonsters);
        else 
            s = FormatTime(KFGRI.TimeToNextWave);
        C.TextSize(S, XL, YL);
        C.SetPos(C.ClipX-XL, 0);
        C.DrawText(S);        
    }
    
    // deaths
    if ( bDrawSpecDeaths ) {
        d = 0;
        for ( i = 0; i < KFGRI.PRIArray.Length; i++) {
            if ( !KFGRI.PRIArray[i].bOnlySpectator )        
                d += KFGRI.PRIArray[i].Deaths;
        }
        if ( d > 0 ) {
            S = string(d);
            C.TextSize(S, XL, YL);
            C.SetPos(c.ClipY*0.01, c.ClipY*0.99 - YL/2);
            C.DrawTile(ScrnScoreBoardClass.default.DeathIcon, YL/2, YL/2, 0, 0, ScrnScoreBoardClass.default.DeathIcon.MaterialUSize(), ScrnScoreBoardClass.default.DeathIcon.MaterialVSize());
            C.SetPos(c.ClipY*0.01 + YL/2, c.ClipY*0.99 - YL);
            C.DrawText(S);
        }
    }
}

//
function AddTextMessage(string M, class<LocalMessage> MessageClass, PlayerReplicationInfo PRI)
{
	local int i;
    local bool bSetPRI;
    
    if ( class'ScrnBalance'.default.Mut != none ) {
        M = class'ScrnBalance'.default.Mut.ParseColorTags(M);
        if ( MessageClass==class'SayMessagePlus' ) {
            MessageClass = class'ScrnSayMessagePlus';
            bSetPRI = true;                
        }
        else if ( MessageClass==class'TeamSayMessagePlus' ) {
            MessageClass = class'ScrnTeamSayMessagePlus';
            bSetPRI = true;
        }
        else if ( MessageClass==class'xDeathMessage' )
            MessageClass = class'ScrnDeathMessage';
    }
    else {
        bSetPRI = MessageClass==class'SayMessagePlus' || MessageClass==class'TeamSayMessagePlus';
    }
    

	if( bMessageBeep && MessageClass.Default.bBeep )
		PlayerOwner.PlayBeepSound();

    for( i=0; i<ConsoleMessageCount; i++ )
    {
        if ( TextMessages[i].Text == "" )
            break;
    }
    if( i == ConsoleMessageCount )
    {
        for( i=0; i<ConsoleMessageCount-1; i++ )
            TextMessages[i] = TextMessages[i+1];
    }
	TextMessages[i].Text = M;
	TextMessages[i].MessageLife = Level.TimeSeconds + MessageClass.Default.LifeTime;
	TextMessages[i].TextColor = MessageClass.static.GetConsoleColor(PRI);
	if( bSetPRI )
		TextMessages[i].PRI = PRI;
	else 
        TextMessages[i].PRI = None;    
}

// added support of color messages
function DisplayMessages(Canvas C)
{
	local int i, j, XPos, YPos,MessageCount;
	local float XL, YL, XXL, YYL;
    
	for( i = 0; i < ConsoleMessageCount; i++ )
	{
		if ( TextMessages[i].Text == "" )
			break;
		else if( TextMessages[i].MessageLife < Level.TimeSeconds )
		{
			TextMessages[i].Text = "";

			if( i < ConsoleMessageCount - 1 )
			{
				for( j=i; j<ConsoleMessageCount-1; j++ )
					TextMessages[j] = TextMessages[j+1];
			}
			TextMessages[j].Text = "";
			break;
		}
		else
			MessageCount++;
	}

	YPos = (ConsoleMessagePosY * HudCanvasScale * C.SizeY) + (((1.0 - HudCanvasScale) / 2.0) * C.SizeY);
	if ( PlayerOwner == none || PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bWaitingPlayer )
	{
		XPos = (ConsoleMessagePosX * HudCanvasScale * C.SizeX) + (((1.0 - HudCanvasScale) / 2.0) * C.SizeX);
	}
	else
	{
		XPos = (0.005 * HudCanvasScale * C.SizeX) + (((1.0 - HudCanvasScale) / 2.0) * C.SizeX);
	}

	C.Font = GetConsoleFont(C);
	C.DrawColor = LevelActionFontColor;

	C.TextSize ("A", XL, YL);

	YPos -= YL * MessageCount+1; // DP_LowerLeft
	YPos -= YL; // Room for typing prompt

	for( i=0; i<MessageCount; i++ )
	{
		if ( TextMessages[i].Text == "" )
			break;

		C.SetPos( XPos, YPos );
		C.DrawColor = TextMessages[i].TextColor;
		YYL = 0;
		XXL = 0;
		if( TextMessages[i].PRI!=None )
		{
			XL = ScrnScoreBoardClass.Static.DrawCountryNameSE(C,TextMessages[i].PRI,XPos,YPos);
			C.SetPos( XPos+XL, YPos );
		}
		if( SmileyMsgs.Length!=0 )
			DrawSmileyText(TextMessages[i].Text,C,,YYL);
		else C.DrawText(TextMessages[i].Text,false);
		YPos += (YL+YYL);
	}
}

exec function DebugCrosshair(bool bEnable)
{
    if ( Level.NetMode != NM_Standalone && (PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bOnlySpectator) )
        return;    
    
    bCrosshairShow = bEnable;
    bShowKFDebugXHair = bEnable;
}

// copy-pated to remove RODebugMode()  -- PooSH
simulated function DrawCrosshair (Canvas C)
{
	local float NormalScale;
	local int i, CurrentCrosshair;
	local float OldScale,OldW, CurrentCrosshairScale;
	local color CurrentCrosshairColor;
	local SpriteWidget CHtexture;

	if ( !bCrosshairShow || !bShowKFDebugXHair )
		return;

    // one more check to prevent hacks
    if ( PlayerOwner.Level.NetMode != NM_Standalone && (PlayerOwner.PlayerReplicationInfo == none || !PlayerOwner.PlayerReplicationInfo.bOnlySpectator) ) {
        bCrosshairShow = false;
        return;     
    }

	if ( (PawnOwner != None) && (PawnOwner.Weapon != None) && (PawnOwner.Weapon.CustomCrosshair >= 0) )
	{
		CurrentCrosshairColor = PawnOwner.Weapon.CustomCrosshairColor;
		CurrentCrosshair = PawnOwner.Weapon.CustomCrosshair;
		CurrentCrosshairScale = PawnOwner.Weapon.CustomCrosshairScale;
		if ( PawnOwner.Weapon.CustomCrosshairTextureName != "" )
		{
			if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
			{
				PawnOwner.Weapon.CustomCrosshairTexture = Texture(DynamicLoadObject(PawnOwner.Weapon.CustomCrosshairTextureName,class'Texture'));
				if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
				{
					log(PawnOwner.Weapon$" custom crosshair texture not found!");
					PawnOwner.Weapon.CustomCrosshairTextureName = "";
				}
			}
			CHTexture = Crosshairs[0];
			CHTexture.WidgetTexture = PawnOwner.Weapon.CustomCrosshairTexture;
		}
	}
	else
	{
		CurrentCrosshair = CrosshairStyle;
		CurrentCrosshairColor = CrosshairColor;
		CurrentCrosshairScale = CrosshairScale;
	}

	CurrentCrosshair = Clamp(CurrentCrosshair, 0, Crosshairs.Length - 1);

	NormalScale = Crosshairs[CurrentCrosshair].TextureScale;
	if ( CHTexture.WidgetTexture == None )
		CHTexture = Crosshairs[CurrentCrosshair];
	CHTexture.TextureScale *= CurrentCrosshairScale;

	for( i = 0; i < ArrayCount(CHTexture.Tints); i++ )
		CHTexture.Tints[i] = CurrentCrossHairColor;

	OldScale = HudScale;
	HudScale=1;
	OldW = C.ColorModulate.W;
	C.ColorModulate.W = 1;
	DrawSpriteWidget (C, CHTexture);
	C.ColorModulate.W = OldW;
	HudScale=OldScale;
	CHTexture.TextureScale = NormalScale;

	//DrawEnemyName(C);
}

exec function SpecHeaderSize(byte size)
{
    if ( size == 0 || size == 1) {
        SpecHeaderFont = 1 - size;
        SaveConfig();
    }
    else    
        PlayerOwner.ClientMessage("Header size must 0 (small) or 1 (big)");
}

defaultproperties
{
    MinMagCapacity=5
    LowAmmoPercent=0.250000
    texCowboy=Texture'ScrnTex.HUD.CowboyMode'
    CowboyTileY=0.010000
    CowboyTileWidth=0.250000
    bShowDamages=true
    DamagePopupFont=4
    DamagePopupFadeOutTime=3.000000
    bShowSpeed=true
    SpeedometerX=0.90
    SpeedometerY=0.00
    SpeedometerFont=5
     
    BlamedIcon=(WidgetTexture=Texture'ScrnTex.HUD.Crap64',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.500000,PosX=0.95,PosY=0.5,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    BlamedIconSize=32 
    BlameCountdown=120
    BlameDrawDistance=800
    
    SingleNadeIcon=(WidgetTexture=Texture'KillingFloor2HUD.HUD.Hud_M79',RenderStyle=STY_Alpha,TextureCoords=(X2=64,Y2=64),TextureScale=0.220000,PosX=0.781000,PosY=0.943000,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
    
    // used in ScrnBuyMenuSaleList. Brought here to allow user config
    TraderGroupColor=(R=128,G=128,B=128,A=255)
    TraderActiveGroupColor=(R=192,G=192,B=255,A=255)
    TraderSelectedGroupColor=(R=192,G=192,B=255,A=255)
    TraderPriceButtonColor=(R=160,G=160,B=160,A=255)
    TraderPriceButtonDisabledColor=(R=255,G=255,B=255,A=255)
    TraderPriceButtonSelectedColor=(R=255,G=128,B=160,A=255)  

    bDrawSpecDeaths=True
    
    strFollowing="FOLLOWING:"
    
    WeightDigits=(RenderStyle=STY_Alpha,TextureScale=0.300000,PosX=0.195000,PosY=0.942000,Tints[0]=(B=64,G=64,R=255,A=255),Tints[1]=(B=64,G=64,R=255,A=255))
}
