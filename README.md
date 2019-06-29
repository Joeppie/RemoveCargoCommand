# RemoveCargoCommand


A command to remove cargo without needing to dump it. This can help avoid lag on servers.
By giving a small bonus to standing, there may be some motivation for players to use the command to get rid of cargo they'd otherwise haul along or indeed dump.


## Usage examples
* `remove all` quickly removes all cargo.
*  `remove 10 ore` - removes 10 ore, if you have the "Ore" good, it is removed, if you only have "Iron Ore", this is removed. If you have both, nothing is removed as it would be ambiguous.
* `remove stolen` removes all stolen cargo.
* `remove dangerous` removes all dangerous cargo.
* `remove stolen` removes all illegal cargo.
* `remove dangerous stolen illegal 200 vehicle 5000 plankton` removes all dangerous, stolen and illegal goods, and then removes 200 Vehicles and 5000 Plankton.

values to remove in excess of the available cargo result in the complete removal of said cargo. 

# Installation

Installation only needs to occur on the server, clients do not need to have any code installed.

1. Extract/copy remove.lua to Avorion/data/scripts/commands (next to e.g. say.lua)
2. Add an entry to admins.xml so that the normal users i.e. `defaultAuthorizationGroup` are authorized to the command:


    <administration>
        <defaultAuthorizationGroup>
            <commands>
                <command name="help"/>
                <command name="invite"/>
        <command name="remove"/> <!-- Add this line, when the server is NOT running, otherwise it overwrites it-->
         ..other commands..
                <command name="whisper"/>
                </commands>
            </defaultAuthorizationGroup>


# License

This code, in so far not itself a derivative of Avorion code/Boxelware owned property, should be considered to be licensed under GNU affero GPL; please share improvements you make when you employ these on a publicly available server. 

