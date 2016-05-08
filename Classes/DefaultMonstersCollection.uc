// backup copy of KFMonstersCollection, because TWI screwing default values instead of creating class istance
class DefaultMonstersCollection extends KFMonstersCollection;

defaultproperties
{
     MonsterClasses(0)=(MClassName="KFChar.ZombieClot_STANDARD",Mid="A")
     MonsterClasses(1)=(MClassName="KFChar.ZombieCrawler_STANDARD",Mid="B")
     MonsterClasses(2)=(MClassName="KFChar.ZombieGoreFast_STANDARD",Mid="C")
     MonsterClasses(3)=(MClassName="KFChar.ZombieStalker_STANDARD",Mid="D")
     MonsterClasses(4)=(MClassName="KFChar.ZombieScrake_STANDARD",Mid="E")
     MonsterClasses(5)=(MClassName="KFChar.ZombieFleshpound_STANDARD",Mid="F")
     MonsterClasses(6)=(MClassName="KFChar.ZombieBloat_STANDARD",Mid="G")
     MonsterClasses(7)=(MClassName="KFChar.ZombieSiren_STANDARD",Mid="H")
     MonsterClasses(8)=(MClassName="KFChar.ZombieHusk_STANDARD",Mid="I")
     
     StandardMonsterClasses(0)=(MClassName="KFChar.ZombieClot_STANDARD",Mid="A")
     StandardMonsterClasses(1)=(MClassName="KFChar.ZombieCrawler_STANDARD",Mid="B")
     StandardMonsterClasses(2)=(MClassName="KFChar.ZombieGoreFast_STANDARD",Mid="C")
     StandardMonsterClasses(3)=(MClassName="KFChar.ZombieStalker_STANDARD",Mid="D")
     StandardMonsterClasses(4)=(MClassName="KFChar.ZombieScrake_STANDARD",Mid="E")
     StandardMonsterClasses(5)=(MClassName="KFChar.ZombieFleshpound_STANDARD",Mid="F")
     StandardMonsterClasses(6)=(MClassName="KFChar.ZombieBloat_STANDARD",Mid="G")
     StandardMonsterClasses(7)=(MClassName="KFChar.ZombieSiren_STANDARD",Mid="H")
     StandardMonsterClasses(8)=(MClassName="KFChar.ZombieHusk_STANDARD",Mid="I")
     
     ShortSpecialSquads(2)=(ZedClass=("KFChar.ZombieCrawler_STANDARD","KFChar.ZombieGorefast_STANDARD","KFChar.ZombieStalker_STANDARD","KFChar.ZombieScrake_STANDARD"),NumZeds=(2,2,1,1))
     ShortSpecialSquads(3)=(ZedClass=("KFChar.ZombieBloat_STANDARD","KFChar.ZombieSiren_STANDARD","KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1,2,1))
     NormalSpecialSquads(3)=(ZedClass=("KFChar.ZombieCrawler_STANDARD","KFChar.ZombieGorefast_STANDARD","KFChar.ZombieStalker_STANDARD","KFChar.ZombieScrake_STANDARD"),NumZeds=(2,2,1,1))
     NormalSpecialSquads(4)=(ZedClass=("KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1))
     NormalSpecialSquads(5)=(ZedClass=("KFChar.ZombieBloat_STANDARD","KFChar.ZombieSiren_STANDARD","KFChar.ZombieScrake_STANDARD","KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1,2,1,1))
     NormalSpecialSquads(6)=(ZedClass=("KFChar.ZombieBloat_STANDARD","KFChar.ZombieSiren_STANDARD","KFChar.ZombieScrake_STANDARD","KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1,2,1,2))
     LongSpecialSquads(4)=(ZedClass=("KFChar.ZombieCrawler_STANDARD","KFChar.ZombieGorefast_STANDARD","KFChar.ZombieStalker_STANDARD","KFChar.ZombieScrake_STANDARD"),NumZeds=(2,2,1,1))
     LongSpecialSquads(6)=(ZedClass=("KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1))
     LongSpecialSquads(7)=(ZedClass=("KFChar.ZombieBloat_STANDARD","KFChar.ZombieSiren_STANDARD","KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1,1,1))
     LongSpecialSquads(8)=(ZedClass=("KFChar.ZombieBloat_STANDARD","KFChar.ZombieSiren_STANDARD","KFChar.ZombieScrake_STANDARD","KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1,2,1,1))
     LongSpecialSquads(9)=(ZedClass=("KFChar.ZombieBloat_STANDARD","KFChar.ZombieSiren_STANDARD","KFChar.ZombieScrake_STANDARD","KFChar.ZombieFleshPound_STANDARD"),NumZeds=(1,2,1,2))

     FinalSquads(0)=(ZedClass=("KFChar.ZombieClot_STANDARD"),NumZeds=(4))
     FinalSquads(1)=(ZedClass=("KFChar.ZombieClot_STANDARD","KFChar.ZombieCrawler_STANDARD"),NumZeds=(3,1))
     FinalSquads(2)=(ZedClass=("KFChar.ZombieClot_STANDARD","KFChar.ZombieStalker_STANDARD","KFChar.ZombieCrawler_STANDARD"),NumZeds=(3,1,1))

     FallbackMonsterClass="KFChar.ZombieStalker_STANDARD"
     EndGameBossClass="KFChar.ZombieBoss_STANDARD"
}
