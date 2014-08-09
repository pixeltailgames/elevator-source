ENT.Type   				= "anim"
ENT.Base                = "base_anim"
ENT.PrintName           = "Spooky Scary Skeleton BoneMERGED"
ENT.RenderGroup         = RENDERGROUP_TRANSLUCENT
ENT.ModelToMerge		= "models/skeleton/skeleton_whole.mdl"	

if SERVER then

	function ENT:Initialize()

		self:SetModel( "models/props_c17/oildrum001.mdl" )
		self:SetNoDraw( true )
		self:DrawShadow( false )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

		timer.Simple( .1, function()

			local ent = ents.Create( "npc_citizen" )
			ent:SetPos( self:GetPos() )
			ent:Spawn()
			
			umsg.Start( "ApplyBoneMerge" )
				umsg.Entity( ent )
				umsg.String( self.ModelToMerge )
			umsg.End()

		end )

	end
	
	function ENT:OnRemove()

		if ( self.NPCEntity ) then
			
			self.NPCEntity:Remove()
			self.NPCEntity = nil

		end
		
	end

end

if CLIENT then

	hook.Add( "PreDrawOpaqueRenderables", "BoneMergeHide", function()

		for _, ent in pairs( ents.GetAll() ) do
		
			if ( ent.BoneMerge ) then
				ent:AddEffects( EF_NODRAW )
			end

		end

	end )

	usermessage.Hook( "ApplyBoneMerge", function( um )

		local ent = um:ReadEntity()
		local model = um:ReadString()
	
		if !IsValid( ent ) then return end

		ent.BoneMerge = true
		ent:AddEffects( EF_NODRAW )
		
		ent.BoneMergeModel = ClientsideModel( model )
		ent.BoneMergeModel:AddEffects( EF_BONEMERGE )
		ent.BoneMergeModel:SetParent( ent )

	end )

	function ENT:Draw()

		if ( !self.NPCEntity ) then return end
		
		self.NPCEntity:AddEffects( EF_NODRAW )

		if ( self.NPCEntity.BoneMergeModel ) then
			self.NPCEntity.BoneMergeModel:SetParent( self )
		end

	end

	function ENT:OnRemove()

		if ( !self.NPCEntity ) then return end
	
		if ( self.NPCEntity.BoneMergeModel ) then

			self.NPCEntity.BoneMergeModel:Remove()
			self.NPCEntity.BoneMergeModel = nil

		end

	end

end