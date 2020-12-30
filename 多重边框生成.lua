-- 功能：
--     覆盖原有行边框，生成指定多重边框字幕
-- 注意：
--     1.多重边框情况下不支持设置透明边框（暂时将原来计划的透明度效果去除）
--     2.会将原有行注释，生成新行代替原有字幕



local tr = aegisub.gettext
script_name = tr("边框")
script_description = tr("边框")
script_author = "拉姆0v0"
script_version = "v1.0"

include("karaskel.lua")
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

dialog_config1=
{
    [1]={class="label",x=0,y=0,label="多重边框层数："},
    [2]={class="intedit",name="border_num",x=1,y=0,width=1,height=1,value="1",hint="请输入整数"},
}


local conf_template ={
    [1]='{class="label",x=0,y=%s,label="【第%s层】"}',
    [2]='{class="label",x=1,y=%s,label="颜色："}',
    [3]='{class="color",name="ca_%s",x=2,y=%s,width=1,height=1,value="HFFFFFF"}',
    [4]='{class="label",x=3,y=%s,label="厚度："}',
    [5]='{class="edit",name="houdu_%s",x=4,y=%s,width=1,height=1,value="1"}',
} 

local tags_template = "{\\pos(%s,%s)\\bord%s\\shad0\\3c&%s&\\3a&%s&}"

function border(subs,sel)
    -- 初始化层数
    buttons1,results1 = aegisub.dialog.display(dialog_config1,{"OK","Cancel"})
    if buttons1 == "OK" then
        local border_num = results1["border_num"]
        if border_num > 0  then
            -- 主体
            -- 生成dialog
            local dialog_config2={}
            for i = 1, border_num do
                dialog_config2[(i-1)*5+1] = unserialize(conf_template[1]:format(i-1, i))
                dialog_config2[(i-1)*5+2] = unserialize(conf_template[2]:format(i-1))
                dialog_config2[(i-1)*5+3] = unserialize(conf_template[3]:format(i, i-1))
                dialog_config2[(i-1)*5+4] = unserialize(conf_template[4]:format(i-1))
                dialog_config2[(i-1)*5+5] = unserialize(conf_template[5]:format(i, i-1))
            end
            buttons2,results2 =aegisub.dialog.display(dialog_config2,{"OK","Cancel"})
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
                        local text = tags_template:format(pos_x, pos_y, bord, border_data[j].color, border_data[j].alpha)..l.text:gsub("{[^}]+}", "")
                        l.layer = #border_data-j+1
                        l.text = text
                        subs.append(l)
                    end
                    simple_l.comment = true
                    subs[sel[i]] = simple_l
                end
            else
                aegisub.debug.out("已取消！")
            end
        else
            aegisub.debug.out("层数应大于0！")
        end
    else
        aegisub.debug.out("已取消！")
    end
end

TLL_macros = {
	{
		script_name = "边框",
		script_description = "边框",
		entry = function(subs,sel) border(subs,sel) end,
		validation = false
    },
}

for i = 1, #TLL_macros do
	aegisub.register_macro(script_name.." "..script_version.."/"..TLL_macros[i]["script_name"], TLL_macros[i]["script_description"], TLL_macros[i]["entry"], TLL_macros[i]["validation"])
end