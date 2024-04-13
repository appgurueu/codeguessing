                                 const std=@import("std");const ArrayList                 
                                 =std.ArrayList;const Doer=struct{                        
                                 const State=enum{Normal,JustTainted                      
                        ,Tainted,TaintedGroup,Ignore,};const SyntaxError=error            
                        .InvalidSyntax;buf:ArrayList(u8),stk:ArrayList(usize              
                        ),stateStk:ArrayList(State),state:State,concatBegin               
                        :usize,pub                     fn init(alloc:anytype)Doer         
                        {return Doer                  {.buf=ArrayList(u8).init            
                        (alloc),.                     stk=ArrayList(usize).init           
                     (alloc),.         stateStk=ArrayList(State).init(alloc),.state       
                     =.Normal,         .concatBegin=0,};}pub fn startConcat(self:         
                     *Doer)void        {self.eraseConcat();self.state=.Normal;}pub        
                     fn eraseConcat (self:*Doer)void                    {self.buf.shrinkRetainingCapacity
                     (self.concatBegin);}pub fn pushState               (self:*Doer)!void 
                     {try self      .stk.append(self                    .concatBegin);try 
      self.stateStk.append(         self.state);self                             .concatBegin
      =self.buf.items.len;}         pub fn popState                              (self:   
      *Doer)!void{self.concatBegin  =self.stk.popOrNull                          () orelse 
   return SyntaxError;self.         state=self.stateStk.popOrNull() orelse unreachable;}   
   pub fn taint(self:*Doer)         void{self.eraseConcat();self.state=.Tainted;}pub fn   
   bufChar(self:*Doer,c:u8)         !void{try self.buf.append(c);}pub fn do(self:*Doer,   
   in:anytype     )![]const             u8{while(in.readByte())|c|{switch(self.state){.   
   Normal=>switch (c){'\\'=>           try self.bufChar(try in.readByte()),'|'=>self.state
   =.Ignore,      '*'=>{},'['          =>{if(try in.readByte()!=']')return SyntaxError;   
   self.state     =.JustTainted           ;},']'=>return SyntaxError,'('=>try self.pushState
   (),')'=>try     self.popState          (),else=>try self.bufChar(c),},.JustTainted     
   =>switch(      c){'\\'=>               {try in.skipBytes(1,.{});self.taint();},'*'     
   =>self.state   =.Normal,                                                '|'=>self      
   .startConcat   (),'('=>{                                                self.taint     
   ();try self    .pushState                                               ();},')'=>     
   {self.         eraseConcat                                              ();self.state  
   =.TaintedGroup ;},else=>                                                self.taint     
   (),},.         Tainted=>                                                switch(c)      
   {'\\'=>        try in.skipBytes                                         (1,.{}),'|'    
   =>self         .startConcat                                             (),'('=>try    
   self.pushState (),')'=>{                                                self.eraseConcat
   ();self.state  =.TaintedGroup                                           ;},else=>      
   {},},.TaintedGroup=>switch                                              (c){'*'=>      
   try self.      popState(                                                ),'|'=>{try    
   self.popState  ();self.startConcat                                      ();},'('=>     
   {try self.popState();self                                               .taint();      
   try self.pushState();},')'                                              =>{try self    
      .popState();self.state              =.TaintedGroup;},'\\'=>{try    in.skipBytes     
      (1,.{});try self.popState           ();self.taint();},else=>{try   self.popState    
      ();self.taint();}},.Ignore          =>switch(c){'\\','['=>try in  .skipBytes        
                     (1,.{}               ),']'=>return SyntaxError     ,'('=>try         
                     self.pushState       (),')'=>try  self.popState    (),else=>         
                     {},},}               }else|err   |{if(err!=error   .EndOfStream      
                     )return               err;}switch(self.state       ){.Normal         
                     ,.Ignore             =>return self.buf.toOwnedSlice(),else=>         
                     return                SyntaxError,}}};pub fn        main()!void      
                     {const stdout=std.io.getStdOut   ().writer();var bufout=std          
                     .io.bufferedWriter(stdout);const  stdin=std.io.getStdIn()            
                     ;var bufin=std.io.bufferedReader (stdin.reader());var arena          
                     =std.heap.ArenaAllocator.init                                        
                     (std.heap.page_allocator);defer                                      
                     arena.deinit();var doer=Doer                                         
.init(arena.allocator());try bufout.writer().writeAll(try doer.do(bufin.reader()));try bufout.flush();}