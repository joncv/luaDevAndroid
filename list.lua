--
-- Created by IntelliJ IDEA.  Copyright (C) 2017 Hanks
-- User: hanks
-- Date: 2017/5/26
--
require "import"
import "android.widget.*"
import "android.content.*"
import "android.view.View"
import "androlua.LuaHttp"
import "androlua.LuaAdapter"
import "androlua.LuaImageLoader"

local JSON = require("cjson")
local uihelper = require('uihelper')

-- create view table
local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    {
        ListView,
        id = "listview",
        dividerHeight = 0,
        layout_width = "fill",
        layout_height = "fill",
    },
}

local item_view = {
    FrameLayout,
    layout_width = "fill",
    layout_height = "240dp",
    {
        ImageView,
        id = "iv_image",
        layout_width = "fill",
        layout_height = "fill",
        scaleType = "centerCrop",
    },
    {
        TextView,
        id = "tv_title",
        background = "#66000000",
        layout_width = "fill",
        layout_height = "fill",
        padding = "32dp",
        gravity = "center",
        maxLines = "5",
        lineSpacingMultiplier = '1.2',
        textSize = "14sp",
        textColor = "#CCFFFFFF",
    },
}


local data = {
    dailyList = {}
}
local adapter

local function getData()
    -- http://baobab.kaiyanapp.com/api/v1/feed
    local url = data.nextPageUrl
    if url == nil then url = 'http://baobab.kaiyanapp.com/api/v1/feed?udid=3e7ee30c6fc0004a773dc33b0597b5732b145c04' end
    if url:find('udid=') == nil then url = url .. '&udid=3e7ee30c6fc0004a773dc33b0597b5732b145c04' end
    print(url)
    LuaHttp.request({ url = url }, function(error, code, body)
        if error or code ~= 200 then
            print('fetch data error')
            return
        end
        local str = JSON.decode(body)
        uihelper.runOnUiThread(activity, function()
            data.nextPageUrl = str.nextPageUrl
            local list = str.dailyList[1].videoList
            for i = 1, #list do
                data.dailyList[#data.dailyList + 1] = list[i]
            end
            adapter.notifyDataSetChanged()
        end)
    end)
end

local function launchDetail(item)
    Toast.makeText(activity, item.title, 0).show()
end

function getView()
    local view = loadlayout(layout)
    adapter = LuaAdapter(luajava.createProxy("androlua.LuaAdapter$AdapterCreator", {
        getCount = function() return #data.dailyList end,
        getItem = function(position) return nil end,
        getItemId = function(position) return position end,
        getView = function(position, convertView, parent)
            position = position + 1 -- lua 索引从 1开始
            if position == #data.dailyList then
                getData()
            end
            if convertView == nil then
                local views = {} -- store views
                convertView = loadlayout(item_view, views, ListView)
                if parent then
                    local params = convertView.getLayoutParams()
                    params.width = parent.getWidth()
                end
                convertView.setTag(views)
            end
            local views = convertView.getTag()
            local item = data.dailyList[position]
            if item then
                LuaImageLoader.load(views.iv_image, item.coverForFeed)
                views.tv_title.setText(item.title)
            end
            return convertView
        end
    }))
    listview.setAdapter(adapter)
    listview.setOnItemClickListener(luajava.createProxy("android.widget.AdapterView$OnItemClickListener", {
        onItemClick = function(adapter, view, position, id)
            launchDetail(data.dailyList[position + 1])
        end,
    }))
    getData()
    return view
end
