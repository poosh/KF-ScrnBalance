class ScrnSeekerSixMultiRocket extends ScrnSeekerSixRocket;

var byte FlockIndex;
var ScrnSeekerSixMultiRocket Flock[6];

var(Flocking) float	FlockRadius;
var(Flocking) float	FlockStiffness;
var(Flocking) float FlockMaxForce;
var(Flocking) float	FlockCurlForce;
var bool bCurl;

replication
{
    reliable if (bNetInitial && Role == ROLE_Authority)
        FlockIndex, bCurl;
}

simulated function PostNetBeginPlay()
{
    local ScrnSeekerSixMultiRocket R;
    local int i, p, q;
    local Array<ScrnSeekerSixMultiRocket> Rockets;

    Super.PostNetBeginPlay();

    if (FlockIndex != 0) {
        SetTimer(0.1, true);

        // look for other rockets and set thier flock values
        if (Flock[1] == none) {
            Rockets[0] = self;
            i = 1;

            ForEach DynamicActors(class'ScrnSeekerSixMultiRocket', R) {
                if (R.FlockIndex == FlockIndex) {
                    if (R == Self)
                        continue;
                    Rockets[i] = R;
                    if (++i == 6)
                        break;
                }
            }

            for (p = 0; p < Rockets.Length; ++p) {
                if (Rockets[p] == none)
                    continue;

                i = 0;
                for (q = 0; q < Rockets.Length; ++q) {
                    if (p != q && Rockets[q] != none) {
                        Rockets[p].Flock[i] = Rockets[q];
                        i++;
                    }
                }
            }
        }
    }
}

simulated function Timer()
{
    local vector ForceDir, CurlDir;
    local float ForceMag;
    local int i;

    super.Timer();
    if (bHidden)
        return;

    Velocity = Default.Speed * Normal(Dir * 0.5 * Default.Speed + Velocity);

    // Work out force between flock to add madness
    for(i = 0; i < 6; ++i) {
        if (Flock[i] == none)
            continue;

        // Attract if distance between rockets is over 2*FlockRadius, repulse if below.
        ForceDir = Flock[i].Location - Location;
        ForceMag = FlockStiffness * ( (2 * FlockRadius) - VSize(ForceDir) );
        Acceleration = Normal(ForceDir) * Min(ForceMag, FlockMaxForce);

        // Vector 'curl'
        CurlDir = Flock[i].Velocity Cross ForceDir;
        if ( bCurl == Flock[i].bCurl )
            Acceleration += Normal(CurlDir) * FlockCurlForce;
        else
            Acceleration -= Normal(CurlDir) * FlockCurlForce;
    }
}


defaultproperties
{
    FlockRadius=12
    FlockStiffness=-100
    FlockMaxForce=600
    FlockCurlForce=450
}
