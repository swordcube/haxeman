package;

using StringTools;

typedef Command = {
	var name:String;
	var description:String;
	var callback:(args:Array<String>)->Void;
}

class Main {
	public static var commands:Array<Command> = [
		{
			name: "help",
			description: "Lists out every available command.",
			callback: Commands.help
		},
		{
			name: "install",
			description: "Installs a specified version of Haxe.",
			callback: Commands.install
		},
		{
			name: "uninstall",
			description: "Uninstalls a specified version of Haxe.",
			callback: Commands.uninstall
		},
		{
			name: "use",
			description: "Uses a specified version of Haxe.",
			callback: Commands.use
		},
		{
			name: "current",
			description: "Prints the current Haxe version to the console.",
			callback: Commands.current
		}
	];

	static function main():Void {
		final args:Array<String> = Sys.args();
		if(args == null || args.length == 0)
			Sys.println('Welcome to haxeman! A simple version manager for Haxe.\nRun "haxeman help" to get a list of commands.');
		
		final currentCommand:String = args.shift().trim().toLowerCase();

		for(command in commands) {
			if(command.name == currentCommand) {
				command.callback(args);
				break;
			}
		}
	}
}