# Lovely-Scene
A love2D custom cutscene parser

**NOTE:** requires [Tserial](https://github.com/zhsso/Tserial.lua) for tables to be read properly within scene files.

# Breakdown
LovelyScene is a library made to help those who want an easier way to create 'cutscenes'. It's not exactly easy to describe what it is without really looking at what it does, but on a basic level it's a special file parser I wrote to enable easy cutscene creation. When used with my other library, [LovelyEvent](https://github.com/Schwegg/Lovely-Event), it can make cutscenes within your game easier to achieve and a lot less of a hasstle to write once it's set up.

* The 'language' of scene is very primitive, but gets the job done.
* It parses the `.lscene` file line-by-line and checks for indentations.
* quotation marks (`"`) are used to group strings together. Because of how the script parses through the file, it first breaks it into words, then breaks the line down into words. In order for it to recognize certain words as 'grouped' aka as a single variable (eg. `scene "example scene"`) you'll need to use quotation marks.

# Usage (Functions)
<br>

```Lua
LovelyScene:setSceneDirectory( path )
```
Used to set the scene directory which is used as the path to the given file when calling `loadScene`.
* `path` (string, by default is `scenes/`) - the path to the scenes folder, for if you decide the `scenes` folder within your project isn't where you want to store your scenes for whatever reason.
<br>

```Lua
LovelyScene:setActorSearchFunc( func )
```
Sets the function to be called when the parser encounters the `actor` keyword.
* `func` (function) - function called when `actor` keyword is found in parser.
<br>

```Lua
LovelyScene:newKeyword( keywordName, keywordFunction, breaksParse )
```
Adds a keyword that the parser will search for and run the given `keywordFunction` when found.
* `keywordName` (string) - name of keyword, searched for when parsing. (best practice is to keep the keyword as one word, otherwise use quotation marks to group them)
* `keywordFunction` (function) - function called when keyword is found.
  * `command` variable is broken down into `actor` (current actor, nil if none) and `vars` which is a table of the inputted variables/words after the keyword on the line.
* `breaksParse` (bool, false by default) - whether calling this keyword will prematurely end the current scene, eg. `break` or `goto`
<br>

```Lua
LovelyScene:loadScene( file, sceneID )
```
Use to run a scene, if no `sceneID` is given, will call `scene ""` by default.
* `file` (string) - file name within the path (from setSceneDirectory, or `scenes/` by default)
* `sceneID` (string) - ID/Name of scene within the given file
<br>

# Usage (Within Scene File)

## Comments:
exactly the same as lua comments:
```Lua
-- example comment
```

## Scene:
defined with the `scene` keyword, indentation doesn't matter. anything under the keyword is counted as part of *that* scene. So no, sub-scenes do not work.
```Lua
scene ""
-- if left blank with closed quotation marks, defines that scene as the 'default scene'
-- which is called by default if no sceneID is given when calling loadScene().
scene exampleScene
scene "ExampleScene"
```

## Actor:
Defined with the `actor` keyword. Any indented keywords after will be called within the context of the actor, eg. `Actor:function()`
```Lua
actor Player
  setDirection left
```
In this example, `setDirection left` is being called within the context of the Actor. Not all default keywords work with this (eg. `if`, `print`, etc.)

## Set:
Used to set variables, as the name implies, via the `set` keyword. eg.
```Lua
set varA += 1
set varB = right
set varC /= 10
```
  * Set can use `=`,`+=`,`-=`,`*=`,`/=` and `%=`
  * Set cannot set a variable equal to another variable. Unless I find a way to do so later down the road, you'll have to make do.

## If:
It's exactly what you'd think. It's set up in a way so it will execute anything after `if` as if it were a lua function. so:
```Lua
if exampleGlobalBoolean == true and getPlayer().direction == 'left'
  print only executes if true!
```
will find the global variable `exampleGlobalBoolean` and run `getPlayer()` and check if the `direction` of player is == to the string `left`.
**Note:** strings must use single quotation while within an if check, otherwise will return a global variable of the same name (or nil).

## Default Keywords:
* `goto` keyword will search for the given scene and will do as expected, jumping to that scene and stopping the currently running scene.
* `break` will stop the current scene, ending is if it were a loop.
* `print` works exactly the same as the lua equivalent, printing whatever is after the keyword (within the same line).
