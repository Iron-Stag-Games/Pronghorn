return if game:GetService("RunService"):IsClient() then {
	-- Client
	ExampleScript = true;
	ExampleClientModule = true;

	-- Shared
	Remotes = true;
	ExampleSharedModule = true;
} else {
	-- Server
	ExampleScript = true;
	ExampleServerModule = true;

	-- Shared
	Remotes = true;
	ExampleSharedModule = true;
}
