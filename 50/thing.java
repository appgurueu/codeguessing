import java.util.*;import java.util.regex.Pattern;import java.util.stream.*;import java.io.*;
// da spek sed "Your complete function may produce any amount of output, although the result should depend on text_so_far given some corpus."
// dis meks a infinte strem o'. do smth liek java thing.java "I like fish" <bible.txt | head -c 1000 o jst ctrl^C idk
class Thing{
public static void main(String... args){
final var corpus=new BufferedReader(new InputStreamReader(System.in)).lines().collect(Collectors.joining("\n"));
final var text_so_far=args[0];
final var n=3;
var next=new HashMap<String,ArrayList<String>>();
var p=Pattern.compile("\\w+");
var m=p.matcher(corpus);
var prevs=new ArrayList<String>();
prevs.add("");
while(m.find()){
var tok=m.group();
var ctx=prevs.get(prevs.size()-1);
for(var i=1;i<=Math.min(prevs.size()-1,n);i++){
var nexts=next.getOrDefault(ctx,new ArrayList<>());
nexts.add(tok);
next.put(ctx,nexts);
ctx=" "+prevs.get(prevs.size()-1-i)+" "+ctx;
}
prevs.add(tok);
}
var r=new Random();
m=p.matcher(text_so_far);
var ks=prevs;
prevs=new ArrayList<String>();
for (var i=0;i<n;i++)
prevs.add(ks.get(r.nextInt(ks.size())));
while (m.find())
prevs.add(m.group());
while(true){
var ctx = prevs.get(prevs.size()-1);
var choisez = new ArrayList<String>();
for(var j=1;j<=Math.min(prevs.size()-1,n);j++) {
choisez.addAll(next.getOrDefault(ctx, new ArrayList<>()));
ctx = prevs.get(prevs.size()-1-j)+" "+ctx;
}
if(choisez.isEmpty()){
for(var i=0;i<n;i++)
prevs.add(ks.get(r.nextInt(ks.size())));
}
var w = choisez.get(r.nextInt(choisez.size()));
System.out.print(" "+w);
prevs.add(w);
}
}
}
