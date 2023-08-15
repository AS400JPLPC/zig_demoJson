const std = @import("std");
const dds = @import("dds");
// keyboard
const kbd = @import("cursed").kbd;

// tools utility
const utl = @import("utils");

const deb_Log = @import("logger").openFile;   // open  file
const end_Log = @import("logger").closeFile;  // close file
const plog   = @import("logger").scoped;      // print file 



const allocator = std.heap.page_allocator;


const Ctype = enum {
  null,
  bool,
  integer,
  float,
  number_string,
  string,
  array,
  object,
  decimal_string
};



//..............................//

const DEFBUTTON = struct {
    name: [] const u8,
    key : kbd,
    show: bool,
    check: bool,
    title: []const u8
};

const Jbutton = enum {
  name,
  key,
  show,
  check,
  title
};

//..............................//
const DEFLABEL = struct {
    name :  []const u8,
    posx:   usize,
    posy:   usize,
    text:   []const u8,
    title:  bool
};

const Jlabel = enum {
  name,
  posx,
  posy,
  text,
  title
};

//..............................//
const RPANEL = struct {
    name:   [] const u8,
    posx:   usize,
    posy:   usize,

    lines:  usize,
    cols:   usize,

    cadre:  dds.CADRE,

    title:  []const u8 ,

    button: std.ArrayList(DEFBUTTON),

    label:  std.ArrayList(DEFLABEL)
};

const Jpanel = enum {
  name,
  posx,
  posy,
  lines,
  cols,
  cadre,
  title,
  button,
  label
};



//var NPANEL = std.ArrayList(pnl.PANEL).init(allocator);

var ENRG : RPANEL= undefined;


//---------------------------------------------------------------------------
//  string return enum

fn strToEnum ( comptime EnumTag : type ,  vtext: [] const u8 )  EnumTag {

    inline for (@typeInfo(EnumTag).Enum.fields) |f| {
      
      if ( std.mem.eql(u8, f.name , vtext) )  return @field(EnumTag, f.name);

    }
    

    var buffer : [128] u8 =  [_]u8{0} ** 128;
    var result =  std.fmt.bufPrintZ(buffer[0..], "invalid Text {s} for strToEnum ",.{vtext}) catch unreachable;
    @panic(result);
}

//----------------------------------------------------
// JSON
//----------------------------------------------------

const T = struct {
  x: ?std.json.Value,

  pub fn init(self: std.json.Value) T {
      return T {
        .x = self
      };
  }

  pub fn get(self: T, query: []const u8) T {
    
    if (self.x.?.object.get(query) == null) {
      std.debug.print("ERROR::{s}::", .{ "invalid" });
      return T.init(self.x.?);
    }

    return T.init(self.x.?.object.get(query).?);
  }

  pub fn ctrlPack(self: T , Xtype : Ctype) !bool {

    try printPack(self,Xtype);

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    switch (self.x.?) {
      .null => {
          if (Xtype != .null) return false;
      }, 

      .bool => {
          if (Xtype != Ctype.bool ) return false;
      },

      .integer => {
          if (Xtype != Ctype.integer) return false;
      },

      .float =>{
          if (Xtype != Ctype.float) return false;
      },

      .number_string =>{
          if (Xtype != Ctype.number_string) return false;
      },

      .string =>{
          if (Xtype != Ctype.string) return false;
          if (Xtype == Ctype.decimal_string) return utl.isDecimalStr(try std.fmt.allocPrint(allocator,"{s}",.{self.x.?.string}));
      },

      .array =>{
          if (Xtype != Ctype.array) return false;
      },

      .object => {
          if (Xtype != Ctype.object) return false;
          //try printPack(self,Xtype);
      }

    }


    return true;
  }

  pub fn index(self: T, i: usize)  T {

    switch (self.x.?) {
      .array => {
        if (i > self.x.?.array.items.len) {
          std.debug.print("ERROR::{s}::\n", .{ "index out of bounds" });
          return T.init(self.x.?);
        }
      },
      else => {
        std.debug.print("ERROR::{s}:: {s}\n", .{ "Not array", @tagName(self.x.?) });
        return T.init(self.x.?);
      }
    }
    return T.init(self.x.?.array.items[i]);
  }


  pub fn printPack(self: T , Xtype : Ctype) !void {

    std.debug.print("{}:",.{Xtype});


    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();
    const i = self.x.?;
    const P = struct { value: ?std.json.Value };
    try std.json.stringify(P{ .value = i }, .{ }, out.writer());
    std.debug.print("{s}\n", .{ out.items });
  }
};




pub fn jsonDecode(my_json : []const u8) !void {

  var val: T = undefined;
  

  const parsed = try std.json.parseFromSlice(std.json.Value, allocator, my_json, .{ });
  defer parsed.deinit();

  std.debug.print("\n", .{ });


  const json = T.init(parsed.value);

  _= try json.ctrlPack(Ctype.object);



  val = json.get("PANEL");


  var nbrPanel = val.x.?.array.items.len;

  var p: usize = 0 ;

  const Rpanel = std.enums.EnumIndexer(Jpanel);

  const Rlabel = std.enums.EnumIndexer(Jlabel);

  const Rbutton = std.enums.EnumIndexer(Jbutton);

  while (p < nbrPanel) : ( p +=1 ) {


    var n: usize = 0 ; // index




    while (n < Rpanel.count) : ( n +=1 ) {
    var v: usize = 0 ; // index 
    var y: usize = 0 ; // array len
    var z: usize = 0 ; // compteur 
    var b: usize = 0 ; // button
    var l: usize = 0 ; // label
      switch(Rpanel.keyForIndex(n)) {

        Jpanel.name =>  { 
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));

              if ( try val.ctrlPack(Ctype.string) )  
                ENRG.name = try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
              else 
                @panic(try std.fmt.allocPrint(allocator,"Json  Panel err_Field :{s}\n", .{ 
                  @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.posx => {
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
              
              if ( try val.ctrlPack(Ctype.integer) )  
                ENRG.posx =  @intCast(val.x.?.integer)
              else 
                @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                  @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.posy => {
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
              
              if ( try val.ctrlPack(Ctype.integer) )  
                ENRG.posy =  @intCast(val.x.?.integer)
              else 
                @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                  @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.lines => {
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
              
              if ( try val.ctrlPack(Ctype.integer) )  
                ENRG.lines =  @intCast(val.x.?.integer)
              else 
                @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                  @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.cols => {
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
              
              if ( try val.ctrlPack(Ctype.integer) )  
                ENRG.cols =  @intCast(val.x.?.integer)
              else 
                @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                  @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.cadre => {
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
              
              if ( try val.ctrlPack(Ctype.string) ) {
                
                ENRG.cadre = strToEnum(dds.CADRE, val.x.?.string);
              }
              else 
                @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                  @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.title => {
              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
                    
              if ( try val.ctrlPack(Ctype.string) )  
                  ENRG.title = try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
              else 
              @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                @tagName(Rpanel.keyForIndex(n))}));
        },
        Jpanel.button => {

              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));

              var bt :DEFBUTTON =undefined;
              y = val.x.?.array.items.len;
              z = 0;
              b = 0;

              while(z < y) : (z += 1 ) {

                v =0;
                while (v < Rbutton.count) : ( v +=1 ) {

                  val = json.get("PANEL").index(p).get("button").index(b).get(@tagName(Rbutton.keyForIndex(v)));

                  switch(Rbutton.keyForIndex(v)) {
                    Jbutton.name => {
                        if ( try val.ctrlPack(Ctype.string)) 
                          bt.name =  try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));
                    },
                    Jbutton.key => {
                        if ( try val.ctrlPack(Ctype.string)) {
                          
                          bt.key = strToEnum(kbd, val.x.?.string);
                                      
                        }
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));
                    },
                    Jbutton.show => {
                        if ( try val.ctrlPack(Ctype.bool)) 
                          bt.show = val.x.?.bool
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));

                    },
                    Jbutton.check=> {
                        if ( try val.ctrlPack(Ctype.bool)) 
                          bt.check = val.x.?.bool
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));

                    },
                    Jbutton.title => {
                        if ( try val.ctrlPack(Ctype.string)) 
                          bt.title = try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));

                        ENRG.button.append(bt) catch unreachable;
                    }
                  }
                }
                b +=1;
              }

        },
        Jpanel.label => {

              val = json.get("PANEL").index(p).get(@tagName(Rpanel.keyForIndex(n)));
              
              var lb :DEFLABEL =undefined;
              y = val.x.?.array.items.len;
              z = 0 ;
              l = 0 ;
              while(z < y) : (z += 1 ) {
                
                v =0;
                while (v < Rlabel.count) : ( v +=1 ) {
                        val = json.get("PANEL").index(p).get("label").index(l).get(@tagName(Rlabel.keyForIndex(v)));
                        try val.printPack(Ctype.array);

                  switch(Rlabel.keyForIndex(v)) {
                    Jlabel.name => {
                        if ( try val.ctrlPack(Ctype.string)) 
                          lb.name =  try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rlabel.keyForIndex(v))}));
                    },
                    Jlabel.posx => {
                        if ( try val.ctrlPack(Ctype.integer)) {
                          
                          lb.posx = @intCast(val.x.?.integer);
                        }
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));
                    },
                    Jlabel.posy => {
                        if ( try val.ctrlPack(Ctype.integer)) {
                          
                          lb.posy = @intCast(val.x.?.integer);
                        }
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));
                    },
                    Jlabel.text => {
                        if ( try val.ctrlPack(Ctype.string)) 
                          lb.text =  try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rlabel.keyForIndex(v))}));
                    },
                    Jlabel.title => {
                        if ( try val.ctrlPack(Ctype.bool)) 
                          lb.title = val.x.?.bool
                        else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                          @tagName(Rpanel.keyForIndex(n)),
                          @tagName(Rbutton.keyForIndex(v))}));

                        ENRG.label.append(lb) catch unreachable;
                    }

                  }
                }
                l +=1;
              }
        }

      }
    }
  }

}

pub const ErrMain = error{
        Invalide_size,
};


// astuce dangereuse reserve internal function
fn strToUsize_01(str: []const u8) usize{
      return std.fmt.parseUnsigned(u64, str,10)  catch  { 
        plog(.ERROR).err(" err{s}",.{str});
        @panic("panic à bord");}; 
}

pub fn main() !void {
  

    var out_buf: [1024]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();

    var w = std.json.writeStream(out, .{ .whitespace = .indent_2 });
    defer w.deinit();

  try w.beginObject();
    try w.objectField("PANEL");

    try w.beginArray();
      try w.beginObject();
        try w.objectField("name");
        try w.print("  \"{s}\"", .{"panel01"});

        try w.objectField("posx");
        try w.print("  {d}", .{1});
        try w.objectField("posy");
        try w.print("  {d}", .{2});

        try w.objectField("lines");
        try w.print(" {d}", .{3});
        try w.objectField("cols");
        try w.print("  {d}", .{4});

        try w.objectField("cadre");
        try w.print(" \"{s}\"", .{"line1"});

        try w.objectField("title");
        try w.print(" \"{s}\"", .{"Title-PANEL"});

        try w.objectField("button");
        try w.beginArray();

          try w.beginObject();
          try w.objectField("name");
          try w.print("  \"{s}\"", .{"nF3"});
          try w.objectField("key");
          try w.print("   \"{s}\"", .{"F3"});
          try w.objectField("show");
          try w.print("  {}", .{true});
          try w.objectField("check");
          try w.print(" {}", .{false});
          try w.objectField("title");
          try w.print(" \"{s}\"", .{"F3 exit"});
          try w.endObject();


          try w.beginObject();
          try w.objectField("name");
          try w.print("  \"{s}\"", .{"nF9"});
          try w.objectField("key");
          try w.print("   \"{s}\"", .{"F9"});
          try w.objectField("show");
          try w.print("  {}", .{true});
          try w.objectField("check");
          try w.print(" {}", .{false});
          try w.objectField("title");
          try w.print(" \"{s}\"", .{"F9 Enrg."});
          try w.endObject();

        try w.endArray();

        try w.objectField("label");
        try w.beginArray();

          try w.beginObject();
          try w.objectField("name");
          try w.print("  \"{s}\"", .{"lbl01"});

          try w.objectField("posx");
          try w.print("  {d}", .{10});
          try w.objectField("posy");
          try w.print("  {d}", .{11});

          try w.objectField("text");
          try w.print("  \"{s}\"", .{"Nom.......:"});
          try w.objectField("title");
          try w.print(" {}", .{true});
          try w.endObject();


          try w.beginObject();
          try w.objectField("name");
          try w.print("  \"{s}\"", .{"lbl02"});

          try w.objectField("posx");
          try w.print("  {d}", .{11});
          try w.objectField("posy");
          try w.print("  {d}", .{11});

          try w.objectField("text");
          try w.print("  \"{s}\"", .{"Prénom....:"});
          try w.objectField("title");
          try w.print(" {}", .{true});
          try w.endObject();

        try w.endArray();
      try w.endObject();

    try w.endArray();
  try w.endObject();

    const result = slice_stream.getWritten();

    //std.debug.print("{s}\r\n",.{result});

    var my_file = try std.fs.cwd().createFile("fileJson.txt", .{ .read = true });
    

    _ = try my_file.write(result);
    my_file.close();

    my_file = try std.fs.cwd().openFile("fileJson.txt", .{});
    defer my_file.close();


      var buf : []u8= allocator.alloc(u8, result.len) catch unreachable ;

      try my_file.seekTo(0);
      _= try my_file.read(buf[0..]);
      std.debug.print("{s}\r\n",.{buf});



    // init arraylist 
    ENRG.button = std.ArrayList(DEFBUTTON).init(allocator);
    ENRG.label = std.ArrayList(DEFLABEL).init(allocator);

    // return  catch after panic

    jsonDecode(buf) catch return ;





deb_Log("zmodlJson.txt");

plog(.main).debug("Begin\n", .{});

plog(.schema).debug("\nwrite Json",.{});
plog(.schema).debug("\n{s}\n",.{buf});
plog(.schema).debug("\nRead Json",.{});

plog(.Panel).debug("\n",.{});
plog(.Panel).debug("{s}",.{ENRG.name});
plog(.Panel).debug("{d}",.{ENRG.posx});
plog(.Panel).debug("{d}",.{ENRG.posy});
plog(.Panel).debug("{}", .{ENRG.cadre});
plog(.Panel).debug("{s}\n",.{ENRG.title});


plog(.Button).debug("\n", .{});
for (ENRG.button.items ) | f|{
  plog(.Button).debug("{s}",.{f.name});
  plog(.Button).debug("{any}" ,.{f.key});
  plog(.Button).debug("{}" ,.{f.show});
  plog(.Button).debug("{}" ,.{f.check});
  plog(.Button).debug("{s}\n",.{f.title});
}

plog(.Label).debug("\n", .{});
for (ENRG.label.items ) | f|{
  plog(.Label).debug("{s}",.{f.name});
  plog(.Label).debug("{d}" ,.{f.posx});
  plog(.Label).debug("{d}" ,.{f.posy});
  plog(.Label).debug("{s}" ,.{f.text});
  plog(.Label).debug("{}\n",.{f.title});
}

_= strToUsize_01("test");

plog(.end).debug("End.\n", .{});

end_Log();

} // end