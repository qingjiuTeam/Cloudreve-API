require "import"
import"java.io.File"

-- local Http = require("func.tool.Http")
local appinit = require("res.config.appinit")
local data = require("func.tool.data")
local encrypt = require("func.tool.encrypt")
local _M = {}

local function succode(code)
  return code == 200
end

function _M.succode(code)
  switch code
   case 200
    return true
   default
    -- print("链接错误:"..code)
  end

end

local folder_pathtext
function _M.setPathText(str_a)
  folder_pathtext = str_a
end

function _M.getNowpath(str)
  local datas = data.getData("cache_foldet_path")
  if not datas then
    datas = {}
    data.setData("cache_foldet_path", datas)
  end
  local path = table.concat(datas ,"/")
  if path == "" then
    path = "/"
    folder_pathtext.Text = path
   else
    path = "/"..path
    folder_pathtext.Text = path.."/"
    path = path..(str or "")
  end
  return path
end


function _M.toGetdata(t)
  local _data = {}
  for k,v in pairs(t) do
    table.insert(data,k.."="..tostring(v))
  end
  return table.concat(data,"&")
end


-- [[ 新建文件
--    参数:目录
--]]
function _M.addOffline(tourl, path, fun_c)
  local url = appinit.domainUrl.."/api/v3/aria2/url"
  local cookie = data.getData("user_cookie")
  local datas = {
    ["url"] = tourl,
    ["dst"] = path}
    
  Http.post(url, encrypt.json.encode(datas), cookie, function(code, body, cookie)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end)
end

--[[ 获取文件预览链接
-- 参数: 文件id
--]]
function _M.getPreviewUrl(ids, fun_c)
  local cookie = data.getData("user_cookie")
  local url = appinit.domainUrl.."/api/v3/file/preview/"..ids
  return url
end


--[[ 获得路径下的内容
--  参数: 路径名称, 回调
--]]
function _M.getDir(path, fun_c)
  local url = appinit.domainUrl.."/api/v3/directory"..(path and path or "/")
  local cookie = data.getData("user_cookie")
  Http.get(url, cookie, function(code, body)
    -- if code~=-1 and code>=200 and code<=400 then
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end

--[[ 获取简略内存
--   参数: 回调
--]]
function _M.briefStorage(fun_c)
  local url = appinit.domainUrl.."/api/v3/user/storage"
  local cookie = data.getData("user_cookie")
  Http.get(url, cookie, function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end

--[[ 获得上传策略
--   参数: 回调
inpath 自动获取
  path=%2F        (不填默认/)
  &size=37289999
  &name=bmob.lua
  &type=onedrive (默认onedrive"
--]]
function _M.getUploadmod(arr_info,fun_c)
  arr_info.type = arr_info.type or "onedrive"
  arr_info.path = arr_info.path or "/"
  -- arr_info.path = arr_info.path == "" or "/"

  if arr_info.inpath then
    local file = File(arr_info.inpath)
    arr_info.inpath = nil
    arr_info.size = file.length()
    arr_info.name = file.getName()
  end

  local url = appinit.domainUrl.."/api/v3/file/upload/credential?%s"
  local cookie = data.getData("user_cookie")
  Http.get( string.format(url,_M.toGetdata(arr_info) ), cookie, function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end

function _M.getUploadprogres(url,fun_c)
  -- local cookie = data.getData("user_cookie")
  Http.get(url, cookie, function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end



--[[
getUploadmod({
  inpath = "/sdcard/test/bigfile.txt",
  path = "/"
},function(code,body)
  print(dump(body))
end)
--]]



--[[ 获得下载链接(已登录的)
--   参数: 文件id,回调
--]]
function _M.getDownurl(str_fileid, fun_c)
  local url = appinit.domainUrl.."/api/v3/file/download/"..str_fileid
  local head = {
    ["cookie"] = data.getData("user_cookie")}
  Http.put(url, "",head , function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end



--[[ 登录
--   参数: 账号, 密码, 回调
--]]
function _M.login(username, password, fun_c)
  local url = appinit.domainUrl.."/api/v3/user/session"
  local datas = {
    ["userName"] = username,
    ["Password"] = password,
    ["captchaCode"] = ""
  }
  Http.post(url, encrypt.json.encode(datas), function(code, body, cookie)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body, cookie)
  end)
end

--[[ 退出登录
--   参数: 回调
--]]
function _M.logout(fun_c)
  local url = appinit.domainUrl.."/api/v3/user/session"
  local cookie = data.getData("user_cookie")
  Http.delete(url, cookie, function(code, body, cookie)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end


--[[ 获取我的分享
--   参数:页码, 查询方式(参见下), 排序(参见下), 回调
created_at 创建日期
DESC 最新到最旧
ASC  最旧到最新


downloads 下载次数
DESC 多到少
ASC 少到多

views 浏览次数
DESC 多到少
ASC 少到多
--]]
function _M.getMyshare(void_page, str_other, str_sort, fun_c)
  local _data = toGetdata({
    ["page"] = void_page or "1",
    ["order_by"] = str_orther or "created_at",
    ["order"] = str_sort or "DESC"
  })
  local url = appinit.domainUrl.."/api/v3/share?".._data
  local cookie = data.getData("user_cookie")
  Http.get(url, cookie, function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end



--[[ 删除文件
--   参数: 文件列表[id]/文件夹列表[id]
--]]
function _M.deleteFile(arr , fun_c)
  local _data = "{"..
  [["items":]] .. string.format("[\"%s\"]",table.concat(arr.file or {}, "\",\""))..","..
  [["dirs":]] .. string.format("[\"%s\"]",table.concat(arr.dir or {}, "\",\"")).."}"
  local url = appinit.domainUrl.."/api/v3/object"
  local cookie = data.getData("user_cookie")
  local cbk = function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end
  local httpTask = Http.HttpTask(url, "DELETE", cookie, nil, nil, cbk);
  httpTask.execute{_data}
end



-- [[ 新建文件
--    参数:目录
--]]
function _M.newFile(path,fun_c)
  local url = appinit.domainUrl.."/api/v3/file/create"
  local cookie = data.getData("user_cookie")
  local datas = {
    ["path"] = path}
  Http.post(url, encrypt.json.encode(datas), cookie, function(code, body, cookie)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end)
end


--[[ 新建文件夹
--   参数:目录
--]]
function _M.newDir(path,fun_c)
  local url = appinit.domainUrl.."/api/v3/directory"
  local datas = {
    ["path"] = path}
  local head = {
    ["cookie"] = data.getData("user_cookie")}
  Http.put(url, encrypt.json.encode(datas) ,head , function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end)
end

--[[ 小文件上传
   参数 arr_info:
         inpath 必填 文件路径
         path   上传路径 默认/
         name   文件名称 选填
--]]
function _M.littleUpload(url, arr_info, fun_c)
  local file = File(arr_info.inpath)
  --arr_info.size = file.length()
  arr_info.name = file.getName()

  local head = {
    ["X-Path"] = arr_info.path or "/",
    ["X-FileName"] = arr_info.name
  }
  local body = io.open(arr_info.inpath):read("*a")
  local cookie = data.getData("user_cookie")
  local url = appinit.domainUrl..(url or "/api/v3/file/upload")
  local cbk = function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end

  local httpTask = Http.HttpTask(url, "POST", cookie, nil, head, cbk);
  httpTask.execute{file}
end




--[[
&name=    -- 文件名
&chunk=   -- 当前块 从0起
&chunks=  -- 总块
--]]
function _M.blockUpload(arr_info, fun_c)
  local head = arr_info.head
  local file = File(tostring(arr_info.path))
  local url = arr_info.url
  local cbk = function(code, body)
    if succode(code) then
      body2 = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body2, body)
    end
  end

  local httpTask = Http.HttpTask(url, "PUT", nil, nil, head, cbk);
  httpTask.execute{file}
end


--[[ 上传完毕 
     参数 data.token bodydata callback
--]]
function _M.okUpload(url, content, fun_c)
  local cookie = data.getData("user_cookie")
  Http.post(url, content, cookie,
  function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end)
end

--[[ 新建文件
--    参数:目录
--]]
function _M.renameFile(arr, fun_c)
  local url = appinit.domainUrl.."/api/v3/object/rename"
  local cookie = data.getData("user_cookie")
  local datas = encrypt.json.encode({
    ["action"] = "rename",
    ["src"] = {
      ["dirs"] = {arr.dir or "==="},
      ["items"] = {arr.file or "==="},
    },
    ["new_name"] = arr.name
  })
  Http.post(url, datas:gsub([["==="]],"") , cookie, function(code, body, cookie)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end)
end

--[[ 分享文件
--    参数:table 回调
table:
id ： 文件夹id string
dir ： 是否文件夹 boolean
password ： 密码 string 留空为无
endtime ： 到期时间 number s
score ： 积分 number
downs ： 限制下载  -1为不限
canview ： 可预览   boolean
--]]
function _M.shareFile(arr, fun_c)
  local url = appinit.domainUrl.."/api/v3/share"
  local cookie = data.getData("user_cookie")
  local datas = encrypt.json.encode(arr)
  --[[{
    ["id"] = arr.id, -- 文件id
    ["is_dir"] = arr.dir, -- 是否文件夹
    ["password"] = arr.password, -- 密码
    ["downloads"] = arr.downs, -- 下载次数限制
    ["expire"] = arr.time, -- 到期时间
    ["score"] = arr.score, -- 下载积分
    ["preview"] = arr.canview -- 可否预览
  })]]
  Http.post(url, datas, cookie, function(code, body, cookie)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    if fun_c then
      fun_c(code, body)
    end
  end)
end


function _M.userInfo(fun_c)
  local url = appinit.domainUrl.."/api/v3/user/me"--..data
  local cookie = data.getData("user_cookie")
  Http.get(url, cookie, function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end



function _M.getUserhead(ids, bak)
  local headicon = {
    ["l"] = appinit.domainUrl.."/api/v3/user/avatar/"..ids.."/l",
    ["s"] = appinit.domainUrl.."/api/v3/user/avatar/"..ids.."/s",
  }

  thread(function(fun_c,urls)
    require("import")
    local urls = luajava.astable(urls)
    LuaBitmap.setCacheTime(-1)

    if pcall(function() -- l尺
        local bit = loadbitmap(urls.l)
        fun_c(bit)

      end) then

     elseif pcall(function() -- s尺
        local bit = loadbitmap(urls.s)
        fun_c(bit)

      end) then

     else
      local bit = loadbitmap(activity.getLuaDir().."/res/drawable/icon/defhead.jpg")
      fun_c(bit)

    end

  end, bak, headicon)
end


function _M.getSettingList(fun_c)
  local url = appinit.domainUrl.."/api/v3/user/setting"
  local cookie = data.getData("user_cookie")
  Http.get(url, cookie, function(code, body)
    -- if code~=-1 and code>=200 and code<=400 then
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end)
end


function _M.setPolicy(ids, fun_c)
  local url = appinit.domainUrl.."/api/v3/user/setting/policy"
  local cookie = data.getData("user_cookie")
  local data = encrypt.json.encode({id=ids})

  local cbk = function(code, body)
    if succode(code) then
      body = encrypt.json.decode(body)
    end
    fun_c(code, body)
  end
  local httpTask = Http.HttpTask(url, "PATCH", cookie, nil, nil, cbk);
  httpTask.execute{data}
end


return _M



--[[
fun_c = function(code,body)
  print(dump(body))
end

local data = toGetdata({
  ["page"] = void_page or "1",
  ["order_by"] = str_orther or "created_at",
  ["order"] = str_sort or "DESC",
  ["keywords"] = "supper",
})
-- https://cloud.qingstore.cn/share/search?page=1&order_by=&order=&keywords=你好
local url = appinit.domainUrl.."/api/v3/user/me"--..data
local cookie = data.getData("user_cookie")
Http.get(url, cookie, function(code, body)
  print(code)
  if code~=-1 and code>=200 and code<=400 then
    body = encrypt.json.decode(body)
  end
  fun_c(code, body)
end)
--]]
