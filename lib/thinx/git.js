// Git Shell Manager

var Globals = require("./globals.js");
var app_config = Globals.app_config();
var fs = require("fs-extra");

module.exports = class Git {

    fetch(owner, command, local_path) {
		const exec = require("child_process");
		let success = false;
		let result;
		let RSAKey = require("./rsakey"); let rsa = new RSAKey();
		const key_paths = rsa.getKeyPathsForOwner(owner);
		if (key_paths.count < 1) {
			console.log("no_rsa_keys_found"); // todo: build or audit log
			return false;
		}		
		for (var kindex in key_paths) {
			var gfpfx = "ssh-agent bash -c 'ssh-add " + app_config.ssh_keys + "/" + key_paths[kindex] + "; ".replace("//", "/");
			console.log("git prefix", kindex, gfpfx);
			let cmd = gfpfx + command + "'";
			console.log("git command: " + cmd);			
			try {
				result = exec.execSync(cmd);
				let rstring = result.toString();
				console.log("[sources] git rsa clone result: ", rstring);

				if (rstring.indexOf("Already up-to-date.") != -1) {
					return true;
				}

				if (rstring.indexOf("FETCH_HEAD") != -1) {
					return true;
				}

				if (rstring.indexOf("up-to-date") !== -1) {
					return true;
				} 

				if (typeof(local_path) !== "undefined") {
					success = fs.existsSync(local_path + "/*"); // may throw!
					console.log("Fetch successful? : " + success);
				}
				if (success == true) {
					return success;
				}
			} catch (e) {
				console.log("git rsa clone error: " + e);
				success = false;
			}
		}
		return success;
	}
};