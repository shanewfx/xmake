--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        clang.lua
--

-- load modules
local utils     = require("base/utils")
local table     = require("base/table")
local string    = require("base/string")
local config    = require("base/config")

-- define module: clang
local clang = clang or {}

-- check the given flag 
function clang._check(flag)

    -- this flag has been checked?
    clang._CHECK = clang._CHECK or {}
    if clang._CHECK[flag] then
        return clang._CHECK[flag]
    end

    -- check it
    if 0 ~= os.execute(string.format("%s %s -S -o %s -xc %s > %s 2>&1", clang.name, flag, xmake._NULDEV, xmake._NULDEV, xmake._NULDEV)) then
        flag = ""
    end

    -- save it
    clang._CHECK[flag] = flag

    -- ok?
    return flag
end

-- the init function
function clang.init(name)

    -- save name
    clang.name = name or "clang"

    -- the architecture
    local arch = config.get("arch")
    assert(arch)

    -- init flags for architecture
    local flags_arch = ""
    if arch == "x86" then flags_arch = "-m32"
    elseif arch == "x64" then flags_arch = "-m64"
    else flags_arch = "-arch " .. arch
    end

    -- init cxflags
    clang.cxflags = { flags_arch }

    -- init mxflags
    clang.mxflags = {   flags_arch
                    ,   "-fmessage-length=0"
                    ,   "-pipe"
                    ,   "-fpascal-strings"
                    ,   "\"-DIBOutlet=__attribute__((iboutlet))\""
                    ,   "\"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))\""
                    ,   "\"-DIBAction=void)__attribute__((ibaction)\""}

    -- init asflags
    clang.asflags = { flags_arch } 

    -- init ldflags
    clang.ldflags = { flags_arch }

    -- init shflags
    clang.shflags = { flags_arch, "-dynamiclib" }

    -- suppress warning for the ccache bug
    if config.get("ccache") then
        table.join2(clang.cxflags, "-Qunused-arguments")
        table.join2(clang.mxflags, "-Qunused-arguments")
    end

    -- init flags map
    clang.mapflags = 
    {
        -- others
        ["-ftrapv"]                     = clang._check
    ,   ["-fsanitize=address"]          = clang._check
    }

end

-- make the compile command
function clang.command_compile(srcfile, objfile, flags)

    -- make it
    return string.format("%s -c %s -o%s %s", clang.name, flags, objfile, srcfile)
end

-- make the link command
function clang.command_link(objfiles, targetfile, flags)

    -- make it
    return string.format("%s %s -o%s %s", clang.name, flags, targetfile, objfiles)
end

-- make the define flag
function clang.flag_define(define)

    -- make it
    return "-D" .. define
end

-- make the undefine flag
function clang.flag_undefine(undefine)

    -- make it
    return "-U" .. undefine
end

-- make the includedir flag
function clang.flag_includedir(includedir)

    -- make it
    return "-I" .. includedir
end

-- make the link flag
function clang.flag_link(link)

    -- make it
    return "-l" .. link
end

-- make the linkdir flag
function clang.flag_linkdir(linkdir)

    -- make it
    return "-L" .. linkdir
end

-- the main function
function clang.main(cmd)

    -- execute it
    local ok = os.execute(cmd)

    -- ok?
    return utils.ifelse(ok == 0, true, false)
end

-- return module: clang
return clang