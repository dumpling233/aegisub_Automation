local tr = aegisub.gettext
script_name = tr("歌词处理")
script_description = tr("用于处理你不知道从哪里找来的混搭歌词")
script_author = "拉姆0v0"
script_version = "2.0"

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

dialog_config=
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
	buttons,results =aegisub.dialog.display(dialog_config,{"OK","Cancel"})
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

TLL_macros = {
	{
		script_name = "中日分离2.0",
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
		script_name = "一键添加内联特效",
		script_description = "用于添加内敛特效",
		entry = function(subs,sel) add_fx(subs,sel) end,
		validation = false
	},
}

for i = 1, #TLL_macros do
	aegisub.register_macro(script_name.." "..script_version.."/"..TLL_macros[i]["script_name"], TLL_macros[i]["script_description"], TLL_macros[i]["entry"], TLL_macros[i]["validation"])
end
