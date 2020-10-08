
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:SpawnFunction( ply, tr, name )
	if !tr.Hit then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 50
	local ent = ents.Create( name )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
    self:SetModel( GetConVar( "Craft_Config_Model" ):GetString() )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetHealth( GetConVar( "Craft_Config_MaxHealth" ):GetInt() )
	self:SetMaxHealth( GetConVar( "Craft_Config_MaxHealth" ):GetInt() )
	self:SetTrigger( true )
	self:SetColor( CRAFT_CONFIG_COLOR )

	if GetConVar( "Craft_Config_Material" ):GetString() != "" then
		self:SetMaterial( GetConVar( "Craft_Config_Material" ):GetString() )
	end
	
    local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end
	hook.Call( "Craft_OnSpawn", nil, self )
end

util.AddNetworkString( "CraftingTableMenu" )
function ENT:Use( activator, caller )
	local canuse = hook.Call( "Craft_OnUse", nil, self, activator )
	if !activator:IsPlayer() or !canuse then return end
	net.Start( "CraftingTableMenu" )
	net.WriteEntity( self )
	net.WriteEntity( activator )
	net.Send( activator )
end

util.AddNetworkString( "StartCrafting" )
util.AddNetworkString( "CraftMessage" )
net.Receive( "StartCrafting", function( len, ply )
	local self = net.ReadEntity()
	local ent = net.ReadString()
	local entname = net.ReadString()
	local CraftMaterials = CraftingTable[ent].Materials
	local SpawnItem = CraftingTable[ent].SpawnFunction
	local SpawnCheck = CraftingTable[ent].SpawnCheck
	if CraftMaterials then
		for k,v in pairs( CraftMaterials ) do
			if self:GetNWInt( "Craft_"..k ) < v then
				ply:SendLua( [[
					chat.AddText( Color( 100, 100, 255 ), "[Crafting Table]: ", color_white, "Required items are not on the table!" ) 
					surface.PlaySound( GetConVar( "Craft_Config_Fail_Sound" ):GetString() )
				]] )
				return
			end
		end
		if SpawnCheck and !SpawnCheck( ply, self ) then return end
		if SpawnItem then
			local validfunction = true
			SpawnItem( ply, self )
			self:EmitSound( GetConVar( "Craft_Config_Craft_Sound" ):GetString() )
			net.Start( "CraftMessage" )
			net.WriteBool( validfunction )
			net.WriteString( entname )
			net.Send( ply )
			hook.Call( "Craft_OnStartCrafting", nil, ent, ply )
		else
			local validfunction = false
			net.Start( "CraftMessage" )
			net.WriteBool( validfunction )
			net.WriteString( entname )
			net.Send( ply )
			return
		end
		for k,v in pairs( CraftMaterials ) do
			self:SetNWInt( "Craft_"..k, self:GetNWInt( "Craft_"..k ) - v ) --Only removes required materials
		end
	end
end )

util.AddNetworkString( "DropItem" )
net.Receive( "DropItem", function( len, ply )
	local ent = net.ReadEntity()
	local item = net.ReadString()
	local e = ents.Create( item )
	e:SetPos( ent:GetPos() + Vector( 0, 70, 0 ) )
	e:Spawn()
	ent:SetNWInt( "Craft_"..item, ent:GetNWInt( "Craft_"..item ) - 1 )
	ent:EmitSound( GetConVar( "Craft_Config_Drop_Sound" ):GetString() )
	hook.Call( "Craft_OnDropItem", nil, ent, ply )
end )

function ENT:Touch( ent )
	for k,v in pairs( CraftingIngredient ) do
		if self.TouchCooldown and self.TouchCooldown > CurTime() then return end
		if k == ent:GetClass() then
			self:SetNWInt( "Craft_"..ent:GetClass(), self:GetNWInt( "Craft_"..ent:GetClass() ) + 1 )
			self:EmitSound( GetConVar( "Craft_Config_Place_Sound" ):GetString() )
			local effectdata = EffectData()
			effectdata:SetOrigin( ent:GetPos() )
			effectdata:SetScale( 2 )
			util.Effect( "ManhackSparks", effectdata )
			ent:Remove()
			hook.Call( "Craft_OnIngredientTouch", nil, self, ent )
			self.TouchCooldown = CurTime() + 0.1 --Small cooldown since ent:Touch runs multiple times before the for loop has time to break
			break
		end
	end
end

function ENT:OnTakeDamage( dmg )
	local candmg = hook.Call( "Craft_OnTakeDamage", nil, self, dmg )
	if !candmg then return end
	if self:Health() <= 0 and !self.Exploding then
		if GetConVar( "Craft_Config_Should_Explode" ):GetBool() then
			self.Exploding = true --Prevents a bunch of fires from spawning at once causing the server to hang for a few seconds if VFire is installed
			local e = ents.Create( "env_explosion" )
			e:SetPos( self:GetPos() )
			e:Spawn()
			e:SetKeyValue( "iMagnitude", 200 )
			e:Fire( "Explode", 0, 0 )
			self:Remove()
			hook.Call( "Craft_OnExplode", nil, self )
		else
			self:EmitSound( GetConVar( "Craft_Config_Destroy_Sound" ):GetString() )
			self:Remove()
		end
		return
	end
	local damage = dmg:GetDamage()
	self:SetHealth( self:Health() - damage )
end

--Example usage in an item spawn function: self:AddItem( "iron", 5 )
--The first argument must be the class name of a registered crafting ingredient
--If you want to remove an item, make the second argument negative
function ENT:AddItem( item, amount )
	self:SetNWInt( "Craft_"..item, math.Clamp( self:GetNWInt( "Craft_"..item ) + amount, 0, math.huge ) )
end
