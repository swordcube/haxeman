package;

import utils.SemanticVersion;
import haxe.io.Input;
import sys.io.Process;
import sys.io.File;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.thread.Thread;

import github.GitHubRelease;
import github.GitHubAsset;

using StringTools;

class Commands {
    static inline var REG_HKLM_ENVIRONMENT = 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment';

    public static function help(args:Array<String>):Void {
        var buffer:StringBuf = new StringBuf();
        buffer.add('\n--== [ Commands ] ==--\n\n');
        
        for(command in Main.commands)
            buffer.add('${command.name} - ${command.description}\n');
        
        buffer.add('\n--==================--\n');
        Sys.println(buffer.toString());
    }

    public static function install(args:Array<String>):Void {
        var version:String = args[0];
        if(version == null || version.length == 0) {
            Sys.println('No version specified to install!');
            return;
        }
        version = version.trim();

        var force:Bool = args.contains("--force");
        if(version == "latest")
            Sys.println('Installing latest Haxe version ${(force) ? '[FORCED]' : ''}...');
        else
            Sys.println('Installing Haxe ${version} ${(force) ? '[FORCED]' : ''}...');

        Sys.println('\nPlease wait, this may take a minute!');

        var home:String = Sys.getEnv((Sys.systemName() == "Windows") ? "UserProfile" : "HOME");
        var internalDir:String = Path.join([home, ".haxeman"]);

        // Create .haxeman folder if non-existent
        if(!FileSystem.exists(internalDir)) {
            trace('${internalDir} non-existent, creating...');
            FileSystem.createDirectory(internalDir);
            FileSystem.createDirectory(Path.join([internalDir, "versions"]));
        }

        // Cancel if selected version is already installed
        var downloadDir:String = Path.join([home, "Downloads"]);

        // Download and unzip the new version
        // trace("DEBUG: Downloading zip");

        var content:Dynamic = Json.parse(HttpUtil.requestText('https://api.github.com/repos/HaxeFoundation/haxe/releases'));
        var success:Bool = true;
        
        if(!(content is Array))
            success = false;
        else {
            var releases:Array<GitHubRelease> = content;
            var platformEnding:String = switch(Sys.systemName()) {
                case "Mac":     "osx.tar.gz";
                case "Linux":   "linux64.tar.gz"; 
                default:        "win.zip";
            }
            var release:GitHubRelease = null;
            var assetUrl:String = null;

            if(version == "latest") {
                version = releases[0].tag_name;
                release = releases[0];
            } else {
                for(r in releases) {
                    if(r.tag_name == version) {
                        release = r;
                        break;
                    }
                }
            }
            for(asset in release.assets) {
                if(asset.browser_download_url.endsWith('-${platformEnding}')) {
                    assetUrl = asset.browser_download_url;
                    break;
                }
            }

            var versionDir:String = Path.join([internalDir, "versions", version]);
            if(FileSystem.exists(versionDir)) {
                if(force)
                    FileUtil.deleteDirectory(versionDir);
                else {
                    Sys.println('Haxe ${version} is already installed, use --force to force a re-install.');
                    return;
                }
            }
            // If the version isn't already installed, or
            // we forced a re-install, install this version
            FileSystem.createDirectory(versionDir);

            // trace('DEBUG: Downloading ${assetUrl}');

            final zipName:String = 'HX_${version}.zip';
            final downloadedZip:String = Path.join([downloadDir, zipName]);
            
            final bytes = HttpUtil.requestBytes(assetUrl);
            // trace('DEBUG: Downloading ${zipName} to ${downloadedZip}');

            final output = File.write(downloadedZip, true);
            output.write(bytes);
            output.close();

            final haxemanLoc:String = Path.join([internalDir, zipName]);
            // trace('DEBUG: Extracting ${downloadedZip} to ${haxemanLoc}');

            // Delete existing haxeman copy
            if(FileSystem.exists(haxemanLoc))
                FileSystem.deleteFile(haxemanLoc);

            // Move downloaded zip to .haxeman folder
            FileSystem.rename(downloadedZip, haxemanLoc);

            // Extract the zip
            FileUtil.unzipFile(haxemanLoc, versionDir, "../");

            // Delete the zip
            FileSystem.deleteFile(haxemanLoc);
        }

        // Install finished :D
        // ...or failed :(
        if(success)
            Sys.println('Haxe ${version} successfully installed!\nRun "haxeman use ${version}" to use this version.');
        else    
            Sys.println('Haxe ${version} failed to install :(');
    }

    public static function uninstall(args:Array<String>):Void {
        var version:String = args[0];
        if(version == null || version.length == 0) {
            Sys.println('No version specified to install!');
            return;
        }
        version = version.trim();
            
        var home:String = Sys.getEnv((Sys.systemName() == "Windows") ? "UserProfile" : "HOME");
        var internalDir:String = Path.join([home, ".haxeman"]);
        var versionDir:String = Path.join([internalDir, "versions", version]);
        
        var currentVerFile:String = Path.join([internalDir, ".current"]);
        var curVersion:String = (FileSystem.exists(currentVerFile)) ? File.getContent(currentVerFile) : null;

        if(curVersion == version)
            FileSystem.deleteFile(currentVerFile);

        if(!FileSystem.exists(versionDir)) {
            Sys.println('Haxe ${version} is not installed!');
            return;
        }
        FileUtil.deleteDirectory(versionDir);
        Sys.println('Haxe ${version} successfully uninstaled!');
    }

    public static function use(args:Array<String>):Void {
        // Sys.print('This command will fail if not ran as admin!\nEnter "YES" to continue:');

        // TODO: make this "Are we admin?" check work on macOS and Linux
        final isNotAdmin:Int = Sys.command('net.exe session 1>NUL 2>NUL || (Exit /b 1)');
        if(isNotAdmin == 1) {
            Sys.println('This command requires admin permissions.');
            return;
        }
        var home:String = Sys.getEnv((Sys.systemName() == "Windows") ? "UserProfile" : "HOME");
        var internalDir:String = Path.join([home, ".haxeman"]);
        var currentVerFile:String = Path.join([internalDir, ".current"]);

        var version:SemanticVersion = args[0];
        if(version == null || version.length == 0) {
            Sys.println('No version specified to use!');
            return;
        }
        version = version.toLowerCase().trim();

        // Find latest version if version specified
        // is well  .. ... . latest
        if(version == "latest") {
            var versionDir:String = Path.join([internalDir, "versions"]);
            if(FileSystem.exists(versionDir)) {
                for(ver in FileSystem.readDirectory(versionDir)) {
                    final f:String = Path.join([versionDir, ver]);
                    if(FileSystem.isDirectory(f)) {
                        final sVer:SemanticVersion = cast ver;
                        if(sVer > version)
                            version = sVer;
                    }
                }
            }
        }

        // Delete old .current file
        if(FileSystem.exists(currentVerFile))
            FileSystem.deleteFile(currentVerFile);

        // Make new .current file
        final tempFile:String = Path.join([home, "Downloads", "haxeman.hxmantemp"]);
        File.saveContent(tempFile, version);

        // Put it in the correct place
        FileSystem.rename(tempFile, currentVerFile);

        // Set HAXEPATH to correct value
        // trace('DEBUG: Haxe path before: ${Sys.getEnv("HAXEPATH")}');
        Sys.putEnv("HAXEPATH", Path.join([internalDir, "versions", version]));
        switch(Sys.systemName()) {
            case "Windows":
                __setRegValue(REG_HKLM_ENVIRONMENT, "HAXEPATH", REG_SZ, Sys.getEnv("HAXEPATH"));

            default:
        }
        // trace('DEBUG: Haxe path after: ${Sys.getEnv("HAXEPATH")}');

        Sys.println('Current version of Haxe is now ${version}!');
    }

    public static function current(args:Array<String>):Void {
        var home:String = Sys.getEnv((Sys.systemName() == "Windows") ? "UserProfile" : "HOME");
        var internalDir:String = Path.join([home, ".haxeman"]);
        var currentVerFile:String = Path.join([internalDir, ".current"]);
        
        var version:String = (FileSystem.exists(currentVerFile)) ? File.getContent(currentVerFile) : null;
        if(version == null || version.length == 0) {
            Sys.println('You haven\'t selected a version of Haxe yet!\nRun "haxeman use" to use a version.');
            return;
        }
        version = version.trim();
        Sys.println(version);
    }

    static function __setRegValue<T>(regDir:String, name:String, dataType:RegDataType<T>, value:T) {
		var p = new Process('reg', ['add', regDir, '/v', name, '/t', dataType, '/d', '$value', '/f']);
		if(p.exitCode() != 0) {
			var error = p.stderr.readAll().toString();
			p.close();
			var msg = 'Cannot set a value for $name via reg.exe: $error';
			Sys.println(msg);
		}
		p.close();
	}
}

enum abstract RegDataType<T>(String) to String {
	var REG_EXPAND_SZ:RegDataType<String>;
	var REG_SZ:RegDataType<String>;
}