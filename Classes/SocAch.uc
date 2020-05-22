Class SocAch extends ScrnAchievements;

#exec OBJ LOAD FILE=ScrnAch_T.utx

defaultproperties
{
    ProgressName="Social Isolation Achievements"
    DefaultAchGroup="SocIso"
    GroupInfo(1)=(Group="SocIso",Caption="Social Isolation")

    AchDefs(0)=(id="DoubleOutbreak",DisplayName="Double Outbreak",Description="Survive the Virus outbreak during the Zed outbreak. Win %c games in Social Isolation.",Icon=Texture'ScrnAch_T.SocIso.DoubleOutbreak',MaxProgress=15,DataSize=4)
    AchDefs(1)=(id="TripleInvasion",DisplayName="Triple Invasion",Description="Zeds + Demons + Virus. Survive all of that in a single Hell on Earth game.",Icon=Texture'ScrnAch_T.SocIso.TripleInvasion',MaxProgress=1,DataSize=1)
    AchDefs(2)=(id="SelfIsolation",DisplayName="Self-Isolation",Description="Do not give a single chance for the Virus to spread. Keep distance for the entire game!",Icon=Texture'ScrnAch_T.SocIso.SelfIsolation',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(3)=(id="TW_Isolation",DisplayName="TeamWork: Proper Distancing",Description="Survive the 3+player game without spreading the Virus",Icon=Texture'ScrnAch_T.SocIso.TW_Isolation',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(4)=(id="Asymptomatic",DisplayName="Asymptomatic",Description="You had no symptoms during the game despite being infected",Icon=Texture'ScrnAch_T.SocIso.Asymptomatic',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(5)=(id="CovidiotS",DisplayName="Covidiot, Social",Description="Spread the Virus to at least 3 players in a single game",Icon=Texture'ScrnAch_T.SocIso.Noob',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(6)=(id="CovidiotG",DisplayName="Covidiot, Greedy",Description="Buy 1000 rolls of toilet paper",Icon=Texture'ScrnAch_T.SocIso.TP_Pile',MaxProgress=1000,DataSize=10)
    AchDefs(7)=(id="CovidiotD",DisplayName="Covidiot, Dumb",Description="Get infected despite having 100 rolls of TP in your inventory",Icon=Texture'ScrnAch_T.SocIso.TP_Virus',MaxProgress=1,DataSize=1,bForceShow=True)
    AchDefs(8)=(id="CovidiotParty",DisplayName="Covidiot Party",Description="All players in the team got infected (3+p)",Icon=Texture'ScrnAch_T.SocIso.CovidiotParty',MaxProgress=1,DataSize=1,bForceShow=True)
}
