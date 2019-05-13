
include('shared.lua')

function ENT:Draw()
	self:DrawModel()
end

local DrawItems, DrawRecipes, DrawMainMenu

DrawItems = function( ent )
	local itemtable = {}
	local mainframe = vgui.Create( "DFrame" )
	mainframe:SetTitle( "Items currently on the table:" )
	mainframe:SetSize( 500, 500 )
	mainframe:Center()
	mainframe:MakePopup()
	mainframe.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_MENU_COLOR )
	end
	local backbutton = vgui.Create( "DButton", mainframe )
	backbutton:SetText( "Back" )
	backbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	backbutton:SetPos( 350, 3 )
	backbutton:SetSize( 50, 20 )
	backbutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	backbutton.DoClick = function()
		mainframe:Close()
		DrawMainMenu( ent )
		surface.PlaySound( CRAFT_CONFIG_UI_SOUND )
	end

	local mainframescroll = vgui.Create( "DScrollPanel", mainframe )
	mainframescroll:Dock( FILL )
	for k,v in pairs( CraftingTable ) do
		for a,b in pairs( v.Materials ) do
			if table.HasValue( itemtable, a ) then break end --Prevents two or more of the same materials from being listed if they are used in more than one recipe
			local scrollbutton = vgui.Create( "DButton", mainframescroll )
			if ent:GetNWInt( "Craft_"..a ) == nil then
				scrollbutton:SetText( a..": 0" )
			else
				scrollbutton:SetText( a..": "..ent:GetNWInt( "Craft_"..a ) )
			end
			scrollbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
			scrollbutton:Dock( TOP )
			scrollbutton:DockMargin( 0, 0, 0, 5 )
			scrollbutton.Paint = function( self, w, h )
				draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
			end
			scrollbutton.DoClick = function()
				if ent:GetNWInt( "Craft_"..a ) == nil or ent:GetNWInt( "Craft_"..a ) == 0 then
					surface.PlaySound( CRAFT_CONFIG_FAIL_SOUND )
					return
				end
				net.Start( "DropItem" )
				net.WriteEntity( ent )
				net.WriteString( a )
				net.SendToServer()
				timer.Simple( 0.3, function() --Small timer to let the net message go through
					mainframe:Close()
					DrawItems( ent )
				end )
			end
			table.insert( itemtable, a )
		end
	end
end

DrawRecipes = function( ent )
	local ply = LocalPlayer()
	local mainframe = vgui.Create( "DFrame" )
	mainframe:SetTitle( "Choose an item to craft:" )
	mainframe:SetSize( 500, 500 )
	mainframe:Center()
	mainframe:MakePopup()
	mainframe.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_MENU_COLOR )
	end
	local backbutton = vgui.Create( "DButton", mainframe )
	backbutton:SetText( "Back" )
	backbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	backbutton:SetPos( 350, 3 )
	backbutton:SetSize( 50, 20 )
	backbutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	backbutton.DoClick = function()
		mainframe:Close()
		DrawMainMenu( ent )
		surface.PlaySound( CRAFT_CONFIG_UI_SOUND )
	end
	local mainframescroll = vgui.Create( "DScrollPanel", mainframe )
	mainframescroll:Dock( FILL )
	for k,v in pairs( CraftingTable ) do
		local mainbuttons = vgui.Create( "DButton", mainframescroll )
		mainbuttons:SetText( v.Name )
		mainbuttons:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
		mainbuttons:Dock( TOP )
		mainbuttons:DockMargin( 0, 0, 0, 5 )
		mainbuttons.Paint = function( self, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
		end
		mainbuttons.DoClick = function()
			chat.AddText( Color( 100, 100, 255 ), "[Crafting Table]: ", Color( 100, 255, 100 ), "<"..v.Name.."> ", Color( 255, 255, 255 ), v.Description )
			ply.SelectedCraftingItem = tostring( k )
			ply.SelectedCraftingItemName = v.Name
			surface.PlaySound( CRAFT_CONFIG_SELECT_SOUND )
			mainframe:Close()
			DrawRecipes( ent ) --Refreshes the button so it shows the currently selected item
		end
	end
	local selectedbutton = vgui.Create( "DButton", mainframe )
	if ply.SelectedCraftingItemName then
		selectedbutton:SetText( "Currently Selected Item: "..ply.SelectedCraftingItemName )
	else
		selectedbutton:SetText( "Currently Selected Item: N/A" )
	end
	selectedbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	selectedbutton:SetPos( 5, 465 )
	selectedbutton:SetSize( 245, 30 )
	selectedbutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	local craftbutton = vgui.Create( "DButton", mainframe )
	craftbutton:SetText( "Craft Selected Item" )
	craftbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	craftbutton:Dock( BOTTOM )
	craftbutton:DockMargin( 250, 0, 0, 0 )
	craftbutton:SetSize( 245, 30 )
	craftbutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	craftbutton.DoClick = function()
		if !ply.SelectedCraftingItem then
			chat.AddText( Color( 100, 100, 255 ), "[Crafting Table]: ", Color( 255, 255, 255 ), "Please select an item to craft." )
			surface.PlaySound( CRAFT_CONFIG_FAIL_SOUND )
			return
		end
		net.Start( "StartCrafting" )
		net.WriteEntity( ent )
		net.WriteString( ply.SelectedCraftingItem )
		net.WriteString( ply.SelectedCraftingItemName )
		net.SendToServer()
		mainframe:Close()
		ply.SelectedCraftingItem = nil
		ply.SelectedCraftingItemName = nil
	end
end

DrawMainMenu = function( ent )
	local mainframe = vgui.Create( "DFrame" )
	mainframe:SetTitle( "Crafting Table - Main Menu" )
	mainframe:SetSize( 500, 300 )
	mainframe:Center()
	mainframe:MakePopup()
	mainframe.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_MENU_COLOR )
	end
	local recipesbutton = vgui.Create( "DButton", mainframe )
	recipesbutton:SetText( "View Recipes/Craft an Item" )
	recipesbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	recipesbutton:SetPos( 25, 50 )
	recipesbutton:SetSize( 250, 30 )
	recipesbutton:CenterHorizontal()
	recipesbutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	recipesbutton.DoClick = function()
		DrawRecipes( ent )
		mainframe:Close()
		surface.PlaySound( CRAFT_CONFIG_UI_SOUND )
    end
	local itemsbutton = vgui.Create( "DButton", mainframe )
	itemsbutton:SetText( "View Items Currently on the Table" )
	itemsbutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	itemsbutton:SetPos( 25, 100 )
	itemsbutton:SetSize( 250, 30 )
	itemsbutton:CenterHorizontal()
	itemsbutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	itemsbutton.DoClick = function()
		DrawItems( ent )
		mainframe:Close()
		surface.PlaySound( CRAFT_CONFIG_UI_SOUND )
	end
	local closebutton = vgui.Create( "DButton", mainframe )
	closebutton:SetText( "Exit Table" )
	closebutton:SetTextColor( CRAFT_CONFIG_BUTTON_TEXT_COLOR )
	closebutton:SetPos( 25, 150 )
	closebutton:SetSize( 150, 15 )
	closebutton:CenterHorizontal()
	closebutton.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, CRAFT_CONFIG_BUTTON_COLOR )
	end
	closebutton.DoClick = function()
		mainframe:Close()
		surface.PlaySound( CRAFT_CONFIG_UI_SOUND )
	end
end

net.Receive( "CraftingTableMenu", function( len, ply ) --Receiving the net message to open the main crafting table menu
	local ent = net.ReadEntity()
	DrawMainMenu( ent )
end )

net.Receive( "CraftMessage", function( len, ply ) --Have to network the entname into here since the client can't see it serverside
	local validfunction = net.ReadBool()
	local entname = net.ReadString()
	if validfunction then
		chat.AddText( Color( 100, 100, 255 ), "[Crafting Table]: ", Color( 255, 255, 255 ), "Successfully crafted a "..entname.." ." )
	else
		chat.AddText( Color( 100, 100, 255 ), "[Crafting Table]: ", Color( 255, 255, 255 ), "ERROR! Missing SpawnFunction for "..entname.." ("..ent..")" )
	end
end )