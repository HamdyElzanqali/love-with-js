// The queue of lua actions to execute inside the game.
// You should not override this variable as it's used inside the new love.js file.
var queue = []

// To directly run javascript code through the eval function, you can just use
//      js.eval("console.log('Hello, World!')")
// Please note that eval might be considered and a security risk by some websites,
// so use the other way around with js.run() instead.


// Change this to fit your needs.
// Triggered by js.run("command", "first argument", "2", ...)
// All arguments will be strings, so you will have to convert them to the correct type yourself.
function runCommand(cmd, args) {

    // You can use a switch statement to handle different commands.
    switch (cmd) {
        case "foo":
            // do stuff
            // The first argument is args[0], second is args[1], etc.
            // Don't forget to use "break" at the end of each case.
            break

        case "bar":
            // do other stuff
            break

        default:
            break
    }

}

// Use run_lua("print('Hello, World!')") to directly execute lua code in the game.
// Note that you can't directly get the return value of the executed code.
// To get the return value, you will have to execute a function with js.run() that returns the value within the game.
// You may want to remove this function since it can be used to easily 'hack' the game.
function run_lua(cmd) {
    queue.push("RUN_LUA: " + cmd)
}

// Use lua() to execute pre-defined functions in the game without relaying on "load" or "loadstring"
// To set these functions, use: 
//          js.set("name", function(args)
//              -- do stuff
//          end)
// You can't directly get the return value of the executed function.
function lua(cmd, ...args) {
    queue.push("LUA: " + cmd + ">>>" + args.join(">>>"))
}