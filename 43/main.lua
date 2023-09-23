-- (c) 2021 🥺🥺🥺
-- this code was manualy cursed to meet the lowest standards ✅✅✅
-- "Inter-token spacing is the root of all evil." - Mahatma Gandhi
local splurped={}
do
	local ts={_G}
	local s={}
	repeat
		local ns={}
		local fr={}
		for _,t in pairs(ts) do
			s[t]=1
			for k,v in pairs(t) do
				if fr[k]==nil then
					fr[k]=v
				else
					fr[k]=fr
				end
				if type(v)=="table" and not s[v] then
					ns[#ns+1]=v
				end
			end
		end
		for k,v in pairs(fr) do
			if splurped[k]==nil and v~=fr then
				splurped[k]=v
			end
		end
		ts=ns
	until#ts==0
end
setfenv(1,setmetatable({},{__index=splurped}))
local function mapva(f,...)
	if select("#",...)==0 then return end
	return f((...)),mapva(f,select(2,...))
end
p,x,pts,stp=400,0,{},{} -- 400² is the HOLY RESOLUTION - DO NOT TOUCH!
function love.load(args)
	R,r,d=mapva(tonumber,unpack(args))
	m=p/(R-r+abs(d))*0.5*0.75
	R,r,d=R*m,r*m,d*m
	mdt = min(abs(1/(R-r)),abs(r/(R-r)/d))/10
	setTitle(((r<0)and"epi"or"hypo").."trochoid")
	setMode(p,p)
end
function love.update(fdt)
	n=ceil(fdt/mdt)
	dt=fdt/n
	for i=1,n do
		x=x-dt
		y=-x*(R-r)/r
		cx,cy=p/2,p/2
		rx,ry=cx+(R-r)*cos(x),cy+(R-r)*sin(x)
		px,py=floor(rx-d*cos(y)),floor(ry-d*sin(y))
		h=py*p+px
		if not stp[h] then
			stp[h]=1
			insert(pts,{px,py})
		end
	end
end
function love.draw()
	setColor(0,1,0,1)
	ellipse("line",cx,cy,R,R)
	ellipse("line",rx,ry,abs(r),abs(r))
	line(rx,ry,px,py)
	setColor(1,0,0,1)
	points(pts)
end
