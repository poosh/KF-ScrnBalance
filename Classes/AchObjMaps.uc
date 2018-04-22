// shorted class name - less bytes needs to send as custom stat
Class AchObjMaps extends ScrnObjMapAchievements;

#exec OBJ LOAD FILE=ScrnAch_T.utx

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
}