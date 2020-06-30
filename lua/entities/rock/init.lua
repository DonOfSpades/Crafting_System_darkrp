
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:SpawnFunction( ply, tr, name )
	if !tr.Hit then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 100
	local ent = ents.Create( name )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
    self:SetModel( table.Random( CRAFT_CONFIG_ROCK_MODELS ) )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )
	
    local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end

	self:SetHealth( GetConVar( "Craft_Config_Rock_Health" ):GetInt() )
	self:SetMaxHealth( GetConVar( "Craft_Config_Rock_Health" ):GetInt() )
	self:SetNWBool( "IsHidden", false )
end

local function UnhideEnt( ent )
	if IsValid( ent ) then
		ent:SetSolid( SOLID_VPHYSICS )
		ent:SetMoveType( MOVETYPE_VPHYSICS )
		ent:SetColor( color_white )
		ent:SetNWBool( "IsHidden", false )
		ent:SetHealth( ent:GetMaxHealth() )
		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion( false )
		end
	end
end

local function HideEnt( ent )
	if IsValid( ent ) then
		local color = ent:GetColor()
		ent:SetSolid( SOLID_NONE )
		ent:SetMoveType( MOVETYPE_NONE )
		ent:SetColor( ColorAlpha( color, 0 ) )
		ent:SetNWBool( "IsHidden", true )
		timer.Create( "Hidden_"..ent:EntIndex(), GetConVar( "Craft_Config_Rock_Respawn" ):GetInt(), 1, function() UnhideEnt( ent ) end )
	end
end

function ENT:OnTakeDamage( dmg )
	local ply = dmg:GetAttacker()
	local wep = ply:GetActiveWeapon()
	local hidden = self:GetNWBool( "IsHidden" )
	if !ply:IsPlayer() then return end
	if self:Health() <= 0 then return end
	if CRAFT_CONFIG_MINE_WHITELIST[string.lower( wep:GetClass() )] then
		local health = self:Health()
		local maxhealth = self:GetMaxHealth()
		self:SetHealth( health - ( maxhealth * 0.05 ) )
	end
	if self:Health() <= 0 and !hidden then
		for i=1, math.random( 2, 6 ) do
			local e = ents.Create( table.Random( CRAFT_CONFIG_ROCK_INGREDIENTS ) )
			e:SetPos( self:GetPos() + Vector( 0, 0, i * 5 ) )
			e:Spawn()
		end
		HideEnt( self )
	end
end

function ENT:OnRemove()
	local index = self:EntIndex()
	if timer.Exists( "Hidden_"..index ) then
		timer.Remove( "Hidden_"..index )
	end
end
