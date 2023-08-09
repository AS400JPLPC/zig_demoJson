const std = @import("std");
const utf = @import("std").unicode;

const dds = @import("dds");
// tools utility
const utl = @import("utils");

const allocator = std.heap.page_allocator;






const Rvals = enum {
  testing,
  production,
};

const Rbutton = enum {
  Tkey,
  title,
};
const Rdata = enum {
  vals,
  uptime,
  hello,
  decimalString,
  button
};

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

const DEFBUTTON = struct {
    Tkey : [] const u8,
    title: [] const u8,
  };
const DEFVALS = struct {
    testing : i32,
    production : i32 ,
  };

const Rvalue = struct {
  vals : DEFVALS,

  uptime : i32,
  hello  : [] const u8,
  decimal: [] const u8,

  button:std.ArrayList(DEFBUTTON) ,

};

var ENRG : Rvalue =undefined ;

  
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

          if (Xtype == Ctype.decimal_string) return utl.isDecimalStr(try std.fmt.allocPrint(allocator,"{s}",.{self.x.?.string}));
          if (Xtype != Ctype.string) return false;
      },

      .array =>{
          if (Xtype != Ctype.string) return false;
      },

      .object => {
          if (Xtype != Ctype.object) return false;
          const i = self.x.?;
          const P = struct { value: ?std.json.Value };
          try std.json.stringify(P{ .value = i }, .{ }, out.writer());
          std.debug.print("{s}\n", .{ out.items });
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
};





pub fn jsonRecord(my_json : []const u8) !void {

  var val: T = undefined;
  

  const parsed = try std.json.parseFromSlice(std.json.Value, allocator, my_json, .{ });
  defer parsed.deinit();

  std.debug.print("\n", .{ });


  const json = T.init(parsed.value);

  _= try json.ctrlPack(Ctype.object);

  



  std.debug.print("----------------------------\r\n",.{});
  std.debug.print("----------------------------\r\n",.{});

  const Record = std.enums.EnumIndexer(Rdata);

  const Record_vals = std.enums.EnumIndexer(Rvals);

  const Record_button = std.enums.EnumIndexer(Rbutton);

  var n: usize = 0 ;
  var v: usize = 0 ;
  while (n < Record.count) : ( n +=1 ) {

      switch(Record.keyForIndex(n)) {
        Rdata.vals =>  { 
              v =0;
              while (v < Record_vals.count) : ( v +=1 ) {
                switch(Record_vals.keyForIndex(v)) {
                  Rvals.testing => {
                      val = json.get("vals").get(@tagName(Record_vals.keyForIndex(v)));

                      //std.debug.print("{d}\r\n",.{val.x.?.integer});
                      if ( try val.ctrlPack(Ctype.integer) )  
                        ENRG.vals.testing = @intCast(val.x.?.integer)
                      else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                        @tagName(Record.keyForIndex(n)),
                        @tagName(Record_vals.keyForIndex(v))}));
                  },
                  Rvals.production => {
                      val = json.get("vals").get(@tagName(Record_vals.keyForIndex(v)));
                      
                      //std.debug.print("{d}\r\n",.{val.x.?.integer});
                      if ( try val.ctrlPack(Ctype.integer) )  
                        ENRG.vals.production =  @intCast(val.x.?.integer)
                      else 
                        @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}.{s}\n", .{ 
                        @tagName(Record.keyForIndex(n)),
                        @tagName(Record_vals.keyForIndex(v))}));

                  }
                }
              }
        },
        Rdata.uptime => {
          val = json.get(@tagName(Record.keyForIndex(n)));
                
          //std.debug.print("{d}\r\n",.{val.x.?.integer});
          if ( try val.ctrlPack(Ctype.integer) )  
              ENRG.uptime =  @intCast(val.x.?.integer)
          else 
          @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
          @tagName(Record.keyForIndex(n))}));

        },
        Rdata.hello => {
          val = json.get(@tagName(Record.keyForIndex(n)));
                
          //std.debug.print("{s}\r\n",.{val.x.?.string});
          if ( try val.ctrlPack(Ctype.string )) 
              ENRG.hello = try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
          else 
          @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
          @tagName(Record.keyForIndex(n))}));

        },
        Rdata.decimalString => {
          val = json.get(@tagName(Record.keyForIndex(n)));

          std.debug.print("{s}\r\n",.{val.x.?.string});
          if ( try val.ctrlPack(Ctype.decimal_string))  
            ENRG.decimal = try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
          else 
          @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
          @tagName(Record.keyForIndex(n))}));


        },
        Rdata.button => {
          val = json.get(@tagName(Record.keyForIndex(n)));

          var btn : DEFBUTTON = undefined;
          var y = val.x.?.array.items.len;
          var z : usize = 0;

          //std.debug.print("{d}\r\n",.{y});
            while(z < y) : (z += 1 ) {
              //std.debug.print("{d}\r\n",.{z});
              v =0;
              while (v < Record_button.count) : ( v +=1 ) {

                switch(Record_button.keyForIndex(v)) {
                  Rbutton.Tkey => {
                      val = json.get("button").index(z).get(@tagName(Record_button.keyForIndex(v)));

                      //std.debug.print("{s}\r\n",.{val.x.?.string});
                      if ( try val.ctrlPack(Ctype.string)) 
                        btn.Tkey =  try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
                      else 
                      @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                      @tagName(Record.keyForIndex(n))}));
                  },
                  Rbutton.title => {
                      val = json.get("button").index(z).get(@tagName(Record_button.keyForIndex(v)));

                      //std.debug.print("{s}\r\n",.{val.x.?.string});
                      if ( try val.ctrlPack(Ctype.string)) 
                        btn.title = try std.fmt.allocPrint(allocator,"{s}",.{val.x.?.string})
                      else 
                      @panic(try std.fmt.allocPrint(allocator,"Json  err_Field :{s}\n", .{ 
                      @tagName(Record.keyForIndex(n))}));

                      ENRG.button.append(btn) catch unreachable;
                  }
                }
              }
            }
        }

      }
    }

}



pub fn main() !void {



    var out_buf: [1024]u8 = undefined;
    var slice_stream = std.io.fixedBufferStream(&out_buf);
    const out = slice_stream.writer();

    var w = std.json.writeStream(out, .{ .whitespace = .indent_2 });
    defer w.deinit();

    try w.beginObject();

      try w.objectField("vals");
      try w.beginObject();
        try w.objectField("testing");
        try w.print("  {}", .{1});
        try w.objectField("production");
        try w.print("  {}", .{42});
      try w.endObject();

      try w.objectField("uptime");
      try w.print("  {}", .{9999});
      try w.objectField("hello");
      try w.print("  \"{s}\"", .{"bonjour"});
      try w.objectField("decimalString");
      try w.print("  \"{s}\"", .{"71.10"}); 

      try w.objectField("button");
      try w.beginArray();

        try w.beginObject();
        try w.objectField("Tkey");
        try w.print("  \"{s}\"", .{"F3"});
        try w.objectField("title");
        try w.print("  \"{s}\"", .{"F3 exit"});
        try w.endObject();

        try w.beginObject();
        try w.objectField("Tkey");
        try w.print("  \"{s}\"", .{"F9"});
        try w.objectField("title");
        try w.print("  \"{s}\"", .{"F9 enrg"});
        try w.endObject();

      try w.endArray();

    try w.endObject();

    const result = slice_stream.getWritten();

    //std.debug.print("{s}\r\n",.{result});

    var my_file = try std.fs.cwd().createFile("fileJson.txt", .{ .read = true });
    defer my_file.close();

    _ = try my_file.write(result);

      var buf : []u8= allocator.alloc(u8, result.len) catch unreachable ;

      try my_file.seekTo(0);
      _= try my_file.read(buf[0..]);
      std.debug.print("{s}\r\n",.{buf});



    // init arraylist 
    ENRG.button = std.ArrayList(DEFBUTTON).init(allocator);

    // return  catch after panic

    jsonRecord(buf) catch return ;

    std.debug.print("{d}\r\n",.{ENRG.vals.testing});
    std.debug.print("{d}\r\n",.{ENRG.vals.production});
    std.debug.print("{d}\r\n",.{ENRG.uptime});
    std.debug.print("{s}\r\n",.{ENRG.hello});
    std.debug.print("{s}\r\n",.{ENRG.decimal});
    std.debug.print("{s}\r\n",.{ENRG.button.items[0].Tkey});
    std.debug.print("{s}\r\n",.{ENRG.button.items[0].title});
    std.debug.print("{s}\r\n",.{ENRG.button.items[1].Tkey});
    std.debug.print("{s}\r\n",.{ENRG.button.items[1].title});

}
