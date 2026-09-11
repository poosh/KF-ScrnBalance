# Function Call Replication  on KF1 (UE2.5 Engine)
Function call replication (a.k.a. RPC) is supported *only* between the server and the player who ows the actor (`bNetOwner=true`). Function calls are not replicated to other clients (who have `bNetOwner=false`). A good example is human pawn. You can use RPC between the server and the player who controls the pawn, but those are not replicated to other clients, where you can replicate only properties (and then process them in `PostNetReceive`, `Tick`, `Timer`, etc.).

`PlayerController` exists only on the the server and owning player - and that's the only controller the client has.

An RPC is executed *only* on the remote side if such exists, otherwise locally. The "otherwise" part is interesting, as it applies for Solo games (`Level.NetMode == NM_Standalone`) and Listen servers (actors that are owned by the listening players).

Here is a test code from `ScrnPlayerController`:
```
replication
{
    // replicate from client to server
    reliable if ( Role < ROLE_Authority )
        ServerRep;

    // replicate from server to client
    reliable if ( Role == ROLE_Authority )
        ClientRep;
}

function ServerRep(string val)
{
    log("ServerRep << " $ val);
    if (val == "exec") {
        ClientRep("server");
    }
}

function ClientRep(string val)
{
    log("ClientRep << " $ val);
    if (val == "exec") {
        ServerRep("client");
    }
}

exec function TestRep()
{
    log(">>TestRep");
    ServerRep("exec");
    ClientRep("exec");
    log("<<TestRep");
}
```

After entering `TestRep` in console, the exec function calls both server and client function. A string argument is used to avoid recursion and distinguish remote from local calls. Here are the results on different net modes:
```
NM_Standalone:
ScriptLog: >>TestRep
ScriptLog: ServerRep << exec
ScriptLog: ClientRep << server
ScriptLog: ClientRep << exec
ScriptLog: ServerRep << client
ScriptLog: <<TestRep

NM_ListenServer (executed on local PlayerController):
ScriptLog: >>TestRep
ScriptLog: ServerRep << exec
ScriptLog: ClientRep << server
ScriptLog: ClientRep << exec
ScriptLog: ServerRep << client
ScriptLog: <<TestRep

NM_ListenServer (executed on remote client):
ScriptLog: ServerRep << exec
ScriptLog: ServerRep << client


NM_DedicatedServer:
ScriptLog: ServerRep << exec
ScriptLog: ServerRep << client

NM_Client:
ScriptLog: >>TestRep
ScriptLog: ClientRep << exec
ScriptLog: <<TestRep
ScriptLog: ClientRep << server
```

NM_Standalone and executes both server and client functions. NM_DedicatedServer executes only server function while NM_Client - only client. NM_ListenServer behaves as NM_Standalone for locally owned actors (local player controller, pawn, etc.) but as NM_DedicatedServer - for remotely owned actors.

## Simulated
Note `simulated` keyword is not used for `ClientRep` function. It is because the PlayerController.Role on the client side is `ROLE_AutonomousProxy` - which can execute non-simulated functions. Moreover, marking functions as simulated inside player controller class is useless. "Simulated" has nothing to do with function replication. It only allows function execution when `Role=ROLE_SimulatedProxy`.
