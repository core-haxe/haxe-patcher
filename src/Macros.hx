package;

import haxe.macro.Compiler;

class Macros {
    public static macro function getStdPaths() {
        var paths = Compiler.getConfiguration().stdPath;
        return macro $v{paths};
    }
}