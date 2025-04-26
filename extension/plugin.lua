function init(plugin)
    print("Aseprite is initializing AtlasMaker")

    if plugin.preferences == nil then
        plugin.preferences = {
            hideConfirm = false
        }
    end
  
		plugin:newMenuSeparator{
				group="sprite_crop"
		}
	
    plugin:newCommand {
        id="atlasmaker",
        title="AtlasMaker...",
        group="sprite_crop",
        onclick=function()
            local executable = app.fs.joinPath(app.fs.userConfigPath, "extensions", "atlasmaker", "atlasmaker.lua")
            loadfile(executable)(plugin.preferences)
        end
    }
end
  
function exit(plugin)
    print("Aseprite is closing AtlasMaker")
end