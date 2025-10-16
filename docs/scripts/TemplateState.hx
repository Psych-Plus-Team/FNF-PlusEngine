/*
You need to rename this file to the state it will affect, the main one you need to create is TitleState.hx
Although you can also create from MainMenuState.hx

Like a state script, only onCreate, onUpdate and onDestroy are used, but there are differences:

*/

function onCreate()
{
    // This is called before super.create()
}

function onCreatePost()
{
    // This is called after super.create()
}

function onUpdate(elapsed)
{
    // This is called before super.update()
}

function onUpdatePost(elapsed)
{
    // This is called after super.update()
}

function onDestroy()
{
    // This is called before super.destroy()
}

function onDestroyPost()
{
    // This is called after super.destroy()
}   

// From here you can create your own functions and variables

/*
====================================
AVAILABLE HSCRIPT VARIABLES FOR CUSTOMSTATES
====================================

- Almost all states can be imported
- GameplayChangersSubstate
- Difficulty
- WeekData
- Discord
- RatioScaleMode
- Capabilities
- ModState
- MusicBeatState
- Highscore
- Song
- FlxAxes
- FlxTypedGroup
- FlxCamera
- FlxFlicker
- And more...

====================================
AVAILABLE VARIABLES FOR CUSTOMSTATES
====================================

1. stateName (String)
   - The name of the current state
   - Example: var name = stateName; // "TitleState"
   - Useful for: Knowing which state you're currently in

2. persistentUpdate (Bool)
   - Controls whether the state continues updating when another state is opened on top
   - Example: persistentUpdate = true; // The state will continue updating
   - Default: Scripts can control it individually
   - Useful for: Keeping animations or music active in overlapping states

3. persistentDraw (Bool)
   - Controls whether the state continues drawing when another state is opened on top
   - Example: persistentDraw = true; // The state will remain visible
   - Default: true
   - Useful for: Creating overlays or menus that show the previous state

====================================
SHARED VARIABLES SYSTEM
====================================
These functions allow you to share data between different custom ModStates:

4. setSharedVar(name, value)
   - Saves a variable that other states can read
   - Example: setSharedVar('playerScore', 1000);
   - Example: setSharedVar('playerName', 'Lenin');
   - Useful for: Passing data between custom states
   - IMPORTANT: Use prefixes to organize your mod's variables
   - Example: setSharedVar('mymod_score', 1000);

5. getSharedVar(name, ?defaultValue)
   - Gets a previously saved shared variable
   - Example: var score = getSharedVar('playerScore', 0);
   - If the variable doesn't exist, returns the defaultValue
   - Useful for: Retrieving data from previous states

6. hasSharedVar(name)
   - Checks if a shared variable exists
   - Example: if (hasSharedVar('playerScore')) { ... }
   - Returns: true if it exists, false if not
   - Useful for: Checking before getting a variable

7. removeSharedVar(name)
   - Removes a specific shared variable
   - Example: removeSharedVar('playerScore');
   - Returns: true if removed, false if it didn't exist
   - Useful for: Cleaning up data you no longer need

8. clearSharedVars()
   - Removes ALL shared variables from THIS script's scope
   - Example: clearSharedVars();
   - WARNING! This only clears during the function call, not globally
   - Useful for: Resetting data within your state

====================================
MEMORY MANAGEMENT & AUTOMATIC CLEANUP
====================================

⚠️ IMPORTANT: Understanding SharedVars Lifetime

SharedVars are STATIC and persist across the ENTIRE game session, but they are
automatically cleaned up in these situations:

1. AUTOMATIC CLEANUP ON MOD CHANGE:
   - When you switch between mods (enable/disable in Mods Menu)
   - All sharedVars are cleared automatically
   - This prevents memory leaks from disabled mods
   
2. AUTOMATIC CLEANUP ON MOD SWITCH:
   - When loading a ModState from a different mod
   - Previous mod's sharedVars are cleared
   - Only the current active mod's data persists

3. MANUAL CLEANUP:
   - Use clearSharedVars() in your state to clean data
   - Best practice: Call it in onCreate() of your first state
   - Example: 
     function onCreate() {
         clearSharedVars(); // Clean slate for your mod
         setSharedVar('mymod_initialized', true);
     }

BEST PRACTICES FOR SHAREDVARS:

✅ DO:
   - Use prefixes for your mod: 'mymod_variableName'
   - Clear data when exiting your mod's custom states
   - Use removeSharedVar() for specific cleanup
   - Check with hasSharedVar() before reading

❌ DON'T:
   - Store huge objects (use files instead)
   - Rely on data from disabled mods
   - Use generic names like 'score' or 'data'
   - Expect data to persist after mod is disabled

EXAMPLE - PROPER CLEANUP:

// First state of your mod
function onCreate() {
    clearSharedVars(); // Start fresh
    setSharedVar('mymod_stage', 'intro');
    setSharedVar('mymod_playerName', 'Player');
}

// Last state before exiting mod
function onDestroy() {
    // Clean up when leaving your mod
    clearSharedVars();
}

// Checking data from another state
function onCreate() {
    if (hasSharedVar('mymod_stage')) {
        var stage = getSharedVar('mymod_stage', 'intro');
        trace('Continuing from: ' + stage);
    } else {
        trace('Starting fresh!');
    }
}
    
====================================
PRACTICAL EXAMPLE - SCORE SYSTEM
======================================

// In TitleState.hx - First state
function onCreate() {
    clearSharedVars(); // Clean previous session data
    setSharedVar('mymod_difficulty', 'normal');
    setSharedVar('mymod_playerName', 'NewPlayer');
}

// In MainMenuState.hx - Second state
function onCreate() {
    // Data from TitleState is still available
    var dif = getSharedVar('mymod_difficulty', 'easy');
    var name = getSharedVar('mymod_playerName', 'Unknown');
    trace('Player: ' + name + ' | Difficulty: ' + dif);
}

// Switch to PlayState
function onUpdate(elapsed) {
    if (controls.ACCEPT) {
        setSharedVar('mymod_maxScore', 5000);
        nextState = new PlayState(); // Switch state
    }
}

// In ResultsState.hx - Final state
function onCreate() {
    var score = getSharedVar('mymod_maxScore', 0);
    var playerName = getSharedVar('mymod_playerName', 'Unknown');
    trace(playerName + ' scored: ' + score);
}

function onDestroy() {
    // Clean up when exiting your mod's flow
    clearSharedVars();
}

====================================
ADVANCED EXAMPLE - MOD DETECTION
======================================

// Check if coming from specific mod state
function onCreate() {
    var previousMod = getSharedVar('currentModDirectory', null);
    
    if (previousMod == null) {
        trace('First time entering custom states');
    } else if (previousMod != 'mymod') {
        trace('Switched from another mod, data was cleared');
    } else {
        trace('Continuing within same mod');
    }
    
    // Your mod's initialization
    if (!hasSharedVar('mymod_initialized')) {
        setSharedVar('mymod_initialized', true);
        setSharedVar('mymod_visits', 0);
    }
    
    var visits = getSharedVar('mymod_visits', 0);
    setSharedVar('mymod_visits', visits + 1);
}
====================================
HOW DO I SWITCH STATES?
====================================

Good question my favorite silly, what you have to do is simple

To switch between ModStates you have to do this:

- MusicBeatState.switchState(new ModState('StateName'));

The "State Name" is the name of the .hx file you created in /mods/yourmod/states/StateName.hx

To switch to a normal state you do this:

- MusicBeatState.switchState(new StateName());

This will normally switch to the engine state you want.

====================================
IMPORTANT NOTES
======================================

- Shared variables (sharedVars) are STATIC, they persist between all ModStates
- SharedVars are AUTOMATICALLY CLEARED when:
  * You change between different mods (enable/disable in Mods Menu)
  * You switch from one mod's ModState to another mod's ModState
  * This prevents memory leaks from disabled or inactive mods
- Use prefixes for your variables to avoid conflicts: 'mymod_variableName'
- Only use nextState to switch states, never FlxG.switchState directly
- The stateName is defined when creating the ModState: new ModState('StateName')
- Scripts are automatically loaded from: mods/yourmod/states/StateName.hx
- persistentUpdate and persistentDraw are useful for substates and overlapping menus
- Call clearSharedVars() in your first state's onCreate() for a clean start
- MEMORY SAFETY: Your mod's sharedVars won't affect other mods or leak memory
- If you disable a mod, its sharedVars are cleared automatically on next state load

====================================
FAQ - FREQUENTLY ASKED QUESTIONS
======================================

Q: What happens to sharedVars when I disable my mod?
A: They are automatically cleared the next time any ModState is loaded.
   This prevents memory leaks and ensures clean state.

Q: Can another mod read my mod's sharedVars?
A: Technically yes, but they're cleared when switching mods. Use prefixes
   like 'mymod_' to avoid accidental conflicts.

Q: Do sharedVars persist after closing the game?
A: NO. SharedVars only exist during the current game session. Use files
   (SaveData, FlxSave, or File.saveContent) for persistent data.

Q: How much data can I store in sharedVars?
A: Keep it lightweight (primitives, small objects). For large data like
   images or long arrays, use files instead.

Q: Will sharedVars slow down my mod?
A: No, it's a simple Map<String, Dynamic> lookup. Very fast.

Q: What's the difference between clearSharedVars() in script vs globally?
A: In scripts, it only clears during that function call. The engine also
   clears automatically when switching between different mods.

*/
