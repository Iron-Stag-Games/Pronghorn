return game:GetService("RunService"):IsClient() and {
	-- Client
	ExampleScript = true;
	ExampleClientModule = true;

	-- Shared
	Remotes = true;
	ExampleSharedModule = true;
} or {
	-- Server
	ExampleScript = true;
	ExampleServerModule = true;

	-- Shared
	Remotes = true;
	ExampleSharedModule = true;
}
