return game:GetService("RunService"):IsClient() and {
	-- Client
	ScriptName = true;
	ModuleName = true;

	-- Shared
	Remotes = true;
} or {
	-- Server
	ScriptName = true;
	ModuleName = true;

	-- Shared
	Remotes = true;
}
