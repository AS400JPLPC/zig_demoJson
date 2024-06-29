const std = @import("std");


pub fn build(b: *std.Build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});


  
    // zig-src            source projet
    // zig-src/deps       curs/ form / outils ....
    // src_c              source c/c++
    // zig-src/lib        source .h 


    // Building the executable

    const Prog = b.addExecutable(.{
    .name = "modlJson",
    .root_source_file = b.path( "./modlJson.zig" ),
    .target = target,
    .optimize = optimize,
    });

	// for match use regex 
	//Prog.linkLibC();

	// Resolve the 'library' dependency.
	const library_dep = b.dependency("library", .{});
	
	// Import the smaller 'cursed' and 'utils' modules exported by the library. etc...
	Prog.root_module.addImport("cursed", library_dep.module("cursed"));
	Prog.root_module.addImport("utils", library_dep.module("utils"));
    Prog.root_module.addImport("match", library_dep.module("match"));
    Prog.root_module.addImport("forms", library_dep.module("forms"));
    
     Prog.root_module.addImport("logger", library_dep.module("logger"));


	b.installArtifact(Prog);



}
