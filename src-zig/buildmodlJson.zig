const std = @import("std");


pub fn build(b: *std.build) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});


  
    // zig-src            source projet
    // zig-src/deps       curs/ form / outils ....
    // src_c              source c/c++
    // zig-src/lib        source .h 


    // Definition of module

        // Definition of module
    // data commune
    const dds = b.createModule(.{
      .source_file = .{ .path = "./deps/curse/dds.zig" },
    });
    
    const utils = b.createModule(.{
      .source_file = .{ .path = "./deps/curse/utils.zig" },
      .dependencies= &.{.{ .name = "dds", .module = dds }},
    });

    const cursed = b.createModule(.{
      .source_file = .{ .path = "./deps/curse/cursed.zig" },
      .dependencies= &.{
        .{ .name = "dds", .module = dds },
        .{ .name = "utils", .module = utils },
      },
    });



    // Building the executable

    const Prog = b.addExecutable(.{
    .name = "modlJson",
    .root_source_file = .{ .path = "./modlJson.zig" },
    .target = target,
    .optimize = optimize,
    });
    
    Prog.addIncludePath(.{.path = "./lib/"});
    Prog.linkLibC();
    Prog.addObjectFile(.{.cwd_relative = "/usr/lib/libpcre2-posix.so"});
    Prog.addModule("dds"   , dds);
    Prog.addModule("utils" , utils);
    Prog.addModule("cursed", cursed);




    const install_exe = b.addInstallArtifact(Prog, .{});
    b.getInstallStep().dependOn(&install_exe.step); 



}