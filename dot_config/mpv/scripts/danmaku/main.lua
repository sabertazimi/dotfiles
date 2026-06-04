-- https://github.com/itKelis/MPV-Play-BiliBili-Comments

local mp = require("mp")
local utils = require("mp.utils")
local options = require("mp.options")

local o = {
	--是否自动显示弹幕
	autoplay = true,
	--最小弹幕数量
	mincount = 1,
	--弹幕字体
	fontname = "sans-serif",
	--弹幕字体大小
	fontsize = "36",
	--弹幕不透明度(0-1)
	opacity = "0.25",
	--滚动弹幕显示的持续时间 (秒)
	duration_marquee = "10",
	--静止弹幕显示的持续时间 (秒)
	duration_still = "5",
	--保留底部多少高度的空白区域 (取值0.0-1.0)
	percent = "0.75",
	--弹幕屏蔽的关键词文件路径，支持绝对和相对路径
	filter_file = "",
	--是否对低帧率视频自动添加fps滤镜，以保证滚动弹幕流畅
	fps_vf = true,
	--是否在osd显示日志
	log_osd = false,
	-- python可执行文件路径，默认为环境变量的python，若无法运行请指定 python 的路径
	python_path = "python",
}

options.read_options(o)

local danmaku_file = nil
local danmaku_open = false
local sec_sub_visibility = mp.get_property_native("secondary-sub-visibility")
local sec_sub_ass_override = mp.get_property_native("secondary-sub-ass-override")

local function get_cid()
	local cid, danmaku_id = nil, nil
	local tracks = mp.get_property_native("track-list")
	for _, track in ipairs(tracks) do
		if track["lang"] == "danmaku" then
			cid = track["external-filename"]:match("/(%d-)%.xml$")
			danmaku_id = track["id"]
			break
		end
	end
	return cid, danmaku_id
end

local function get_sub_count()
	local count = 0
	local tracks = mp.get_property_native("track-list")
	for _, track in ipairs(tracks) do
		if track["type"] == "sub" then
			count = count + 1
		end
	end
	return count
end

local function file_exists(path)
	if path then
		local meta = utils.file_info(path)
		return meta and meta.is_file
	end
	return false
end

local function log(msg, secs)
	mp.msg.info(msg)

	if o.log_osd then
		secs = secs or 2.5
		mp.osd_message(msg, secs)
	end
end

local function add_fps_vf()
	if not danmaku_open or not o.fps_vf then
		return
	end

	local video_fps = mp.get_property_number("container-fps", 30)
	local video_speed = mp.get_property_number("speed", 1)

	if video_fps < 45 and video_speed < 1.5 then
		mp.commandv("vf", "append", '@Danmaku-FPS:lavfi="fps=fps=60:round=down"')
	else
		mp.commandv("vf", "remove", "@Danmaku-FPS")
	end
end

local function danmaku_show()
	log("显示弹幕")
	danmaku_open = true
	mp.set_property_native("secondary-sub-visibility", true)
	add_fps_vf()
end

local function danmaku_unshow()
	log("隐藏弹幕")
	danmaku_open = false
	mp.set_property_native("secondary-sub-visibility", false)
	mp.commandv("vf", "remove", "@Danmaku-FPS")
end

local function load_danmaku(file)
	if not file_exists(file) then
		return
	end
	mp.set_property_native("secondary-sub-visibility", false)
	mp.set_property_native("secondary-sub-ass-override", false)
	mp.commandv("sub-add", file, "auto")
	local sub_count = get_sub_count()
	mp.set_property_native("secondary-sid", sub_count)
	local approximated_count = math.floor((utils.file_info(file)["size"] - 850) / 120)
	log(file .. " [" .. utils.file_info(file)["size"] .. "][" .. approximated_count .. "]")
	if o.autoplay and approximated_count >= o.mincount then
		danmaku_show()
	end
end

local function danmaku_process(cid)
	if cid == nil then
		return
	end

	local danmaku_dir = os.getenv("TEMP") or "/tmp/"
	local directory = mp.get_script_directory()
	local py_path = utils.join_path(directory, "danmaku2ass.py")

	local dw = 1920
	local dh = 1080
	local aspect = mp.get_property_number("width", 16) / mp.get_property_number("height", 9)
	if aspect > dw / dh then
		dh = math.floor(dw / aspect)
	elseif aspect < dw / dh then
		dw = math.floor(dh * aspect)
	end
	local arg = {
		o.python_path,
		py_path,
		"-d",
		danmaku_dir,
		"-s",
		"" .. dw .. "x" .. dh,
		"-fn",
		o.fontname,
		"-fs",
		o.fontsize,
		"-a",
		o.opacity,
		"-dm",
		o.duration_marquee,
		"-ds",
		o.duration_still,
		"-flf",
		mp.command_native({ "expand-path", o.filter_file }),
		"-p",
		tostring(math.floor(o.percent * dh)),
		"-r",
		cid,
	}

	mp.command_native_async({
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		args = arg,
	}, function(res, val, err)
		if err == nil then
			danmaku_file = utils.join_path(danmaku_dir, "bilibili.ass")
			load_danmaku(danmaku_file)
		else
			log("处理错误: " .. err)
		end
	end)
end

local function danmaku_check()
	local cid = mp.get_opt("cid")

	if cid == nil then
		local path = mp.get_property("path")
		if
			path
			and not path:find("^%a[%w.+-]-://")
			and not (path:find("bilibili.com") or path:find("bilivideo.com"))
		then
			return
		end

		local danmaku_id = nil
		cid, danmaku_id = get_cid()

		if danmaku_id ~= nil then
			mp.commandv("sub-remove", danmaku_id)
		end
	end

	mp.set_property_native("sid", false)

	danmaku_process(cid)
end

local function danmaku_toggle()
	if not danmaku_file then
		return
	end

	if danmaku_open then
		danmaku_unshow()
	elseif mp.get_property_native("secondary-sid") then
		danmaku_show()
	end
end

local function danmaku_terminate()
	if not danmaku_file then
		return
	end
	log("文件结束")
	if file_exists(danmaku_file) then
		os.remove(danmaku_file)
	end
	danmaku_file = nil
	danmaku_open = false
	mp.set_property_native("secondary-sub-visibility", sec_sub_visibility)
	mp.set_property_native("secondary-sub-ass-override", sec_sub_ass_override)
	mp.commandv("vf", "remove", "@Danmaku-FPS")
end

mp.register_event("file-loaded", danmaku_check)
mp.register_event("end-file", danmaku_terminate)
mp.observe_property("speed", nil, add_fps_vf)

mp.register_script_message("load-danmaku", danmaku_process)
mp.add_key_binding("b", "toggle", danmaku_toggle)
