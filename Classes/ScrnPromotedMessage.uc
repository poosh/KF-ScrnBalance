class ScrnPromotedMessage extends KFVetEarnedMessageSR
    abstract;

var Sound PromotedSnd;
var String PromotedSndRef;
var String PromotedSndRefDef;

static function PreloadAssets()
{
    default.PromotedSnd = sound(DynamicLoadObject(default.PromotedSndRef, class'Sound', true));
    if ( default.PromotedSnd == none )
        default.PromotedSnd = sound(DynamicLoadObject(default.PromotedSndRefDef, class'Sound', true));
}

static function UnloadAssets()
{
    default.PromotedSnd = none;
}


static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    if ( default.PromotedSnd == none )
        PreloadAssets();
    //log("PromotedSnd="$default.PromotedSnd, 'ScrnBalance');
    if ( default.PromotedSnd != none ) {
        P.ClientPlaySound(default.PromotedSnd,true,2.f,SLOT_Talk);
        P.ClientPlaySound(default.PromotedSnd,true,2.f,SLOT_Interface);
    }

    if( SRHUDKillingFloor(P.myHUD)!=None && KFPlayerReplicationInfo(P.PlayerReplicationInfo)!=None
        && OptionalObject!=None && KFPlayerReplicationInfo(P.PlayerReplicationInfo).ClientVeteranSkill==OptionalObject )
    {
        // Temporarly fill the bar.
        SRHUDKillingFloor(P.myHUD).LevelProgressBar = 1.f;
        SRHUDKillingFloor(P.myHUD).NextLevelTimer = P.Level.TimeSeconds+1.f;
    }
    default.DrawColor = class'ScrnHUD'.static.PerkColor(Switch);
    Super(CriticalEventPlus).ClientReceive(P,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

defaultproperties
{
    EarnedString="You have been promoted to %v level %l!"
    //PromotedSnd=Sound'ScrnSnd.Promoted'
    PromotedSndRef="ScrnSnd.Promoted"
    PromotedSndRefDef="KF_InterfaceSnd.Perks.PerkAchieved"
}
