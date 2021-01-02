-- 更新：
--     1.增加了对原有行存在的\frz(即绕z轴旋转标签)的自适应
--     2.增加了能够将常用边框效果存储为预设的功能，可以从预设打开之前存储的多层样式
-- 功能：
--     覆盖原有行边框，生成指定多重边框字幕
-- 注意：
--     1.多重边框情况下不支持设置透明边框（暂时将原来计划的透明度效果去除）
--     2.会将原有行注释，生成新行代替原有字幕



local tr = aegisub.gettext
script_name = tr("边框")
script_description = tr("边框")
script_author = "拉姆0v0"
script_version = "v1.1"

include("karaskel.lua")



fp=aegisub.decode_path("?data").."\\border_data.lua"
-- 序列化和反序列化方法
function serialize(obj)
    local lua = ""
    local t = type(obj)
    if t == "number" then
        lua = lua .. obj
    elseif t == "boolean" then
        lua = lua .. tostring(obj)
    elseif t == "string" then
        lua = lua .. string.format("%q", obj)
    elseif t == "table" then
        lua = lua .. "{\n"
    for k, v in pairs(obj) do
        lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"
    end
    local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
        for k, v in pairs(metatable.__index) do
            lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"
        end
    end
        lua = lua .. "}"
    elseif t == "nil" then
        return nil
    else
        error("can not serialize a " .. t .. " type.")
    end
    return lua
end

function unserialize(lua)
    local t = type(lua)
    if t == "nil" or lua == "" then
        return nil
    elseif t == "number" or t == "string" or t == "boolean" then
        lua = tostring(lua)
    else
        error("can not unserialize a " .. t .. " type.")
    end
    lua = "return " .. lua
    local func = loadstring(lua)
    if func == nil then
        return nil
    end
    return func()
end

function coloralpha2assCA(coloralpha)
    local length = #coloralpha
    -- local A = coloralpha:sub(length-1, length)
    -- local B = coloralpha:sub(length-3, length-2)
    -- local G = coloralpha:sub(length-5, length-4)
    -- local R = coloralpha:sub(length-7, length-6)
    -- return "H"..B..G..R, "H"..A
    local B = coloralpha:sub(length-1, length)
    local G = coloralpha:sub(length-3, length-2)
    local R = coloralpha:sub(length-5, length-4)
    return "H"..B..G..R, "H00"
end

function getPosFromText(text)
    local out = text:match("[%-?%d+%.*%d*]+[,]+[%-?%d+%.*%d*]+")
    if out ~= nil then
        return out
    else
        return ""
    end
end

function getFrz(text)
    local frz = text:match("\\frz%-?%d+%.*%d*")
    if frz ~= nil then
        return frz
    else
        return ""
    end
end

dialog_config1=
{
    [1]={class="label",x=0,y=0,label="多重边框层数："},
    [2]={class="intedit",name="border_num",x=1,y=0,width=1,height=1,value="1",hint="请输入整数"},
    [3]={class="label",x=0,y=1,label="选择预设："},
    [4]={class="dropdown",name="selete",x=1,y=1,width=5,height=1,items={},value=""},
}


local conf_template ={
    [1]='{class="label",x=0,y=%s,label="【第%s层】"}',
    [2]='{class="label",x=1,y=%s,label="颜色："}',
    [3]='{class="color",name="ca_%s",x=2,y=%s,width=1,height=1,value="%s"}',
    [4]='{class="label",x=3,y=%s,label="厚度："}',
    [5]='{class="edit",name="houdu_%s",x=4,y=%s,width=1,height=1,value="%s"}',
} 

local tags_template = "{\\pos(%s,%s)\\bord%s\\shad0\\3c&%s&\\3a&%s&%s}"


    

function border(subs,sel)
    -- 读取库数据
    local data=io.open(fp,"a+")
    local data_str = data:read('*a')
    data:close()
    if data_str == "" then
        local data_w =io.open(fp,"w+")
        data_w:write(serialize({}))
        data_w:close()
        data_str = "{}"
    end
    -- config设置
    local data_reader_table = unserialize(data_str)
    local select_table = {}
    for k,v in pairs(data_reader_table) do
        table.insert(select_table,v.name)
    end
    dialog_config1[4].items = select_table
    dialog_config1[4].value = dialog_config1[4].items[1]
    -- 初始化层数
    local buttons1 = "Delete preset"
    while buttons1=="Delete preset" do
        buttons1,results1 = aegisub.dialog.display(dialog_config1,{"New","Open preset","Delete preset","Cancel"})
        if buttons1=="Delete preset" then
            local delete_name = results1["selete"]
            for k,v in pairs(data_reader_table) do
                if v.name == delete_name then
                    table.remove(data_reader_table,k)
                    local data_w = io.open(fp, "w+")
                    data_w:write(serialize(data_reader_table))
                    data_w:close()
                    local after_select_table = {}
                    for k,v in pairs(data_reader_table) do
                        table.insert(after_select_table,v.name)
                    end
                    dialog_config1[4].items = after_select_table
                    dialog_config1[4].value = dialog_config1[4].items[1]
                end
            end
        end
    end
    if buttons1 == "New" then
        local border_num = results1["border_num"]
        if border_num > 0  then
            -- 主体
            -- 生成dialog
            local dialog_config2={}
            for i = 1, border_num do
                dialog_config2[(i-1)*5+1] = unserialize(conf_template[1]:format(i-1, i))
                dialog_config2[(i-1)*5+2] = unserialize(conf_template[2]:format(i-1))
                dialog_config2[(i-1)*5+3] = unserialize(conf_template[3]:format(i, i-1, "HFFFFFF"))
                dialog_config2[(i-1)*5+4] = unserialize(conf_template[4]:format(i-1))
                dialog_config2[(i-1)*5+5] = unserialize(conf_template[5]:format(i, i-1, "1"))
            end
            buttons2,results2 =aegisub.dialog.display(dialog_config2,{"OK","save as","Cancel"})
            if buttons2 == "OK" then
                local meta, styles = karaskel.collect_head(subs, false)
                local border_data = {}
                for i = 1, border_num do
                    local color,alpha = coloralpha2assCA(results2["ca_"..i])
                    local houdu = results2["houdu_"..i]
                    border_data[i] = {
                        ["color"] = color,
                        ["alpha"] = alpha,
                        ["houdu"] = houdu,
                    }
                end

                -- 对每一行分别应用多层边框
                for i = 1, #sel do
                    local pos_x
                    local pos_y
                    -- 分别判断每行是不是自带pos
                    local l = subs[sel[i]]
                    local simple_l = subs[sel[i]]
                    karaskel.preproc_line(subs, meta, styles, l)
                    local postag_str = getPosFromText(l.text)
                    local frztag_str = getFrz(l.text)
                    if postag_str == "" then
                        
                        pos_x = l.x
                        pos_y = l.y
                    else
                        pos_x = tonumber(postag_str:sub(1,postag_str:find("[,]+")-1))
                        pos_y = tonumber(postag_str:sub(postag_str:find("[,]+")+1,-1))
                    end
                    local bord = 0
                    -- 对每个边框生成
                    for j = 1, #border_data do
                        bord = bord + tonumber(border_data[j].houdu)
                        local text = tags_template:format(pos_x, pos_y, bord, border_data[j].color, border_data[j].alpha, (frztag_str == "" and "" or frztag_str))..l.text:gsub("{[^}]+}", "")
                        l.layer = #border_data-j+1
                        l.text = text
                        subs.append(l)
                    end
                    simple_l.comment = true
                    subs[sel[i]] = simple_l
                end
            elseif buttons2 == "save as" then
                dialog_config3=
                {
                    [1]={class="label",x=0,y=0,label="给你的预设起个名字吧："},
                    [2]={class="edit",name="yushename",x=1,y=0,width=5,height=1,value="预设1",hint="输入你的名字"},
                }
                buttons3,results3 =aegisub.dialog.display(dialog_config3,{"OK","Cancel"})
                if buttons3 == "OK" then
                    local save_name = results3["yushename"]
                    if save_name ~= "" then
                        local alive = false
                        for k,v in pairs(data_reader_table) do
                            if v.name == save_name then
                                alive = true
                                break
                            end
                        end
                        if alive == false then
                            local border_data = {}
                            for i = 1, border_num do
                                local color,alpha = coloralpha2assCA(results2["ca_"..i])
                                local houdu = results2["houdu_"..i]
                                border_data[i] = {
                                    ["color"] = color,
                                    ["alpha"] = alpha,
                                    ["houdu"] = houdu,
                                }
                            end
                            table.insert(data_reader_table,{["name"]=save_name,["data"]=border_data})
                            local data_w =io.open(fp,"w+")
                            data_w:write(serialize(data_reader_table))
                            data_w:close()
                            aegisub.debug.out("已保存！")
                        else
                            aegisub.debug.out("已存在同名预设！")
                        end
                    else
                        aegisub.debug.out("预设名不得为空！")
                    end
                else
                    aegisub.debug.out("已取消保存！")
                end
            else
                aegisub.debug.out("已取消！")
            end
        else
            aegisub.debug.out("层数应大于0！")
        end
    elseif buttons1 == "Open preset" then
        local yushe_name = results1["selete"]
        local data_table_yushe = ""
        for k,v in pairs(data_reader_table) do
            if v.name == yushe_name  then
                data_table_yushe = v.data
                break
            else
                data_table_yushe = ""
            end
        end
        if data_table_yushe ~= "" then
            -- 主体
            -- 生成dialog
            local dialog_config2 = {}
            for i = 1, #data_table_yushe do
                dialog_config2[(i - 1) * 5 + 1] = unserialize(conf_template[1]:format(i - 1, i))
                dialog_config2[(i - 1) * 5 + 2] = unserialize(conf_template[2]:format(i - 1))
                dialog_config2[(i - 1) * 5 + 3] = unserialize(
                                                      conf_template[3]:format(i, i - 1, data_table_yushe[i].color))
                dialog_config2[(i - 1) * 5 + 4] = unserialize(conf_template[4]:format(i - 1))
                dialog_config2[(i - 1) * 5 + 5] = unserialize(
                                                      conf_template[5]:format(i, i - 1, data_table_yushe[i].houdu))
            end
            buttons2, results2 = aegisub.dialog.display(dialog_config2, {"OK", "save as", "Cancel"})
            if buttons2 == "OK" then
                local meta, styles = karaskel.collect_head(subs, false)
                local border_data = {}
                for i = 1, #data_table_yushe do
                    local color, alpha = coloralpha2assCA(results2["ca_" .. i])
                    local houdu = results2["houdu_" .. i]
                    border_data[i] = {
                        ["color"] = color,
                        ["alpha"] = alpha,
                        ["houdu"] = houdu
                    }
                end

                -- 对每一行分别应用多层边框
                for i = 1, #sel do
                    local pos_x
                    local pos_y
                    -- 分别判断每行是不是自带pos
                    local l = subs[sel[i]]
                    local simple_l = subs[sel[i]]
                    karaskel.preproc_line(subs, meta, styles, l)
                    local postag_str = getPosFromText(l.text)
                    local frztag_str = getFrz(l.text)
                    if postag_str == "" then

                        pos_x = l.x
                        pos_y = l.y
                    else
                        pos_x = tonumber(postag_str:sub(1, postag_str:find("[,]+") - 1))
                        pos_y = tonumber(postag_str:sub(postag_str:find("[,]+") + 1, -1))
                    end
                    local bord = 0
                    -- 对每个边框生成
                    for j = 1, #border_data do
                        bord = bord + tonumber(border_data[j].houdu)
                        local text = tags_template:format(pos_x, pos_y, bord, border_data[j].color,
                                         border_data[j].alpha, (frztag_str == "" and "" or frztag_str)) ..
                                         l.text:gsub("{[^}]+}", "")
                        l.layer = #border_data - j + 1
                        l.text = text
                        subs.append(l)
                    end
                    simple_l.comment = true
                    subs[sel[i]] = simple_l
                end
            elseif buttons2 == "save as" then
                dialog_config3 = {
                    [1] = {
                        class = "label",
                        x = 0,
                        y = 0,
                        label = "给你的预设起个名字吧："
                    },
                    [2] = {
                        class = "edit",
                        name = "yushename",
                        x = 1,
                        y = 0,
                        width = 5,
                        height = 1,
                        value = "预设1",
                        hint = "输入你的名字"
                    }
                }
                buttons3, results3 = aegisub.dialog.display(dialog_config3, {"OK", "Cancel"})
                if buttons3 == "OK" then
                    local save_name = results3["yushename"]
                    if save_name ~= "" then
                        local alive = false
                        for k, v in pairs(data_reader_table) do
                            if v.name == save_name then
                                alive = true
                                break
                            end
                        end
                        if alive == false then
                            local border_data = {}
                            for i = 1, #data_table_yushe do
                                local color, alpha = coloralpha2assCA(results2["ca_" .. i])
                                local houdu = results2["houdu_" .. i]
                                border_data[i] = {
                                    ["color"] = color,
                                    ["alpha"] = alpha,
                                    ["houdu"] = houdu
                                }
                            end
                            table.insert(data_reader_table, {
                                ["name"] = save_name,
                                ["data"] = border_data
                            })
                            local data_w = io.open(fp, "w+")
                            data_w:write(serialize(data_reader_table))
                            data_w:close()
                            aegisub.debug.out("已保存！")
                        else
                            aegisub.debug.out("已存在同名预设！")
                        end
                    else
                        aegisub.debug.out("预设名不得为空！")
                    end
                else
                    aegisub.debug.out("已取消保存！")
                end
            else
                aegisub.debug.out("已取消！")
            end
        else
            aegisub.debug.out("不可打开空预设")
        end
    else
        aegisub.debug.out("已取消！")
    end
end

TLL_macros = {
	{
		script_name = "边框v1.1",
		script_description = "边框",
		entry = function(subs,sel) border(subs,sel) end,
		validation = false
    },
}

for i = 1, #TLL_macros do
	aegisub.register_macro(script_name.." "..script_version.."/"..TLL_macros[i]["script_name"], TLL_macros[i]["script_description"], TLL_macros[i]["entry"], TLL_macros[i]["validation"])
end