# love-with-js

A quick and easy way to connect Lua to Javascript in [LÖVE](https://love2d.org/) games that uses love.js.

This comes in handy in case you are trying to implement an SDK like [CrazyGames'](https://www.crazygames.com) or you want to connect the game to the webpage so it behaves a certain way when a button (outside the game) is pressed for example.

Unlike [Love.js-Api-Player](https://www.github.com/MrcSnm/Love.js-Api-Player), this method doesn't rely on `Console Wrapping` which makes it widely supported on most (if not all) websites and browsers.

## Installation

Export your LÖVE game to web with love.js (Unfortunately, this only works in the browser and not in the standalone builds since it runs JavaScript in the browser.)  

Replace your `love.js` next to your `index.html` with the modified version I created.  
(Tested with love 11.4 but should also work with any version.)

Copy `lua-server.js` next to your `index.html` file. 

Add the following line to your `<head>` tag at the top of the `index.html` file.

```html
    <script src="lua-server.js"></script>
```

Now, you should be able to use the library inside the game.


## Usage

Copy `js-server.lua` anywhere in your project where you can load it.

```lua
    --load the library
    local js = require "path.to.js-server"
```

### Running JavaScript code from Lua

There are two ways to run your JavaScript code from lua:  

#### 1. Directly using the `js.eval(code)` function.

Please note that this method relies on JavaScript's `eval()` function which may be considered a secuirty risk and thus it is blocked on some websites.

```lua
    --run a block of code in javascript directly.
    js.eval("alert('Hello from Lua!');")
```

#### 2. Using the `js.run(command, ...)` function.

This is the safest and recommended way to run your code.  
You can also use it to separate the game logic from the JavaScript logic. (e.g. writing the game once while implementing different SDKs in your `lua-server.js` file)

In lua, you can simply do:

```lua
    --runs the `foo` function with the arguments 1, 2, 3
    js.run("foo", 1, 2, 3)
```

Now, head to your `lua-server.js` and change the `runCommand()` function.  
`runCommand(cmd, args)` takes `cmd` which is the name of the command and `args` which is a list of the arguments (they are all strings by default).

```javascript
    function runCommand(cmd, args) {
        // You can use a switch statement to handle different commands.
        switch (cmd) {
            case "foo":
                // do something
                // args is a list of strings with the passed arguments
                console.log("First: " + args[0] + "\nSecond: " + args[1] + "\nThird: " + args[2])
                break

            case "bar":
                // do something else
                break

            default:
                break
        }
    }
```

### Running Lua code from Javascript 

You also have two available options here:

#### 1. Directly using the `run_lua(code)` function.

If you look down in the `lua-server.js` file you will see a pre-defined function for you to use anywhere in your JavaScript side.

```javascript
    // Runs a block of code in lua directly.
    run_lua("print('Hello from JavaScript!')")
```

Note that the player can also open the console and use this function to break or hack your game. You may prefer deleting it from the `lua-server.js` file.

#### 2. Using the `lua(command, ...)` function.

It's the recommended way.

Similar in spirit to `js.run()`, you can use it in JavaScript as follows:

```javascript
    // runs the `foo` function with the arguments 1, 2, 3
    lua("foo", 1, 2, 3)
```

Then inside your lua script, you need to define the function as follows:

```lua
    -- Binds a function to a specific command from JavaScript.
    js.set("foo", function(first, second, third){
        print(first .. ", " .. second .. ", " .. third)
    })
```

However, in order for this to work you need to call `js.update()` each frame.  
If `js.update()` causes any performance problem (which should not and did not happen as I was testing the game), consider only calling it manually when needed.

```lua
    function love.update(dt)
        js.update()
        ...
    end
```

### Returning values

Because of the way this is implemented, it is impossible to `return` anything in the same line. However, you can instead call a function with the desired return value you need as a response.

```javacript
    // JavaScript
    function runCommand(cmd, args) {
        switch (cmd) {
            case "get_leaderboard":
                leaderboard = sdk_leaderboard()

                // It will be called in the same order in the game.
                for (let player in leaderboard) {
                    lua("add_leaderboard_player", player.name, player.score);
                }
                // You can also convert the array to JSON then convert it back to a list in lua using 
                // another library like rxi/json.lua.
                
                break

            case "get_online_name":
                name = sdk_get_name(args[0])
                lua("set_name", name)
                break
            ...
        }
    }
```

```lua
    -- Lua
    js.set("get_id", function(){
        js.run("id", global.ID)
    })
```

Note that there will be a frame delay when recieving data from JavaScript if you are only calling `js.update()` in `love.update`. If that is a problem for you, you can also manually call `js.update()` after requesting the data.

### Passing arguments

Because of the way this is designed, anything passed is and will be converted automatically to a string. (because it relies on print and input to communicate with the game).  
Remember to convert between the data types after recieving the arguments.  
You can use any number of arguments you like.

To pass an array or an object, you should first convert them to JSON or any equivalent you like.

```javascript
    // Convert to JSON before sending data to the game
    let numbers = [1, 2, 3]
    lua("numbers", JSON.stringify(numbers));
    ...

    // Convert from JSON after recieving data from the game (assuming it's JSON)
    let numbers = JSON.parse(args[0]); 

```

To convert back and forth from JSON in lua, you can use the [rxi's json.lua](https://www.github.com/rxi/json.lua) library.

## How it works?

In a nutshell, all it does is that it captures the output and manipulates the input to the game by slightly modifying the `love.js` file.  
It checks if  the output starts with a specific suffix which is either "RUN_JS: " or "JS: " then it interprets the remaining string accordingly.  
To communicate back with lua, it modifies the response given to the input using Lua's `io.read()` function.  
A side effect to this is that you can no longer use `io.read()` to get the input from the browser using the `window.prompt()`. If you would like to still be able to use `window.prompt()`, you can add a function to your `runCommand()` function that uses `window.prompt()` then send back the input to the game.  

Since `js.update()` uses Lua's `io.read()`, it can in theory cause performance problems since it waits for the input (which should happen instantly). I had no performance problems myself, but if you run into any, you can manually call `js.update()` when needed instead of calling it from `love.update()`.


Here is what's changed in the `love.js` file in case some breaking change happens in the future. (`beautify` the file then go to around the line 1826).

```javascript
    ...
    default_tty_ops: {
        get_char: function (tty) {
        if (!tty.input.length) {
            // var result = null;
            // if (ENVIRONMENT_IS_NODE) {
            //   var BUFSIZE = 256;
            //   var buf = Buffer.alloc ? Buffer.alloc(BUFSIZE) : new Buffer(BUFSIZE);
            //   var bytesRead = 0;
            //   try {
            //     bytesRead = nodeFS.readSync(process.stdin.fd, buf, 0, BUFSIZE, null)
            //   } catch (e) {
            //     if (e.toString().indexOf("EOF") != -1) bytesRead = 0;
            //     else throw e
            //   }
            //   if (bytesRead > 0) {
            //     result = buf.slice(0, bytesRead).toString("utf-8")
            //   } else {
            //     result = null
            //   }
            // } else if (typeof window != "undefined" && typeof window.prompt == "function") {
            //   result = window.prompt("Input: ");
            //   if (result !== null) {
            //     result += "\n"
            //   }
            // } else if (typeof readline == "function") {
            //   result = readline();
            //   if (result !== null) {
            //     result += "\n"
            //   }
            // }

            result = queue.join("<<<")
            queue = [];
            
            if (!result) {
                return null
            } else {
                result += "\n"
            }

            tty.input = intArrayFromString(result, true)
        }
        return tty.input.shift()
        },
        put_char: function (tty, val) {
        if (val === null || val === 10) {
            //out(UTF8ArrayToString(tty.output, 0)
            )
            let str = UTF8ArrayToString(tty.output, 0);
            if (str.startsWith("JS: ")){
            let cmd = str.slice(4).split(">>>");
            runCommand(cmd[0], cmd.slice(1));
            } else if (str.startsWith("RUN_JS: ")) {
                eval(str.slice(8));
            }
            else {
                out(UTF8ArrayToString(tty.output, 0))
            }
            tty.output = []
        } else {
            if (val != 0) tty.output.push(val)
        }
        },
        flush: function (tty) {
        if (tty.output && tty.output.length > 0) {
            //out(UTF8ArrayToString(tty.output, 0))

            if (str.startsWith("JS: ")){
            let cmd = str.slice(4).split(">>>");
                runCommand(cmd[0], cmd.slice(1));
            } else if (str.startsWith("RUN_JS: ")) {
                eval(str.slice(8));
            }
            else {
                out(UTF8ArrayToString(tty.output, 0))
            }
            tty.output = []
        }
        }
    },
    ...
```
