local tr = aegisub.gettext
script_name = tr("轴检查")
script_description = tr("脱裤子放屁工具")
script_author = "拉姆0v0"
script_version = "v1.0"

dialog_config1=
  {

	[1]={class="label",x=0,y=0,label="可自由设置检查的时间间隔"},
	[2]={class="label",x=0,y=1,label="设置要检查的前后之间的时间间隔："},
	[3]={class="intedit",name="时间间隔",x=1,y=1,width=1,height=1,items={},value=300,hint="请输入整数"},

  }
function text_processing(subs,sel)
	buttons,results =aegisub.dialog.display(dialog_config1,{"OK","Cancel"})
	if buttons=="OK" then
		local timex = results["时间间隔"]
		local stylen={}
		local stylenline={}
		local shannum={}
		for i=1,#subs do
			if subs[i].class == "dialogue" and subs[i].comment == false then
				if #stylen == 0 then
					table.insert(stylen,subs[i].style)
					table.insert(shannum,0)
					table.insert(stylenline,{i})
				else
					local isin=0
					for j=1,#stylen do
						if subs[i].style == stylen[j] then
							table.insert(stylenline[j],i)
							isin=1
							break
						end
					end
					if isin==0 then
						table.insert(stylen,subs[i].style)
						table.insert(shannum,0)
						table.insert(stylenline,{i})
					end
				end
			end
		end
--查找闪轴部分
        aegisub.debug.out("在不同样式中，前后相差小于"..tostring(timex).."毫秒的情况：\n\n")
	    for i=1,#stylen do
		    aegisub.debug.out(stylen[i].."：")
		    for j=1,(#stylenline[i]-1) do
			    if (subs[stylenline[i][j+1]].start_time-subs[stylenline[i][j]].end_time <= timex) and (subs[stylenline[i][j+1]].start_time-subs[stylenline[i][j]].end_time > 0) then
			    	local subp = subs[stylenline[i][j]]
		        	subp.actor = "(该样式的此行与下一行之间的间隔小于"..tostring(timex).."毫秒，请调整)"..subp.actor
					subs[stylenline[i][j]] = subp


					shannum[i]=shannum[i]+1
				end
			end
			aegisub.debug.out(tostring(shannum[i]).."处\n")
		end
		aegisub.debug.out("\n具体位置已标记在说话人一栏，请查看。\n\nby 拉姆0v0")
	end
end


TLL_macros = {
	{
		script_name = "检查闪轴",
		script_description = "检查闪轴",
		entry = function(subs,sel) text_processing(subs,sel) end,
		validation = false
	},
	
}

for i = 1, #TLL_macros do
	aegisub.register_macro(script_name.." "..script_version.."/"..TLL_macros[i]["script_name"], TLL_macros[i]["script_description"], TLL_macros[i]["entry"], TLL_macros[i]["validation"])
end
