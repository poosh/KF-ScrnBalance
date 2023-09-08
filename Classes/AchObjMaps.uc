// shorted class name - less bytes needs to send as custom stat
Class AchObjMaps extends ScrnObjMapAchievements;

#exec OBJ LOAD FILE=ScrnAch_T.utx

// The engine limits the size of a localized string to 4096.
// That's why we need to do the copy-paste crap below to bypass the limitaion.
var localized string DisplayName0;
var localized string DisplayName1;
var localized string DisplayName2;
var localized string DisplayName3;
var localized string DisplayName4;
var localized string DisplayName5;
var localized string DisplayName6;
var localized string DisplayName7;
var localized string DisplayName8;
var localized string DisplayName9;
var localized string DisplayName10;
var localized string DisplayName11;
var localized string DisplayName12;
var localized string DisplayName13;
var localized string DisplayName14;
var localized string DisplayName15;


simulated function SetDefaultAchievementData()
{
    AchDefs[0].DisplayName = DisplayName0;
    AchDefs[1].DisplayName = DisplayName1;
    AchDefs[2].DisplayName = DisplayName2;
    AchDefs[3].DisplayName = DisplayName3;
    AchDefs[4].DisplayName = DisplayName4;
    AchDefs[5].DisplayName = DisplayName5;
    AchDefs[6].DisplayName = DisplayName6;
    AchDefs[7].DisplayName = DisplayName7;
    AchDefs[8].DisplayName = DisplayName8;
    AchDefs[9].DisplayName = DisplayName9;
    AchDefs[10].DisplayName = DisplayName10;
    AchDefs[11].DisplayName = DisplayName11;
    AchDefs[12].DisplayName = DisplayName12;
    AchDefs[13].DisplayName = DisplayName13;
    AchDefs[14].DisplayName = DisplayName14;
    AchDefs[15].DisplayName = DisplayName15;

    super.SetDefaultAchievementData();
}


defaultproperties
{
    ProgressName="Objective Map Achievements"

    AchDefs(0)=(id="KFO-Steamland",DisplayName="Simplified Force Adhesion Afficianado",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_213')
    AchDefs(1)=(id="KFO-SteamlandHard",DisplayName="Oscillating Hydrogen Transition Achiever",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_214')
    AchDefs(2)=(id="KFO-SteamlandSui",DisplayName="Alpha Wave Osteooxidation Activator",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_215')
    AchDefs(3)=(id="KFO-SteamlandHoe",DisplayName="Tachyon Cytoneutralization Explorer",Description="Steamland",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_216')
    AchDefs(4)=(id="KFO-FrightYard",DisplayName="Fork Lift Operator",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_232')
    AchDefs(5)=(id="KFO-FrightYardHard",DisplayName="Truck Driver",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_233')
    AchDefs(6)=(id="KFO-FrightYardSui",DisplayName="Crane Operator",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_234')
    AchDefs(7)=(id="KFO-FrightYardHoe",DisplayName="Shipping Magnate",Description="Fright Yard",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_235')
    AchDefs(8)=(id="KFO-Transit",DisplayName="Day-trip",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_264')
    AchDefs(9)=(id="KFO-TransitHard",DisplayName="Long weekend",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_265')
    AchDefs(10)=(id="KFO-TransitSui",DisplayName="Serious vacation",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_266')
    AchDefs(11)=(id="KFO-TransitHoe",DisplayName="Moved to Paris!",Description="Transit",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_267')
    AchDefs(12)=(id="KFO-Foundry-SE",DisplayName="Billy Aldridge",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_44')
    AchDefs(13)=(id="KFO-Foundry-SEHard",DisplayName="Jessica Aldridge",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_45')
    AchDefs(14)=(id="KFO-Foundry-SESui",DisplayName="David Masterson",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_46')
    AchDefs(15)=(id="KFO-Foundry-SEHoe",DisplayName="Kevin Clamely",Description="Foundry",Icon=Texture'KillingFloor2HUD.Achievements.Achievement_70')

    DisplayName0="Simplified Force Adhesion Afficianado"
    DisplayName1="Oscillating Hydrogen Transition Achiever"
    DisplayName2="Alpha Wave Osteooxidation Activator"
    DisplayName3="Tachyon Cytoneutralization Explorer"
    DisplayName4="Fork Lift Operator"
    DisplayName5="Truck Driver"
    DisplayName6="Crane Operator"
    DisplayName7="Shipping Magnate"
    DisplayName8="Day-trip"
    DisplayName9="Long weekend"
    DisplayName10="Serious vacation"
    DisplayName11="Moved to Paris!"
    DisplayName12="Billy Aldridge"
    DisplayName13="Jessica Aldridge"
    DisplayName14="David Masterson"
    DisplayName15="Kevin Clamely"
}