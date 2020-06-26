local tr = aegisub.gettext
script_name = tr("小工具合集")
script_description = tr("用于处理你不知道从哪里找来的混搭歌词")
script_author = "拉姆0v0"
script_version = "v3.0"

function text_processing(subs,sel)
	local line_storage1={}
	local line_storage2={}
	local line_storageblank={}
	local line_storagetext={}
	local num=#sel
	for i = 1, num do
		if (subs[sel[i]].text=="" or string.match(subs[sel[i]].text,"^[ ]*$") or string.match(subs[sel[i]].text,"^[　]*$")) then
			table.insert(line_storageblank,subs[sel[i]])
		else
			table.insert(line_storagetext,subs[sel[i]])
		end
	end
	for i,v in ipairs(line_storagetext) do
		if i%2==1 then
			table.insert(line_storage1,v)
		else
			table.insert(line_storage2,v)
		end
	end
	for i = 1, num do
		aegisub.progress.set(i/num*100)
		if i<=#line_storagetext then
			if i<=(#line_storagetext/2) then
				subs[sel[i]]=line_storage1[i]
			else
				subs[sel[i]]=line_storage2[i-(#line_storagetext/2)]
			end
		else
			subs[sel[i]]=line_storageblank[i-#line_storagetext]
		end
	end
	aegisub.debug.out("已将中日歌词分开，空白行或者空格行位于最下方")
end

function full_to_half(subs,sel)
	for i = 1, #sel do
		aegisub.progress.set(i/#sel*100)
		local subp = subs[sel[i]]
		subp.text = string.gsub(subp.text, "　", " ")
		subs[sel[i]] = subp
	end
end

function delete_k(subs,sel)
	for i = 1, #sel do
		aegisub.progress.set(i/#sel*100)
		local subp = subs[sel[i]]
		subp.text = string.gsub(subp.text, "{\\k[1-9]%d*}", "")
		subs[sel[i]] = subp
	end
end

dialog_config1=
  {

	[1]={class="label",x=0,y=1,label="第二个音节可以设置为空，即只在第一个音节出设置内联特效"},

    [2]={class="label",x=0,y=1,label=""},
    [3]={class="label",x=0,y=2,label="在第一个音节设置内联特效"},
    [4]={class="edit",name="在第一个音节设置内联特效",x=1,y=2,width=1,height=1,items={},value="\\-A"},

    [5]={class="label",x=0,y=3,label=""},
    [6]={class="label",x=0,y=4,label="在第二个音节设置内联特效"},
    [7]={class="edit",name="在第二个音节设置内联特效",x=1,y=4,width=1,height=1,items={},value="\\-B"},

    [8]={class="label",x=0,y=5,label=""},
    [9]={class="label",x=0,y=6,label="小提示：按OK做处理后，可以ctrl-z撤销本处理，还有ctrl-y反撤销"},

  }

function add_fx(subs,sel)
	buttons,results =aegisub.dialog.display(dialog_config1,{"OK","Cancel"})
	if buttons=="OK" then
		local fx1 = results["在第一个音节设置内联特效"]
	    local fx2 = results["在第二个音节设置内联特效"]
		for i = 1, #sel do
			aegisub.progress.set(i/#sel*100)
		    local subp = subs[sel[i]]
		    local t = string.match(subp.text, "^[^}]+") 
		    subp.text = string.gsub(subp.text, "[}]", fx2.."}",2)
		    subp.text = string.gsub(subp.text, "^[^}]+", t..fx1)
		    subs[sel[i]] = subp
	    end
	end
end

function hexstring2number(hexstring, len)  
    if not len or len > 8 then return end  
  
    local hexbyte = {}  
    for i = 1, len do  
		hexbyte[i] = string.byte(hexstring, i)  
	end 

	local detection=0x10
	local num_string = {}
	for i = 1, len do  
		if hexbyte[i]>=detection then
			num_string[i]=string.format("%x", hexbyte[i])
		else
			num_string[i]="0"..string.format("%x", hexbyte[i])
		end
	end
	

	local num = tonumber("0x"..num_string[1]..num_string[2]..num_string[3]..num_string[4])  
    return num  
end  
  
function get_png_size(path)  
    local png_file = io.open(path, "rb")  
	local data = png_file:read("*all")  
	
  
    -- 保证png至少有37个字节，因为包含文件头等起码就超过这个数字了  
    if #data < 37 then return end  
  
    -- 文件头的相关信息请百度  
    local png_header_info = {0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52}  
	for i = 1, #png_header_info do  
        if (string.byte(data, i) ~= png_header_info[i]) then  
            return  
        end  
	end  
	
    -- 这四个字节表示png的宽度  
	data = string.sub(data, #png_header_info + 1)
	local width = hexstring2number(data, 4)  
	
	data = string.sub(data, 5)
    local height = hexstring2number(data, 4)  
  
    return width, height  
end  

dialog_config2=
  {
	[1]={class="label",x=0,y=0,label="1.使用此功能时，请确认你的aegisub有安装VSFilterMod滤镜。\n2.VSFilterMod只支持24或32位带或不带透明通道的真彩色png格式的图片！\n3.该功能导入的图片无法修改显示大小，请选择大小合适的png格式图片！\nps:你的图片文件名如果过于诡异可能会失败，例如“7J`%TFT)K9]JUL3KF`@26$Y”之类的\n\nby 拉姆0v0"},
  }

function pngmassage_test(subs,sel)
	buttons,results =aegisub.dialog.display(dialog_config2,{"OK","Cancel"})
	if buttons=="OK" then
		filename = aegisub.dialog.open('请选择一张png图片', '', '','Text files (.png)|*.png', false, true)
		if filename==nil then
			return
		end
		local x,y=get_png_size(filename)
		local size_x,size_y
		for i=1,#subs do
			if subs[i].key == "PlayResX" then
				size_x=subs[i].value
			end
			if subs[i].key == "PlayResY" then
				size_y=subs[i].value
			end
			if subs[i].class == "dialogue" then
				local l=subs[i]
				l.start_time=0
				l.end_time=5000
				local text1="{\\p1\\an2\\bord0\\shad0\\1img("..filename..")\\pos("..tostring(tonumber(size_x)/2)..","..tostring(tonumber(size_y)-50)..")}m 0 0 l "..tostring(x).." 0 l "..tostring(x).." "..tostring(y).." l 0 "..tostring(y)
				l.text=text1
				l.effect=""
				l.style="Default"
				l.comment = false
				subs.insert(i,l)
			break
			end
		end
	    aegisub.debug.out("已完成！\n文件路径："..filename.."\n图片分辨率："..tostring(x).."x"..tostring(y))
	end
end

TLL_macros = {
	{
		script_name = "中日歌词分离v2.0",
		script_description = "用于将中日穿插排版的歌词分离开来",
		entry = function(subs,sel) text_processing(subs,sel) end,
		validation = false
	},
	{
		script_name = "全角空格 to 半角空格",
		script_description = "用于将歌词中的全角空格转换为半角空格",
		entry = function(subs,sel) full_to_half(subs,sel) end,
		validation = false
	},
	{
		script_name = "删除所选行k标签",
		script_description = "用于删除所选行k标签",
		entry = function(subs,sel) delete_k(subs,sel) end,
		validation = false
	},
	{
		script_name = "一键添加内联特效标签",
		script_description = "用于添加内联特效标签",
		entry = function(subs,sel) add_fx(subs,sel) end,
		validation = false
	},
	{
		script_name = "一键插入图片v2.0",
		script_description = "免去调整图片大小的功能，一键插入图片",
		entry = function(subs,sel) pngmassage_test(subs,sel) end,
		validation = false
	},
}

for i = 1, #TLL_macros do
	aegisub.register_macro(script_name.." "..script_version.."/"..TLL_macros[i]["script_name"], TLL_macros[i]["script_description"], TLL_macros[i]["entry"], TLL_macros[i]["validation"])
end
