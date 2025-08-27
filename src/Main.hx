package;

import sys.io.File;
import haxe.crypto.Sha1;
import sys.FileSystem;
import haxe.io.Path;

using StringTools;

class Main {
    static function main() {
        var srcPath = Path.normalize(Sys.getCwd() + "/patches/std");
        var dstPaths = Macros.getStdPaths();

        Sys.println("");
        var dryRun = false;
        for (dstPath in dstPaths) {
            startPatch(srcPath, dstPath, dryRun);
        }
    }

    private static function startPatch(srcPath:String, dstPath:String, dryRun:Bool) {
        var srcPath = Path.normalize(srcPath);
        var dstPath = Path.normalize(dstPath);
        Sys.println('patching haxe ${srcPath} => ${dstPath}');
        patchFolder(srcPath, dstPath, srcPath, dstPath, dryRun);
    }

    private static function patchFolder(srcPath:String, dstPath:String, srcRoot:String, dstRoot:String, dryRun:Bool) {
        var srcContents = FileSystem.readDirectory(srcPath);
        for (srcItem in srcContents) {
            var srcFullPath = Path.normalize(srcPath + "/" + srcItem);
            var dstFullPath = Path.normalize(dstPath + "/" + srcItem);
            if (!FileSystem.exists(srcFullPath) || !FileSystem.exists(dstFullPath)) {
                continue;
            }
            if (FileSystem.isDirectory(srcFullPath)) {
                patchFolder(srcFullPath, dstFullPath, srcRoot, dstRoot, dryRun);
            } else {
                var srcRelativePath = srcFullPath.replace(srcRoot, "");
                var dstRelativePath = dstFullPath.replace(dstRoot, "");
                var dstCheckSum = Sha1.encode(File.getContent(dstFullPath));
                var dstBackupFilename = Path.normalize(dstPath + "/" + srcItem + "_" + dstCheckSum + ".backup");
                Sys.println('  - ${srcRelativePath} => ${dstRelativePath} (checksum: ${dstCheckSum})');
                if (!dryRun) {
                    File.copy(dstFullPath, dstBackupFilename);
                    File.copy(srcFullPath, dstFullPath);
                }
            }
        }
    }
}