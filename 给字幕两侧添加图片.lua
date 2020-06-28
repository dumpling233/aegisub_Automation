local tr = aegisub.gettext
script_name = tr("给选中的字幕两侧添加图片v1.0")
script_description = tr("给选中的字幕两侧添加图片v1.0")
script_author = "拉姆0v0"
script_version = "v1.0"

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

	[1]={class="label",x=0,y=0,label="请设置图片的出现位置和设定纵向偏移"},
	[2]={class="label",x=0,y=2,label="设置纵向偏移-->>"},
    [3]={class="intedit",name="图片纵向偏移",x=1,y=2,width=1,height=1,items={},value=0,hint="请输入整数"},
	[4]={class="label",x=0,y=3,label="(可忽略，不可为空。正数为下移，负数为上移)"},

	[5]={class="label",x=0,y=5,label="设置图片出现位置(至少选择一个)"},
    [6]={class="label",x=0,y=6,label="字幕左侧-->>"},
	[7]={class="checkbox",name="字幕左侧",x=1,y=6,width=1,height=1,items={},value=true},
	[8]={class="label",x=0,y=7,label="字幕右侧-->>"},
    [9]={class="checkbox",name="字幕右侧",x=1,y=7,width=1,height=1,items={},value=true},

  }

function pngmassage_test(subs,sel)
	filename = aegisub.dialog.open('请选择一张png图片', '', '','Text files (.png)|*.png', false, true)
	if filename==nil then
		return
	end
	buttons,results =aegisub.dialog.display(dialog_config2,{"OK","Cancel"})
	if buttons=="OK" then
		local ymove = results["图片纵向偏移"]
		local lc = results["字幕左侧"]
		local rc = results["字幕右侧"]
		local x,y=get_png_size(filename)
		local video_size_x,video_size_y
		for i=1,#subs do
			if subs[i].key == "PlayResX" then
				video_size_x=subs[i].value
			end
			if subs[i].key == "PlayResY" then
				video_size_y=subs[i].value
			end
		end

		for i=1,#sel do
			local l=subs[sel[i]]
			local alignx
			local posy
			for i=1,#subs do
				if (subs[i].class == "style" and subs[i].name == l.style) then
					style_table = subs[i]
				end
			end
			width, height, descent, ext_lead = aegisub.text_extents(style_table, l.text)
			if style_table.align == 2 then
				posy=video_size_y-style_table.margin_t
			else
				posy=style_table.margin_t+height
			end
			local textl="{\\p1\\an2\\bord0\\shad0\\1img("..filename..")\\pos("..tostring(tonumber(video_size_x)/2-width/2-x/2-10)..","..tostring(posy+ymove)..")}m 0 0 l "..tostring(x).." 0 l "..tostring(x).." "..tostring(y).." l 0 "..tostring(y)
			local textr="{\\p1\\an2\\bord0\\shad0\\1img("..filename..")\\pos("..tostring(tonumber(video_size_x)/2+width/2+x/2+10)..","..tostring(posy+ymove)..")}m 0 0 l "..tostring(x).." 0 l "..tostring(x).." "..tostring(y).." l 0 "..tostring(y)
			if lc==true then
				l.text=textl
			    subs.append(l)
			end
			if rc==true then
				l.text=textr
			    subs.append(l)
			end
			if lc==false and rc==false then
				aegisub.debug.out("请至少勾选左右中的一侧添加图片！")
				return
			end
		end
	    aegisub.debug.out("已完成！！！！！！\n\n文件路径："..filename.."\n图片分辨率："..tostring(x).."x"..tostring(y).."\n\n若显示为白色空白：\n1.请检查是否安装了最新版本的VSFilterMod\n2.请检查你所选择的图片名称是否存在非法字符，可以试着修改文件名为比较正常的文件名\n\n提示：若图片生成位置不理想，需要调整纵向偏移，可以ctrl-z撤销本次处理重新设置纵向偏移，还有ctrl-y反撤销\n\nby 拉姆0v0")
	end	
end


aegisub.register_macro(script_name, script_description, pngmassage_test)
