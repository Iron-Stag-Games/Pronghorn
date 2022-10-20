return game:GetService("RunService"):IsClient() and {
	-- Client
	ExampleScript = true;
	ExampleModule = true;

	-- Shared
	Remotes = true;
} or {
	-- Server
	ExampleScript = true;
	ExampleModule = true;

	-- Shared
	Remotes = true;
}
