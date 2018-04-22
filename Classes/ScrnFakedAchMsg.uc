class ScrnFakedAchMsg extends ScrnAchievementEarnedMsg
    abstract;
    
struct FakedAchData
{
    var texture Icon;
    var string Title, Text;
};    
var array<FakedAchData> Achievements; 


static function RenderComplexMessage(
        Canvas C,
        out float XL,
        out float YL,
        optional String MessageString,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject // must be ScrnAchievementInfo
        )
{
    local float X,Y, MaxWidth, MaxHeight, TextX, TextY, IconY;
    local float TextWidth, TextHeight;
    local float OrgX, ClipX; //dunno if it should be restored, but just in case
    local byte Style;

    // don't draw a message if it is fully transparent
    if ( c.DrawColor.A < 10 )
        return;
        
    // log("RenderComplexMessage: "
        // @ "RelatedPRI_1="$RelatedPRI_1
        // @ "OptionalObject="$OptionalObject
        // , 'ScrnBalance');
        

    ClipX = c.ClipX;
    OrgX = c.OrgX;
    Style = C.Style;

    //test max width 
    C.Font = class'ScrnBalanceSrv.ScrnHUD'.static.LoadFontStatic(6);
    C.StrLen( default.Achievements[Switch].Title, TextWidth, TextHeight);
    
    MaxWidth = max(256, TextWidth + 104);
    MaxHeight = 120; 

    //X = C.CurX;
    X = (c.ClipX - MaxWidth)*0.5; 
    Y = C.ClipY - MaxHeight;

    //background
    C.SetPos(X, Y);
    C.DrawTileStretched(default.BackGround, MaxWidth, MaxHeight);
    
    c.OrgX = X;
    c.ClipX = MaxWidth - 8;

    // achievement earnied title
    MessageString = default.EarnedString;

    C.Font = class'ScrnBalanceSrv.ScrnHUD'.static.LoadFontStatic(7);
    C.SetDrawColor(127, 127, 127, c.DrawColor.A);
    C.StrLen(MessageString, TextWidth, TextHeight);
    C.SetPos((MaxWidth - TextWidth)/2, Y + 7);
    C.DrawTextClipped(MessageString);
    
    IconY = Y + 40;
    TextX = 88;
    TextY = IconY;
    
    // ICON
    C.SetDrawColor(255, 255, 255, c.DrawColor.A);
    C.Style = ERenderStyle.STY_Alpha;
    C.SetPos(16, TextY); //top align with the achievement name
    C.DrawIcon(default.Achievements[Switch].Icon, 1.0);
    C.Style = Style;
    
    
    c.OrgX += TextX;
    c.ClipX -= TextX;
    
    // achievement name
    C.SetPos(0, TextY);
    C.SetDrawColor(50, 192, 50, c.DrawColor.A);
    C.Font =class'ScrnBalanceSrv.ScrnHUD'.static.LoadFontStatic(6);
    C.StrLen(default.Achievements[Switch].Title, TextWidth, TextHeight);
    C.DrawTextClipped(default.Achievements[Switch].Title);
    
    
    //description
    C.SetDrawColor(192, 192, 192, c.DrawColor.A);
    C.SetPos(0, TextY + TextHeight*1.1);
    C.Font = class'ScrnBalanceSrv.ScrnHUD'.static.LoadFontStatic(8);
    //to do set positions
    C.DrawText(default.Achievements[Switch].Text);
    
    //restore original values
    c.OrgX = OrgX; 
    c.ClipX = ClipX; 
    C.Style = Style;
}

defaultproperties
{
    Achievements(0)=(Icon=texture'ScrnAch_T.Achievements.Baron',Title="Blame Baron",Text="You died? No ammo? You're lagging? Your game crashed? Blame Baron!")
    Achievements(1)=(Icon=texture'ScrnAch_T.Achievements.SellCrap',Title="Sell THIS!",Text="Begging for money too much? Your teammates made you a present. Maybe try to sell it.")
    Achievements(2)=(Icon=texture'KillingFloorHUD.Achievements.Achievement_27',Title="Enjoy Your Luxury Funeral",Text="Didn't shared money? Now you can afford a luxury funeral.")
    Achievements(3)=(Icon=texture'ScrnAch_T.Achievements.BlameTWI',Title="Blame Tripwire",Text="Broken mods? New bugs? Ruined balance? Milked players? Blame Tripwire!")
}