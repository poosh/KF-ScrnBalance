// for ScrnStoryGameInfo. ScrnGameType uses ScrnGameLength.
class DefaultMonstersCollectionZedPack extends KFMonstersCollection;

defaultproperties
{
    MonsterClasses(0)=(MClassName="ScrnZedPack.Clot",Mid="A")
    MonsterClasses(1)=(MClassName="ScrnZedPack.Crawler",Mid="B")
    MonsterClasses(2)=(MClassName="ScrnZedPack.GoreFast",Mid="C")
    MonsterClasses(3)=(MClassName="ScrnZedPack.Stalker",Mid="D")
    MonsterClasses(4)=(MClassName="ScrnZedPack.Scrake",Mid="E")
    MonsterClasses(5)=(MClassName="ScrnZedPack.Fleshpound",Mid="F")
    MonsterClasses(6)=(MClassName="ScrnZedPack.Bloat",Mid="G")
    MonsterClasses(7)=(MClassName="ScrnZedPack.Siren",Mid="H")
    MonsterClasses(8)=(MClassName="ScrnZedPack.Husk",Mid="I")

    StandardMonsterClasses(0)=(MClassName="ScrnZedPack.Clot",Mid="A")
    StandardMonsterClasses(1)=(MClassName="ScrnZedPack.Crawler",Mid="B")
    StandardMonsterClasses(2)=(MClassName="ScrnZedPack.GoreFast",Mid="C")
    StandardMonsterClasses(3)=(MClassName="ScrnZedPack.Stalker",Mid="D")
    StandardMonsterClasses(4)=(MClassName="ScrnZedPack.Scrake",Mid="E")
    StandardMonsterClasses(5)=(MClassName="ScrnZedPack.Fleshpound",Mid="F")
    StandardMonsterClasses(6)=(MClassName="ScrnZedPack.Bloat",Mid="G")
    StandardMonsterClasses(7)=(MClassName="ScrnZedPack.Siren",Mid="H")
    StandardMonsterClasses(8)=(MClassName="ScrnZedPack.Husk",Mid="I")

    ShortSpecialSquads(2)=(ZedClass=("ScrnZedPack.Crawler","ScrnZedPack.Gorefast","ScrnZedPack.Stalker","ScrnZedPack.Scrake"),NumZeds=(2,2,1,1))
    ShortSpecialSquads(3)=(ZedClass=("ScrnZedPack.Bloat","ScrnZedPack.Siren","ScrnZedPack.FleshPound"),NumZeds=(1,2,1))
    NormalSpecialSquads(3)=(ZedClass=("ScrnZedPack.Crawler","ScrnZedPack.Gorefast","ScrnZedPack.Stalker","ScrnZedPack.Scrake"),NumZeds=(2,2,1,1))
    NormalSpecialSquads(4)=(ZedClass=("ScrnZedPack.FleshPound"),NumZeds=(1))
    NormalSpecialSquads(5)=(ZedClass=("ScrnZedPack.Bloat","ScrnZedPack.Siren","ScrnZedPack.Scrake","ScrnZedPack.FleshPound"),NumZeds=(1,2,1,1))
    NormalSpecialSquads(6)=(ZedClass=("ScrnZedPack.Bloat","ScrnZedPack.Siren","ScrnZedPack.Scrake","ScrnZedPack.FleshPound"),NumZeds=(1,2,1,2))
    LongSpecialSquads(4)=(ZedClass=("ScrnZedPack.Crawler","ScrnZedPack.Gorefast","ScrnZedPack.Stalker","ScrnZedPack.Scrake"),NumZeds=(2,2,1,1))
    LongSpecialSquads(6)=(ZedClass=("ScrnZedPack.FleshPound"),NumZeds=(1))
    LongSpecialSquads(7)=(ZedClass=("ScrnZedPack.Bloat","ScrnZedPack.Siren","ScrnZedPack.FleshPound"),NumZeds=(1,1,1))
    LongSpecialSquads(8)=(ZedClass=("ScrnZedPack.Bloat","ScrnZedPack.Siren","ScrnZedPack.Scrake","ScrnZedPack.FleshPound"),NumZeds=(1,2,1,1))
    LongSpecialSquads(9)=(ZedClass=("ScrnZedPack.Bloat","ScrnZedPack.Siren","ScrnZedPack.Scrake","ScrnZedPack.FleshPound"),NumZeds=(1,2,1,2))

    FinalSquads(0)=(ZedClass=("ScrnZedPack.Clot"),NumZeds=(4))
    FinalSquads(1)=(ZedClass=("ScrnZedPack.Clot","ScrnZedPack.Crawler"),NumZeds=(3,1))
    FinalSquads(2)=(ZedClass=("ScrnZedPack.Clot","ScrnZedPack.Stalker","ScrnZedPack.Crawler"),NumZeds=(3,1,1))

    FallbackMonsterClass="ScrnZedPack.Stalker"
    EndGameBossClass="ScrnZedPack.HardPat"
}