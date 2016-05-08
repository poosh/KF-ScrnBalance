class StringReplicationInfo extends ReplicationInfo;

const MaxSize = 255;

var String Str;
var StringReplicationInfo Next;

replication 
{
	reliable if ( bNetDirty && Role == ROLE_Authority )
		Str, Next;
}

simulated function SetString(string value)
{
	ClearString();
	
	if ( len(value) < MaxSize )
		Str = value;
	else {
		Str = Left(value, MaxSize);
		Next = spawn(self.class, self);
		Next.SetString(Right(value, len(value) - MaxSize));
	}
}

simulated function string GetString()
{
	if ( Next == none )
		return Str;
		
	return Str $ Next.GetString();
}

simulated function ClearString()
{
	Str = "";
	if ( Next != none ) {
		Next.ClearString();
		Next.Destroy();
		Next = none;
	}
}

defaultproperties
{
}
