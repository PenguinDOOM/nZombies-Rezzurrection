AddCSLuaFile()

ENT.Base = "nz_zombiebase_moo"
ENT.PrintName = "Thrasher aka The Cheekeater"
ENT.Category = "Brainz"
ENT.Author = "Laby and Moo"

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Decapitated")
	self:NetworkVar("Bool", 1, "Alive")
	self:NetworkVar("Bool", 2, "MooSpecial")
end

--Girly weak ass bitch
--tag_spore_leg
--tag_spore_chest
--tag_spore_back

if CLIENT then return end -- Client doesn't really need anything beyond the basics

ENT.SpeedBasedSequences = true
ENT.IsMooZombie = true
ENT.RedEyes = true
ENT.IsMooSpecial = true

ENT.AttackRange = 100

ENT.Models = {
	{Model = "models/moo/_codz_ports/t7/island/thrasher/moo_codz_t7_thrasher.mdl", Skin = 0, Bodygroups = {0,0}},
}

local spawn = {"nz_trav_teleport_in"}

ENT.DeathSequences = {
	"nz_death_v1",
	"nz_death_v2"
}

ENT.BarricadeTearSequences = {
	--Leave this empty if you don't intend on having a special enemy use tear anims.
}

local AttackSequences = {
	{seq = "nz_attack_v1", dmgtimes = {0.7}},
	{seq = "nz_attack_v2", dmgtimes = {0.7}},
}

local JumpSequences = {
	{seq = "nz_trav_barricadejump", speed = 15, time = 2.5},
}

local walksounds = {
	Sound("enemies/bosses/thrasher/vox/ambient_01.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_02.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_03.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_04.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_05.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_06.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_07.ogg"),
	Sound("enemies/bosses/thrasher/vox/ambient_08.ogg")
}

ENT.AttackSounds = {
	"enemies/bosses/thrasher/vox/attack_01.ogg",
	"enemies/bosses/thrasher/vox/attack_02.ogg",
	"enemies/bosses/thrasher/vox/attack_03.ogg"
}

ENT.PainSounds = {
	"nz/zombies/death/nz_flesh_impact_1.wav",
	"nz/zombies/death/nz_flesh_impact_2.wav",
	"nz/zombies/death/nz_flesh_impact_3.wav",
	"nz/zombies/death/nz_flesh_impact_4.wav"
}

ENT.DeathSounds = {
	"enemies/bosses/thrasher/vox/death_01.ogg",
	"enemies/bosses/thrasher/vox/death_02.ogg",
	"enemies/bosses/thrasher/vox/death_03.ogg",
}

ENT.ActStages = {
	[1] = {
		act = ACT_WALK,
		minspeed = 0,
		attackanims = AttackSequences,
		barricadejumps = JumpSequences,
	}
}

ENT.IdleSequence = "nz_idle"

ENT.SequenceTables = {
	{Threshold = 0, Sequences = {
		{
			SpawnSequence = {spawn},
			MovementSequence = {
				"nz_walk_v1",
				"nz_walk_v2",
			},
			PassiveSounds = {walksounds},
		},
	}},
	{Threshold = 75, Sequences = {
		{
			SpawnSequence = {spawn},
			MovementSequence = {
				"nz_run_v1",
				"nz_run_v2",
			},
			PassiveSounds = {walksounds},
		},
	}}
}

function ENT:StatsInitialize()
	if SERVER then
		enraged = false
		self.NextAction = 0
		self.NextTeleporTime = 0
		self:SetMooSpecial(true)
		self:SetRunSpeed( 60 )
		self.loco:SetDesiredSpeed( 60 )
		self:SetCollisionBounds(Vector(-16,-16, 0), Vector(16, 16, 70))
	end
end

function ENT:OnSpawn()

	self:SolidMaskDuringEvent(MASK_SOLID_BRUSHONLY)
	self:EmitSound("enemies/bosses/thrasher/vox/spawn_0"..math.random(1,2)..".ogg",511)
	self:EmitSound("enemies/bosses/thrasher/tele_hand_up.ogg",511)
	ParticleEffect("bo3_zombie_spawn",self:GetPos()+Vector(0,0,1),Angle(0,0,0),nil)
	self:SetInvulnerable(true)

	self:EmitSound("enemies/bosses/thrasher/teleport_in_01.ogg",511)
	self:EmitSound("enemies/bosses/thrasher/dst_rock_quake_0"..math.random(1,5)..".ogg",511)
	for i=1,1 do
		ParticleEffect("bo3_panzer_landing",self:LocalToWorld(Vector(20+(i*2),20,0)),Angle(0,0,0),nil)
	end
	self:SetSpecialAnimation(true)
	local seq = self:SelectSpawnSequence()
	if seq then
		self:PlaySequenceAndWait(seq)
		self:SetSpecialAnimation(false)
		self:SetInvulnerable(false)
		self:CollideWhenPossible()
	end
end

function ENT:PerformDeath(dmgInfo)
	if self:GetSpecialAnimation() then
		self:PlaySound(self.DeathSounds[math.random(#self.DeathSounds)], 90, math.random(85, 105), 1, 2)
		if IsValid(self) then
			ParticleEffect("bo3_margwa_death",self:LocalToWorld(Vector(0,0,0)),Angle(0,0,0),nil)
			self:Remove()
		end
	else
		self:PlaySound(self.DeathSounds[math.random(#self.DeathSounds)], 90, math.random(85, 105), 1, 2)
		self:DoDeathAnimation(self.DeathSequences[math.random(#self.DeathSequences)])
	end
end

function ENT:DoDeathAnimation(seq)
	self.BehaveThread = coroutine.create(function()
		self:PlaySequenceAndWait(seq)
		if IsValid(self) then
			ParticleEffect("bo3_margwa_death",self:LocalToWorld(Vector(0,0,0)),Angle(0,0,0),nil)
			self:Remove()
		end
	end)
end

local function GetClearPaths(ent, pos, tiles)
	local clearPaths = {}
	local filter = player.GetAll()
	for _, tile in pairs( tiles ) do
		local tr = util.TraceLine({
			start = pos,
			endpos = tile,
			filter = filter,
			mask = MASK_PLAYERSOLID
		})
		
		if not tr.Hit and util.IsInWorld(tile) then
			table.insert( clearPaths, tile )
		end
	end
	
	return clearPaths
end

local function GetSurroundingTiles(ent, pos)
	local tiles = {}
	local x, y, z
	local minBound, maxBound = ent:OBBMins(), ent:OBBMaxs()
	local checkRange = math.max(12, maxBound.x, maxBound.y)
	
	for z = -1, 1, 1 do
		for y = -1, 1, 1 do
			for x = -1, 1, 1 do
				local testTile = Vector(x,y,z)
				testTile:Mul( checkRange )
				local tilePos = pos + testTile
				table.insert( tiles, tilePos )
			end
		end
	end
	
	return tiles
end

local function CollisionBoxClear(ent, pos, minBound, maxBound)
	local filter = {ent}
	local tr = util.TraceEntity({
		start = pos,
		endpos = pos,
		filter = filter,
		mask = MASK_PLAYERSOLID
	}, ent)

	return !tr.StartSolid || !tr.AllSolid
end

function ENT:FindSpotBehindPlayer(pos, count, range, stepd, stepu)
	local targ = self:GetTarget()
	pos = pos or targ:GetPos()
	range = range or 100
	stepd = stepd or 25
	stepu = stepu or 25
	count = count or 6

	if navmesh.IsLoaded() then
		local tab = navmesh.Find(pos, range, stepd, stepu)
		local postab = {}

		for i=1, count do
			for _, nav in RandomPairs(tab) do
				if IsValid(nav) and not nav:IsUnderwater() then
					local testpos = nav:GetRandomPoint()
					local norm = (testpos - pos):GetNormal()

					if targ:GetAimVector():Dot(norm) < 0 then
						table.insert(postab, testpos)
						break
					end
				end
			end
		end

		if not table.IsEmpty(postab) then
			table.sort(postab, function(a, b) return a:DistToSqr(pos) < b:DistToSqr(pos) end)
			pos = postab[1]
		end
	end

	local minBound, maxBound = self:OBBMins(), self:OBBMaxs()
	if not CollisionBoxClear( self, pos, minBound, maxBound ) then
		local surroundingTiles = GetSurroundingTiles( self, pos )
		local clearPaths = GetClearPaths( self, pos, surroundingTiles )	
		for _, tile in pairs( clearPaths ) do
			if CollisionBoxClear( self, tile, minBound, maxBound ) then
				pos = tile
				break
			end
		end
	end

	return pos
end

function ENT:OnPathTimeOut()
	local target = self:GetTarget()
	local actionchance = math.random(10)
	if CurTime() < self.NextAction then return end
	for k,v in pairs(player.GetAll()) do
		if not v:GetNotDowned() and enraged then
			if math.random(5) == 3 and CurTime() > self.NextTeleporTime then
				-- Eat downed players, His chance is near always. So if he's angered... Fuck you :)
				for k,v in pairs(player.GetAll()) do
					if v:GetNotDowned() then
					else
						self:SetTarget(v)
						target = self:GetTarget()
					end
				end
				if math.random(100) == 69 then
					self:EmitSound("Thrasher_roar_laby.wav",511)
				else
					self:EmitSound("enemies/bosses/thrasher/vox/spawn_0"..math.random(1,2)..".ogg",511)
				end
				self:SolidMaskDuringEvent(MASK_SOLID_BRUSHONLY)
				self:SetSpecialAnimation(true)
				self:SetBlockAttack(true)
				timer.Simple(0.2, function()
					ParticleEffect("bo3_astronaut_pulse",self:LocalToWorld(Vector(0,0,60)),Angle(0,0,0),nil)				
				end)
				self:SetAngles((target:GetPos() - self:GetPos()):Angle())
				self:PlaySequenceAndWait("nz_anger")
				timer.Simple(1, function()
					self:EmitSound("enemies/bosses/thrasher/teleport_in_01.ogg",511)
					self:EmitSound("enemies/bosses/thrasher/dst_rock_quake_0"..math.random(1,5)..".ogg",511)
					for i=1,1 do
						ParticleEffect("bo3_panzer_landing",self:LocalToWorld(Vector(20+(i*2),20,0)),Angle(0,0,0),nil)
					end
				end)
				self:PlaySequenceAndWait("nz_trav_teleport_out")

				local pos = self:FindSpotBehindPlayer(target:GetPos(), 10)
				self:SetPos( pos )
				self:EmitSound("roach/bo3/thrasher/vox/spawn_0"..math.random(2)..".mp3",511)
				self:EmitSound("roach/bo3/thrasher/tele_hand_up.mp3",511)
				ParticleEffect("bo3_zombie_spawn",self:GetPos()+Vector(0,0,1),Angle(0,0,0),nil)

				local ang1 = (target:GetPos() - self:GetPos()):Angle()
				self:SetAngles(Angle(ang1[1], ang1[2] + 10, ang1[3]))
				self:PlaySequenceAndWait("nz_trav_teleport_in")
				self:CollideWhenPossible()

				local ang2 = (target:GetPos() - self:GetPos()):Angle()
				self:SetAngles(Angle(ang2[1], ang2[2] + 10, ang2[3]))
				timer.Simple(2, function()
					if IsValid(self) and not target:GetNotDowned() then
						local succ = self:GetBonePosition( 27 )
						self:EmitSound("exploder/explode/brute_armour_slide_flesh_00.wav")
						self:EmitSound("tubebeetle/explode/tubebeetle_pop_03.wav")
						self:EmitSound("tubebeetle/explode/tubebeetle_pop_03.wav")
						self:EmitSound("exploder/explode/brute_belly_puss_shared_01.wav")
						self:EmitSound("exploder/explode/brute_puss_bomb_l_shared_00.wav")
						self:EmitSound("divider/divider_merge_18.wav")
						self:EmitSound("divider/divider_merge_18.wav")
						self:EmitSound("bo1_overhaul/n6/xplo"..math.random(2)..".mp3")
						ParticleEffect("divider_slash2",succ,Angle(0,0,0),nil)
						ParticleEffect("divider_slash3",succ,Angle(0,0,0),nil)
						ParticleEffect("baby_dead",succ,Angle(0,0,0),nil)
						if self:Alive() then -- Bitch don't you eat those cheeks from beyond the grave.
							target:Kill() -- CHEEEEEEKSSSSSSSS
						end
					end
				end)
				
				if not target:GetNotDowned() and IsValid(self) then
					self:PlaySequenceAndWait("nz_consume")
				end
				
				self:Retarget()
				self:SetSpecialAnimation(false)
				self:SetBlockAttack(false)
				self:ResetMovementSequence()
			
				self.NextAction = CurTime() + math.random(1, 5)
				self.NextTeleporTime = CurTime() + math.random(1, 10)
			end
		else
			if actionchance == 2 and CurTime() > self.NextTeleporTime then
				--YOU CAN'T ESCAPE
				self:SolidMaskDuringEvent(MASK_SOLID_BRUSHONLY)
				self:SetSpecialAnimation(true)
				self:SetBlockAttack(true)
				self:SetAngles((target:GetPos() - self:GetPos()):Angle())
	
				timer.Simple(1, function()
					self:EmitSound("enemies/bosses/thrasher/teleport_in_01.ogg",511)
					self:EmitSound("enemies/bosses/thrasher/dst_rock_quake_0"..math.random(1,5)..".ogg",511)
					for i=1,1 do
						ParticleEffect("bo3_panzer_landing",self:LocalToWorld(Vector(20+(i*2),20,0)),Angle(0,0,0),nil)
					end	
				end)
				self:PlaySequenceAndWait("nz_trav_teleport_out")

				local pos = self:FindSpotBehindPlayer(target:GetPos(), 10)
				self:SetPos( pos )
				self:EmitSound("enemies/bosses/thrasher/vox/spawn_0"..math.random(1,2)..".ogg",511)
				self:EmitSound("enemies/bosses/thrasher/enrage_imp_00.ogg",511)
				ParticleEffect("bo3_zombie_spawn",self:GetPos()+Vector(0,0,1),Angle(0,0,0),nil)	

				local ang1 = (target:GetPos() - self:GetPos()):Angle()
				self:SetAngles(Angle(ang1[1], ang1[2] + 10, ang1[3]))
				self:PlaySequenceAndWait("nz_trav_teleport_in")
				self:CollideWhenPossible()

				local ang2 = (target:GetPos() - self:GetPos()):Angle()
				self:SetAngles(Angle(ang2[1], ang2[2] + 10, ang2[3]))
				self:SetSpecialAnimation(false)
				self:SetBlockAttack(false)
				self:ResetMovementSequence()
			
				self.NextAction = CurTime() + math.random(1, 5)
				self.NextTeleporTime = CurTime() + math.random(1, 8)
			elseif not enraged and actionchance == 1 and CurTime() > self.NextAction then
				enraged = true -- OOOOOOO PISS EM
				self:EmitSound("enemies/bosses/thrasher/vox/spawn_0"..math.random(1,2)..".ogg",511)
				self:EmitSound("enemies/bosses/thrasher/enrage_imp_00.ogg",511)
				ParticleEffect("bo3_astronaut_pulse",self:LocalToWorld(Vector(0,0,60)),Angle(0,0,0),nil)
				self:PlaySequenceAndWait("nz_anger")
				self:SetRunSpeed(150)
				self.loco:SetDesiredSpeed(150)
				self:SpeedChanged() -- Updates current anim to be a sprinting one.
			end
		end
	end
end

function ENT:PlayAttackAndWait( name, speed )

	local len = self:SetSequence( name )
	speed = speed or 1

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )

	local endtime = CurTime() + len / speed

	while ( true ) do

		if ( endtime < CurTime() ) then
			if !self:GetStop() then
				self:StartActivity( ACT_WALK )
				self.loco:SetDesiredSpeed( self:GetRunSpeed() )
			end
			return
		end
		if self:IsValidTarget( self:GetTarget() ) then
			self.loco:FaceTowards( self:GetTarget():GetPos() )
		end

		coroutine.yield()

	end

end


-- A standard attack you can use it or create something fancy yourself
function ENT:Attack( data )

	self:SetLastAttack(CurTime())

	data = data or {}
	
	data.attackseq = data.attackseq
	if !data.attackseq then
		local curstage = self:GetActStage()
		local actstage = self.ActStages[curstage]
		if !self:GetCrawler() and !actstage and curstage <= 0 then actstage = self.ActStages[1] end
		--if self:GetCrawler() then self.CrawlAttackSequences end
		
		local attacktbl = actstage and actstage.attackanims or self.AttackSequences
		local target = type(attacktbl) == "table" and attacktbl[math.random(#attacktbl)] or attacktbl
		
		if type(target) == "table" then
			local id, dur = self:LookupSequenceAct(target.seq)
			if !target.dmgtimes then
			data.attackseq = {seq = id, dmgtimes =  {0.5} }
			else
			data.attackseq = {seq = id, dmgtimes = target.dmgtimes }
			end
			data.attackdur = dur
		elseif target then -- It is a string or ACT
			local id, dur = self:LookupSequenceAct(attacktbl)
			data.attackseq = {seq = id, dmgtimes = {dur/2}}
			data.attackdur = dur
		else
			local id, dur = self:LookupSequence("swing")
			data.attackseq = {seq = id, dmgtimes = {1}}
			data.attackdur = dur
		end
	end
	
	self:SetAttacking( true )

	if self:GetTarget():IsPlayer() then
		for k,v in pairs(data.attackseq.dmgtimes) do
			self:TimedEvent( v, function()
				if self.AttackSounds then self:PlaySound(self.AttackSounds[math.random(#self.AttackSounds)], 100, math.random(85, 105), 1, 2) end
				self:EmitSound( "enemies/bosses/thrasher/swing_0"..math.random(1,7)..".ogg", 90, math.random(95, 105))
				if !self:GetStop() and self:IsValidTarget( self:GetTarget() ) and self:TargetInRange( self:GetAttackRange() + 10 ) then
					local dmgInfo = DamageInfo()
					dmgInfo:SetAttacker( self )
					dmgInfo:SetDamage( 90 ) -- OW, STUPID BITCH!!!!
					dmgInfo:SetDamageType( DMG_SLASH )
					dmgInfo:SetDamageForce( (self:GetTarget():GetPos() - self:GetPos()) * 7 + Vector( 0, 0, 16 ) )
					self:GetTarget():TakeDamageInfo(dmgInfo)
					if !IsValid(self:GetTarget()) then return end
					self:GetTarget():EmitSound( "nz/zombies/attack/player_hit_"..math.random(0,5)..".wav", SNDLVL_TALKING, math.random(95,105))
					self:GetTarget():ViewPunch( VectorRand():Angle() * 0.01 )
				end
			end)
		end
	end

	self:TimedEvent(data.attackdur, function()
		self:SetAttacking(false)
		self:SetLastAttack(CurTime())
	end)

	self:PlayAttackAndWait(data.attackseq.seq, 1)
end

function ENT:IsValidTarget( ent )
	if not ent then return false end
	return IsValid( ent ) and ent:GetTargetPriority() ~= TARGET_PRIORITY_NONE and ent:GetTargetPriority() ~= TARGET_PRIORITY_SPECIAL
end