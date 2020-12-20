-- MIT License
--
-- Copyright (c) Geert Eikelboom, Mark Lagendijk
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
-- Original script by Geert Eikelboom
-- Generalized and released on GitHub (with permission of Geert) by Mark Lagendijk

obs = obslua
settings = {}




-- Script hook for defining the script description
function script_description()
local description = [[
<center><h2>Execute a CLI command whenever a scene is activated.</h2></center>
<br>
When specifying the command 'SCENE_VALUE' can be used to denote the 'value' that was entered for the scene.<br>
<br>
Example:<br>
When command is<br>
    curl -X POST http://192.168.1.123/load-preset -d "preset=SCENE_VALUE"<br>
<br>
And Scene 1 value is<br>
    5<br>
<br>
Activating Scene 1 would execute:<br>
    curl -X POST http://192.168.1.123/load-preset -d "preset=5"<br>
<p>See <a href="https://github.com/marklagendijk/obs-scene-execute-command-script/">https://github.com/marklagendijk/obs-scene-execute-command-script/</a> for further documentation and examples.
<hr/></p>]]
	return description
end

-- Script hook for defining the settings that can be configured for the script
function script_properties()
	local props = obs.obs_properties_create()
	-- Live
	obs.obs_properties_add_text(props, "command", "Command", obs.OBS_TEXT_DEFAULT)
	-- Preview
	obs.obs_properties_add_text(props, "Preview_command", "<p>Preview Command<hr/></p>", obs.OBS_TEXT_DEFAULT)
	
	local scenes = obs.obs_frontend_get_scenes()
	obs.obs_properties_add_int_slider(props, "N/A", "<p>Live Scene Settings:<hr/></p>", 0,0,0)
	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			local scene_name = obs.obs_source_get_name(scene)
			-- Live
			obs.obs_properties_add_bool(props, "scene_enabled_" .. scene_name, "Execute when '" .. scene_name .. "' is activated")
			obs.obs_properties_add_bool(props, "scene_inacktiv_enabled_".. scene_name, "Execute when '" .. scene_name .. "' is Deactivated")
			obs.obs_properties_add_text(props, "scene_value_" .. scene_name, scene_name .. " value", obs.OBS_TEXT_DEFAULT)
		end
	end	
	    --obs.obs_properties_add_text(props, "N/A", "<p><hr/><br>Preview Settings<hr/></p>", obs.OBS_TEXT_DEFAULT)
	    obs.obs_properties_add_int_slider(props, "N/A2", "<p>Preview Scene Settings:<hr/></p>", 0,0,0)
	
	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			local scene_name = obs.obs_source_get_name(scene)
			-- Preview
			obs.obs_properties_add_bool(props, "Preview_scene_enabled_" .. scene_name, "Execute when '" .. scene_name .. "' is activated")
			obs.obs_properties_add_bool(props, "Preview_scene_inacktiv_enabled_".. scene_name, "Execute when '" .. scene_name .. "' is Deactivated")
			obs.obs_properties_add_text(props, "Preview_scene_value_" .. scene_name,"Preview ".. scene_name .. " value", obs.OBS_TEXT_DEFAULT)
		end	
	end
	
	--Set last scene to current scene when loading script
	
	obs.source_list_release(scenes)
	
	
	return props
end

-- Script hook that is called whenver the script settings change
function script_update(_settings)	
	settings = _settings
end

-- Script hook that is called when the script is loaded
last_scene = ""
preview_last_scene = ""

function script_load(settings)
	obs.obs_frontend_add_event_callback(handle_event)
	
	------------------------------------------------------------------------------
	-- Set starting value of remember last
	
	--obs.obs_properties_set_param(props,new_last_scene,obs.obs_frontend_get_current_scene())
	--local scene_name = "A"--obs.obs_properties_get_param(new_last_scene)
	local scene = obs.obs_frontend_get_current_scene()
	last_scene = obs.obs_source_get_name(scene)
	--obs.script_log(obs.LOG_INFO, "Starting Scene: \n" .. last_scene .. " ")
	
	-- Preview
    
	local scene = obs.obs_frontend_get_current_preview_scene()
	preview_last_scene = obs.obs_source_get_name(scene)
	obs.script_log(obs.LOG_INFO, "\nStarting Scene: \nLive: " .. last_scene .. " \nPreview: " .. preview_last_scene)
end

function handle_event(event)
	-- Live changed
	if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
		handle_scene_change()	
	end
	-- Prewiew Changed
	if event == obs.OBS_FRONTEND_EVENT_PREVIEW_SCENE_CHANGED then
		handle_scene_change_Preview()	
	end
end

--last_scene = obs.obs_frontend_get_current_scene()


function handle_scene_change()
    -- Live
	local scene = obs.obs_frontend_get_current_scene()
	local scene_name = obs.obs_source_get_name(scene)
	local scene_enabled = obs.obs_data_get_bool(settings, "scene_enabled_" .. scene_name)
	
	if scene_enabled then
		local command = obs.obs_data_get_string(settings, "command")
		local scene_value = obs.obs_data_get_string(settings, "scene_value_" .. scene_name)
		local scene_command = string.gsub(command, "SCENE_VALUE", scene_value)
		obs.script_log(obs.LOG_INFO, "\nActivating " .. scene_name .. ". Executing command:\n  " .. scene_command .. " Last Scene:" .. last_scene)
		os.execute(scene_command)
	else
		obs.script_log(obs.LOG_INFO, "\nActivating " .. scene_name .. ". Command execution is disabled for this scene.".. " Last Scene:" .. last_scene)
	end
	-- Inactive tests
	local scene_inactiv_enabled = obs.obs_data_get_bool(settings, "scene_inacktiv_enabled_" .. last_scene)
	if scene_inactiv_enabled then
		local command = obs.obs_data_get_string(settings, "Preview_command")
		local scene_value = obs.obs_data_get_string(settings, "Preview_scene_value_" .. last_scene)
		local scene_command = string.gsub(command, "SCENE_VALUE", scene_value)
		obs.script_log(obs.LOG_INFO, "\nActivating Deactivation " .. last_scene .. ". Executing command:\n  " .. scene_command)
		os.execute(scene_command)
	else
		obs.script_log(obs.LOG_INFO, "\nActivating Deactivation " .. last_scene .. ". Command execution is disabled for this scene.")
	end
	last_scene = scene_name
	obs.obs_source_release(scene);
end







function handle_scene_change_Preview()
    -- Preview
	local scene = obs.obs_frontend_get_current_preview_scene()
	local scene_name = obs.obs_source_get_name(scene)
	local scene_enabled = obs.obs_data_get_bool(settings, "Preview_scene_enabled_" .. scene_name)
	
	if scene_enabled then
		local command = obs.obs_data_get_string(settings, "Preview_command")
		local scene_value = obs.obs_data_get_string(settings, "Preview_scene_value_" .. scene_name)
		local scene_command = string.gsub(command, "SCENE_VALUE", scene_value)
		obs.script_log(obs.LOG_INFO, "\nActivating Preview " .. scene_name .. ". Executing command:\n  " .. scene_command.. " \nLast Scene:" .. preview_last_scene)
		os.execute(scene_command)
	else
		obs.script_log(obs.LOG_INFO, "\nActivating Preview " .. scene_name .. ". Command execution is disabled for this scene.".. " \nLast Scene:" .. preview_last_scene)
	end
	-- Inactive tests
	local scene_inactiv_enabled = obs.obs_data_get_bool(settings, "Preview_scene_inacktiv_enabled_" .. preview_last_scene)
	if scene_inactiv_enabled then
		local command = obs.obs_data_get_string(settings, "Preview_command")
		local scene_value = obs.obs_data_get_string(settings, "Preview_scene_value_" .. preview_last_scene)
		local scene_command = string.gsub(command, "SCENE_VALUE", scene_value)
		obs.script_log(obs.LOG_INFO, "\nActivating Deactivation " .. preview_last_scene .. ". Executing command:\n  " .. scene_command)
		os.execute(scene_command)
	else
		obs.script_log(obs.LOG_INFO, "\nActivating Deactivation " .. preview_last_scene .. ". Command execution is disabled for this scene.")
	end
	preview_last_scene = scene_name
	obs.obs_source_release(scene);
end
